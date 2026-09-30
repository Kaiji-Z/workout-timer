import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
/// 仅保留训练密度小指标（习惯区下方复用）。

final StatsCalculatorService _statsCalc = StatsCalculatorService();

/// 训练密度指标（组/分钟）
Widget buildDensityMetric(
  BuildContext context,
  List<WorkoutRecord> records,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
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
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.secondaryTextColor,
                ),
              ),
              Text(
                l10n.statsSetsPerMinute(density.toStringAsFixed(1)),
                style: context.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Text(
          l10n.statsSetsOverMinutes(totalSets, totalMinutes.toStringAsFixed(0)),
          style: context.bodySmall.copyWith(
            fontSize: 11,
            color: theme.secondaryTextColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
