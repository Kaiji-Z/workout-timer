import 'package:flutter/material.dart';
// 计划详情弹窗（从 plan_screen.dart 拆分）。
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../providers/plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/muscle_group.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/build_context_text_styles.dart';
import '../main.dart';

class PlanDetailSheet extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onAddToDate;
  final VoidCallback? onDelete;

  const PlanDetailSheet({
    super.key,
    required this.plan,
    required this.onAddToDate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 计划名称
            Text(
              plan.name,
              style: context.headlineLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // 右上角删除按钮
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                  icon: Icon(Icons.delete_outline, color: theme.errorColor),
                  tooltip: l10n.planDeleteTitle,
                ),
              ),
            const SizedBox(height: 8),

            // 目标部位
            Text(
              l10n.planDetailTargetMuscles(plan.targetMusclesText),
              style: context.bodyMedium.copyWith(
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),

            // 统计
            Row(
              children: [
                _buildStatItem(
                  context,
                  '${plan.exerciseCount}',
                  l10n.planDetailExerciseCountUnit,
                  theme,
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  '${plan.totalSets}',
                  l10n.planDetailSetsUnit,
                  theme,
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  '~${plan.estimatedDuration}',
                  l10n.planDetailMinutesUnit,
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 动作列表
            Text(l10n.planDetailExerciseList, style: context.titleLarge),
            const SizedBox(height: 12),
            ...plan.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final planExercise = entry.value;
              final hasDetails = planExercise.hasDetails;
              final exercise = planExercise.exercise;
              final imageUrl = exercise?.imageUrl;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasDetails && exercise != null
                      ? () => ExerciseDetailSheet.show(
                          context,
                          exercise: exercise,
                          isSelected: false,
                          onToggle: () => Navigator.pop(context),
                          readOnly: true,
                        )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.textColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 缩略图或序号
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: hasDetails && imageUrl != null
                                ? () {
                                    final exercise = planExercise.exercise;
                                    final imageUrl = exercise?.imageUrl;
                                    if (exercise == null || imageUrl == null) {
                                      return;
                                    }
                                    if (exercise.images.isNotEmpty) {
                                      FullscreenImageViewer.showCarousel(
                                        context,
                                        images: exercise.images,
                                        initialIndex: 0,
                                        title: exercise.name,
                                      );
                                    } else {
                                      FullscreenImageViewer.show(
                                        context,
                                        imageUrl: imageUrl,
                                        title: exercise.name,
                                      );
                                    }
                                  }
                                : null,
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hasDetails
                                    ? theme.accentColor.withValues(alpha: 0.1)
                                    : theme.textColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                                child: hasDetails && imageUrl != null
                                    ? Hero(
                                        tag: imageUrl,
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Icon(
                                            Icons.fitness_center,
                                            color: theme.accentColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            size: 22,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.fitness_center,
                                                color: theme.accentColor
                                                    .withValues(alpha: 0.5),
                                                size: 22,
                                              ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: hasDetails
                                                    ? theme.accentColor
                                                    : theme.secondaryTextColor
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 动作名称
                              Text(
                                hasDetails
                                    ? planExercise.name
                                    : '${planExercise.name} ${l10n.planDetailNoDetailsSuffix}',
                                style: context.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: hasDetails
                                      ? theme.textColor
                                      : theme.secondaryTextColor.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontStyle: hasDetails
                                      ? null
                                      : FontStyle.italic,
                                ),
                              ),
                              // 肌肉标签和器材信息
                              if (hasDetails && exercise != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.accentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        exercise.primaryMuscle.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              fontSize: 11,
                                              color: theme.accentColor,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      exercise.equipmentDisplayName(l10n),
                                      style: context.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          l10n.planDetailEffectiveSets(
                            planExercise.effectiveSets,
                          ),
                          style: context.bodyMedium.copyWith(
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddToDate,
                    icon: Icon(Icons.calendar_today, color: theme.accentColor),
                    label: Text(
                      l10n.planDetailAddToCalendar,
                      style: context.bodyMedium.copyWith(
                        color: theme.accentColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<PlanProvider>().selectPlan(plan);
                      MainNavigation.switchToTab(2);
                    },
                    icon: Icon(Icons.play_arrow, color: theme.onAccentColor),
                    label: Text(
                      l10n.planDetailStartTraining,
                      style: context.titleLarge.copyWith(
                        color: theme.onAccentColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    AppThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: context.headlineLarge.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.accentColor,
          ),
        ),
        Text(label, style: context.bodySmall),
      ],
    );
  }
}
