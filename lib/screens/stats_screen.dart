import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/workout_repository.dart';
import '../bloc/record_provider.dart';

import 'package:flutter/services.dart';
import 'ai_plan_wizard_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutRepository _repository = WorkoutRepository();
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
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;
      final records = context.read<RecordProvider>().records;
      setState(() {
        _oldSessions = sessions;
        _newRecords = records;
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

  /// 获取记录日期
  DateTime _getRecordDate(dynamic record) {
    if (record is WorkoutSession) {
      return DateTime.parse(record.createdAt);
    } else if (record is WorkoutRecord) {
      return record.date;
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

  /// 获取一周的开始日期（周一）
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 获取一周的7天列表
  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  /// 导航周（-1上一周，1下一周）
  void _navigateWeek(int direction) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: 7 * direction));
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
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _getAllRecords().where((record) {
      DateTime date = _getRecordDate(record);
      return date.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
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
          durations[dayIndex] = (durations[dayIndex] ?? 0) + _getRecordDuration(record);
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
          durations[date.day] = (durations[date.day] ?? 0) + _getRecordDuration(record);
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
        'avgSessionsPerWeek': records.length / (uniqueDays.isNotEmpty ? uniqueDays.length / 7 : 1),
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
              'TRAINING STATS',
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
          IconButton(
            icon: Icon(Icons.psychology, color: theme.accentColor),
            tooltip: 'AI 分析',
            onPressed: () => _showAIAnalysisDialog(theme),
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
              children: [
                _buildWeekView(theme),
                _buildMonthView(theme),
              ],
            ),
    );
  }



  Widget _buildSection(String title, AppThemeData theme, List<Widget> children) {
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
  Widget _buildFrequencyOverview(Map<String, dynamic> stats, AppThemeData theme) {
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
            '${(stats['avgSessionsPerWeek'] as double).toStringAsFixed(1)} 次',            '次',
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
              _buildSubMetric('平均组数/次', '${(stats['avgSetsPerSession'] as double).toStringAsFixed(1)} 组', theme),
              Container(width: 1, height: 30, color: theme.textColor.withValues(alpha: 0.1)),
              _buildSubMetric('平均时长/次', formatDuration(stats['avgDurationPerSession'] as int), theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon, Color color, AppThemeData theme) {
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
    final records = _filterBySelectedWeek();
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);
    final dailyDurations = _getDailyDurations(records, true);
    final dailySets = _getDailySets(records, true);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 周选择器
          _buildWeekSelector(theme),
          const SizedBox(height: 20),

          // 训练频率概览
          _buildSection('训练频率', theme, [
            _buildFrequencyOverview(frequencyStats, theme),
          ]),
          const SizedBox(height: 20),

          // 训练量统计
          _buildSection('训练量', theme, [
            _buildVolumeOverview(volumeStats, theme),
          ]),
          const SizedBox(height: 20),

          // 每日训练时长图表
          _buildSection('每日训练时长', theme, [
            _buildDailyDurationChart(dailyDurations, dailySets, theme, isWeekView: true, days: 7),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 月视图
  Widget _buildMonthView(AppThemeData theme) {
    final records = _filterBySelectedMonth();
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);
    final monthlyCounts = _getMonthlyCounts(_selectedYear);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 年份选择器
          _buildYearSelector(theme),
          const SizedBox(height: 16),

          // 月份网格
          _buildMonthGrid(monthlyCounts, theme),
          const SizedBox(height: 20),

          // 训练频率概览
          _buildSection('训练频率 ($_selectedMonth月)', theme, [
            _buildFrequencyOverview(frequencyStats, theme),
          ]),
          const SizedBox(height: 20),

          // 训练量统计
          _buildSection('训练量 ($_selectedMonth月)', theme, [
            _buildVolumeOverview(volumeStats, theme),
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
    final canGoNext = weekStart.add(const Duration(days: 7)).isBefore(DateTime(today.year, today.month, today.day).add(const Duration(days: 1)));

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
                icon: Icon(Icons.chevron_right, color: canGoNext ? theme.textColor : theme.secondaryTextColor.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 7天日历
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final day = weekDays[index];
              final isToday = day.year == today.year &&
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
                            ? const Color(0xFF1A237E)
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
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
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
            onPressed: _selectedYear < DateTime.now().year ? () => _navigateYear(1) : null,
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
    final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
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
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
                        colors: [theme.primaryColor, theme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : isFuture
                        ? theme.textColor.withValues(alpha: 0.05)
                        : intensity > 0
                            ? theme.primaryColor.withValues(alpha: 0.1 + intensity * 0.3)
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isFuture
                              ? theme.secondaryTextColor.withValues(alpha: 0.3)
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
  }

  /// 每日训练时长图表
  Widget _buildDailyDurationChart(Map<int, int> durations, Map<int, int> sets, AppThemeData theme, {required bool isWeekView, int? days}) {
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
                gradient: LinearGradient(colors: [theme.primaryColor, theme.secondaryColor]),
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
                    final heightPercent = maxDuration > 0 ? duration / maxDuration : 0.0;
                    final barHeight = (heightPercent * 70).clamp(4.0, 70.0);

                    return Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: isWeekView ? 2 : 1),
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
                                          colors: [theme.primaryColor, theme.secondaryColor],
                                        )
                                      : null,
                                  color: duration > 0 ? null : theme.textColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(isWeekView ? 4 : 2),
                                ),
                              ),
                              // 数字 - 在柱状条上方
                              Positioned(
                                bottom: barHeight + 2,
                                child: Column(
                                  children: [
                                    if (duration > 0 || setCount > 0)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
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
                  final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                  final bool showLabel = isWeekView || 
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

  // ==================== AI 分析功能 ====================

  /// 显示 AI 分析弹窗
  void _showAIAnalysisDialog(AppThemeData theme) {
    // 根据当前选中的 tab 决定分析周期
    final periodType = _tabController.index == 0 ? 'week' : 'month';
    
    // 获取当前周期的统计数据
    final records = periodType == 'week' 
        ? _filterBySelectedWeek() 
        : _filterBySelectedMonth();
    
    // 计算日期范围
    DateTime startDate;
    DateTime endDate;
    if (periodType == 'week') {
      final weekStart = _getStartOfWeek(_selectedWeekStart);
      startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      endDate = startDate.add(const Duration(days: 7));
    } else {
      startDate = DateTime(_selectedYear, _selectedMonth, 1);
      endDate = DateTime(_selectedYear, _selectedMonth + 1, 0);
    }
    
    // 计算统计数据
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);

    showDialog(
      context: context,
      builder: (context) => _AIAnalysisDialog(
        theme: theme,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        frequencyStats: frequencyStats,
        volumeStats: volumeStats,
        records: records.whereType<WorkoutRecord>().toList(),
      ),
    );
  }
}

/// AI 分析弹窗组件
class _AIAnalysisDialog extends StatefulWidget {
  final AppThemeData theme;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> frequencyStats;
  final Map<String, dynamic> volumeStats;
  final List<WorkoutRecord> records;

  const _AIAnalysisDialog({
    required this.theme,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.frequencyStats,
    required this.volumeStats,
    required this.records,
  });

  @override
  State<_AIAnalysisDialog> createState() => _AIAnalysisDialogState();
}

class _AIAnalysisDialogState extends State<_AIAnalysisDialog> {
  String _selectedGoal = 'muscle_building';
  final Set<String> _selectedFocusAreas = {};
  late String _generatedPrompt;
  bool _isPromptCopied = false;

  @override
  void initState() {
    super.initState();
    _generatedPrompt = _generatePrompt();
  }

  /// 格式化肌肉分布数据
  String _formatMuscleDistribution() {
    final muscleFrequency = widget.frequencyStats['muscleFrequency'] as Map<PrimaryMuscleGroup, int>?;
    if (muscleFrequency == null || muscleFrequency.isEmpty) {
      return '- 暂无肌肉训练数据';
    }

    // 按训练次数排序
    final sortedMuscles = muscleFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sortedMuscles.fold<int>(0, (sum, e) => sum + e.value);
    final buffer = StringBuffer();

    for (final entry in sortedMuscles) {
      final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0.0';
      buffer.writeln('  - ${entry.key.displayName}: ${entry.value}次 ($percentage%)');
    }

    return buffer.toString().trimRight();
  }

  /// 格式化恢复管理数据（计算每个肌肉的休息天数）
  String _formatRecoveryManagement() {
    if (widget.records.isEmpty) {
      return '- 暂无恢复数据';
    }

    // 统计每个肌肉部位最后训练日期
    final Map<PrimaryMuscleGroup, DateTime> lastTrainedDates = {};

    for (final record in widget.records) {
      for (final muscle in record.trainedMuscles) {
        final existingDate = lastTrainedDates[muscle];
        if (existingDate == null || record.date.isAfter(existingDate)) {
          lastTrainedDates[muscle] = record.date;
        }
      }
    }

    if (lastTrainedDates.isEmpty) {
      return '- 暂无肌肉恢复数据';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buffer = StringBuffer();

    // 按休息天数排序（从长到短）
    final sortedEntries = lastTrainedDates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      final lastDate = DateTime(entry.value.year, entry.value.month, entry.value.day);
      final restDays = today.difference(lastDate).inDays;
      buffer.writeln('  - ${entry.key.displayName}: 已休息$restDays 天');
    }

    return buffer.toString().trimRight();
  }

  /// 格式化常用动作数据
  String _formatCommonExercises() {
    if (widget.records.isEmpty) {
      return '- 暂无动作数据';
    }

    // 统计每个动作的训练次数
    final Map<String, int> exerciseCounts = {};

    for (final record in widget.records) {
      for (final exercise in record.exercises) {
        final name = exercise.name.isNotEmpty ? exercise.name : exercise.exerciseId;
        exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
      }
    }

    if (exerciseCounts.isEmpty) {
      return '- 暂无动作训练数据';
    }

    // 按次数排序，取前10个
    final sortedExercises = exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topExercises = sortedExercises.take(10);
    final buffer = StringBuffer();

    for (final entry in topExercises) {
      buffer.writeln('  - ${entry.key}: ${entry.value} 次');
    }

    return buffer.toString().trimRight();
  }

  /// 获取薄弱部位（训练次数最少的）
  List<String> _getWeakMuscles() {
    final muscleFrequency = widget.frequencyStats['muscleFrequency'] as Map<PrimaryMuscleGroup, int>?;
    if (muscleFrequency == null || muscleFrequency.isEmpty) {
      return [];
    }

    // 所有主要肌肉部位
    final allMuscles = PrimaryMuscleGroup.values;
    final trainedMuscles = muscleFrequency.keys.toSet();

    // 找出未训练的部位
    final untrained = allMuscles.where((m) => !trainedMuscles.contains(m)).map((m) => m.displayName).toList();

    // 找出训练次数最少的部位（<= 平均值的 50%）
    final avgFrequency = muscleFrequency.values.fold<int>(0, (sum, v) => sum + v) / muscleFrequency.length;
    final weakTrained = muscleFrequency.entries
        .where((e) => e.value <= avgFrequency * 0.5)
        .map((e) => e.key.displayName)
        .toList();

    return [...untrained, ...weakTrained];
  }

  /// 获取过度训练的部位（连续训练天数过多）
  List<String> _getOvertrainedMuscles() {
    if (widget.records.length < 2) {
      return [];
    }

    // 按日期排序记录
    final sortedRecords = List<WorkoutRecord>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<PrimaryMuscleGroup, int> consecutiveDays = {};

    // 检查每个肌肉部位的连续训练情况
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
        consecutiveDays[muscle] = maxConsecutive;
      }
    }

    return consecutiveDays.entries
        .where((e) => e.value >= 3)
        .map((e) => '${e.key.displayName}(连续${e.value}天)')
        .toList();
  }

  String _generatePrompt() {
    final periodLabel = widget.periodType == 'week' ? '本周' : '本月';
    final dateFormat = '${widget.startDate.year}年${widget.startDate.month}月${widget.startDate.day}日';

    // 格式化训练目标
    final goalLabels = {
      'muscle_building': '增肌',
      'fat_loss': '减脂',
      'strength': '力量提升',
      'endurance': '耐力增强',
    };

    // 格式化重点部位
    final muscleLabels = {
      'chest': '胸部',
      'back': '背部',
      'shoulders': '肩部',
      'arms': '手臂',
      'legs': '腿部',
      'core': '核心',
    };

    // 获取薄弱部位和过度训练部位
    final weakMuscles = _getWeakMuscles();
    final overtrainedMuscles = _getOvertrainedMuscles();

    final buffer = StringBuffer();
    buffer.writeln('你是一位专业的健身教练。根据我的训练数据，为我生成下个周期的训练计划。');
    buffer.writeln();
    buffer.writeln('## 训练周期');
    buffer.writeln('- 类型: $periodLabel');
    buffer.writeln('- 日期范围: $dateFormat');
    buffer.writeln();
    buffer.writeln('## 基础统计');
    buffer.writeln('- 训练次数: ${widget.frequencyStats['sessionCount']} 次');
    buffer.writeln('- 训练天数: ${widget.frequencyStats['workoutDays']} 天');
    buffer.writeln('- 总组数: ${widget.volumeStats['totalSets']} 组');
    buffer.writeln('- 总时长: ${(widget.volumeStats['totalDuration'] as int) ~/ 60} 分钟');
    buffer.writeln();
    buffer.writeln('## 肌肉分布');
    buffer.writeln(_formatMuscleDistribution());
    buffer.writeln();
    buffer.writeln('## 恢复管理');
    buffer.writeln(_formatRecoveryManagement());
    buffer.writeln();
    buffer.writeln('## 常用动作');
    buffer.writeln(_formatCommonExercises());
    buffer.writeln();
    buffer.writeln('## 用户目标');
    buffer.writeln('- 主要目标: ${goalLabels[_selectedGoal] ?? _selectedGoal}');
    if (_selectedFocusAreas.isNotEmpty) {
      buffer.writeln('- 重点加强: ${_selectedFocusAreas.map((m) => muscleLabels[m] ?? m).join('、')}');
    }
    if (weakMuscles.isNotEmpty) {
      buffer.writeln('- 薄弱部位: ${weakMuscles.join('、')} (需要加强)');
    }
    if (overtrainedMuscles.isNotEmpty) {
      buffer.writeln('- 过度训练风险: ${overtrainedMuscles.join('、')} (需要更多休息)');
    }
    buffer.writeln();
    buffer.writeln('## 输出格式');
    buffer.writeln('Output ONLY valid JSON:');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "name": "计划名称",');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "dayOfWeek": 1,');
    buffer.writeln('      "targetMuscles": ["chest", "shoulders"],');
    buffer.writeln('      "exercises": [');
    buffer.writeln('        {"exerciseName": "Barbell Bench Press", "targetSets": 4}');
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('## 规则');
    buffer.writeln('1. dayOfWeek: 1=周一 ... 7=周日');
    buffer.writeln('2. targetMuscles: chest, back, shoulders, arms, legs, core');
    buffer.writeln('3. targetSets: 3-5 每个动作');
    buffer.writeln('4. 复合动作优先，孤立动作在后');
    buffer.writeln('5. 根据训练频率安排休息日');
    buffer.writeln('6. 针对薄弱部位增加训练量和动作选择');
    buffer.writeln('7. 避免过度训练：同一肌群训练间隔至少48小时');
    buffer.writeln('8. 大肌群(胸/背/腿)需要更长恢复时间(72小时)');
    buffer.writeln('9. 同一肌群每周训练2-3次为宜');
    buffer.writeln('10. 渐进式超负荷：逐渐增加重量或次数');
    buffer.writeln();
    buffer.writeln('生成我的训练计划。JSON only:');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.psychology, color: widget.theme.accentColor),
          const SizedBox(width: 8),
          Text(
            'AI 训练分析',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.theme.textColor,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 训练目标单选
              Text(
                '训练目标',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildGoalChip('增肌', 'muscle_building'),
                  _buildGoalChip('减脂', 'fat_loss'),
                  _buildGoalChip('力量', 'strength'),
                  _buildGoalChip('耐力', 'endurance'),
                ],
              ),
              const SizedBox(height: 16),
              
              // 重点加强部位多选
              Text(
                '重点加强部位 (可选)',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFocusChip('胸', 'chest'),
                  _buildFocusChip('背', 'back'),
                  _buildFocusChip('肩', 'shoulders'),
                  _buildFocusChip('手臂', 'arms'),
                  _buildFocusChip('腿', 'legs'),
                  _buildFocusChip('核心', 'core'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Prompt 展示区域
              Text(
                '生成的 Prompt',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.theme.textColor.withValues(alpha: 0.1)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _generatedPrompt,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: widget.theme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '取消',
            style: TextStyle(color: widget.theme.secondaryTextColor),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _generatedPrompt));
            setState(() => _isPromptCopied = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prompt 已复制到剪贴板')),
            );
          },
          icon: Icon(Icons.copy, size: 18, color: _isPromptCopied ? widget.theme.accentColor : widget.theme.surfaceColor),
          label: Text(_isPromptCopied ? '已复制' : '复制'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPromptCopied ? widget.theme.accentColor.withValues(alpha: 0.1) : widget.theme.cardColor,
            foregroundColor: _isPromptCopied ? widget.theme.accentColor : widget.theme.accentColor,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isPromptCopied
              ? () {
                  Navigator.pop(context);
                  // 跳转到 AI 计划向导页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIPlanWizardScreen(
                        statsAnalysisMode: true,
                        generatedPrompt: _generatedPrompt,
                      ),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('导入 AI 建议'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.accentColor,
            foregroundColor: widget.theme.surfaceColor,
            disabledBackgroundColor: widget.theme.textColor.withValues(alpha: 0.1),
            disabledForegroundColor: widget.theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalChip(String label, String value) {
    final isSelected = _selectedGoal == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = value;
          _generatedPrompt = _generatePrompt();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? widget.theme.accentColor : widget.theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? widget.theme.accentColor : widget.theme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : widget.theme.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusChip(String label, String value) {
    final isSelected = _selectedFocusAreas.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          if (isSelected) {
            _selectedFocusAreas.remove(value);
          } else {
            _selectedFocusAreas.add(value);
          }
          _generatedPrompt = _generatePrompt();
        });
      },
      selectedColor: widget.theme.accentColor.withValues(alpha: 0.15),
      checkmarkColor: widget.theme.accentColor,
      backgroundColor: widget.theme.textColor.withValues(alpha: 0.05),
      side: BorderSide(color: widget.theme.textColor.withValues(alpha: 0.1)),
      labelStyle: TextStyle(
        color: isSelected ? widget.theme.accentColor : widget.theme.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
