import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/workout_repository.dart';
import '../services/stats_calculator_service.dart';
import '../bloc/record_provider.dart';
import 'ai_analysis_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutRepository _repository = WorkoutRepository();
  final StatsCalculatorService _statsCalc = StatsCalculatorService();
  List<WorkoutSession> _oldSessions = [];
  List<WorkoutRecord> _newRecords = [];
  bool _isLoading = true;
  DateTime _selectedWeekStart = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final recordProvider = context.read<RecordProvider>();
      // 确保记录已加载（首次进入时可能还未加载）
      if (recordProvider.recordCount == 0) {
        await recordProvider.loadRecords();
      }
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;
      setState(() {
        _oldSessions = sessions;
        _newRecords = recordProvider.records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 获取所有记录（合并旧记录和新记录）
  List<dynamic> _getAllRecords() {
    return [..._oldSessions, ..._newRecords];
  }

  /// 获取记录日期（剥离时间部分，只保留日期）
  DateTime _getRecordDate(dynamic record) {
    if (record is WorkoutSession) {
      final parsed = DateTime.parse(record.createdAt);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } else if (record is WorkoutRecord) {
      return DateTime(record.date.year, record.date.month, record.date.day);
    }
    return DateTime.now();
  }

  /// 获取记录组数
  int _getRecordSets(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalSets;
    } else if (record is WorkoutRecord) {
      return record.totalSets;
    }
    return 0;
  }

  /// 获取记录时长（秒）
  int _getRecordDuration(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalRestTimeMs ~/ 1000;
    } else if (record is WorkoutRecord) {
      return record.durationSeconds;
    }
    return 0;
  }

  /// 获取一周的开始日期（周一），剥离时间部分
  DateTime _getStartOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: date.weekday - 1));
  }

  /// 获取一周的7天列表
  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  /// 导航周（-1上一周，1下一周）
  void _navigateWeek(int direction) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(
        Duration(days: 7 * direction),
      );
      // 不允许导航到未来的周
      final now = DateTime.now();
      final thisWeekStart = _getStartOfWeek(now);
      if (_selectedWeekStart.isAfter(thisWeekStart)) {
        _selectedWeekStart = thisWeekStart;
      }
    });
  }

  /// 导航年份
  void _navigateYear(int direction) {
    setState(() {
      _selectedYear += direction;
      // 不允许导航到未来年份
      if (_selectedYear > DateTime.now().year) {
        _selectedYear = DateTime.now().year;
      }
    });
  }

  /// 选择月份
  void _selectMonth(int month) {
    setState(() {
      _selectedMonth = month;
      // 如果选择的月份在未来，重置为当前月
      final now = DateTime.now();
      if (_selectedYear == now.year && month > now.month) {
        _selectedMonth = now.month;
      }
    });
  }

  /// 按选中的周筛选记录
  List<dynamic> _filterBySelectedWeek() {
    final weekStart = _getStartOfWeek(_selectedWeekStart);
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _getAllRecords().where((record) {
      DateTime date = _getRecordDate(record);
      return date.isAfter(
            startOfWeek.subtract(const Duration(milliseconds: 1)),
          ) &&
          date.isBefore(endOfWeek);
    }).toList();
  }

  /// 按选中的月份筛选记录
  List<dynamic> _filterBySelectedMonth() {
    return _getAllRecords().where((record) {
      DateTime date = _getRecordDate(record);
      return date.year == _selectedYear && date.month == _selectedMonth;
    }).toList();
  }

  /// 按指定周的周一筛选记录（参数化版本，用于获取上一周期数据）
  List<dynamic> _filterByWeek(DateTime referenceDate) {
    final weekStart = _getStartOfWeek(referenceDate);
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _getAllRecords().where((record) {
      DateTime date = _getRecordDate(record);
      return date.isAfter(
            startOfWeek.subtract(const Duration(milliseconds: 1)),
          ) &&
          date.isBefore(endOfWeek);
    }).toList();
  }

  /// 按指定年月筛选记录（参数化版本，用于获取上一周期数据）
  List<dynamic> _filterByMonth(int year, int month) {
    return _getAllRecords().where((record) {
      DateTime date = _getRecordDate(record);
      return date.year == year && date.month == month;
    }).toList();
  }

  /// 获取一年中每月的训练次数
  Map<int, int> _getMonthlyCounts(int year) {
    final counts = <int, int>{};
    for (int i = 1; i <= 12; i++) {
      counts[i] = 0;
    }

    for (final record in _getAllRecords()) {
      final date = _getRecordDate(record);
      if (date.year == year) {
        counts[date.month] = (counts[date.month] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// 获取选中周内有训练的天数
  Set<int> _getWorkoutDaysInWeek() {
    final days = <int>{};
    final records = _filterBySelectedWeek();
    final weekStart = _getStartOfWeek(_selectedWeekStart);

    for (final record in records) {
      final date = _getRecordDate(record);
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        days.add(dayIndex);
      }
    }

    return days;
  }

  /// 获取每日训练时长（周视图或月视图）
  Map<int, int> _getDailyDurations(List<dynamic> records, bool isWeek) {
    final durations = <int, int>{};

    if (isWeek) {
      final weekStart = _getStartOfWeek(_selectedWeekStart);
      for (int i = 0; i < 7; i++) {
        durations[i] = 0;
      }

      for (final record in records) {
        final date = _getRecordDate(record);
        final dayIndex = date.difference(weekStart).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          durations[dayIndex] =
              (durations[dayIndex] ?? 0) + _getRecordDuration(record);
        }
      }
    } else {
      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        durations[i] = 0;
      }

      for (final record in records) {
        final date = _getRecordDate(record);
        if (date.year == _selectedYear && date.month == _selectedMonth) {
          durations[date.day] =
              (durations[date.day] ?? 0) + _getRecordDuration(record);
        }
      }
    }

    return durations;
  }

  /// 获取每日训练组数（周视图或月视图）
  Map<int, int> _getDailySets(List<dynamic> records, bool isWeek) {
    final sets = <int, int>{};

    if (isWeek) {
      final weekStart = _getStartOfWeek(_selectedWeekStart);
      for (int i = 0; i < 7; i++) {
        sets[i] = 0;
      }

      for (final record in records) {
        final date = _getRecordDate(record);
        final dayIndex = date.difference(weekStart).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          sets[dayIndex] = (sets[dayIndex] ?? 0) + _getRecordSets(record);
        }
      }
    } else {
      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        sets[i] = 0;
      }

      for (final record in records) {
        final date = _getRecordDate(record);
        if (date.year == _selectedYear && date.month == _selectedMonth) {
          sets[date.day] = (sets[date.day] ?? 0) + _getRecordSets(record);
        }
      }
    }

    return sets;
  }

  /// 计算训练频率统计
  Map<String, dynamic> _calculateFrequencyStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'sessionCount': 0,
        'workoutDays': 0,
        'avgSessionsPerWeek': 0.0,
        'muscleFrequency': <PrimaryMuscleGroup, int>{},
      };
    }

    final uniqueDays = <String>{};
    final muscleFrequency = <PrimaryMuscleGroup, int>{};

    for (final record in records) {
      final date = _getRecordDate(record);
      uniqueDays.add('${date.year}-${date.month}-${date.day}');

      if (record is WorkoutRecord && record.trainedMuscles.isNotEmpty) {
        for (final muscle in record.trainedMuscles) {
          muscleFrequency[muscle] = (muscleFrequency[muscle] ?? 0) + 1;
        }
      }
    }

    return {
      'sessionCount': records.length,
      'workoutDays': uniqueDays.length,
      'avgSessionsPerWeek':
          records.length / (uniqueDays.isNotEmpty ? uniqueDays.length / 7 : 1),
      'muscleFrequency': muscleFrequency,
    };
  }

  /// 计算训练量统计
  Map<String, dynamic> _calculateVolumeStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'totalSets': 0,
        'totalDuration': 0,
        'avgSetsPerSession': 0.0,
        'avgDurationPerSession': 0,
      };
    }

    int totalSets = 0;
    int totalDuration = 0;

    for (final record in records) {
      totalSets += _getRecordSets(record);
      totalDuration += _getRecordDuration(record);
    }

    return {
      'totalSets': totalSets,
      'totalDuration': totalDuration,
      'avgSetsPerSession': totalSets / records.length,
      'avgDurationPerSession': totalDuration ~/ records.length,
    };
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            Text(
              '训练统计',
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
        actions: [
          TextButton.icon(
            onPressed: () => _navigateToAIAnalysis(theme),
            icon: Icon(Icons.psychology, size: 20, color: theme.accentColor),
            label: Text(
              'AI 分析',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 2,
          labelColor: theme.textColor,
          unselectedLabelColor: theme.secondaryTextColor,
          labelStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: '周视图'),
            Tab(text: '月视图'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [_buildWeekView(theme), _buildMonthView(theme)],
            ),
    );
  }

  Widget _buildSection(
    String title,
    AppThemeData theme,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 训练频率概览
  Widget _buildFrequencyOverview(
    Map<String, dynamic> stats,
    AppThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            '训练次数',
            '${stats['sessionCount']}',
            '次',
            Icons.fitness_center,
            theme.primaryColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '训练天数',
            '${stats['workoutDays']}',
            '天',
            Icons.calendar_today,
            theme.secondaryColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '周均训练',
            '${(stats['avgSessionsPerWeek'] as double).toStringAsFixed(1)} 次',
            '次',
            Icons.trending_up,
            theme.accentColor,
            theme,
          ),
        ),
      ],
    );
  }

  /// 训练量概览
  Widget _buildVolumeOverview(Map<String, dynamic> stats, AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '总组数',
                '${stats['totalSets']}',
                '组',
                Icons.repeat,
                theme.primaryColor,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '总时长',
                formatDuration(stats['totalDuration'] as int),
                '',
                Icons.timer,
                theme.secondaryColor,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubMetric(
                '平均组数/次',
                '${(stats['avgSetsPerSession'] as double).toStringAsFixed(1)} 组',
                theme,
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.textColor.withValues(alpha: 0.1),
              ),
              _buildSubMetric(
                '平均时长/次',
                formatDuration(stats['avgDurationPerSession'] as int),
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    AppThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  // ==================== 周视图和月视图 UI ====================

  /// 周视图
  Widget _buildWeekView(AppThemeData theme) {
    // Show global empty state if no records at all
    if (_getAllRecords().isEmpty) {
      return _buildGlobalEmptyState(theme);
    }

    final records = _filterBySelectedWeek();
    final workoutRecords = records.whereType<WorkoutRecord>().toList();
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);
    final dailyDurations = _getDailyDurations(records, true);
    final dailySets = _getDailySets(records, true);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: AppDimensions.bottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 周选择器
          _buildWeekSelector(theme),
          const SizedBox(height: 20),

          // 概览 (频率 + 训练量)
          _CollapsibleSection(
            title: '概览',
            theme: theme,
            children: [
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(volumeStats, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 每日训练时长图表
          _buildSection('每日训练时长', theme, [
            _buildDailyDurationChart(
              dailyDurations,
              dailySets,
              theme,
              isWeekView: true,
              days: 7,
            ),
          ]),
          const SizedBox(height: 20),

          // 进步追踪 (力量进步 + 常用动作)
          _CollapsibleSection(
            title: '进步追踪',
            theme: theme,
            children: [
              _buildStrengthProgressSection(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildCommonExercisesChart(
                _calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (肌群容量 + 恢复状态)
          _CollapsibleSection(
            title: '身体分析',
            theme: theme,
            children: [
              _buildMuscleVolumeChart(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildSecondaryRecoveryStatusList(
                _calculateSecondaryRecoveryData(workoutRecords),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 训练洞察
          _buildSection('训练洞察', theme, [
            _buildTrainingInsightsCard(
              _calculateWeakMusclesData(records),
              _calculateOvertrainedMusclesData(records),
              theme,
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 月视图
  Widget _buildMonthView(AppThemeData theme) {
    // Show global empty state if no records at all
    if (_getAllRecords().isEmpty) {
      return _buildGlobalEmptyState(theme);
    }

    final records = _filterBySelectedMonth();
    final workoutRecords = records.whereType<WorkoutRecord>().toList();
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);
    final monthlyCounts = _getMonthlyCounts(_selectedYear);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: AppDimensions.bottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年份选择器
          _buildYearSelector(theme),
          const SizedBox(height: 16),

          // 月份网格
          _buildMonthGrid(monthlyCounts, theme),
          const SizedBox(height: 20),

          // 概览 (频率 + 训练量)
          _CollapsibleSection(
            title: '概览 ($_selectedMonth月)',
            theme: theme,
            children: [
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(volumeStats, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 进步追踪 (力量进步 + 常用动作)
          _CollapsibleSection(
            title: '进步追踪',
            theme: theme,
            children: [
              _buildStrengthProgressSection(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildCommonExercisesChart(
                _calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (肌群容量 + 恢复状态)
          _CollapsibleSection(
            title: '身体分析',
            theme: theme,
            children: [
              _buildMuscleVolumeChart(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildSecondaryRecoveryStatusList(
                _calculateSecondaryRecoveryData(workoutRecords),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 训练洞察
          _buildSection('训练洞察', theme, [
            _buildTrainingInsightsCard(
              _calculateWeakMusclesData(records),
              _calculateOvertrainedMusclesData(records),
              theme,
            ),
          ]),
        ],
      ),
    );
  }

  /// 周选择器
  Widget _buildWeekSelector(AppThemeData theme) {
    final weekStart = _getStartOfWeek(_selectedWeekStart);
    final weekDays = _getWeekDays(weekStart);
    final today = DateTime.now();
    final workoutDays = _getWorkoutDaysInWeek();
    final canGoNext = weekStart
        .add(const Duration(days: 7))
        .isBefore(
          DateTime(
            today.year,
            today.month,
            today.day,
          ).add(const Duration(days: 1)),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 周导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _navigateWeek(-1),
                icon: Icon(Icons.chevron_left, color: theme.textColor),
              ),
              Column(
                children: [
                  Text(
                    '${weekStart.month}月 ${weekStart.day}日 - ${weekDays.last.month}月 ${weekDays.last.day}日',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    '${weekStart.year}年',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: canGoNext ? () => _navigateWeek(1) : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext
                      ? theme.textColor
                      : theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 7天日历
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final day = weekDays[index];
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final hasWorkout = workoutDays.contains(index);
              final dayNames = ['一', '二', '三', '四', '五', '六', '日'];

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      dayNames[index],
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 11,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday
                            ? theme.accentColor
                            : hasWorkout
                            ? theme.primaryColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: isToday
                            ? null
                            : Border.all(
                                color: hasWorkout
                                    ? theme.primaryColor
                                    : theme.textColor.withValues(alpha: 0.1),
                                width: 1,
                              ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: '.SF Pro Display',
                            fontSize: 14,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? Colors.white
                                : hasWorkout
                                ? theme.primaryColor
                                : theme.textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 年份选择器
  Widget _buildYearSelector(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _navigateYear(-1),
            icon: Icon(Icons.chevron_left, color: theme.textColor),
          ),
          Text(
            '$_selectedYear 年',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          IconButton(
            onPressed: _selectedYear < DateTime.now().year
                ? () => _navigateYear(1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              color: _selectedYear < DateTime.now().year
                  ? theme.textColor
                  : theme.secondaryTextColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// 月份网格
  Widget _buildMonthGrid(Map<int, int> counts, AppThemeData theme) {
    final monthNames = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    final now = DateTime.now();
    final maxCount = counts.values.fold(0, (max, e) => e > max ? e : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 使用 LayoutBuilder 计算精确高度，避免 shrinkWrap 产生多余空白行
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 12个月 = 4列 × 3行
          const crossAxisSpacing = 8.0;
          const mainAxisSpacing = 8.0;
          const columns = 4;
          const rows = 3;

          // 计算单元格大小（正方形）
          final cellWidth =
              (constraints.maxWidth - (columns - 1) * crossAxisSpacing) /
              columns;

          // 计算网格总高度
          final gridHeight = rows * cellWidth + (rows - 1) * mainAxisSpacing;

          return SizedBox(
            height: gridHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 1.0,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final count = counts[month] ?? 0;
                final isSelected = month == _selectedMonth;
                final isFuture = _selectedYear == now.year && month > now.month;
                final intensity = maxCount > 0 ? count / maxCount : 0.0;

                return GestureDetector(
                  onTap: isFuture ? null : () => _selectMonth(month),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : isFuture
                          ? theme.textColor.withValues(alpha: 0.05)
                          : intensity > 0
                          ? theme.primaryColor.withValues(
                              alpha: 0.1 + intensity * 0.3,
                            )
                          : theme.textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : theme.textColor.withValues(alpha: 0.1),
                            ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthNames[index],
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                ? theme.secondaryTextColor.withValues(
                                    alpha: 0.3,
                                  )
                                : theme.textColor,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontFamily: '.SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : theme.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Global empty state when there are no records at all
  Widget _buildGlobalEmptyState(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: theme.secondaryTextColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无训练数据',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成几次训练后这里会显示统计信息',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 每日训练时长图表
  Widget _buildDailyDurationChart(
    Map<int, int> durations,
    Map<int, int> sets,
    AppThemeData theme, {
    required bool isWeekView,
    int? days,
  }) {
    final maxDuration = durations.values.fold(0, (max, e) => e > max ? e : max);
    final displayDays = days ?? (isWeekView ? 7 : 31);

    if (maxDuration == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无训练数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '时长/组数',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 11,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 图表 - 使用固定高度容器，确保所有柱状条从同一基线开始
        SizedBox(
          height: isWeekView ? 130 : 140,
          child: Column(
            children: [
              // 固定高度的图表区域
              Expanded(
                child: Row(
                  children: List.generate(displayDays, (index) {
                    final key = isWeekView ? index : index + 1;
                    final duration = durations[key] ?? 0;
                    final setCount = sets[key] ?? 0;
                    final heightPercent = maxDuration > 0
                        ? duration / maxDuration
                        : 0.0;
                    final barHeight = (heightPercent * 70).clamp(4.0, 70.0);

                    return Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isWeekView ? 2 : 1,
                          ),
                          height: barHeight + 40, // 柱状条高度 + 数字空间
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // 柱状条 - 固定在底部
                              Container(
                                height: barHeight,
                                width: isWeekView ? 24 : 8,
                                decoration: BoxDecoration(
                                  gradient: duration > 0
                                      ? LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            theme.primaryColor,
                                            theme.secondaryColor,
                                          ],
                                        )
                                      : null,
                                  color: duration > 0
                                      ? null
                                      : theme.textColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    isWeekView ? 4 : 2,
                                  ),
                                ),
                              ),
                              // 数字 - 在柱状条上方
                              Positioned(
                                bottom: barHeight + 2,
                                child: Column(
                                  children: [
                                    if (duration > 0 || setCount > 0)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            formatDuration(duration),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: '.SF Pro Text',
                                              fontSize: isWeekView ? 11 : 9,
                                              color: theme.secondaryTextColor,
                                            ),
                                          ),
                                          if (setCount > 0)
                                            Text(
                                              '$setCount 组',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: '.SF Pro Text',
                                                fontSize: isWeekView ? 10 : 8,
                                                color: theme.secondaryTextColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // 日期标签 - 放在图表区域下方，不影响柱状条对齐
              Row(
                children: List.generate(displayDays, (index) {
                  final key = isWeekView ? index : index + 1;
                  // 月视图只显示部分日期标签（1, 5, 10, 15, 20, 25, 月末）
                  final daysInMonth = DateTime(
                    _selectedYear,
                    _selectedMonth + 1,
                    0,
                  ).day;
                  final bool showLabel =
                      isWeekView ||
                      key == 1 ||
                      key == 5 ||
                      key == 10 ||
                      key == 15 ||
                      key == 20 ||
                      key == 25 ||
                      key == daysInMonth;

                  return Expanded(
                    child: Text(
                      isWeekView
                          ? ['一', '二', '三', '四', '五', '六', '日'][index]
                          : (showLabel ? '$key' : ''),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: isWeekView ? 10 : 9,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 新增图表数据计算方法 ====================

  /// 计算肌肉分布数据
  Map<PrimaryMuscleGroup, int> _calculateMuscleDistribution(
    List<dynamic> records,
  ) {
    final distribution = <PrimaryMuscleGroup, int>{};

    for (final record in records) {
      if (record is WorkoutRecord && record.trainedMuscles.isNotEmpty) {
        for (final muscle in record.trainedMuscles) {
          distribution[muscle] = (distribution[muscle] ?? 0) + 1;
        }
      }
    }

    return distribution;
  }

  /// 计算常用动作数据（TOP 10）
  Map<String, int> _calculateCommonExercises(List<dynamic> records) {
    final exerciseCounts = <String, int>{};

    for (final record in records) {
      if (record is WorkoutRecord) {
        for (final exercise in record.exercises) {
          final name = exercise.name;
          if (name.isNotEmpty) {
            exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(10));
  }

  /// 计算薄弱部位（训练次数最少或未训练的）
  List<Map<String, dynamic>> _calculateWeakMusclesData(List<dynamic> records) {
    final muscleDistribution = _calculateMuscleDistribution(records);
    final allMuscles = PrimaryMuscleGroup.values;
    final result = <Map<String, dynamic>>[];

    for (final muscle in allMuscles) {
      if (!muscleDistribution.containsKey(muscle)) {
        result.add({
          'muscle': muscle,
          'displayName': muscle.displayName,
          'count': 0,
          'status': 'untrained',
        });
      }
    }

    if (muscleDistribution.isNotEmpty) {
      final avgCount =
          muscleDistribution.values.fold<int>(0, (sum, v) => sum + v) /
          muscleDistribution.length;
      for (final entry in muscleDistribution.entries) {
        if (entry.value <= avgCount * 0.5) {
          result.add({
            'muscle': entry.key,
            'displayName': entry.key.displayName,
            'count': entry.value,
            'status': 'weak',
          });
        }
      }
    }

    return result;
  }

  /// 计算过度训练风险部位（连续3天以上训练同一肌群）
  List<Map<String, dynamic>> _calculateOvertrainedMusclesData(
    List<dynamic> records,
  ) {
    if (records.length < 2) return [];

    final sortedRecords = List<WorkoutRecord>.from(
      records.whereType<WorkoutRecord>(),
    )..sort((a, b) => a.date.compareTo(b.date));

    final result = <Map<String, dynamic>>[];

    for (final muscle in PrimaryMuscleGroup.values) {
      int maxConsecutive = 0;
      int currentConsecutive = 0;
      DateTime? lastDate;

      for (final record in sortedRecords) {
        if (record.trainedMuscles.contains(muscle)) {
          if (lastDate == null) {
            currentConsecutive = 1;
          } else {
            final diff = record.date.difference(lastDate).inDays;
            if (diff == 1) {
              currentConsecutive++;
            } else if (diff > 1) {
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
        result.add({
          'muscle': muscle,
          'displayName': muscle.displayName,
          'consecutiveDays': maxConsecutive,
        });
      }
    }

    return result;
  }

  // ==================== 新增图表组件方法 ====================

  /// 常用动作图表（水平条形图）
  Widget _buildCommonExercisesChart(
    Map<String, int> exercises,
    AppThemeData theme,
  ) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无动作数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    final maxCount = exercises.values.fold<int>(
      0,
      (max, e) => e > max ? e : max,
    );

    return Column(
      children: exercises.entries.map((entry) {
        final percentage = maxCount > 0 ? entry.value / maxCount : 0.0;
        final displayName = entry.key.length > 20
            ? '${entry.key.substring(0, 18)}...'
            : entry.key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    color: theme.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage.clamp(0.1, 1.0),
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.accentColor,
                              theme.accentColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${entry.value}次',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 训练洞察卡片（薄弱部位 + 过度训练风险）
  Widget _buildTrainingInsightsCard(
    List<Map<String, dynamic>> weakMuscles,
    List<Map<String, dynamic>> overtrainedMuscles,
    AppThemeData theme,
  ) {
    if (weakMuscles.isEmpty && overtrainedMuscles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '训练均衡，继续保持！',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weakMuscles.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.trending_down, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                '薄弱部位',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: weakMuscles.map((m) {
              final status = m['status'] as String;
              final label = status == 'untrained'
                  ? '${m['displayName']} (未训练)'
                  : '${m['displayName']} (${m['count']}次)';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    color: Colors.orange,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        if (overtrainedMuscles.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: theme.errorColor),
              const SizedBox(width: 6),
              Text(
                '过度训练风险',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: overtrainedMuscles.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${m['displayName']} (连续${m['consecutiveDays']}天)',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    color: theme.errorColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ==================== 新增统计组件 ====================

  /// 力量进步 section - PR榜单 + 预估1RM
  Widget _buildStrengthProgressSection(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final maxWeights = _statsCalc.calculateMaxWeightsByExercise(records);
    final estimated1RMs = _statsCalc.calculateEstimated1RM(records);

    if (maxWeights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无力量数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    // Sort by weight descending, take top 8
    final sortedPRs = maxWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top8PRs = sortedPRs.take(8).toList();

    // Sort by 1RM descending, take top 5
    final sorted1RMs = estimated1RMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5_1RMs = sorted1RMs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PR榜单标题
        Row(
          children: [
            Icon(Icons.emoji_events, size: 16, color: theme.accentColor),
            const SizedBox(width: 6),
            Text(
              'PR 榜单',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // PR列表
        ...top8PRs.asMap().entries.map((entry) {
          final index = entry.key;
          final pr = entry.value;
          final rank = index + 1;
          final exerciseName = pr.key.length > 15
              ? '${pr.key.substring(0, 13)}...'
              : pr.key;
          final isTop = rank == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // 排名
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isTop
                        ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                        : theme.textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isTop
                        ? Border.all(color: const Color(0xFFFFD700))
                        : null,
                  ),
                  child: Center(
                    child: isTop
                        ? const Text('🏆', style: TextStyle(fontSize: 12))
                        : Text(
                            '$rank',
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // 动作名称
                Expanded(
                  child: Text(
                    exerciseName,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: theme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 重量
                Text(
                  '${pr.value.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isTop ? theme.accentColor : theme.textColor,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        // 分隔线
        Divider(color: theme.textColor.withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        // 预估1RM
        Row(
          children: [
            Icon(Icons.fitness_center, size: 16, color: theme.secondaryColor),
            const SizedBox(width: 6),
            Text(
              '预估极限重量 (1RM)',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: top5_1RMs.map((e1rm) {
            final name = e1rm.key.length > 10
                ? '${e1rm.key.substring(0, 8)}...'
                : e1rm.key;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$name: ${e1rm.value.toStringAsFixed(1)}kg',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 11,
                  color: theme.accentColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 肌群容量分布 - 甜甜圈图
  Widget _buildMuscleVolumeChart(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final distribution = _statsCalc.calculateMuscleVolumeDistribution(records);

    if (distribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无训练数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    // Calculate total volume
    final totalVolume = distribution.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );

    // Color mapping for each PrimaryMuscleGroup
    final muscleColors = <PrimaryMuscleGroup, Color>{
      PrimaryMuscleGroup.chest: const Color(0xFFE53935), // Red
      PrimaryMuscleGroup.back: const Color(0xFF1E88E5), // Blue
      PrimaryMuscleGroup.shoulders: const Color(0xFFFB8C00), // Orange
      PrimaryMuscleGroup.arms: const Color(0xFF8E24AA), // Purple
      PrimaryMuscleGroup.legs: const Color(0xFF43A047), // Green
      PrimaryMuscleGroup.core: const Color(0xFF00ACC1), // Cyan
    };

    // Sort entries by volume for consistent display
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Donut chart
        SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _DonutChartPainter(
              data: sortedEntries,
              colors: muscleColors,
              totalVolume: totalVolume,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Center text showing total volume
        Text(
          _formatVolume(totalVolume),
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        Text(
          '总容量',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: sortedEntries.map((entry) {
            final percentage = totalVolume > 0
                ? (entry.value / totalVolume * 100).toStringAsFixed(1)
                : '0.0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: muscleColors[entry.key],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.displayName} $percentage%',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    color: theme.textColor,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Format volume with thousand separators
  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${volume.toStringAsFixed(0)} kg';
  }

  /// Calculate secondary muscle recovery data grouped by primary muscle
  Map<PrimaryMuscleGroup, List<Map<String, dynamic>>>
  _calculateSecondaryRecoveryData(List<WorkoutRecord> records) {
    final secondaryRecovery = _statsCalc.calculateSecondaryMuscleRecovery(
      records,
    );
    final grouped = <PrimaryMuscleGroup, List<Map<String, dynamic>>>{};

    for (final entry in secondaryRecovery.entries) {
      final primary = entry.key.primaryMuscle;
      grouped.putIfAbsent(primary, () => []);
      grouped[primary]!.add({
        'muscle': entry.key,
        'displayName': entry.key.displayName,
        'days': entry.value,
      });
    }

    // Sort sub-muscles by days within each group
    for (final group in grouped.values) {
      group.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    }

    return grouped;
  }

  /// Recovery status list with secondary muscles (refactored)
  Widget _buildSecondaryRecoveryStatusList(
    Map<PrimaryMuscleGroup, List<Map<String, dynamic>>> groupedData,
    AppThemeData theme,
  ) {
    if (groupedData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无恢复数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    // Sort primary muscle groups by their min recovery days
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) {
        final minDaysA = a.value.fold<int>(
          999,
          (min, e) => (e['days'] as int) < min ? e['days'] as int : min,
        );
        final minDaysB = b.value.fold<int>(
          999,
          (min, e) => (e['days'] as int) < min ? e['days'] as int : min,
        );
        return minDaysA.compareTo(minDaysB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedGroups.map((groupEntry) {
        final primaryMuscle = groupEntry.key;
        final subMuscles = groupEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary muscle group header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                primaryMuscle.displayName,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Sub-muscle chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subMuscles.map((subData) {
                final days = subData['days'] as int;
                Color chipColor;
                IconData icon;

                if (days >= 3) {
                  chipColor = theme.successColor;
                  icon = Icons.check_circle;
                } else if (days >= 1) {
                  chipColor = Colors.orange;
                  icon = Icons.access_time;
                } else {
                  chipColor = theme.errorColor;
                  icon = Icons.warning;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: chipColor),
                      const SizedBox(width: 4),
                      Text(
                        '${subData['displayName']} $days天',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: chipColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  // ==================== AI 分析功能 ====================

  /// 导航到 AI 分析全屏页面
  void _navigateToAIAnalysis(AppThemeData theme) {
    final periodType = _tabController.index == 0 ? 'week' : 'month';

    final records = periodType == 'week'
        ? _filterBySelectedWeek()
        : _filterBySelectedMonth();

    // 计算日期范围
    DateTime startDate;
    DateTime endDate;
    List<dynamic> previousRecords;

    if (periodType == 'week') {
      final weekStart = _getStartOfWeek(_selectedWeekStart);
      startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      endDate = startDate.add(const Duration(days: 7));
      previousRecords = _filterByWeek(
        startDate.subtract(const Duration(days: 7)),
      );
    } else {
      startDate = DateTime(_selectedYear, _selectedMonth, 1);
      endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
      int prevMonth = _selectedMonth - 1;
      int prevYear = _selectedYear;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear--;
      }
      previousRecords = _filterByMonth(prevYear, prevMonth);
    }

    // 全部 WorkoutRecord
    final allWorkoutRecords = _getAllRecords()
        .whereType<WorkoutRecord>()
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAnalysisScreen(
          periodType: periodType,
          startDate: startDate,
          endDate: endDate,
          records: records.whereType<WorkoutRecord>().toList(),
          previousRecords: previousRecords.whereType<WorkoutRecord>().toList(),
          allRecords: allWorkoutRecords,
        ),
      ),
    );
  }
}

/// Collapsible section wrapper for grouping related stats sections
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final AppThemeData theme;

  const _CollapsibleSection({
    required this.title,
    required this.children,
    required this.theme,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: widget.theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 8,
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.theme.textColor,
            ),
          ),
          children: widget.children,
        ),
      ),
    );
  }
}

/// Custom painter for donut chart
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<PrimaryMuscleGroup, double>> data;
  final Map<PrimaryMuscleGroup, Color> colors;
  final double totalVolume;

  _DonutChartPainter({
    required this.data,
    required this.colors,
    required this.totalVolume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || totalVolume == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final ringWidth = 24.0;
    final innerRadius = outerRadius - ringWidth;

    double startAngle = -90 * (3.14159265359 / 180); // Start from top
    const gapDegrees = 2.0;
    const gapRadians = gapDegrees * (3.14159265359 / 180);

    for (final entry in data) {
      final muscle = entry.key;
      final volume = entry.value;
      final percentage = volume / totalVolume;
      final sweepAngle = percentage * 2 * 3.14159265359 - gapRadians;

      final paint = Paint()
        ..color = colors[muscle] ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: (outerRadius + innerRadius) / 2,
        ),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle + gapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.totalVolume != totalVolume;
  }
}
