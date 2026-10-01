import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../models/muscle_group.dart';
import '../services/stats_calculator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 今日状态卡 — 问题驱动统计页的第一区（页面之锚）。
///
/// 回答"今天状态行不行、该练什么"：
/// - 急慢性负荷比（ACWR 简化版）：一个数字 + 分区标签，仅作护栏参考；
/// - 六个主肌群的恢复时点 chips，按"最久没练"在前排序。
///
/// 数据全部经构造参数传入（负荷比由上层 [StatsCalculatorService.
/// acuteChronicRatio] 预计算），组件本身无状态、无 DateTime.now()。
class StatsTodayCard extends StatelessWidget {
  /// 急慢性负荷比；null = 基线不足（无急性期之外的历史）
  final double? loadRatio;

  /// 每主肌群距上次训练天数；未出现的肌群视为无数据
  final Map<PrimaryMuscleGroup, int> recency;

  final AppThemeData theme;

  const StatsTodayCard({
    super.key,
    required this.loadRatio,
    required this.recency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ratio = loadRatio;
    final band = StatsCalculatorService().loadRatioBand(ratio);

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
              Icon(Icons.wb_sunny_outlined, size: 16, color: theme.accentColor),
              const SizedBox(width: 6),
              Text(
                l10n.statsTodayTitle,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRatioBlock(context, l10n, ratio, band),
          const SizedBox(height: 16),
          _buildChips(context, l10n),
        ],
      ),
    );
  }

  Widget _buildRatioBlock(
    BuildContext context,
    AppLocalizations l10n,
    double? ratio,
    LoadRatioBand band,
  ) {
    final bandColor = switch (band) {
      LoadRatioBand.noData => theme.secondaryTextColor,
      LoadRatioBand.low => theme.accentColor,
      LoadRatioBand.normal => theme.successColor,
      LoadRatioBand.high => theme.errorColor,
    };
    final bandLabel = switch (band) {
      LoadRatioBand.noData => l10n.statsLoadRatioNoData,
      LoadRatioBand.low => l10n.statsLoadRatioLow,
      LoadRatioBand.normal => l10n.statsLoadRatioNormal,
      LoadRatioBand.high => l10n.statsLoadRatioHigh,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.statsLoadRatioLabel,
                    style: context.bodySmall.copyWith(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 首次见到的用户需要一条行内解释，不止免责声明
                  Tooltip(
                    message: l10n.tooltipAcwr,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                ratio == null ? '--' : ratio.toStringAsFixed(2),
                style: context.displaySmall.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: bandColor,
                  height: 1.1,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bandLabel,
                style: context.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: bandColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.statsLoadRatioHint,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.statsLoadRatioDisclaimer,
                style: context.bodySmall.copyWith(
                  fontSize: 10,
                  color: theme.secondaryTextColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChips(BuildContext context, AppLocalizations l10n) {
    // 最久没练的排最前——"该练什么"的答案就在第一个 chip
    final entries = PrimaryMuscleGroup.values.map((muscle) {
      final days = recency[muscle];
      return MapEntry(muscle, days);
    }).toList()
      ..sort((a, b) {
        final aDays = a.value;
        final bDays = b.value;
        if (aDays == null && bDays == null) return 0;
        if (aDays == null) return 1; // 无数据沉底
        if (bDays == null) return -1;
        return bDays.compareTo(aDays);
      });

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in entries)
          _buildChip(context, l10n, entry.key, entry.value),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    AppLocalizations l10n,
    PrimaryMuscleGroup muscle,
    int? days,
  ) {
    final level = StatsCalculatorService().recoveryLevel(days);
    final color = switch (level) {
      RecoveryLevel.noData => theme.secondaryTextColor.withValues(alpha: 0.6),
      RecoveryLevel.recovering => theme.accentColor,
      RecoveryLevel.recovered => theme.successColor,
      RecoveryLevel.stale => theme.secondaryTextColor,
    };
    final when = days == null
        ? l10n.statsChipNever
        : days == 0
            ? l10n.statsChipToday
            : l10n.statsChipDaysAgo(days);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // The 15% Tint Rule
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        l10n.statsMuscleChip(localizedMuscleGroup(context, muscle), when),
        style: context.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
