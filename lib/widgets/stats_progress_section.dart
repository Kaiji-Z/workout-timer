import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../services/stats_calculator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 进步区 — 问题驱动统计页第三区。
///
/// 回答"进步了没"：
/// - 动作级估算 1RM 走势（时间轴，无时间桶）——默认选会话数最多的动作，
///   可切换 全部/近90天 范围；
/// - 近 6 周每周滚动总量柱状图 + 斜率标注（递进/回落/平稳）；
/// - 最近 PR 一行（全部动作里日期最新的最佳组）。
class StatsProgressSection extends StatefulWidget {
  /// 动作名 → 按日期排序的估算1RM点（来自 calculateEstimated1RMTrend）
  final Map<String, List<Estimated1RMPoint>> e1rmTrends;

  /// 近6周每周滚动容量（来自 weeklyRollingVolumeTrend）
  final List<RollingVolumePoint> weeklyTrend;

  /// "近90天"过滤的基准日（组件内不取当前时间）
  final DateTime today;

  final AppThemeData theme;

  const StatsProgressSection({
    super.key,
    required this.e1rmTrends,
    required this.weeklyTrend,
    required this.today,
    required this.theme,
  });

  @override
  State<StatsProgressSection> createState() => _StatsProgressSectionState();
}

class _StatsProgressSectionState extends State<StatsProgressSection> {
  String? _selectedExercise;
  bool _last90Days = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = widget.theme;
    final trends = widget.e1rmTrends;

    // 默认选中会话数最多的动作
    final selected = _selectedExercise ??
        (trends.isEmpty
            ? null
            : (trends.entries.toList()
                  ..sort(
                    (a, b) => b.value.length.compareTo(a.value.length),
                  ))
                .first
                .key);

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
              Icon(Icons.trending_up, size: 16, color: theme.accentColor),
              const SizedBox(width: 6),
              Text(
                l10n.statsProgressTracking,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (trends.isEmpty)
            Text(
              l10n.statsProgressEmpty,
              style: context.bodyMedium.copyWith(
                color: theme.secondaryTextColor,
              ),
            )
          else ...[
            _buildExerciseChips(context, trends.keys.toList()),
            const SizedBox(height: 12),
            if (selected != null)
              _buildSelectedSummary(context, selected, trends[selected]!),
            if (_latestPr(trends) != null) ...[
              const SizedBox(height: 12),
              _buildPrRow(context, _latestPr(trends)!),
            ],
          ],
          const SizedBox(height: 16),
          _buildWeeklyTrend(context),
        ],
      ),
    );
  }

  // ==================== 动作选择 ====================

  Widget _buildExerciseChips(BuildContext context, List<String> names) {
    final theme = widget.theme;
    final sorted = names.toList()
      ..sort(
        (a, b) => (widget.e1rmTrends[b]?.length ?? 0)
            .compareTo(widget.e1rmTrends[a]?.length ?? 0),
      );
    // 会话数优先，最多展示 8 个（横向滚动），避免长名单占满卡片
    final shown = sorted.take(8).toList();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = shown[index];
          final isSelected =
              name == (_selectedExercise ?? _defaultExercise());
          return ChoiceChip(
            label: Text(
              name,
              style: context.bodySmall.copyWith(
                fontSize: 11,
                color: isSelected ? theme.onAccentColor : theme.textColor,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedExercise = name),
            backgroundColor: theme.textColor.withValues(alpha: 0.06),
            selectedColor: theme.accentColor,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }

  String? _defaultExercise() {
    final trends = widget.e1rmTrends;
    if (trends.isEmpty) return null;
    final entries = trends.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return entries.first.key;
  }

  // ==================== 选中动作摘要 + 范围切换 ====================

  Widget _buildSelectedSummary(
    BuildContext context,
    String name,
    List<Estimated1RMPoint> points,
  ) {
    final l10n = context.l10n;
    final theme = widget.theme;

    final filtered = _last90Days
        ? points
              .where(
                (p) => !p.date
                    .isBefore(widget.today.subtract(const Duration(days: 90))),
              )
              .toList()
        : points;

    final String summary;
    if (filtered.isEmpty) {
      summary = l10n.statsNo1rmData;
    } else if (filtered.length == 1) {
      summary = '${filtered.first.estimated1RM.toStringAsFixed(1)} kg';
    } else {
      summary =
          '${filtered.first.estimated1RM.toStringAsFixed(1)} → '
          '${filtered.last.estimated1RM.toStringAsFixed(1)} kg';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: context.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _rangeChip(context, l10n.statsProgressAll, !_last90Days, () {
              setState(() => _last90Days = false);
            }),
            const SizedBox(width: 6),
            _rangeChip(context, l10n.statsProgress90d, _last90Days, () {
              setState(() => _last90Days = true);
            }),
          ],
        ),
        Text(
          'Mayhew',
          style: context.bodySmall.copyWith(
            fontSize: 10,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _rangeChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          // The 15% Tint Rule — selected 用实底 accent，未选中用 15% tint
          color: selected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        ),
        child: Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? theme.onAccentColor : theme.accentColor,
          ),
        ),
      ),
    );
  }

  // ==================== 最近 PR ====================

  MapEntry<String, Estimated1RMPoint>? _latestPr(
    Map<String, List<Estimated1RMPoint>> trends,
  ) {
    MapEntry<String, Estimated1RMPoint>? latest;
    for (final entry in trends.entries) {
      for (final point in entry.value) {
        if (latest == null || point.date.isAfter(latest.value.date)) {
          latest = MapEntry(entry.key, point);
        }
      }
    }
    return latest;
  }

  Widget _buildPrRow(
    BuildContext context,
    MapEntry<String, Estimated1RMPoint> pr,
  ) {
    final l10n = context.l10n;
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 14, color: theme.accentColor),
          const SizedBox(width: 6),
          Text(
            l10n.statsLatestPr,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.statsPrLine(
                pr.key,
                pr.value.weight.toStringAsFixed(1),
                pr.value.reps ?? 0,
              ),
              style: context.bodySmall.copyWith(
                color: theme.textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 近6周滚动容量 ====================

  Widget _buildWeeklyTrend(BuildContext context) {
    final l10n = context.l10n;
    final theme = widget.theme;
    final trend = widget.weeklyTrend;
    final volumes = trend.map((p) => p.volume).toList();
    final maxVolume = volumes.isEmpty
        ? 0.0
        : volumes.reduce((a, b) => a > b ? a : b);

    final slope = StatsCalculatorService().linearSlope(volumes);
    final mean = volumes.isEmpty
        ? 0.0
        : volumes.reduce((a, b) => a + b) / volumes.length;
    final epsilon = mean * 0.05;
    final String? slopeLabel;
    final slopeColor = theme.secondaryTextColor;
    if (slope == null || mean == 0) {
      slopeLabel = null;
    } else if (slope > epsilon) {
      slopeLabel = l10n.statsTrendRising;
    } else if (slope < -epsilon) {
      slopeLabel = l10n.statsTrendFalling;
    } else {
      slopeLabel = l10n.statsTrendFlat;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.statsProgressTrendTitle,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
            ),
            if (slopeLabel != null)
              Text(
                slopeLabel,
                style: context.bodySmall.copyWith(
                  fontSize: 10,
                  color: slopeColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final point in trend)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: maxVolume > 0
                            ? (point.volume / maxVolume).clamp(0.02, 1.0)
                            : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0072B2).withValues(
                              alpha: 0.75,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trend.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _shortDate(trend.first.windowEnd),
                style: context.bodySmall.copyWith(
                  fontSize: 9,
                  color: theme.secondaryTextColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _shortDate(trend.last.windowEnd),
                style: context.bodySmall.copyWith(
                  fontSize: 9,
                  color: theme.secondaryTextColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _shortDate(DateTime d) => '${d.month}/${d.day}';
}
