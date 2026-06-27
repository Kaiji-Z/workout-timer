import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/workout_repository.dart';
import '../services/stats_calculator_service.dart';
import '../services/stats_aggregator_service.dart';
import '../providers/record_provider.dart';
import '../widgets/volume_trend_charts.dart';
import '../animations/animation_primitives.dart';
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
  final StatsAggregatorService _aggregator = StatsAggregatorService();
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.navStats,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
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

  /// 训练频率概览 — 降级为紧凑的次要指标行
  ///
  /// 重构后不再是等权重的卡片网格（DESIGN.md 反例：SaaS 仪表盘）。
  /// 次要指标用统一的 15% tint + 紧凑布局，把视觉中心让给英雄数字。
  Widget _buildFrequencyOverview(
    Map<String, dynamic> stats,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            l10n.statsSessionCount,
            '',
            l10n.statsSessionCountUnit,
            Icons.fitness_center,
            theme.accentColor,
            theme,
            numValue: (stats['sessionCount'] as num).toDouble(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            l10n.statsWorkoutDays,
            '',
            l10n.statsDaysUnit,
            Icons.calendar_today,
            theme.accentColor,
            theme,
            numValue: (stats['workoutDays'] as num).toDouble(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            l10n.statsAvgPerWeek,
            '',
            l10n.statsSessionCountUnit,
            Icons.trending_up,
            theme.accentColor,
            theme,
            numValue: stats['avgSessionsPerWeek'] as double,
            decimalPlaces: 1,
          ),
        ),
      ],
    );
  }

  /// 英雄数字 — 周期总训练量 (kg)。
  ///
  /// 这是整屏唯一的视觉中心（DESIGN.md「扫一眼就懂」+ PRODUCT.md「单核」）。
  /// 36px 深靛蓝大号数字 + vs 上期变化作为唯一伴随元素。次要指标降级到
  /// _buildFrequencyOverview / _buildVolumeOverview 的紧凑行。
  Widget _buildHeroVolume(
    List<WorkoutRecord> workoutRecords,
    AppThemeData theme, {
    double? volumeChange,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final totalVolume = _statsCalc.calculateTotalVolume(
      workoutRecords,
      bodyWeight: _userBodyWeight,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        // The hero is the ONE element that breaks the tint convention: a solid
        // indigo fill (the disciplined "冷静" half of the duality) makes total
        // volume the screen's unambiguous focal point, distinct from the five
        // 15%-tint subordinate boxes beneath it. White number on deep indigo
        // clears WCAG (DESIGN.md §1 Duality).
        color: theme.accentColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.whatshot_rounded,
                size: 18,
                color: theme.onAccentColor.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.statsTotalVolume,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: theme.onAccentColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Hero number — the screen's single dominant typographic moment.
          CountUp(
            target: totalVolume,
            decimalPlaces: totalVolume >= 1000 ? 0 : 1,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: theme.onAccentColor,
                  height: 1.05,
                  letterSpacing: -1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
            suffix: ' kg',
          ),
          const SizedBox(height: 8),
          if (volumeChange != null)
            _buildVolumeChangeBadge(volumeChange, theme)
          else
            Text(
              l10n.statsNoPrevComparison,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    color: theme.onAccentColor.withValues(alpha: 0.7),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
        ],
      ),
    );
  }

  /// vs 上期 变化徽章 — 英雄数字的唯一伴随元素。
  /// 在深靛蓝 hero 上用半透明白底徽章，保持高对比可读。
  Widget _buildVolumeChangeBadge(double volumeChange, AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isUp = volumeChange >= 0;
    final changeRounded = volumeChange.round();
    // On the indigo hero, encode direction by icon + sign, not by green/red
    // (which would fight the deep-blue ground). A translucent white chip reads
    // cleanly and stays on-brand.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.onAccentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: theme.onAccentColor,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.statsVolumeChangeVsPrev(isUp ? '+' : '', changeRounded),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: 12,
                  color: theme.onAccentColor,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
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
  ///
  /// 英雄数字（总训练量 kg）已移到 _buildHeroVolume。这里只保留辅助量。
  Widget _buildVolumeOverview(
    Map<String, dynamic> stats,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.statsTotalSets,
                '',
                l10n.statsSetsUnit,
                Icons.repeat,
                theme.accentColor,
                theme,
                numValue: (stats['totalSets'] as num).toDouble(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.statsTotalDuration,
                formatDuration(stats['totalDuration'] as int),
                '',
                Icons.timer,
                theme.accentColor,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // The 15% Tint Rule — was 0.1, now system-standard 0.15.
            color: theme.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubMetric(
                l10n.statsAvgSetsPerSession,
                l10n.statsSetsCount(
                    (stats['avgSetsPerSession'] as double).round()),
                theme,
              ),
              Container(
                width: 1,
                height: 30,
                color: theme.textColor.withValues(alpha: 0.1),
              ),
              _buildSubMetric(
                l10n.statsAvgDurationPerSession,
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
    AppThemeData theme, {
    double? numValue,
    int decimalPlaces = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        // The 15% Tint Rule — was 0.1. Tint is always the accent (disciplined
        // indigo) so secondary metrics stay calm and cede focus to the hero.
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          if (numValue != null)
            CountUp(
              target: numValue,
              decimalPlaces: decimalPlaces,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            )
          else
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
          ).textTheme.titleLarge!.copyWith(
                color: theme.accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
    final l10n = AppLocalizations.of(context)!;
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
          _CollapsibleSection(
            title: l10n.statsOverview,
            theme: theme,
            children: [
              // Hero — the screen's single visual center (DESIGN.md「扫一眼就懂」).
              _buildHeroVolume(
                workoutRecords,
                theme,
                volumeChange: volumeChange,
              ),
              const SizedBox(height: 16),
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(volumeStats, theme),
              const SizedBox(height: 12),
              _buildDensityMetric(workoutRecords, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 每日训练时长图表
          _buildSection(l10n.statsDailyDurationTitle, theme, [
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
          _buildSection(l10n.statsVolumeTrendTitle, theme, [
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
            title: l10n.statsProgressTracking,
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
            title: l10n.statsBodyAnalysis,
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

    final l10n = AppLocalizations.of(context)!;
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
          _CollapsibleSection(
            title: l10n.statsOverviewMonth(_selectedMonth),
            theme: theme,
            children: [
              _buildHeroVolume(
                workoutRecords,
                theme,
                volumeChange: volumeChange,
              ),
              const SizedBox(height: 16),
              _buildFrequencyOverview(frequencyStats, theme),
              const SizedBox(height: 16),
              _buildVolumeOverview(volumeStats, theme),
              const SizedBox(height: 12),
              _buildDensityMetric(workoutRecords, theme),
            ],
          ),
          const SizedBox(height: 20),

          // 训练量趋势（月）
          _buildSection(l10n.statsVolumeTrendTitle, theme, [
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
            title: l10n.statsProgressTracking,
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
            title: l10n.statsBodyAnalysis,
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

  /// Locale-aware weekday short name (0=Mon..6=Sun for the 7-day grid).
  String _weekdayShort(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.statsWeekdayMon;
      case 1:
        return l10n.statsWeekdayTue;
      case 2:
        return l10n.statsWeekdayWed;
      case 3:
        return l10n.statsWeekdayThu;
      case 4:
        return l10n.statsWeekdayFri;
      case 5:
        return l10n.statsWeekdaySat;
      case 6:
        return l10n.statsWeekdaySun;
      default:
        return '';
    }
  }

  /// 周选择器
  Widget _buildWeekSelector(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.statsWeekRange(weekStart.month, weekStart.day,
                        weekDays.last.month, weekDays.last.day),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge!.copyWith(color: theme.textColor),
                  ),
                  Text(
                    l10n.statsYearLabel(weekStart.year),
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
                          l10n.statsToday,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
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
                      _weekdayShort(index, l10n),
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.statsToday,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
    final l10n = AppLocalizations.of(context)!;
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
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
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
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
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
    final l10n = AppLocalizations.of(context)!;
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
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: theme.textColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statsEmptyHint,
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
    final l10n = AppLocalizations.of(context)!;
    final maxDuration = durations.values.fold(0, (max, e) => e > max ? e : max);
    final displayDays = days ?? (isWeekView ? 7 : 31);

    if (maxDuration == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            l10n.statsNoData,
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
                // Data series use the Okabe-Ito palette (ChartPalette), not the
                // brand warm gradient — see DESIGN.md §2 / The Okabe-Ito rule.
                color: ChartPalette.byIndex(0),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.statsDurationPerSetsLegend,
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
                                  // Single quantitative series: solid Okabe-Ito
                                  // color, not a brand-warm gradient. Avoids the
                                  // "gradient bar = looks premium" reflex and
                                  // keeps data viz colorblind-safe (DESIGN.md §2).
                                  color: duration > 0
                                      ? ChartPalette.byIndex(0)
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
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                          ),
                                          if (setCount > 0)
                                            Text(
                                              l10n.statsSetsCount(setCount),
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
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
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
                          ? _weekdayShort(index, l10n)
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
  Map<String, int> _calculateCommonExercises(List<dynamic> records) =>
      _aggregator.calculateCommonExercises(records);

  // ==================== 新增统计组件 ====================

  /// 常用动作图表（水平条形图）
  Widget _buildCommonExercisesChart(
    Map<String, int> exercises,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            l10n.statsNoExerciseData,
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
                          // Ranked data series — solid Okabe-Ito fill, not the
                          // brand-indigo gradient. Colorblind-safe (DESIGN.md §2).
                          // Uses bluish-green (index 2), distinct from the
                          // daily-duration bars' orange (index 0) so the two
                          // unrelated series don't share a hue.
                          color: ChartPalette.byIndex(2),
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
                  l10n.statsExerciseCount(entry.value),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ChartPalette.byIndex(2),
                    fontFeatures: const [FontFeature.tabularFigures()],
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
    final l10n = AppLocalizations.of(context)!;
    final distribution = _statsCalc.calculateMuscleVolumeDistribution(
      records,
      bodyWeight: _userBodyWeight,
    );

    if (distribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            l10n.statsNoData,
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
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          l10n.statsTotalCapacity,
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
                  l10n.statsOtherPercent((otherPercentage * 100).toStringAsFixed(1)),
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
  String _formatVolume(double volume) =>
      StatsAggregatorService.formatVolume(volume);

  /// 主肌群恢复天数（简化版：只显示6个主肌群）
  Widget _buildPrimaryRecoveryList(
    List<WorkoutRecord> records,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.statsNoRecoveryData,
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
          l10n.statsRecoveryStatus,
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
                // The 15% Tint Rule — was 0.1.
                color: chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(color: chipColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: chipColor),
                  const SizedBox(width: 6),
                  Text(
                    l10n.statsRecoveryDays(muscle.displayName, days),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
    final l10n = AppLocalizations.of(context)!;
    if (records.isEmpty) return const SizedBox.shrink();

    final density = _statsCalc.calculateDensity(records);
    final totalSets = records.fold<int>(0, (sum, r) => sum + r.totalSets);
    final totalMinutes =
        records.fold<int>(0, (sum, r) => sum + r.durationSeconds) / 60.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // The 15% Tint Rule — was 0.08 fill / 0.2 border. Border at 0.3 keeps it
        // consistent with StatusBadge styling (DESIGN.md §5).
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
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
                  l10n.statsDensity,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  l10n.statsSetsPerMinute(density.toStringAsFixed(1)),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Text(
            l10n.statsSetsOverMinutes(
                totalSets, totalMinutes.toStringAsFixed(0)),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11,
              color: theme.secondaryTextColor,
              fontFeatures: const [FontFeature.tabularFigures()],
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
    final l10n = AppLocalizations.of(context)!;
    final trend = _statsCalc.calculateEstimated1RMTrend(records);

    if (trend.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            l10n.statsNo1rmData,
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
              l10n.statsEstimated1rmTrend,
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
                    l10n.statsRecordsCount(points.length),
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
                    '${weeks > 0 ? l10n.anPrompt1rmWeeksSuffix(weeks.toStringAsFixed(0)) : ''}',
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
    final l10n = AppLocalizations.of(context)!;
    final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(records);

    if (setsPerMuscle.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Text(
            l10n.statsNoMuscleSetsData,
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
              l10n.statsSetsPerMuscleTitle,
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
          l10n.statsMevReference,
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
                                // Solid fill, not a gradient — categorical data
                                // (the hue already encodes the muscle group).
                                color: color,
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
                    l10n.statsSetsCount(sets),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAboveMEV ? color : theme.secondaryTextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
