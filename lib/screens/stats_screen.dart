import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../services/workout_repository.dart';
import '../services/stats_calculator_service.dart';
import '../services/stats_aggregator_service.dart';
import '../providers/record_provider.dart';
import '../widgets/stats_charts.dart';
import '../widgets/stats_metric_sections.dart';
import '../widgets/volume_trend_charts.dart';
import 'ai_analysis_screen.dart';
import '../services/user_preferences_service.dart';
import '../animations/page_transitions.dart';
import '../theme/build_context_text_styles.dart';

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
  final StatsAggregatorService _aggregator = StatsAggregatorService();
  List<WorkoutSession> _oldSessions = [];
  List<WorkoutRecord> _newRecords = [];
  bool _isLoading = true;
  DateTime _selectedWeekStart = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<dynamic>? _cachedAllRecords;
  double _userBodyWeight = 0.0;

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
    return _cachedAllRecords ??= StatsAggregatorService.mergeRecords(
      _oldSessions,
      _newRecords,
    );
  }

  /// 获取一周的开始日期（周一），剥离时间部分
  DateTime _getStartOfWeek(DateTime date) => _aggregator.getStartOfWeek(date);

  /// 获取一周的7天列表
  List<DateTime> _getWeekDays(DateTime weekStart) =>
      _aggregator.getWeekDays(weekStart);

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
    return _aggregator.filterByWeek(
      _getAllRecords(),
      _getStartOfWeek(_selectedWeekStart),
    );
  }

  /// 按选中的月份筛选记录
  List<dynamic> _filterBySelectedMonth() {
    return _aggregator.filterByMonth(
      _getAllRecords(),
      _selectedYear,
      _selectedMonth,
    );
  }

  /// 按指定周的周一筛选记录（参数化版本，用于获取上一周期数据）
  List<dynamic> _filterByWeek(DateTime referenceDate) {
    return _aggregator.filterByWeek(
      _getAllRecords(),
      _getStartOfWeek(referenceDate),
    );
  }

  /// 按指定年月筛选记录（参数化版本，用于获取上一周期数据）
  List<dynamic> _filterByMonth(int year, int month) {
    return _aggregator.filterByMonth(_getAllRecords(), year, month);
  }

  /// 获取一年中每月的训练次数
  Map<int, int> _getMonthlyCounts(int year) {
    return _aggregator.getMonthlyCounts(_getAllRecords(), year);
  }

  /// 获取选中周内有训练的天数
  Set<int> _getWorkoutDaysInWeek() {
    return _aggregator.getWorkoutDaysInWeek(
      _getAllRecords(),
      _getStartOfWeek(_selectedWeekStart),
    );
  }

  /// 获取每日训练时长（周视图或月视图）
  Map<int, int> _getDailyDurations(List<dynamic> records, bool isWeek) {
    return _aggregator.getDailyDurations(
      records,
      isWeek: isWeek,
      weekStart: _selectedWeekStart,
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  /// 获取每日训练组数（周视图或月视图）
  Map<int, int> _getDailySets(List<dynamic> records, bool isWeek) {
    return _aggregator.getDailySets(
      records,
      isWeek: isWeek,
      weekStart: _selectedWeekStart,
      year: _selectedYear,
      month: _selectedMonth,
    );
  }

  /// 计算训练频率统计
  Map<String, dynamic> _calculateFrequencyStats(List<dynamic> records) =>
      _aggregator.calculateFrequencyStats(records);

  /// 计算训练量统计
  Map<String, dynamic> _calculateVolumeStats(List<dynamic> records) =>
      _aggregator.calculateVolumeStats(records);

  String formatDuration(int seconds) =>
      StatsAggregatorService.formatDuration(seconds);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.navStats,
          style: context.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.textColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _navigateToAIAnalysis(theme),
            icon: Icon(Icons.psychology, size: 20, color: theme.accentColor),
            label: Text(
              l10n.statsAiAnalysis,
              style: context.labelLarge.copyWith(
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
          labelStyle: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.statsWeekView),
            Tab(text: l10n.statsMonthView),
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

  /// Calculate volume change percentage between current and previous period
  /// Returns null if no comparison is available
  double? _calculateVolumeChange(
    List<dynamic> currentRecords,
    List<dynamic> previousRecords,
  ) {
    return _aggregator.calculateVolumeChange(
      currentRecords,
      previousRecords,
      bodyWeight: _userBodyWeight,
    );
  }

  /// 训练量概览 — 降级为紧凑次要指标行（总组数 / 总时长）
  /// 周视图
  Widget _buildWeekView(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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

          // 概览 (英雄数字 + 频率 + 训练量 + 训练密度)
          StatsCollapsibleSection(
            title: l10n.statsOverview,
            theme: theme,
            children: [
              // Hero — the screen's single visual center (DESIGN.md「扫一眼就懂」).
              buildHeroVolume(
                context,
                workoutRecords,
                theme,
                volumeChange: volumeChange,
                userBodyWeight: _userBodyWeight,
              ),
              const SizedBox(height: 16),
              buildFrequencyOverview(context, frequencyStats, theme),
              const SizedBox(height: 16),
              buildVolumeOverview(context, volumeStats, theme),
              const SizedBox(height: 12),
              buildDensityMetric(context, workoutRecords, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 每日训练时长图表
          buildStatsSection(context, l10n.statsDailyDurationTitle, theme, [
            buildDailyDurationChart(
              context,
              dailyDurations,
              dailySets,
              theme,
              isWeekView: true,
              days: 7,
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
            ),
          ]),
          const SizedBox(height: 20),

          // 训练量趋势（周）
          buildStatsSection(context, l10n.statsVolumeTrendTitle, theme, [
            DailyVolumeChart(
              data: _statsCalc.calculateDailyVolumeTrend(
                workoutRecords,
                bodyWeight: _userBodyWeight,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 进步追踪 (常用动作)
          StatsCollapsibleSection(
            title: l10n.statsProgressTracking,
            theme: theme,
            children: [
              buildCommonExercisesChart(
                context,
                _aggregator.calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (每肌群组数 + 肌群容量 + 恢复状态)
          StatsCollapsibleSection(
            title: l10n.statsBodyAnalysis,
            theme: theme,
            children: [
              buildSetsPerMuscleGroupChart(context, workoutRecords, theme),
              const SizedBox(height: 20),
              buildMuscleVolumeChart(
                context,
                workoutRecords,
                theme,
                userBodyWeight: _userBodyWeight,
              ),
              const SizedBox(height: 16),
              buildPrimaryRecoveryList(context, workoutRecords, theme),
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

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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

          // 概览 (英雄数字 + 频率 + 训练量 + 训练密度)
          StatsCollapsibleSection(
            title: l10n.statsOverviewMonth(_selectedMonth),
            theme: theme,
            children: [
              buildHeroVolume(
                context,
                workoutRecords,
                theme,
                volumeChange: volumeChange,
                userBodyWeight: _userBodyWeight,
              ),
              const SizedBox(height: 16),
              buildFrequencyOverview(context, frequencyStats, theme),
              const SizedBox(height: 16),
              buildVolumeOverview(context, volumeStats, theme),
              const SizedBox(height: 12),
              buildDensityMetric(context, workoutRecords, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 训练量趋势（月）
          buildStatsSection(context, l10n.statsVolumeTrendTitle, theme, [
            DailyVolumeChart(
              data: _statsCalc.calculateDailyVolumeTrend(
                workoutRecords,
                bodyWeight: _userBodyWeight,
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // 进步追踪 (估算1RM趋势 + 常用动作)
          StatsCollapsibleSection(
            title: l10n.statsProgressTracking,
            theme: theme,
            children: [
              buildEstimated1RMTrend(context, workoutRecords, theme),
              const SizedBox(height: 16),
              buildCommonExercisesChart(
                context,
                _aggregator.calculateCommonExercises(records),
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 身体分析 (每肌群组数 + 肌群容量 + 恢复状态)
          StatsCollapsibleSection(
            title: l10n.statsBodyAnalysis,
            theme: theme,
            children: [
              buildSetsPerMuscleGroupChart(context, workoutRecords, theme),
              const SizedBox(height: 20),
              buildMuscleVolumeChart(
                context,
                workoutRecords,
                theme,
                userBodyWeight: _userBodyWeight,
              ),
              const SizedBox(height: 16),
              buildPrimaryRecoveryList(context, workoutRecords, theme),
            ],
          ),
        ],
      ),
    );
  }

  /// 周选择器
  Widget _buildWeekSelector(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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
                tooltip: l10n.statsPrevWeek,
                onPressed: () => _navigateWeek(-1),
                icon: Icon(Icons.chevron_left, color: theme.textColor),
              ),
              Column(
                children: [
                  Text(
                    l10n.statsWeekRange(
                      weekStart.month,
                      weekStart.day,
                      weekDays.last.month,
                      weekDays.last.day,
                    ),
                    style: context.titleLarge.copyWith(color: theme.textColor),
                  ),
                  Text(
                    l10n.statsYearLabel(weekStart.year),
                    style: context.bodySmall,
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
                          l10n.statsToday,
                          style: context.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: l10n.statsNextWeek,
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

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      weekdayShort(index, l10n),
                      style: context.bodySmall.copyWith(
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
                          style: context.labelLarge.copyWith(
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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
            tooltip: l10n.statsPrevYear,
            onPressed: () => _navigateYear(-1),
            icon: Icon(Icons.chevron_left, color: theme.textColor),
          ),
          Text(
            l10n.statsYearLabel(_selectedYear),
            style: context.headlineMedium.copyWith(color: theme.textColor),
          ),
          if (!_isCurrentMonth())
            GestureDetector(
              onTap: _goToCurrentMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.statsToday,
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.statsNextYear,
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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
                // Sequential intensity scale uses the Okabe-Ito "blue" hue so the
                // heatmap reads as data, not decoration, and stays colorblind-safe
                // (DESIGN.md §2). Selection state below is UI accent, not data.
                const heatBlue = Color(0xFF0072B2); // Okabe-Ito blue

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isFuture ? null : () => _selectMonth(month),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: Container(
                      decoration: BoxDecoration(
                        // Selection is a UI state, not data — use the solid
                        // indigo accent (the "冷静" half of the duality), matching
                        // every other selected/active state in the app. The prior
                        // warm gradient was both an off-brand gradient reflex and
                        // a WCAG failure (white text on amber ≈ 1.6:1). Solid
                        // #1A237E with white text clears 3:1 large-text floor.
                        color: isSelected
                            ? theme.accentColor
                            : isFuture
                            ? theme.textColor.withValues(alpha: 0.05)
                            : intensity > 0
                            ? heatBlue.withValues(
                                alpha: 0.12 + intensity * 0.55,
                              )
                            : theme.textColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: theme.textColor.withValues(alpha: 0.1),
                              ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.statsMonthLabel(month),
                            style: context.bodySmall.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.onAccentColor
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
                              style: context.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? theme.onAccentColor
                                    : heatBlue,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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
            l10n.statsNoData,
            style: context.titleLarge.copyWith(
              color: theme.textColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statsEmptyHint,
            style: context.bodyMedium.copyWith(
              color: theme.secondaryTextColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
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
