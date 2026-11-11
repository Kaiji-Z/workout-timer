import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import 'muscle_selector.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../animations/animation_primitives.dart';
import '../theme/build_context_text_styles.dart';

/// 计划卡片 - Flat Vitality 设计
///
/// 显示训练计划的摘要信息
class PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback? onTap;
  final bool isCompact;

  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return AnimatedCard(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceColorRaised,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          boxShadow: AppElevation.raised(theme.shadowColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要内容
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: theme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: context.titleLarge.copyWith(
                                fontSize: 17,
                                color: theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            MuscleBadge(
                              muscles: plan.targetMuscles,
                              compact: true,
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!isCompact) ...[
                    const SizedBox(height: 12),
                    // 统计信息
                    Row(
                      children: [
                        _buildStat(
                          context,
                          l10n.widgetPlanExercisesCount(plan.exerciseCount),
                          Icons.list_alt,
                          theme,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          context,
                          l10n.widgetPlanSetsCount(plan.totalSets),
                          Icons.repeat,
                          theme,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          context,
                          l10n.widgetPlanDuration(plan.estimatedDuration),
                          Icons.timer_outlined,
                          theme,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String text,
    IconData icon,
    AppThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.secondaryTextColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: context.bodyMedium.copyWith(
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

/// 极简进度行 - 计划模式训练中显示
/// 单行：动作名 + 当前组/总组 + 整体进度条
class PlanProgressCompact extends StatelessWidget {
  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final double totalProgress; // 0.0 - 1.0

  const PlanProgressCompact({
    super.key,
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.totalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: Row(
        children: [
          // 动作名 + 进度
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.widgetProgressSummary(exerciseName, currentSet, totalSets),
                style: context.labelLarge.copyWith(color: theme.textColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 进度条
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              child: LinearProgressIndicator(
                value: totalProgress,
                backgroundColor: theme.accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
