import 'package:flutter/material.dart';

import '../animations/animation_primitives.dart';

import '../l10n/app_localizations.dart';
import '../models/workout_record.dart';
import '../services/stats_calculator_service.dart';
import '../services/stats_aggregator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';

/// 统计页「概览指标区」构建器（自 stats_screen.dart 拆出，纯函数无状态）。
///
/// 数据经参数传入，文案经 [BuildContext] 取 l10n，颜色一律走
/// [AppThemeData]（深浅色自适应）。拆分动机见 AGENTS.md 大文件治理。

final StatsCalculatorService _statsCalc = StatsCalculatorService();

Widget buildStatsSection(
  BuildContext context,
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
Widget buildFrequencyOverview(
  BuildContext context,
  Map<String, dynamic> stats,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  return Row(
    children: [
      Expanded(
        child: _buildMetricCard(
          context,
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
          context,
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
          context,
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
Widget buildHeroVolume(
  BuildContext context,
  List<WorkoutRecord> workoutRecords,
  AppThemeData theme, {
  double? volumeChange,
  required double userBodyWeight,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final totalVolume = _statsCalc.calculateTotalVolume(
    workoutRecords,
    bodyWeight: userBodyWeight,
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
          _buildVolumeChangeBadge(context, volumeChange, theme)
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
Widget _buildVolumeChangeBadge(
  BuildContext context,
  double volumeChange,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
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

///
/// 英雄数字（总训练量 kg）已移到 _buildHeroVolume。这里只保留辅助量。
Widget buildVolumeOverview(
  BuildContext context,
  Map<String, dynamic> stats,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
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
              context,
              l10n.statsTotalDuration,
              StatsAggregatorService.formatDuration(
                stats['totalDuration'] as int,
              ),
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
              context,
              l10n.statsAvgSetsPerSession,
              l10n.statsSetsCount(
                (stats['avgSetsPerSession'] as double).round(),
              ),
              theme,
            ),
            Container(
              width: 1,
              height: 30,
              color: theme.textColor.withValues(alpha: 0.1),
            ),
            _buildSubMetric(
              context,
              l10n.statsAvgDurationPerSession,
              StatsAggregatorService.formatDuration(
                stats['avgDurationPerSession'] as int,
              ),
              theme,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildMetricCard(
  BuildContext context,
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

Widget _buildSubMetric(
  BuildContext context,
  String label,
  String value,
  AppThemeData theme,
) {
  return Column(
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
