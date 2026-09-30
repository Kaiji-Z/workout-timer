import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
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
import '../widgets/stats_today_card.dart';
import '../widgets/stats_dose_section.dart';
import '../widgets/stats_progress_section.dart';
import '../widgets/stats_habit_section.dart';
import 'ai_analysis_screen.dart';
import '../services/user_preferences_service.dart';
import '../animations/page_transitions.dart';
import '../theme/build_context_text_styles.dart';

/// 统计页 — 问题驱动四区结构（.goal/SPEC.md §3.1）。
///
/// 身体的问题用滚动窗口（锚定今天）：①今日状态卡 ②剂量 ③进步；
/// 生活的问题用日历：④习惯。周/月日历桶视图与双 Tab 已移除，
/// 历史浏览由 History 页承担。
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  final StatsCalculatorService _statsCalc = StatsCalculatorService();
  final StatsAggregatorService _aggregator = StatsAggregatorService();
  List<WorkoutSession> _oldSessions = [];
  List<WorkoutRecord> _newRecords = [];
  bool _isLoading = true;
  List<dynamic>? _cachedAllRecords;
  double _userBodyWeight = 0.0;
  int _weeklyTarget = 4; // UserPreferences.frequency，_loadData 覆盖

  @override
  void initState() {
    super.initState();
    // 延迟到 build 完成后再加载数据，避免 setState during build 异常
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      _cachedAllRecords = null;
      final recordProvider = context.read<RecordProvider>();
      // 每次进入统计页都从仓库重载：内存列表可能与 DB 脱节（如启动加载
      // 失败后恢复），只信内存会让新记录要先进一次历史页才可见。
      await recordProvider.loadRecords();
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;

      // Load user body weight + weekly frequency for habit target
      double bodyWeight = 0.0;
      int weeklyTarget = 4;
      try {
        final prefsService = UserPreferencesService();
        final prefs = await prefsService.loadPreferences();
        bodyWeight = prefs.bodyWeight;
        if (prefs.frequency > 0) weeklyTarget = prefs.frequency;
      } catch (e) {
        debugPrint('Error loading preferences for stats: $e');
      }

      setState(() {
        _oldSessions = sessions;
        _newRecords = recordProvider.records;
        _isLoading = false;
        _userBodyWeight = bodyWeight;
        _weeklyTarget = weeklyTarget;
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = context.l10n;

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
            onPressed: () => _openAiReview(30),
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              color: theme.primaryColor,
              onRefresh: () async => _loadData(),
              child: _buildBody(theme),
            ),
    );
  }

  Widget _buildBody(AppThemeData theme) {
    final all = _getAllRecords();
    if (all.isEmpty) {
      // RefreshIndicator 需要可滚动子树；空态包一层 ListView
      return ListView(
        children: [
          SizedBox(
            height: 480,
            child: Center(child: _buildGlobalEmptyState(theme)),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final asOf = DateTime(now.year, now.month, now.day);

    // ① 今日状态（滚动窗口，锚定今天）
    final loadRatio = _statsCalc.acuteChronicRatio(
      _newRecords,
      asOf: asOf,
      bodyWeight: _userBodyWeight,
    );
    final recency = _statsCalc.daysSinceLastTrained(_newRecords, today: asOf);

    // ② 剂量（滚动7天）
    final rolling7 = _statsCalc.filterRollingWindow(
      _newRecords,
      asOf: asOf,
      windowDays: 7,
    );
    final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(rolling7);
    final doseStatus = _statsCalc.doseStatusPerMuscle(_newRecords, asOf: asOf);
    final volume7d = _statsCalc.calculateTotalVolume(
      rolling7,
      bodyWeight: _userBodyWeight,
    );

    // ③ 进步（时间轴，无时间桶）
    final e1rmTrends = _statsCalc.calculateEstimated1RMTrend(_newRecords);
    final weeklyTrend = _statsCalc.weeklyRollingVolumeTrend(
      _newRecords,
      asOf: asOf,
      weeks: 6,
      bodyWeight: _userBodyWeight,
    );

    // ④ 习惯（日历语义）
    final dailyVolume = _statsCalc.calculateDailyVolumeTrend(
      _newRecords,
      bodyWeight: _userBodyWeight,
    );
    final trainingDates = [
      for (final record in all) _aggregator.getRecordDate(record),
    ];
    // 练过但没有容量数据的日期（旧版简单会话）也标记为已训练
    final habitVolume = Map<DateTime, double>.of(dailyVolume);
    for (final date in trainingDates) {
      habitVolume.putIfAbsent(
        DateTime(date.year, date.month, date.day),
        () => 0.0,
      );
    }
    final streakWeeks = _statsCalc.consecutiveQualifyingWeeks(
      trainingDates,
      today: asOf,
      weeklyTarget: _weeklyTarget,
    );
    final sessionsThisWeek = _statsCalc.sessionsThisWeek(
      trainingDates,
      today: asOf,
    );

    // 密度小指标（收编进习惯区下方，滚动28天口径）
    final rolling28 = _statsCalc.filterRollingWindow(
      _newRecords,
      asOf: asOf,
      windowDays: 28,
    );

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: AppDimensions.bottomPadding(context),
      ),
      children: [
        StatsTodayCard(
          loadRatio: loadRatio,
          recency: recency,
          theme: theme,
        ),
        const SizedBox(height: 20),
        StatsDoseSection(
          setsPerMuscle: setsPerMuscle,
          doseStatus: doseStatus,
          volume7d: volume7d,
          theme: theme,
        ),
        const SizedBox(height: 20),
        StatsProgressSection(
          e1rmTrends: e1rmTrends,
          weeklyTrend: weeklyTrend,
          today: asOf,
          theme: theme,
        ),
        const SizedBox(height: 20),
        StatsHabitSection(
          dailyVolume: habitVolume,
          streakWeeks: streakWeeks,
          sessionsThisWeek: sessionsThisWeek,
          weeklyTarget: _weeklyTarget,
          today: asOf,
          theme: theme,
        ),
        const SizedBox(height: 12),
        buildDensityMetric(context, rolling28, theme),
        const SizedBox(height: 20),
        _buildAiReviewEntry(theme),
      ],
    );
  }

  // ==================== AI 复盘入口（滚动范围） ====================

  Widget _buildAiReviewEntry(AppThemeData theme) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 16, color: theme.accentColor),
              const SizedBox(width: 6),
              Text(
                l10n.statsAiAnalysis,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.statsAiReviewSubtitle,
            style: context.bodySmall.copyWith(
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _rangeChip(theme, l10n.anRangeDays(7), () => _openAiReview(7)),
              _rangeChip(theme, l10n.anRangeDays(30), () => _openAiReview(30)),
              _rangeChip(theme, l10n.anRangeDays(90), () => _openAiReview(90)),
              _rangeChip(theme, l10n.anRangeCustom, _openAiReviewCustom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(AppThemeData theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // The 15% Tint Rule
          color: theme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: context.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
      ),
    );
  }

  /// 打开滚动复盘：窗口 [今天-(N-1), 今天]，对照窗口为紧邻的前 N 天。
  void _openAiReview(int rangeDays) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    _pushAiReview(start: end.subtract(Duration(days: rangeDays - 1)), end: end);
  }

  /// 自定义复盘：依次选起止日期（滚动语义，不允许选到未来）。
  Future<void> _openAiReviewCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = await showDatePicker(
      context: context,
      initialDate: today.subtract(const Duration(days: 29)),
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (start == null || !mounted) return;

    final end = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: start,
      lastDate: today,
    );
    if (end == null || !mounted) return;

    _pushAiReview(start: start, end: DateTime(end.year, end.month, end.day));
  }

  void _pushAiReview({required DateTime start, required DateTime end}) {
    final rangeDays = end.difference(start).inDays + 1;
    final records = _statsCalc.filterRollingWindow(
      _newRecords,
      asOf: end,
      windowDays: rangeDays,
    );
    final prevEnd = start.subtract(const Duration(days: 1));
    final previousRecords = _statsCalc.filterRollingWindow(
      _newRecords,
      asOf: prevEnd,
      windowDays: rangeDays,
    );

    Navigator.push(
      context,
      FadeUpPageRoute(
        page: AIAnalysisScreen(
          startDate: start,
          endDate: end,
          records: records,
          previousRecords: previousRecords,
          allRecords: _newRecords,
        ),
      ),
    );
  }

  /// Global empty state when there are no records at all
  Widget _buildGlobalEmptyState(AppThemeData theme) {
    final l10n = context.l10n;
    return Column(
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
    );
  }
}
