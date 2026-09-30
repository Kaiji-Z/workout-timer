import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../models/muscle_group.dart';
import '../services/stats_calculator_service.dart';
import '../services/stats_aggregator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 剂量区 — 问题驱动统计页第二区。
///
/// 回答"练够了没、均不均衡"：滚动 7 天每肌群组数（水平条 + MEV/MRV
/// 双参考线）。条的颜色编码剂量状态（不足/带内/过量），肌群名走文字
/// 标签——颜色留给状态，不留给类别（区别于旧版按肌群着色的图）。
///
/// 数据经参数传入（上层用 [StatsCalculatorService.filterRollingWindow]
/// + doseStatusPerMuscle 预计算），组件无状态。
class StatsDoseSection extends StatelessWidget {
  /// 滚动7天每肌群组数；缺键 = 0 组
  final Map<PrimaryMuscleGroup, int> setsPerMuscle;

  /// 滚动7天每肌群剂量状态（六个肌群齐全）
  final Map<PrimaryMuscleGroup, DoseStatus> doseStatus;

  /// 滚动7天总容量（kg，摘要行展示）
  final double volume7d;

  final AppThemeData theme;

  const StatsDoseSection({
    super.key,
    required this.setsPerMuscle,
    required this.doseStatus,
    required this.volume7d,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalSets = PrimaryMuscleGroup.values
        .map((m) => setsPerMuscle[m] ?? 0)
        .fold<int>(0, (a, b) => a + b);

    // 最久没练的（组数最少）在前——和今日卡 chips 同一排序语义
    final muscles = PrimaryMuscleGroup.values.toList()
      ..sort(
        (a, b) =>
            (setsPerMuscle[b] ?? 0).compareTo(setsPerMuscle[a] ?? 0),
      );

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
              Icon(Icons.speed, size: 16, color: theme.accentColor),
              const SizedBox(width: 6),
              Text(
                l10n.statsDoseTitle,
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
          // 摘要行：7天容量 + 7天总组数
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  context,
                  l10n.statsDoseVolumeLabel,
                  StatsAggregatorService.formatVolume(volume7d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryMetric(
                  context,
                  l10n.statsTotalSets,
                  l10n.statsSetsCount(totalSets),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final muscle in muscles)
            _buildBarRow(context, muscle),
          const SizedBox(height: 4),
          // 参考线图例 + 免责声明
          Row(
            children: [
              _legendTick(context, theme.secondaryTextColor.withValues(alpha: 0.6),
                  l10n.statsDoseMevLine(StatsCalculatorService.weeklyMevSets)),
              const SizedBox(width: 12),
              _legendTick(context, theme.errorColor.withValues(alpha: 0.7),
                  l10n.statsDoseMrvLine(StatsCalculatorService.weeklyMrvSets)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statsDoseDisclaimer,
            style: context.bodySmall.copyWith(
              fontSize: 10,
              color: theme.secondaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        // The 15% Tint Rule
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: context.bodySmall.copyWith(
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _legendTick(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.bodySmall.copyWith(
            fontSize: 10,
            color: theme.secondaryTextColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildBarRow(BuildContext context, PrimaryMuscleGroup muscle) {
    final l10n = context.l10n;
    final sets = setsPerMuscle[muscle] ?? 0;
    final status = doseStatus[muscle] ?? DoseStatus.belowMev;

    // Okabe-Ito：带内=蓝，过量=朱红，不足=中性灰（数据色，色盲安全）
    final barColor = switch (status) {
      DoseStatus.noData => theme.textColor.withValues(alpha: 0.2),
      DoseStatus.belowMev => theme.textColor.withValues(alpha: 0.35),
      DoseStatus.inRange => const Color(0xFF0072B2), // Okabe-Ito blue
      DoseStatus.aboveMrv => const Color(0xFFD55E00), // Okabe-Ito vermilion
    };
    final statusLabel = switch (status) {
      DoseStatus.noData => '',
      DoseStatus.belowMev => l10n.statsDoseBelow,
      DoseStatus.inRange => l10n.statsDoseIn,
      DoseStatus.aboveMrv => l10n.statsDoseAbove,
    };

    const mev = StatsCalculatorService.weeklyMevSets;
    const mrv = StatsCalculatorService.weeklyMrvSets;
    final referenceMax =
        (sets > mrv ? sets.toDouble() : mrv.toDouble()) * 1.15;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              localizedMuscleGroup(context, muscle),
              style: context.bodySmall.copyWith(
                fontSize: 11,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final mevX = (mev / referenceMax) * barWidth;
                final mrvX = (mrv / referenceMax) * barWidth;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景槽
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: theme.textColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                    ),
                    // MEV 参考线
                    Positioned(
                      left: mevX - 1,
                      top: -2,
                      child: Container(
                        width: 2,
                        height: 18,
                        color: theme.secondaryTextColor.withValues(alpha: 0.6),
                      ),
                    ),
                    // MRV 参考线
                    Positioned(
                      left: mrvX - 1,
                      top: -2,
                      child: Container(
                        width: 2,
                        height: 18,
                        color: theme.errorColor.withValues(alpha: 0.7),
                      ),
                    ),
                    // 实际组数条
                    FractionallySizedBox(
                      widthFactor:
                          (sets / referenceMax).clamp(0.015, 1.0),
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: barColor,
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
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.statsSetsCount(sets),
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sets > 0 ? theme.textColor : theme.secondaryTextColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (statusLabel.isNotEmpty)
                  Text(
                    statusLabel,
                    style: context.bodySmall.copyWith(
                      fontSize: 9,
                      color: status == DoseStatus.aboveMrv
                          ? theme.errorColor
                          : theme.secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
