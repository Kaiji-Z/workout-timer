import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../models/workout_record.dart';
import '../services/stats_calculator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 统计页遗留图表构建器。
///
/// 周视图/月视图双 Tab 时代的 7 张图已随问题驱动重构退役
/// （.goal/SPEC.md §3.1）：组数图→stats_dose_section、恢复列表→
/// stats_today_card、1RM 趋势→stats_progress_section、月历热格→
/// stats_habit_section、常见动作/肌群环形图/每日时长图→裁撤。
/// 仅保留训练密度区块（习惯区下方，与其他四区同一区块制服）。

final StatsCalculatorService _statsCalc = StatsCalculatorService();

/// 训练密度区块（组/分钟）：统计口径可选 近7天/近30天/全部。
///
/// 外壳沿用统计页四区的区块制服——`surfaceColorRaised` + `radiusXl` +
/// `AppElevation.raised` + `screenPadding`，区头 16px accent 图标 +
/// 13px 标题（图标用 bolt，与剂量区的 speed 区分开）；
/// 口径 chips 沿用 15% Tint 激活语义（进步区范围 chips 同款）。
/// 默认近30天——承接旧版滚动 28 天的口径语义，与 AI 复盘默认窗口一致。
/// 无记录时整卡隐藏（与旧版行为一致）。
class DensityMetricCard extends StatefulWidget {
  /// 全部明细记录（窗口过滤在卡片内部做，切口径无需重建上游）
  final List<WorkoutRecord> records;

  /// 滚动窗口锚定日（date-only 语义）
  final DateTime asOf;

  final AppThemeData theme;

  const DensityMetricCard({
    super.key,
    required this.records,
    required this.asOf,
    required this.theme,
  });

  @override
  State<DensityMetricCard> createState() => _DensityMetricCardState();
}

class _DensityMetricCardState extends State<DensityMetricCard> {
  /// 统计窗口天数；null = 全部
  int? _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = widget.theme;
    if (widget.records.isEmpty) return const SizedBox.shrink();

    final rangeDays = _rangeDays;
    final scoped = rangeDays == null
        ? widget.records
        : _statsCalc.filterRollingWindow(
            widget.records,
            asOf: widget.asOf,
            windowDays: rangeDays,
          );

    final density = _statsCalc.calculateDensity(scoped);
    final totalSets = scoped.fold<int>(0, (sum, r) => sum + r.totalSets);
    final totalMinutes =
        scoped.fold<int>(0, (sum, r) => sum + r.durationSeconds) / 60.0;

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
          // 区头：与今日/剂量/进步/习惯四区同一惯例；点标题看口径释义
          // （进步区 Mayhew tooltip 同款 tap 触发）
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: theme.accentColor),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.tooltipDensity,
                triggerMode: TooltipTriggerMode.tap,
                child: Text(
                  l10n.statsDensity,
                  style: context.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 数值行：密度值为主，总量从属
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l10n.statsSetsPerMinute(density.toStringAsFixed(1)),
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.statsSetsOverMinutes(
                  totalSets,
                  totalMinutes.toStringAsFixed(0),
                ),
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 口径切换：居中（习惯区年份选择器先例），从属于数据行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rangeChip(l10n.statsDensityRange7d, 7),
              const SizedBox(width: 6),
              _rangeChip(l10n.statsDensityRange30d, 30),
              const SizedBox(width: 6),
              _rangeChip(l10n.statsDensityRangeAll, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, int? days) {
    final theme = widget.theme;
    final selected = _rangeDays == days;
    // 读屏可聚焦可触发，且播报选中态（PRODUCT.md 无障碍承诺）
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => setState(() => _rangeDays = days),
        child: Container(
          // 触控目标 ≥48dp（与 stats_progress_section 范围 chips 同款）
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The 15% Tint Rule — selected 用实底 accent，未选中用 15% tint
            color: selected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
          ),
          child: Text(
            label,
            style: context.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? theme.onAccentColor : theme.accentColor,
            ),
          ),
        ),
      ),
    );
  }
}
