import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/muscle_group.dart';
import '../models/workout_record.dart';
import '../services/stats_aggregator_service.dart';
import '../services/stats_calculator_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 统计页「图表区」构建器与配套 painter（自 stats_screen.dart 拆出）。
///
/// 七个图表构建器均为无状态顶层函数；[StatsCollapsibleSection] 是
/// 周/月视图共用的折叠卡片容器。数据经参数传入，颜色走 [AppThemeData]，
/// 图表配色用 Okabe-Ito 色盲安全色板（DESIGN.md 取色铁律：不用品牌深靛蓝）。

final StatsCalculatorService _statsCalc = StatsCalculatorService();

/// 主肌群 → 图表配色（Okabe-Ito 色盲安全色板）。
const _kMuscleColors = <PrimaryMuscleGroup, Color>{
  PrimaryMuscleGroup.chest: Color(0xFFE69F00), // orange
  PrimaryMuscleGroup.back: Color(0xFF56B4E9), // sky blue
  PrimaryMuscleGroup.shoulders: Color(0xFF009E73), // bluish green
  PrimaryMuscleGroup.arms: Color(0xFFF0E442), // yellow
  PrimaryMuscleGroup.legs: Color(0xFF0072B2), // blue
  PrimaryMuscleGroup.core: Color(0xFFD55E00), // vermillion
};

/// 每日训练时长图表
Widget buildDailyDurationChart(
  BuildContext context,
  Map<int, int> durations,
  Map<int, int> sets,
  AppThemeData theme, {
  required bool isWeekView,
  int? days,
  required int selectedYear,
  required int selectedMonth,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final maxDuration = durations.values.fold(0, (max, e) => e > max ? e : max);
  final displayDays = days ?? (isWeekView ? 7 : 31);

  if (maxDuration == 0) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Text(
          l10n.statsNoData,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
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
            style: context.bodySmall.copyWith(
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
                                          StatsAggregatorService.formatDuration(
                                            duration,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                fontSize: isWeekView ? 11 : 9,
                                                color: theme.secondaryTextColor,
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
                                                  fontSize: isWeekView ? 10 : 8,
                                                  color:
                                                      theme.secondaryTextColor,
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
                  selectedYear,
                  selectedMonth + 1,
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
                        ? weekdayShort(index, l10n)
                        : (showLabel ? '$key' : ''),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    style: context.bodySmall.copyWith(
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

// ==================== 新增统计组件 ====================

/// 常用动作图表（水平条形图）
Widget buildCommonExercisesChart(
  BuildContext context,
  Map<String, int> exercises,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  if (exercises.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Text(
          l10n.statsNoExerciseData,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
        ),
      ),
    );
  }

  final maxCount = exercises.values.fold<int>(0, (max, e) => e > max ? e : max);

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
                style: context.bodySmall.copyWith(
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
                style: context.bodySmall.copyWith(
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
Widget buildMuscleVolumeChart(
  BuildContext context,
  List<WorkoutRecord> records,
  AppThemeData theme, {
  required double userBodyWeight,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final distribution = _statsCalc.calculateMuscleVolumeDistribution(
    records,
    bodyWeight: userBodyWeight,
  );

  if (distribution.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Text(
          l10n.statsNoData,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
        ),
      ),
    );
  }

  // Calculate total volume
  final totalVolume = distribution.values.fold<double>(0, (sum, v) => sum + v);

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
        style: context.headlineMedium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: theme.textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      Text(
        l10n.statsTotalCapacity,
        style: context.bodySmall.copyWith(
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
                l10n.statsOtherPercent(
                  (otherPercentage * 100).toStringAsFixed(1),
                ),
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
                    style: context.bodySmall.copyWith(
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
Widget buildPrimaryRecoveryList(
  BuildContext context,
  List<WorkoutRecord> records,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
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
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
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
        style: context.bodyMedium.copyWith(
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
                  style: context.bodySmall.copyWith(
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

/// 估算1RM趋势（top 5 动作的估算1RM变化）
///
/// 使用 Mayhew 指数公式从 weight×reps 估算 1RM，消除重量/次数
/// tradeoff 的歧义，让进步趋势可比。
Widget buildEstimated1RMTrend(
  BuildContext context,
  List<WorkoutRecord> records,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final trend = _statsCalc.calculateEstimated1RMTrend(records);

  if (trend.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Text(
          l10n.statsNo1rmData,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
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
            style: context.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Mayhew',
            style: context.bodySmall.copyWith(
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
                    style: context.bodySmall.copyWith(
                      fontSize: 11,
                      color: theme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    '$e1RM kg',
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Text(
                  l10n.statsRecordsCount(points.length),
                  style: context.bodySmall.copyWith(
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
                  style: context.bodySmall.copyWith(
                    fontSize: 11,
                    color: theme.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '${first.estimated1RM.toStringAsFixed(1)} → ${last.estimated1RM.toStringAsFixed(1)} kg',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (change >= 0 ? theme.successColor : theme.errorColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'
                  '${weeks > 0 ? l10n.anPrompt1rmWeeksSuffix(weeks.toStringAsFixed(0)) : ''}',
                  style: context.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: change >= 0 ? theme.successColor : theme.errorColor,
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
Widget buildSetsPerMuscleGroupChart(
  BuildContext context,
  List<WorkoutRecord> records,
  AppThemeData theme,
) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(records);

  if (setsPerMuscle.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Text(
          l10n.statsNoMuscleSetsData,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
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
            style: context.bodyMedium.copyWith(
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
        style: context.bodySmall.copyWith(
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
                  style: context.bodySmall.copyWith(
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

/// Collapsible section wrapper for grouping related stats sections
class StatsCollapsibleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final AppThemeData theme;

  const StatsCollapsibleSection({
    super.key,
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
            style: context.titleLarge.copyWith(
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

/// Locale-aware weekday short name (0=Mon..6=Sun for the 7-day grid).
/// Locale-aware weekday short name (0=Mon..6=Sun for the 7-day grid).
String weekdayShort(int index, AppLocalizations l10n) {
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
