// 计划表单的步骤指示器与动作条目组件（从 plan_form_screen.dart 拆分）。
import 'package:flutter/material.dart';
import '../l10n/context_l10n.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/app_theme.dart';
import '../theme/build_context_text_styles.dart';
import '../utils/dimensions.dart';

Widget buildPlanFormStepIndicator(
  BuildContext context, {
  required int currentStep,
  required bool isEditMode,
  required void Function(int step) onJumpToStep,
  required AppThemeData theme,
}) {
  final l10n = context.l10n;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
      children: [
        _buildStepItem(
          context,
          1,
          l10n.pfStepSelectMuscle,
          currentStep >= 0,
          currentStep,
          isEditMode,
          onJumpToStep,
          theme,
        ),
        _buildStepLine(currentStep >= 1, theme),
        _buildStepItem(
          context,
          2,
          l10n.pfStepSelectExercise,
          currentStep >= 1,
          currentStep,
          isEditMode,
          onJumpToStep,
          theme,
        ),
        _buildStepLine(currentStep >= 2, theme),
        _buildStepItem(
          context,
          3,
          l10n.pfStepConfirm,
          currentStep >= 2,
          currentStep,
          isEditMode,
          onJumpToStep,
          theme,
        ),
      ],
    ),
  );
}

Widget _buildStepItem(
  BuildContext context,
  int number,
  String label,
  bool isActive,
  int currentStep,
  bool isEditMode,
  void Function(int step) onJumpToStep,
  AppThemeData theme,
) {
  // 步骤索引 = number - 1
  final stepIndex = number - 1;
  // 判断是否可点击：编辑模式全部可点击；创建模式只能回到已完成步骤
  final canTap = isEditMode || stepIndex < currentStep;

  return GestureDetector(
    onTap: canTap ? () => onJumpToStep(stepIndex) : null,
    child: Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? theme.accentColor
                : theme.textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && currentStep > number - 1
                ? Icon(Icons.check, color: theme.onAccentColor, size: 18)
                : Text(
                    '$number',
                    style: context.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? theme.onAccentColor
                          : theme.secondaryTextColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.bodySmall.copyWith(
            color: isActive ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStepLine(bool isActive, AppThemeData theme) {
  return Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive
          ? theme.accentColor
          : theme.textColor.withValues(alpha: 0.1),
    ),
  );
}

Widget buildPlanFormExerciseSetItem(
  BuildContext context, {
  Key? key,
  required int index,
  required PlanExercise planExercise,
  required AppThemeData theme,
  required void Function(int newSets) onSetsChanged,
  required VoidCallback onRemove,
}) {
  final l10n = context.l10n;
  return Container(
    key: key,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.surfaceColorRaised,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      boxShadow: AppElevation.resting(theme.shadowColor),
    ),
    child: Row(
      children: [
        // 拖拽手柄
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.drag_indicator,
              color: theme.secondaryTextColor,
              size: 20,
            ),
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: context.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planExercise.hasDetails
                    ? planExercise.name
                    : '${planExercise.name} ${l10n.pfNoDetailsSuffix}',
                style: context.labelLarge.copyWith(
                  color: planExercise.hasDetails
                      ? theme.textColor
                      : theme.secondaryTextColor.withValues(alpha: 0.7),
                  fontStyle: planExercise.hasDetails ? null : FontStyle.italic,
                ),
              ),
              Text(
                planExercise.exercise?.primaryMuscle.displayName ?? '',
                style: context.bodySmall,
              ),
            ],
          ),
        ),
        // 组数调整
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.pfDecreaseSets,
              onPressed: planExercise.effectiveSets > 1
                  ? () => onSetsChanged(planExercise.effectiveSets - 1)
                  : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: planExercise.effectiveSets > 1
                    ? theme.accentColor
                    : theme.secondaryTextColor.withValues(alpha: 0.3),
              ),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '${planExercise.effectiveSets}',
                style: context.headlineLarge.copyWith(fontSize: 18),
              ),
            ),
            IconButton(
              tooltip: l10n.pfIncreaseSets,
              onPressed: planExercise.effectiveSets < 10
                  ? () => onSetsChanged(planExercise.effectiveSets + 1)
                  : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: planExercise.effectiveSets < 10
                    ? theme.accentColor
                    : theme.secondaryTextColor.withValues(alpha: 0.3),
              ),
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // 删除动作按钮
            IconButton(
              tooltip: l10n.pfDeleteExercise,
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: theme.errorColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    ),
  );
}
