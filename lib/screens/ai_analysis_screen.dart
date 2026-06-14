import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/stats_calculator_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';

/// Full-screen page for AI training analysis.
/// Generates a rich prompt from workout data and lets users copy it to external AI tools.
class AIAnalysisScreen extends StatefulWidget {
  final String periodType; // 'week' or 'month'
  final DateTime startDate;
  final DateTime endDate;
  final List<WorkoutRecord> records; // current period
  final List<WorkoutRecord>
  previousRecords; // previous period for trend comparison
  final List<WorkoutRecord> allRecords; // all records for recovery calculation

  const AIAnalysisScreen({
    super.key,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.records,
    required this.previousRecords,
    required this.allRecords,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  String? _generatedPrompt;
  bool _isPromptCopied = false;

  final StatsCalculatorService _statsCalc = StatsCalculatorService();

  // User preferences loaded asynchronously
  String _selectedGoal = 'muscle_building';
  String _selectedExperience = 'intermediate';
  String _selectedEquipment = 'gym';
  int _selectedFrequency = 4;
  final Set<String> _selectedFocusAreas = {};

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await UserPreferencesService().loadPreferences().timeout(
        const Duration(seconds: 2),
      );
      setState(() {
        _selectedGoal = prefs.goal;
        _selectedExperience = prefs.experience;
        _selectedEquipment = prefs.equipment;
        _selectedFrequency = prefs.frequency;
        _selectedFocusAreas.clear();
        _selectedFocusAreas.addAll(prefs.focusAreasList);
        _generatedPrompt = _generatePrompt();
      });
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      setState(() {
        _generatedPrompt = _generatePrompt();
      });
    }
  }

  // ==================== Data Calculation ====================

  /// Calculate estimated 1RM trend with English exercise names for AI prompt.
  ///
  /// Same logic as [StatsCalculatorService.calculateEstimated1RMTrend] but keys
  /// by `nameEn` (falling back to `name` / `exerciseId`) so the generated prompt
  /// uses standard English exercise names that AI models recognise.
  Map<String, List<Estimated1RMPoint>> _calculate1RMTrendEn(
    List<WorkoutRecord> records,
  ) {
    final result = <String, List<Estimated1RMPoint>>{};

    for (final record in records) {
      final sessionBest = <String, Estimated1RMPoint>{};

      for (final recordedExercise in record.exercises) {
        final name = recordedExercise.nameEn.isNotEmpty
            ? recordedExercise.nameEn
            : (recordedExercise.name.isNotEmpty
                  ? recordedExercise.name
                  : recordedExercise.exerciseId);
        if (name.isEmpty) continue;

        final sets = recordedExercise.setsData;
        if (sets == null || sets.isEmpty) continue;

        for (final set in sets) {
          if (set.weight == null || set.weight! <= 0) continue;
          if (set.reps == null || set.reps! <= 0) continue;

          final e1RM = StatsCalculatorService.estimate1RM(
            set.weight!,
            set.reps!,
          );
          final current = sessionBest[name];
          if (current == null || e1RM > current.estimated1RM) {
            sessionBest[name] = Estimated1RMPoint(
              date: record.date,
              estimated1RM: e1RM,
              weight: set.weight!,
              reps: set.reps,
            );
          }
        }
      }

      for (final entry in sessionBest.entries) {
        result.putIfAbsent(entry.key, () => []);
        result[entry.key]!.add(entry.value);
      }
    }

    for (final points in result.values) {
      points.sort((a, b) => a.date.compareTo(b.date));
    }

    return result;
  }

  // ==================== Formatting Methods ====================

  /// Format muscle volume distribution (weighted by training volume)
  String _formatMuscleVolumeDistribution() {
    final dist = _statsCalc.calculateMuscleVolumeDistribution(widget.records);
    if (dist.isEmpty) return '- 暂无肌肉训练数据';

    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);

    final buffer = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final pct = total > 0
          ? (entry.value / total * 100).toStringAsFixed(1)
          : '0.0';
      final volumeStr = entry.value >= 1000
          ? '${(entry.value / 1000).toStringAsFixed(1)}k'
          : entry.value.toStringAsFixed(0);
      buffer.writeln(
        '  ${i + 1}. ${entry.key.displayName}: $volumeStr kg ($pct%)',
      );
    }
    return buffer.toString().trimRight();
  }

  /// Format volume trend (current vs previous period)
  String _formatVolumeTrend() {
    final currentVolume = _statsCalc.calculateTotalVolume(widget.records);
    final previousVolume = _statsCalc.calculateTotalVolume(
      widget.previousRecords,
    );

    if (currentVolume == 0 && previousVolume == 0) return '- 暂无趋势数据';

    final buffer = StringBuffer();
    String fmtVol(double v) => v >= 1000
        ? '${(v / 1000).toStringAsFixed(1)}k kg'
        : '${v.toStringAsFixed(0)} kg';

    // Total volume trend
    if (previousVolume > 0) {
      final change = ((currentVolume - previousVolume) / previousVolume * 100)
          .round();
      final arrow = change > 0
          ? '↑'
          : change < 0
          ? '↓'
          : '→';
      buffer.writeln(
        '  - 总训练量: ${fmtVol(currentVolume)} (${change > 0 ? '+' : ''}$change% $arrow)',
      );
    } else {
      buffer.writeln('  - 总训练量: ${fmtVol(currentVolume)} (新周期)');
    }

    // Training frequency trend
    final currentDays = _countUniqueDays(widget.records);
    final previousDays = _countUniqueDays(widget.previousRecords);
    if (previousDays > 0) {
      final diff = currentDays - previousDays;
      final arrow = diff > 0
          ? '↑'
          : diff < 0
          ? '↓'
          : '→';
      buffer.writeln('  - 训练频率: $currentDays 天 ($diff$arrow)');
    }

    // Per-muscle volume trend
    final currentMuscleVol = _statsCalc.calculateMuscleVolumeDistribution(
      widget.records,
    );
    final previousMuscleVol = _statsCalc.calculateMuscleVolumeDistribution(
      widget.previousRecords,
    );
    final allMuscles = {
      ...currentMuscleVol.keys,
      ...previousMuscleVol.keys,
    }.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

    for (final muscle in allMuscles) {
      final curr = currentMuscleVol[muscle] ?? 0;
      final prev = previousMuscleVol[muscle] ?? 0;
      if (prev > 0 && curr > 0) {
        final change = ((curr - prev) / prev * 100).round();
        if (change.abs() >= 10) {
          final arrow = change > 0 ? '↑' : '↓';
          buffer.writeln(
            '  - ${muscle.displayName}: ${change > 0 ? '+' : ''}$change% $arrow',
          );
        }
      }
    }

    return buffer.toString().trimRight();
  }

  /// Format sets per muscle group with MEV reference
  String _formatSetsPerMuscleGroup() {
    final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(
      widget.records,
    );
    if (setsPerMuscle.isEmpty) return '- 暂无组数数据';

    final isWeek = widget.periodType == 'week';
    // MEV reference: 10 sets/week (Schoenfeld 2017)
    const weeklyMev = 10;
    final mevLabel = isWeek
        ? '周MEV参考: $weeklyMev 组'
        : '月MEV参考: ${weeklyMev * 4} 组';

    final sorted = setsPerMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('  ($mevLabel)');
    for (final entry in sorted) {
      final sets = entry.value;
      final ratio = isWeek ? sets / weeklyMev : sets / (weeklyMev * 4);
      String status;
      if (ratio >= 1.0) {
        status = '✅ 充足';
      } else if (ratio >= 0.5) {
        status = '⚠️ 偏低';
      } else {
        status = '🔴 不足';
      }
      buffer.writeln('  - ${entry.key.displayName}: $sets 组 $status');
    }
    return buffer.toString().trimRight();
  }

  /// Format estimated 1RM for top exercises (uses English names for AI)
  String _formatEstimated1RM() {
    final trend = _calculate1RMTrendEn(widget.records);
    if (trend.isEmpty) return '- 暂无1RM数据（需要每组重量和次数记录）';

    // Sort by estimated1RM descending (best session), take top 10
    final sorted = trend.entries.toList()
      ..sort(
        (a, b) =>
            b.value.last.estimated1RM.compareTo(a.value.last.estimated1RM),
      );

    final buffer = StringBuffer();
    buffer.writeln('  (基于 Mayhew 公式估算，±5-8kg 误差)');
    for (final entry in sorted.take(10)) {
      final point = entry.value.last;
      final e1RM = point.estimated1RM.toStringAsFixed(1);
      final w = point.weight.toStringAsFixed(1);
      final r = point.reps ?? 0;
      buffer.writeln('  - ${entry.key}: ~$e1RM kg (基于 ${w}kg×$r)');
    }
    return buffer.toString().trimRight();
  }

  /// Format 1RM progression trend (month view only)
  String _format1RMProgression() {
    final trend = _calculate1RMTrendEn(widget.records);
    if (trend.isEmpty) return '- 暂无1RM趋势数据';

    // Filter to exercises with 2+ sessions, sort by change%
    final progressable = <MapEntry<String, List<Estimated1RMPoint>>>[];
    for (final entry in trend.entries) {
      if (entry.value.length >= 2) {
        progressable.add(entry);
      }
    }

    if (progressable.isEmpty) return '- 本周期内各动作仅训练1次，无法计算进步趋势';

    progressable.sort((a, b) {
      final changeA =
          (a.value.last.estimated1RM - a.value.first.estimated1RM) /
          a.value.first.estimated1RM;
      final changeB =
          (b.value.last.estimated1RM - b.value.first.estimated1RM) /
          b.value.first.estimated1RM;
      return changeB.compareTo(changeA);
    });

    final buffer = StringBuffer();
    for (final entry in progressable.take(10)) {
      final first = entry.value.first;
      final last = entry.value.last;
      final change =
          ((last.estimated1RM - first.estimated1RM) / first.estimated1RM * 100);
      final weeks = last.date.difference(first.date).inDays / 7.0;
      final arrow = change > 0
          ? '↑'
          : change < 0
          ? '↓'
          : '→';
      buffer.writeln(
        '  - ${entry.key}: ${first.estimated1RM.toStringAsFixed(1)} → ${last.estimated1RM.toStringAsFixed(1)} kg (${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}% $arrow${weeks > 0 ? ' / ${weeks.toStringAsFixed(0)}周' : ''})',
      );
    }
    return buffer.toString().trimRight();
  }

  /// Format recovery management data (calculate rest days per muscle)
  String _formatRecoveryManagement() {
    // Recovery is a global state (not period-specific)
    final records = widget.allRecords.isNotEmpty
        ? widget.allRecords
        : widget.records;
    if (records.isEmpty) return '- 暂无恢复数据';

    final Map<PrimaryMuscleGroup, DateTime> lastTrainedDates = {};
    for (final record in records) {
      final muscles = _getMusclesFromRecord(record);
      for (final muscle in muscles) {
        final existingDate = lastTrainedDates[muscle];
        if (existingDate == null || record.date.isAfter(existingDate)) {
          lastTrainedDates[muscle] = record.date;
        }
      }
    }

    if (lastTrainedDates.isEmpty) return '- 暂无肌肉恢复数据';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buffer = StringBuffer();

    final sortedEntries = lastTrainedDates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sortedEntries) {
      final lastDate = DateTime(
        entry.value.year,
        entry.value.month,
        entry.value.day,
      );
      final restDays = today.difference(lastDate).inDays;
      String status;
      if (restDays >= 3) {
        status = '✅ 可训练';
      } else if (restDays >= 1) {
        status = '⚠️ 建议再休息${3 - restDays}天';
      } else {
        status = '🔴 今日刚训练';
      }
      buffer.writeln('  - ${entry.key.displayName}: 已休息$restDays天 $status');
    }

    return buffer.toString().trimRight();
  }

  // ==================== Helpers ====================

  /// Count unique training days
  int _countUniqueDays(List<WorkoutRecord> records) {
    final days = <String>{};
    for (final r in records) {
      days.add('${r.date.year}-${r.date.month}-${r.date.day}');
    }
    return days.length;
  }

  /// Extract trained muscles from a record, using exercise.primaryMuscle when available.
  /// Falls back to record.trainedMuscles when no exercise detail is loaded.
  Set<PrimaryMuscleGroup> _getMusclesFromRecord(WorkoutRecord record) {
    final fromExercises = <PrimaryMuscleGroup>{};
    for (final e in record.exercises) {
      if (e.exercise != null) {
        fromExercises.add(e.exercise!.primaryMuscle);
      }
    }
    if (fromExercises.isNotEmpty) return fromExercises;
    return record.trainedMuscles.toSet();
  }

  // ==================== Prompt Generation ====================

  String _generatePrompt() {
    final isWeek = widget.periodType == 'week';
    final periodLabel = isWeek ? '本周' : '本月';
    final dateRange =
        '${widget.startDate.month}月${widget.startDate.day}日 - ${widget.endDate.month}月${widget.endDate.day}日';

    final goalLabels = {
      'muscle_building': '增肌',
      'fat_loss': '减脂',
      'strength': '力量提升',
      'endurance': '耐力增强',
    };
    final experienceLabels = {
      'beginner': '初学者',
      'intermediate': '中级',
      'advanced': '高级',
    };
    final equipmentLabels = {
      'gym': '健身房(全器械)',
      'home_dumbbell': '家用哑铃',
      'bodyweight': '徒手',
    };
    final muscleLabels = {
      'chest': '胸部',
      'back': '背部',
      'shoulders': '肩部',
      'arms': '手臂',
      'legs': '腿部',
      'core': '核心',
    };

    // Basic statistics
    final totalVolume = _statsCalc.calculateTotalVolume(widget.records);
    final density = _statsCalc.calculateDensity(widget.records);
    final sessionCount = widget.records.length;
    final workoutDays = _countUniqueDays(widget.records);
    String fmtVol(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

    final buffer = StringBuffer();

    // Opening — period-adaptive
    buffer.writeln('你是一位专业的健身教练。根据我的训练数据报告，为我制定下个周期的训练计划。');
    if (isWeek) {
      buffer.writeln('本周数据量较少，重点关注恢复状态和下周的肌群轮换安排。');
    } else {
      buffer.writeln('本月数据较充分，重点关注渐进超负荷趋势和肌群容量分配是否均衡。');
    }
    buffer.writeln();

    // Training data report
    buffer.writeln('## 训练数据报告');
    buffer.writeln();

    // Basic info
    buffer.writeln('### 基本信息');
    buffer.writeln('- 分析周期: $periodLabel ($dateRange)');
    buffer.writeln('- 训练次数: $sessionCount 次 / $workoutDays 天');
    buffer.writeln('- 总训练量: ${fmtVol(totalVolume)} kg (组×次×重量)');
    buffer.writeln('- 训练密度: ${density.toStringAsFixed(1)} 组/分钟');
    buffer.writeln();

    // Trend changes
    buffer.writeln('### 趋势变化（vs 上${isWeek ? '周' : '月'}）');
    buffer.writeln(_formatVolumeTrend());
    buffer.writeln();

    // Muscle volume distribution
    buffer.writeln('### 肌肉容量分布');
    buffer.writeln(_formatMuscleVolumeDistribution());
    buffer.writeln();

    // Sets per muscle group (NEW)
    buffer.writeln('### 每肌群组数');
    buffer.writeln(_formatSetsPerMuscleGroup());
    buffer.writeln();

    // Estimated 1RM (REPLACED from PR)
    buffer.writeln('### 估算1RM（本周期最佳，TOP 10）');
    buffer.writeln(_formatEstimated1RM());
    buffer.writeln();

    // 1RM progression — MONTH ONLY
    if (!isWeek) {
      buffer.writeln('### 估算1RM进步趋势');
      buffer.writeln(_format1RMProgression());
      buffer.writeln();
    }

    // Recovery status
    buffer.writeln('### 恢复状态（截至今天，全局数据）');
    buffer.writeln(_formatRecoveryManagement());
    buffer.writeln();

    // User profile
    buffer.writeln('## 用户画像');
    buffer.writeln('- 训练目标: ${goalLabels[_selectedGoal] ?? _selectedGoal}');
    buffer.writeln(
      '- 经验水平: ${experienceLabels[_selectedExperience] ?? _selectedExperience}',
    );
    buffer.writeln('- 每周频率: $_selectedFrequency 天');
    buffer.writeln(
      '- 可用设备: ${equipmentLabels[_selectedEquipment] ?? _selectedEquipment}',
    );
    if (_selectedFocusAreas.isNotEmpty) {
      buffer.writeln(
        '- 重点加强: ${_selectedFocusAreas.map((m) => muscleLabels[m] ?? m).join('、')}',
      );
    }
    buffer.writeln();

    // Output format
    buffer.writeln('## 输出格式');
    buffer.writeln('请按以下两部分输出你的回复：');
    buffer.writeln();
    buffer.writeln('**第一部分：计划设计说明**');
    buffer.writeln();
    buffer.writeln('根据我的训练数据报告，详细说明你为什么这样设计下个周期的训练计划，包括：');
    buffer.writeln('- 分化方式的选择理由（结合我每周 $workoutDays 天的训练频率）');
    buffer.writeln('- 与本周期数据的对比分析（哪些肌群训练不足需要加强，哪些已经过度需要恢复）');
    buffer.writeln('- 每个训练日的动作选择逻辑和容量分配依据');
    buffer.writeln('- 渐进超负荷的具体建议（重量、组数、频率的调整方向）');
    buffer.writeln();
    buffer.writeln('**第二部分：训练计划 JSON**');
    buffer.writeln();
    buffer.writeln('在分析之后，用 ```json 代码块提供结构化训练计划：');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "name": "计划名称",');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "dayOfWeek": 1,');
    buffer.writeln('      "targetMuscles": ["chest", "shoulders"],');
    buffer.writeln('      "exercises": [');
    buffer.writeln(
      '        {"exerciseName": "Barbell Bench Press", "targetSets": 4}',
    );
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('## 动作命名规范');
    buffer.writeln('使用标准英文动作名：');
    buffer.writeln(
      '- 杠铃: Barbell Bench Press, Barbell Squat, Deadlift, Overhead Press, Barbell Row',
    );
    buffer.writeln(
      '- 哑铃: Incline Dumbbell Press, Dumbbell Fly, Dumbbell Curl, Lateral Raise',
    );
    buffer.writeln('- 器械: Cable Fly, Cable Crossover, Lat Pulldown, Leg Press');
    buffer.writeln('- 徒手: Pull-up, Dip, Push-up, Bodyweight Squat');
    buffer.writeln('如果不确定确切名称，使用标准术语即可。');
    buffer.writeln();
    buffer.writeln('请先解释你的设计思路和分析，然后生成训练计划。');

    return buffer.toString();
  }

  // ==================== UI Building ====================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final isWeek = widget.periodType == 'week';

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Instructions
            _buildInstructionsBox(theme),
            const SizedBox(height: 24),

            // Section 2: Training Data Report
            _buildSectionHeader('训练数据报告', theme),
            const SizedBox(height: 12),

            // a) Basic Info
            _buildGlassCard(theme: theme, child: _buildBasicInfoSection(theme)),
            const SizedBox(height: 12),

            // b) Trend Changes
            _buildGlassCard(theme: theme, child: _buildTrendSection(theme)),
            const SizedBox(height: 12),

            // c) Muscle Volume Distribution
            _buildGlassCard(
              theme: theme,
              child: _buildMuscleDistributionSection(theme),
            ),
            const SizedBox(height: 12),

            // d) Sets Per Muscle Group (NEW)
            _buildGlassCard(
              theme: theme,
              child: _buildSetsPerMuscleSection(theme),
            ),
            const SizedBox(height: 12),

            // e) Estimated 1RM (REPLACED from PR)
            _buildGlassCard(
              theme: theme,
              child: _buildEstimated1RMSection(theme),
            ),
            const SizedBox(height: 12),

            // f) 1RM Progression — MONTH ONLY
            if (!isWeek) ...[
              _buildGlassCard(
                theme: theme,
                child: _build1RMProgressionSection(theme),
              ),
              const SizedBox(height: 12),
            ],

            // g) Recovery Status
            _buildGlassCard(theme: theme, child: _buildRecoverySection(theme)),
            const SizedBox(height: 12),

            const SizedBox(height: 24),

            // Section 3: Generated Prompt
            _buildSectionHeader('生成的提示词', theme),
            const SizedBox(height: 12),
            _buildPromptContainer(theme),
            const SizedBox(height: 16),
            _buildCopyButton(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: '关闭',
        icon: Icon(Icons.close, color: theme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: theme.timerGradientColors),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
            ),
          ),
          Icon(Icons.psychology, color: theme.accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            'AI 训练分析',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsBox(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                '使用说明',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1. 查看下方的训练数据报告', theme),
          _buildInstructionStep('2. 复制生成的提示词', theme),
          _buildInstructionStep('3. 粘贴给 ChatGPT / 豆包 / 千问 等 AI', theme),
          _buildInstructionStep('4. AI 会返回分析建议和 JSON 计划', theme),
          _buildInstructionStep('5. 前往「计划」页面 →「导入分析」导入计划', theme),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGlassCard({required AppThemeData theme, required Widget child}) {
    final isDark = theme.isDark;
    final bgAlpha = isDark ? 0.08 : 0.12;
    final borderAlpha = isDark ? 0.20 : 0.30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          decoration: BoxDecoration(
            color: theme.surfaceColor.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: theme.surfaceColor.withValues(alpha: borderAlpha),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(AppThemeData theme) {
    final totalVolume = _statsCalc.calculateTotalVolume(widget.records);
    final density = _statsCalc.calculateDensity(widget.records);
    final totalDurationMin =
        widget.records.fold<int>(0, (sum, r) => sum + r.durationSeconds) ~/ 60;
    final sessionCount = widget.records.length;
    final workoutDays = _countUniqueDays(widget.records);
    final avgPerSession = sessionCount > 0
        ? totalDurationMin ~/ sessionCount
        : 0;
    final avgVolumePerSession = sessionCount > 0
        ? totalVolume / sessionCount
        : 0.0;
    String fmtVol(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('基本信息', theme),
        _buildDataRow('训练次数', '$sessionCount 次 / $workoutDays 天', theme),
        _buildDataRow('总训练量', '${fmtVol(totalVolume)} kg', theme),
        _buildDataRow('训练密度', '${density.toStringAsFixed(1)} 组/分钟', theme),
        if (sessionCount > 0)
          _buildDataRow(
            '平均每次',
            '${fmtVol(avgVolumePerSession)} kg / $avgPerSession 分钟',
            theme,
          ),
      ],
    );
  }

  Widget _buildTrendSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(
          '趋势变化 (vs 上${widget.periodType == 'week' ? '周' : '月'})',
          theme,
        ),
        Text(
          _formatVolumeTrend(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMuscleDistributionSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('肌肉容量分布', theme),
        Text(
          _formatMuscleVolumeDistribution(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSetsPerMuscleSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(
          '每肌群组数 (MEV参考: ${widget.periodType == 'week' ? '10组/周' : '40组/月'})',
          theme,
        ),
        Text(
          _formatSetsPerMuscleGroup(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEstimated1RMSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('估算1RM (Mayhew公式)', theme),
        Text(
          _formatEstimated1RM(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _build1RMProgressionSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('估算1RM进步趋势', theme),
        Text(
          _format1RMProgression(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildRecoverySection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('恢复状态', theme),
        Text(
          _formatRecoveryManagement(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptContainer(AppThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          _generatedPrompt ?? '正在生成提示词...',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: theme.textColor, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildCopyButton(AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _generatedPrompt == null
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: _generatedPrompt!));
                setState(() => _isPromptCopied = true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('提示词已复制到剪贴板')));
              },
        icon: Icon(
          _isPromptCopied ? Icons.check : Icons.copy,
          size: 20,
          color: theme.surfaceColor,
        ),
        label: Text(
          _isPromptCopied ? '已复制' : '复制提示词',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: theme.surfaceColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
    );
  }
}
