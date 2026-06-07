import 'dart:math' as math;
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
import '../widgets/volume_trend_charts.dart';
import 'ai_analysis_screen.dart';
import '../services/user_preferences_service.dart';
import '../animations/page_transitions.dart';

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
  List<dynamic>? _cachedAllRecords;
  double _userBodyWeight = 0.0;

  static const _kMuscleColors = <PrimaryMuscleGroup, Color>{
    PrimaryMuscleGroup.chest: Color(0xFFE69F00), // orange
    PrimaryMuscleGroup.back: Color(0xFF56B4E9), // sky blue
    PrimaryMuscleGroup.shoulders: Color(0xFF009E73), // bluish green
    PrimaryMuscleGroup.arms: Color(0xFFF0E442), // yellow
    PrimaryMuscleGroup.legs: Color(0xFF0072B2), // blue
    PrimaryMuscleGroup.core: Color(0xFFD55E00), // vermillion
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 延迟到 build 完成后再加载数据，避免 setState during build 异常
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _cachedAllRecords = null;
      final recordProvider = context.read<RecordProvider>();
      // 确保记录已加载（首次进入时可能还未加载）
      if (recordProvider.recordCount == 0) {
        await recordProvider.loadRecords();
      }
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;

      // Load user body weight for bodyweight volume calculation
      double bodyWeight = 0.0;
      try {
        final prefsService = UserPreferencesService();
        final prefs = await prefsService.loadPreferences();
        bodyWeight = prefs.bodyWeight;
      } catch (e) {
        debugPrint('Error loading body weight for stats: $e');
      }

      setState(() {
        _oldSessions = sessions;
        _newRecords = recordProvider.records;
        _isLoading = false;
        _userBodyWeight = bodyWeight;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 获取所有记录（合并旧记录和新记录）
  List<dynamic> _getAllRecords() {
    return _cachedAllRecords ??= [..._oldSessions, ..._newRecords];
  }

  /// 获取记录日期（剥离时间部分，只保留日期）
  DateTime _getRecordDate(dynamic record) {
    if (record is WorkoutSession) {
      final parsed = DateTime.parse(record.createdAt);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } else if (record is WorkoutRecord) {
      return DateTime(record.date.year, record.date.month, record.date.day);
    }
    throw ArgumentError('Unknown record type: ${record.runtimeType}');
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

  /// 跳转到本周
  void _goToCurrentWeek() {
    setState(() {
      _selectedWeekStart = _getStartOfWeek(DateTime.now());
    });
  }

  /// 跳转到当前月份
  void _goToCurrentMonth() {
    setState(() {
      final now = DateTime.now();
      _selectedMonth = now.month;
      _selectedYear = now.year;
    });
  }

  /// 是否已选中当前周
  bool _isCurrentWeek() {
    final now = DateTime.now();
    final thisWeekStart = _getStartOfWeek(now);
    final selectedWeekStart = _getStartOfWeek(_selectedWeekStart);
    return thisWeekStart.year == selectedWeekStart.year &&
        thisWeekStart.month == selectedWeekStart.month &&
        thisWeekStart.day == selectedWeekStart.day;
  }

  /// 是否已选中当前月份
  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedYear == now.year && _selectedMonth == now.month;
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

    // Calculate actual sessions per week based on the time span
    final dates = uniqueDays.map((d) {
      final parts = d.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList();
    dates.sort();

    final double avgSessionsPerWeek;
    if (dates.length >= 2) {
      final spanDays = dates.last.difference(dates.first).inDays + 1;
      final spanWeeks = spanDays / 7.0;
      avgSessionsPerWeek = spanWeeks > 0
          ? records.length / spanWeeks
          : records.length.toDouble();
    } else {
      // Single day of data — can't compute meaningful weekly average
      avgSessionsPerWeek = records.length.toDouble();
    }

    return {
      'sessionCount': records.length,
      'workoutDays': uniqueDays.length,
      'avgSessionsPerWeek': avgSessionsPerWeek,
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
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (secs > 0) {
      return '${minutes}m ${secs}s';
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            Text(
              '训练统计',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
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
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
          labelStyle: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
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
              children: [
                RefreshIndicator(
                  color: theme.primaryColor,
                  onRefresh: () async => _loadData(),
                  child: _buildWeekView(theme),
                ),
                RefreshIndicator(
                  color: theme.primaryColor,
                  onRefresh: () async => _loadData(),
                  child: _buildMonthView(theme),
                ),
              ],
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
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          decoration: BoxDecoration(
            color: theme.surfaceColorRaised,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: AppElevation.raised(theme.shadowColor),
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

  /// Calculate volume change percentage between current and previous period
  /// Returns null if no comparison is available
  double? _calculateVolumeChange(
    List<dynamic> currentRecords,
    List<dynamic> previousRecords,
  ) {
    final currentWorkoutRecords = currentRecords
        .whereType<WorkoutRecord>()
        .toList();
    final previousWorkoutRecords = previousRecords
        .whereType<WorkoutRecord>()
        .toList();

    if (currentWorkoutRecords.isEmpty || previousWorkoutRecords.isEmpty)
      return null;

    final currentVolume = _statsCalc.calculateTotalVolume(
      currentWorkoutRecords,
      bodyWeight: _userBodyWeight,
    );
    final previousVolume = _statsCalc.calculateTotalVolume(
      previousWorkoutRecords,
      bodyWeight: _userBodyWeight,
    );

    if (previousVolume == 0) return null;

    return ((currentVolume - previousVolume) / previousVolume) * 100;
  }

  /// 训练量概览
  Widget _buildVolumeOverview(
    Map<String, dynamic> stats,
    AppThemeData theme, {
    double? volumeChange,
  }) {
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
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
        if (volumeChange != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  volumeChange >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: volumeChange >= 0
                      ? theme.successColor
                      : theme.errorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${volumeChange >= 0 ? '+' : ''}${volumeChange.toStringAsFixed(1)}% vs 上期',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    color: volumeChange >= 0
                        ? theme.successColor
                        : theme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: theme.accentColor),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
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

    // 计算周环比变化
    final previousWeekRecords = _filterByWeek(
      _selectedWeekStart.subtract(const Duration(days: 7)),
    );
    final volumeChange = _calculateVolumeChange(records, previousWeekRecords);

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

          // 概览 (频率 + 训练量 + 训练密度)
          _CollapsibleSection(
            title: '概览',
            theme: theme,
            children: [
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(
                volumeStats,
                theme,
                volumeChange: volumeChange,
              ),
              const SizedBox(height: 12),
              _buildDensityMetric(workoutRecords, theme),
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

          // 训练量趋势（周）
          _buildSection('训练量趋势', theme, [
            DailyVolumeChart(
              data: _statsCalc.calculateDailyVolumeTrend(
                workoutRecords,
                bodyWeight: _userBodyWeight,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 进步追踪 (常用动作)
          _CollapsibleSection(
            title: '进步追踪',
            theme: theme,
            children: [
              _buildCommonExercisesChart(
                _calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (每肌群组数 + 肌群容量 + 恢复状态)
          _CollapsibleSection(
            title: '身体分析',
            theme: theme,
            children: [
              _buildSetsPerMuscleGroupChart(workoutRecords, theme),
              const SizedBox(height: 20),
              _buildMuscleVolumeChart(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildPrimaryRecoveryList(workoutRecords, theme),
            ],
          ),
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

    // 计算月环比变化
    final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    final previousMonthRecords = _filterByMonth(prevYear, prevMonth);
    final volumeChange = _calculateVolumeChange(records, previousMonthRecords);

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

          // 概览 (频率 + 训练量 + 训练密度)
          _CollapsibleSection(
            title: '概览 ($_selectedMonth月)',
            theme: theme,
            children: [
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(
                volumeStats,
                theme,
                volumeChange: volumeChange,
              ),
              const SizedBox(height: 12),
              _buildDensityMetric(workoutRecords, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 训练量趋势（月）
          _buildSection('训练量趋势', theme, [
            DailyVolumeChart(
              data: _statsCalc.calculateDailyVolumeTrend(
                workoutRecords,
                bodyWeight: _userBodyWeight,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 进步追踪 (估算1RM趋势 + 常用动作)
          _CollapsibleSection(
            title: '进步追踪',
            theme: theme,
            children: [
              _buildEstimated1RMTrend(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildCommonExercisesChart(
                _calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (每肌群组数 + 肌群容量 + 恢复状态)
          _CollapsibleSection(
            title: '身体分析',
            theme: theme,
            children: [
              _buildSetsPerMuscleGroupChart(workoutRecords, theme),
              const SizedBox(height: 20),
              _buildMuscleVolumeChart(workoutRecords, theme),
              const SizedBox(height: 16),
              _buildPrimaryRecoveryList(workoutRecords, theme),
            ],
          ),
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
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
      ),
      child: Column(
        children: [
          // 周导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: '上一周',
                onPressed: () => _navigateWeek(-1),
                icon: Icon(Icons.chevron_left, color: theme.textColor),
              ),
              Column(
                children: [
                  Text(
                    '${weekStart.month}月 ${weekStart.day}日 - ${weekDays.last.month}月 ${weekDays.last.day}日',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge!.copyWith(color: theme.textColor),
                  ),
                  Text(
                    '${weekStart.year}年',
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isCurrentWeek())
                    GestureDetector(
                      onTap: _goToCurrentWeek,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '今天',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.accentColor,
                              ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: '下一周',
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
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusChip,
                        ),
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
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? theme.surfaceColor
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
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: '上一年',
            onPressed: () => _navigateYear(-1),
            icon: Icon(Icons.chevron_left, color: theme.textColor),
          ),
          Text(
            '$_selectedYear 年',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium!.copyWith(color: theme.textColor),
          ),
          if (!_isCurrentMonth())
            GestureDetector(
              onTap: _goToCurrentMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '今天',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: '下一年',
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
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
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

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFuture ? null : () => _selectMonth(month),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
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
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? theme.surfaceColor
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
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? theme.surfaceColor
                                        : theme.primaryColor,
                                  ),
                            ),
                          ],
                        ],
                      ),
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
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: theme.textColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成几次训练后这里会显示统计信息',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无训练数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '时长/组数',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                                    isWeekView
                                        ? AppDimensions.radiusSm
                                        : AppDimensions.radiusXxs,
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                  fontSize: isWeekView ? 11 : 9,
                                                  color:
                                                      theme.secondaryTextColor,
                                                ),
                                          ),
                                          if (setCount > 0)
                                            Text(
                                              '$setCount 组',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    fontSize: isWeekView
                                                        ? 10
                                                        : 8,
                                                    color: theme
                                                        .secondaryTextColor,
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
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
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

  // ==================== 图表数据计算方法 ====================

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

  // ==================== 新增统计组件 ====================

  /// 常用动作图表（水平条形图）
  Widget _buildCommonExercisesChart(
    Map<String, int> exercises,
    AppThemeData theme,
  ) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无动作数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
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
        final displayName = entry.key.length > 12
            ? '${entry.key.substring(0, 12)}...'
            : entry.key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
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
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
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
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
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

  /// 肌群容量分布 - 甜甜圈图
  Widget _buildMuscleVolumeChart(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final distribution = _statsCalc.calculateMuscleVolumeDistribution(
      records,
      bodyWeight: _userBodyWeight,
    );

    if (distribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无训练数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    // Calculate total volume
    final totalVolume = distribution.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );

    // Color mapping for each PrimaryMuscleGroup (uses class-level static const)

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
              colors: _kMuscleColors,
              totalVolume: totalVolume,
              fallbackColor: theme.secondaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Center text showing total volume
        Text(
          _formatVolume(totalVolume),
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        Text(
          '总容量',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 20),
        // Legend - group small segments (<5%) into "其他"
        Builder(
          builder: (context) {
            const kSmallThreshold = 0.05;
            final legendItems = <MapEntry<String, Color?>>[];
            double otherPercentage = 0;

            for (final entry in sortedEntries) {
              final pct = totalVolume > 0 ? entry.value / totalVolume : 0.0;
              if (pct < kSmallThreshold) {
                otherPercentage += pct;
              } else {
                legendItems.add(
                  MapEntry(
                    '${entry.key.displayName} ${(pct * 100).toStringAsFixed(1)}%',
                    _kMuscleColors[entry.key],
                  ),
                );
              }
            }
            if (otherPercentage > 0) {
              legendItems.add(
                MapEntry(
                  '其他 ${(otherPercentage * 100).toStringAsFixed(1)}%',
                  theme.secondaryTextColor,
                ),
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 8,
              children: legendItems.map((item) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.value ?? theme.secondaryTextColor,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXxs,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.key,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
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

  /// 主肌群恢复天数（简化版：只显示6个主肌群）
  Widget _buildPrimaryRecoveryList(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    // 计算每个主肌群的最后训练日期
    final lastTrained = <PrimaryMuscleGroup, DateTime>{};
    final now = DateTime.now();

    for (final record in records) {
      for (final exercise in record.exercises) {
        final ex = exercise.exercise;
        if (ex == null) continue;
        final muscle = ex.primaryMuscle;
        if (lastTrained[muscle] == null ||
            record.date.isAfter(lastTrained[muscle]!)) {
          lastTrained[muscle] = record.date;
        }
      }
    }

    if (lastTrained.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无恢复数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    // 按恢复天数排序（最久没练的在前）
    final sorted = lastTrained.entries.toList()
      ..sort(
        (a, b) => now
            .difference(b.value)
            .inDays
            .compareTo(now.difference(a.value).inDays),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '恢复状态',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: sorted.map((entry) {
            final days = now.difference(entry.value).inDays;
            final muscle = entry.key;

            Color chipColor;
            IconData icon;
            if (days >= 3) {
              chipColor = theme.successColor;
              icon = Icons.check_circle;
            } else if (days >= 1) {
              chipColor = theme.accentColor;
              icon = Icons.access_time;
            } else {
              chipColor = theme.errorColor;
              icon = Icons.warning;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(color: chipColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: chipColor),
                  const SizedBox(width: 6),
                  Text(
                    '${muscle.displayName} $days天',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== 新增统计组件 ====================

  /// 训练密度指标（组/分钟）
  Widget _buildDensityMetric(List<WorkoutRecord> records, AppThemeData theme) {
    if (records.isEmpty) return const SizedBox.shrink();

    final density = _statsCalc.calculateDensity(records);
    final totalSets = records.fold<int>(0, (sum, r) => sum + r.totalSets);
    final totalMinutes =
        records.fold<int>(0, (sum, r) => sum + r.durationSeconds) / 60.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, size: 20, color: theme.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '训练密度',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  '${density.toStringAsFixed(1)} 组/分钟',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$totalSets组 / ${totalMinutes.toStringAsFixed(0)}分钟',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 估算1RM趋势（top 5 动作的估算1RM变化）
  ///
  /// 使用 Mayhew 指数公式从 weight×reps 估算 1RM，消除重量/次数
  /// tradeoff 的歧义，让进步趋势可比。
  Widget _buildEstimated1RMTrend(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final trend = _statsCalc.calculateEstimated1RMTrend(records);

    if (trend.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无1RM数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    // Sort by number of sessions descending, take top 5
    final sorted = trend.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final top5 = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: theme.accentColor),
            const SizedBox(width: 6),
            Text(
              '估算1RM趋势',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Mayhew',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 10,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...top5.map((entry) {
          final name = entry.key;
          final points = entry.value;
          final displayName = name.length > 10
              ? '${name.substring(0, 10)}...'
              : name;

          // Need at least 2 points to show progression
          if (points.length < 2) {
            final e1RM = points.first.estimated1RM.toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11,
                        color: theme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$e1RM kg',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${points.length}次记录',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final first = points.first;
          final last = points.last;
          final change =
              ((last.estimated1RM - first.estimated1RM) / first.estimated1RM) *
              100;
          final weeks = last.date.difference(first.date).inDays / 7.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${first.estimated1RM.toStringAsFixed(1)} → ${last.estimated1RM.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (change >= 0 ? theme.successColor : theme.errorColor)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'
                    '${weeks > 0 ? ' / ${weeks.toStringAsFixed(0)}周' : ''}',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: change >= 0
                          ? theme.successColor
                          : theme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 每肌群组数（水平条形图 + MEV 参考线）
  Widget _buildSetsPerMuscleGroupChart(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(records);

    if (setsPerMuscle.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            '暂无肌群组数数据',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    // Sort by sets descending
    final sorted = setsPerMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxSets = sorted.first.value;
    // MEV reference: 10 sets/week (Schoenfeld 2017)
    const mevReference = 10;
    final referenceSets = maxSets > mevReference
        ? maxSets.toDouble()
        : mevReference * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, size: 16, color: theme.accentColor),
            const SizedBox(width: 6),
            Text(
              '每肌群组数',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '参考线: MEV 10组/周 (Schoenfeld 2017)',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 10,
            color: theme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ...sorted.map((entry) {
          final muscle = entry.key;
          final sets = entry.value;
          final percentage = referenceSets > 0 ? sets / referenceSets : 0.0;
          final color = _kMuscleColors[muscle] ?? theme.accentColor;
          final isAboveMEV = sets >= mevReference;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    muscle.displayName,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      final mevX = (mevReference / referenceSets) * barWidth;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background bar
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme.shadowColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                          ),
                          // MEV reference line
                          if (mevX <= barWidth)
                            Positioned(
                              left: mevX - 1,
                              top: -2,
                              child: Container(
                                width: 2,
                                height: 24,
                                color: theme.secondaryTextColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          // Actual bar
                          FractionallySizedBox(
                            widthFactor: percentage.clamp(0.02, 1.0),
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$sets组',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAboveMEV ? color : theme.secondaryTextColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
    List<WorkoutRecord> previousRecords;

    if (periodType == 'week') {
      final weekStart = _getStartOfWeek(_selectedWeekStart);
      startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      endDate = startDate.add(const Duration(days: 7));
      previousRecords = _filterByWeek(
        startDate.subtract(const Duration(days: 7)),
      ).whereType<WorkoutRecord>().toList();
    } else {
      startDate = DateTime(_selectedYear, _selectedMonth, 1);
      endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
      int prevMonth = _selectedMonth - 1;
      int prevYear = _selectedYear;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear--;
      }
      previousRecords = _filterByMonth(
        prevYear,
        prevMonth,
      ).whereType<WorkoutRecord>().toList();
    }

    // 全部 WorkoutRecord
    final allWorkoutRecords = _getAllRecords()
        .whereType<WorkoutRecord>()
        .toList();

    Navigator.push(
      context,
      FadeUpPageRoute(
        page: AIAnalysisScreen(
          periodType: periodType,
          startDate: startDate,
          endDate: endDate,
          records: records.whereType<WorkoutRecord>().toList(),
          previousRecords: previousRecords,
          allRecords: allWorkoutRecords,
        ),
      ),
    );
  }
}

/// Collapsible section wrapper for grouping related stats sections
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final AppThemeData theme;

  const _CollapsibleSection({
    required this.title,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
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
            title,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 15,
              color: theme.textColor,
            ),
          ),
          children: children,
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
  final Color fallbackColor;

  _DonutChartPainter({
    required this.data,
    required this.colors,
    required this.totalVolume,
    required this.fallbackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || totalVolume == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final ringWidth = 24.0;
    final innerRadius = outerRadius - ringWidth;

    double startAngle = -math.pi / 2; // Start from top
    const gapDegrees = 2.0;
    final gapRadians = gapDegrees * math.pi / 180;

    for (final entry in data) {
      final muscle = entry.key;
      final volume = entry.value;
      final percentage = volume / totalVolume;

      // Skip segments too small to render (avoid negative sweep angle)
      final rawSweep = percentage * 2 * math.pi - gapRadians;
      if (rawSweep <= 0) {
        startAngle += percentage * 2 * math.pi;
        continue;
      }
      final sweepAngle = rawSweep;

      final paint = Paint()
        ..color = colors[muscle] ?? fallbackColor
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
    if (oldDelegate.data.length != data.length) return true;
    if (oldDelegate.totalVolume != totalVolume) return true;
    if (oldDelegate.fallbackColor != fallbackColor) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i].key != data[i].key ||
          oldDelegate.data[i].value != data[i].value) {
        return true;
      }
    }
    for (final key in colors.keys) {
      if (oldDelegate.colors[key] != colors[key]) return true;
    }
    return false;
  }
}
