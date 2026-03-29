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

/// Full-screen page for AI training analysis.
/// Generates a rich prompt from workout data and lets users copy it to external AI tools.
class AIAnalysisScreen extends StatefulWidget {
  final String periodType; // 'week' or 'month'
  final DateTime startDate;
  final DateTime endDate;
  final List<WorkoutRecord> records; // current period
  final List<WorkoutRecord>
  previousRecords; // previous period for trend comparison
  final List<WorkoutRecord> allRecords; // all records for PR calculation

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
  late String _generatedPrompt;
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
      // Use defaults and generate prompt
      setState(() {
        _generatedPrompt = _generatePrompt();
      });
    }
  }

  // ==================== Data Formatting Methods ====================

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
    final fmtVol = (double v) => v >= 1000
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
    final currentMuscleVol = _calcMuscleVolume(widget.records);
    final previousMuscleVol = _calcMuscleVolume(widget.previousRecords);
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

  /// Count unique training days
  int _countUniqueDays(List<WorkoutRecord> records) {
    final days = <String>{};
    for (final r in records) {
      days.add('${r.date.year}-${r.date.month}-${r.date.day}');
    }
    return days.length;
  }

  /// Calculate per-muscle training volume
  Map<PrimaryMuscleGroup, double> _calcMuscleVolume(
    List<WorkoutRecord> records,
  ) {
    return _statsCalc.calculateMuscleVolumeDistribution(records);
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

  /// Calculate max weights per exercise using English names (for AI prompt)
  Map<String, double> _calculateMaxWeightsByExerciseEn(
    List<WorkoutRecord> records,
  ) {
    final maxWeights = <String, double>{};
    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exerciseName = recordedExercise.nameEn.isNotEmpty
            ? recordedExercise.nameEn
            : recordedExercise.exerciseId;
        if (exerciseName.isEmpty) continue;

        final weight = recordedExercise.maxWeight;
        if (weight == null || weight == 0) continue;

        final currentMax = maxWeights[exerciseName];
        if (currentMax == null || weight > currentMax) {
          maxWeights[exerciseName] = weight;
        }
      }
    }
    return maxWeights;
  }

  /// Format personal records (PR) — uses English exercise names for AI prompt compatibility
  String _formatPRs() {
    final prs = _calculateMaxWeightsByExerciseEn(widget.allRecords);
    if (prs.isEmpty) return '- 暂无重量记录';

    final sorted = prs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    for (final entry in sorted.take(10)) {
      buffer.writeln('  - ${entry.key}: ${entry.value.toStringAsFixed(1)} kg');
    }
    return buffer.toString().trimRight();
  }

  /// Format recovery management data (calculate rest days per muscle)
  String _formatRecoveryManagement() {
    // Use allRecords for the most comprehensive recovery data
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

  /// Format common exercises data
  String _formatCommonExercises() {
    if (widget.records.isEmpty) return '- 暂无动作数据';

    final Map<String, int> exerciseCounts = {};
    for (final record in widget.records) {
      for (final exercise in record.exercises) {
        final name = exercise.nameEn.isNotEmpty
            ? exercise.nameEn
            : (exercise.name.isNotEmpty ? exercise.name : exercise.exerciseId);
        if (name.isNotEmpty) {
          exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
        }
      }
    }

    if (exerciseCounts.isEmpty) return '- 暂无动作训练数据';

    final sortedExercises = exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    for (final entry in sortedExercises.take(10)) {
      buffer.writeln('  - ${entry.key}: ${entry.value} 次');
    }
    return buffer.toString().trimRight();
  }

  /// Get weak muscles (based on training volume)
  List<String> _getWeakMuscles() {
    final muscleVol = _calcMuscleVolume(widget.allRecords);
    if (muscleVol.isEmpty) return [];

    final allMuscles = PrimaryMuscleGroup.values;
    final trainedMuscles = muscleVol.keys.toSet();

    // Untrained muscles
    final untrained = allMuscles
        .where((m) => !trainedMuscles.contains(m))
        .map((m) => m.displayName)
        .toList();

    // Muscles with volume below 50% of average
    final avgVol =
        muscleVol.values.fold<double>(0, (sum, v) => sum + v) /
        muscleVol.length;
    final weakTrained = muscleVol.entries
        .where((e) => e.value <= avgVol * 0.5)
        .map(
          (e) => '${e.key.displayName}(${(e.value / avgVol * 100).round()}%)',
        )
        .toList();

    return [...untrained, ...weakTrained];
  }

  /// Get overtrained muscles (too many consecutive training days)
  List<String> _getOvertrainedMuscles() {
    if (widget.records.length < 2) return [];

    final sortedRecords = List<WorkoutRecord>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<PrimaryMuscleGroup, int> consecutiveDays = {};

    for (final muscle in PrimaryMuscleGroup.values) {
      int maxConsecutive = 0;
      int currentConsecutive = 0;
      DateTime? lastDate;

      for (final record in sortedRecords) {
        final muscles = _getMusclesFromRecord(record);
        if (muscles.contains(muscle)) {
          if (lastDate == null) {
            currentConsecutive = 1;
          } else {
            final diff = record.date.difference(lastDate).inDays;
            if (diff <= 1) {
              currentConsecutive++;
            } else {
              currentConsecutive = 1;
            }
          }
          lastDate = record.date;
          if (currentConsecutive > maxConsecutive) {
            maxConsecutive = currentConsecutive;
          }
        }
      }

      if (maxConsecutive >= 3) {
        consecutiveDays[muscle] = maxConsecutive;
      }
    }

    return consecutiveDays.entries
        .where((e) => e.value >= 3)
        .map((e) => '${e.key.displayName}(连续${e.value}天)')
        .toList();
  }

  /// Get muscle imbalance pairs (ratio >= 2:1)
  List<String> _getMuscleImbalance() {
    final dist = _statsCalc.calculateMuscleVolumeDistribution(widget.records);
    if (dist.isEmpty) return [];

    const threshold = 2.0;
    final result = <String>[];

    final chestVol = dist[PrimaryMuscleGroup.chest] ?? 0;
    final backVol = dist[PrimaryMuscleGroup.back] ?? 0;
    if (chestVol > 0 && backVol > 0) {
      final ratio = chestVol / backVol;
      if (ratio >= threshold) {
        result.add('胸:背 ${ratio.toStringAsFixed(1)}:1');
      } else if (1 / ratio >= threshold) {
        result.add('背:胸 ${(1 / ratio).toStringAsFixed(1)}:1');
      }
    } else if (chestVol > 0 && backVol == 0) {
      result.add('胸:背 ∞:1');
    } else if (backVol > 0 && chestVol == 0) {
      result.add('背:胸 ∞:1');
    }

    final shouldersVol = dist[PrimaryMuscleGroup.shoulders] ?? 0;
    final armsVol = dist[PrimaryMuscleGroup.arms] ?? 0;
    if (shouldersVol > 0 && armsVol > 0) {
      final ratio = shouldersVol / armsVol;
      if (ratio >= threshold) {
        result.add('肩:手臂 ${ratio.toStringAsFixed(1)}:1');
      } else if (1 / ratio >= threshold) {
        result.add('手臂:肩 ${(1 / ratio).toStringAsFixed(1)}:1');
      }
    }

    final upperVol = chestVol + backVol + shouldersVol + armsVol;
    final lowerVol = dist[PrimaryMuscleGroup.legs] ?? 0;
    if (upperVol > 0 && lowerVol > 0) {
      final ratio = upperVol / lowerVol;
      if (ratio >= threshold) {
        result.add('上肢:下肢 ${ratio.toStringAsFixed(1)}:1');
      } else if (1 / ratio >= threshold) {
        result.add('下肢:上肢 ${(1 / ratio).toStringAsFixed(1)}:1');
      }
    } else if (upperVol > 0 && lowerVol == 0) {
      result.add('上肢:下肢 ∞:1');
    } else if (lowerVol > 0 && upperVol == 0) {
      result.add('下肢:上肢 ∞:1');
    }

    return result;
  }

  /// Get strength breakthroughs (new PRs in current period)
  List<String> _getStrengthBreakthroughs() {
    if (widget.records.isEmpty) return [];

    final currentE1RM = _statsCalc.calculateEstimated1RM(widget.records);
    final allE1RM = _statsCalc.calculateEstimated1RM(widget.allRecords);

    final result = <String>[];
    for (final entry in currentE1RM.entries) {
      final name = entry.key;
      final currentVal = entry.value;
      final allVal = allE1RM[name] ?? 0;

      if (currentVal > 0 && currentVal >= allVal) {
        if (widget.records.length < widget.allRecords.length ||
            currentVal > allVal) {
          if (allVal > 0 && allVal < currentVal) {
            result.add(
              '$name ${allVal.toStringAsFixed(1)}→${currentVal.toStringAsFixed(1)}kg',
            );
          } else {
            result.add('$name ${currentVal.toStringAsFixed(1)}kg');
          }
        }
      }
    }

    return result;
  }

  /// Generate dynamic rules based on training goal
  String _getDynamicRules() {
    switch (_selectedGoal) {
      case 'muscle_building':
        return '''1. 每个动作 3-5 组，复合动作可到 5 组
2. 每次训练 5-6 个动作，时长 60-75 分钟
3. 复合动作占 60-70%，孤立动作占 30-40%
4. 同一肌群间隔至少 48 小时，大肌群(胸/背/腿)优先 72 小时
5. 针对薄弱部位增加训练频次和动作选择
6. 参考PR数据安排重量区间，确保渐进超负荷
7. 容量下降的部位适当减量或更换动作刺激''';
      case 'fat_loss':
        return '''1. 每个动作 3-4 组，短间歇(30-60秒)
2. 每次训练 6-8 个动作，时长 45-60 分钟
3. 复合动作占 50%，孤立动作占 50%，多关节参与优先
4. 保持较高训练密度，减少组间休息
5. 结合超级组或循环训练提升心率
6. 保留力量水平，避免大幅降低训练容量''';
      case 'strength':
        return '''1. 每个动作 3-6 组，长间歇(120-180秒)
2. 每次训练 4-5 个动作，时长 60-90 分钟
3. 复合动作占 70-80%，以深蹲/硬拉/卧推/推举为核心
4. 低次数高重量(3-6 reps)，以PR数据为基准安排训练重量
5. 同一肌群间隔至少 72-96 小时确保充分恢复
6. 渐进超负荷为核心原则，每周尝试提升重量或次数''';
      case 'endurance':
        return '''1. 每个动作 2-4 组，短间歇(30-45秒)
2. 每次训练 8-10 个动作，时长 45-60 分钟
3. 高次数(12-20 reps)，中等重量
4. 多关节和单关节动作结合，提升肌肉耐力
5. 组间休息尽量短，保持心率
6. 可加入自重训练和有氧元素''';
      default:
        return '''1. targetSets: 3-5 每个动作
2. 复合动作优先，孤立动作在后
3. 同一肌群间隔至少 48 小时
4. 渐进式超负荷''';
    }
  }

  // ==================== Prompt Generation ====================

  String _generatePrompt() {
    final periodLabel = widget.periodType == 'week' ? '本周' : '本月';
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

    final weakMuscles = _getWeakMuscles();
    final overtrainedMuscles = _getOvertrainedMuscles();
    final muscleImbalance = _getMuscleImbalance();
    final strengthBreakthroughs = _getStrengthBreakthroughs();

    // Basic statistics
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
    final fmtVol = (double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

    final buffer = StringBuffer();

    // Opening
    buffer.writeln('你是一位专业的健身教练。根据我的训练数据报告，为我制定下个周期的训练计划。');
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
    if (sessionCount > 0) {
      buffer.writeln(
        '- 平均每次: ${fmtVol(avgVolumePerSession)} kg / $avgPerSession 分钟',
      );
    }
    buffer.writeln();

    // Trend changes
    buffer.writeln('### 趋势变化（vs 上${widget.periodType == 'week' ? '周' : '月'}）');
    buffer.writeln(_formatVolumeTrend());
    buffer.writeln();

    // Muscle volume distribution
    buffer.writeln('### 肌肉容量分布');
    buffer.writeln(_formatMuscleVolumeDistribution());
    buffer.writeln();

    // PR
    buffer.writeln('### 个人最佳记录（PR）');
    buffer.writeln(_formatPRs());
    buffer.writeln();

    // Recovery status
    buffer.writeln('### 恢复状态（截至今天）');
    buffer.writeln(_formatRecoveryManagement());
    buffer.writeln();

    // Common exercises
    buffer.writeln('### 常用动作（按训练次数 TOP 10）');
    buffer.writeln(_formatCommonExercises());
    buffer.writeln();

    // Training insights
    buffer.writeln('### 训练洞察');
    if (strengthBreakthroughs.isNotEmpty) {
      buffer.writeln('- 力量突破: ${strengthBreakthroughs.join('、')}');
    }
    if (weakMuscles.isNotEmpty) {
      buffer.writeln('- 薄弱部位: ${weakMuscles.join('、')}');
    }
    if (muscleImbalance.isNotEmpty) {
      buffer.writeln('- 肌群不平衡: ${muscleImbalance.join('、')}');
    }
    if (overtrainedMuscles.isNotEmpty) {
      buffer.writeln('- 过度训练风险: ${overtrainedMuscles.join('、')}');
    }
    if (weakMuscles.isEmpty &&
        overtrainedMuscles.isEmpty &&
        muscleImbalance.isEmpty &&
        strengthBreakthroughs.isEmpty) {
      buffer.writeln('- 训练均衡，继续保持');
    }
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

    // Training plan rules
    buffer.writeln('## 训练计划规则');
    buffer.writeln('根据「${goalLabels[_selectedGoal]}」目标，遵循以下原则：');
    buffer.writeln(_getDynamicRules());
    buffer.writeln();

    // Output format
    buffer.writeln('## 输出格式');
    buffer.writeln('Output ONLY valid JSON. No explanations or markdown:');
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
    buffer.writeln('生成我的训练计划。JSON only:');

    return buffer.toString();
  }

  // ==================== UI Building ====================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

            // d) Personal Records
            _buildGlassCard(theme: theme, child: _buildPRSection(theme)),
            const SizedBox(height: 12),

            // e) Recovery Status
            _buildGlassCard(theme: theme, child: _buildRecoverySection(theme)),
            const SizedBox(height: 12),

            // f) Common Exercises
            _buildGlassCard(
              theme: theme,
              child: _buildCommonExercisesSection(theme),
            ),
            const SizedBox(height: 12),

            // g) Training Insights
            _buildGlassCard(theme: theme, child: _buildInsightsSection(theme)),
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.psychology, color: theme.accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            'AI 训练分析',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsBox(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
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
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 13,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: '.SF Pro Display',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: theme.textColor,
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required AppThemeData theme, required Widget child}) {
    // 深色模式下使用更低的透明度
    final isDark = theme.surfaceColor == const Color(0xFF1E1E2E);
    final bgAlpha = isDark ? 0.08 : 0.12;
    final borderAlpha = isDark ? 0.20 : 0.30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderAlpha),
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
    final fmtVol = (double v) =>
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
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.textColor,
            height: 1.5,
          ),
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
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.textColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPRSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('个人最佳记录 (PR)', theme),
        Text(
          _formatPRs(),
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.textColor,
            height: 1.5,
          ),
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
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.textColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCommonExercisesSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('常用动作 TOP 10', theme),
        Text(
          _formatCommonExercises(),
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.textColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(AppThemeData theme) {
    final weakMuscles = _getWeakMuscles();
    final overtrainedMuscles = _getOvertrainedMuscles();
    final muscleImbalance = _getMuscleImbalance();
    final strengthBreakthroughs = _getStrengthBreakthroughs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('训练洞察', theme),
        if (strengthBreakthroughs.isNotEmpty)
          _buildDataRow('力量突破', strengthBreakthroughs.join('、'), theme),
        if (weakMuscles.isNotEmpty)
          _buildDataRow('薄弱部位', weakMuscles.join('、'), theme),
        if (muscleImbalance.isNotEmpty)
          _buildDataRow('肌群不平衡', muscleImbalance.join('、'), theme),
        if (overtrainedMuscles.isNotEmpty)
          _buildDataRow('过度训练风险', overtrainedMuscles.join('、'), theme),
        if (weakMuscles.isEmpty &&
            overtrainedMuscles.isEmpty &&
            muscleImbalance.isEmpty &&
            strengthBreakthroughs.isEmpty)
          Text(
            '训练均衡，继续保持',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              color: theme.textColor,
            ),
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
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              color: theme.secondaryTextColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                color: theme.textColor,
              ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          _generatedPrompt,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: theme.textColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: _generatedPrompt));
          setState(() => _isPromptCopied = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('提示词已复制到剪贴板')));
        },
        icon: Icon(
          _isPromptCopied ? Icons.check : Icons.copy,
          size: 20,
          color: Colors.white,
        ),
        label: Text(
          _isPromptCopied ? '已复制' : '复制提示词',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
