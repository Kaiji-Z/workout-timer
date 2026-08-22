import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import 'glass_widgets.dart';

/// AI 计划向导的通用 UI 组件（自 ai_plan_wizard_screen.dart 拆出）。
///
/// 全部为无状态顶层函数：状态经参数传入，动作经回调上抛，
/// 文案经 [BuildContext] 取 l10n，颜色一律走 [AppThemeData]。

/// 顶部步骤指示器（新建计划 4 步 / 导入分析 3 步）。
Widget aiWizardStepIndicator(
  BuildContext context, {
  required int currentStep,
  required bool isImportTab,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final stepLabels = isImportTab
      ? [
          l10n.aiStepImportAnalysis,
          l10n.aiStepStartWeek,
          l10n.aiStepPreviewImport,
        ]
      : [
          l10n.aiStepProfile,
          l10n.aiStepGeneratePrompt,
          l10n.aiStepPasteJson,
          l10n.aiStepPreviewImport,
        ];

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
      children: [
        for (int i = 0; i < stepLabels.length; i++) ...[
          if (i > 0) _stepLine(currentStep >= i, theme),
          _stepItem(
            context,
            i + 1,
            stepLabels[i],
            currentStep >= i,
            currentStep,
            theme,
          ),
        ],
      ],
    ),
  );
}

Widget _stepItem(
  BuildContext context,
  int number,
  String label,
  bool isActive,
  int currentStep,
  AppThemeData theme,
) {
  return Column(
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
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: isActive ? theme.textColor : theme.secondaryTextColor,
        ),
      ),
    ],
  );
}

Widget _stepLine(bool isActive, AppThemeData theme) {
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

/// 多选题（如专注肌群）：Wrap 流式布局的可选 chip 组。
Widget aiWizardMultiSelectQuestion(
  BuildContext context, {
  required String title,
  required List<String> selectedValues,
  required Map<String, String> options,
  required ValueChanged<List<String>> onChanged,
  required AppThemeData theme,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.entries.map((entry) {
          final label = entry.key;
          final code = entry.value;
          final isSelected = selectedValues.contains(code);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValues = List<String>.from(selectedValues);
                if (isSelected) {
                  newValues.remove(code);
                } else {
                  newValues.add(code);
                }
                onChanged(newValues);
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.accentColor
                      : theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                  border: Border.all(
                    color: isSelected
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? theme.onAccentColor : theme.accentColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

/// 导入流程「选择起始周」步骤（本周 / 下周二选一）。
Widget aiWizardStartWeekStep(
  BuildContext context, {
  required bool? startFromThisWeek,
  required ValueChanged<bool> onSelectionChanged,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiStartWeekHeading,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiStartWeekSubheading,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 24),
        aiWizardStartWeekOption(
          context: context,
          label: l10n.aiStartWeekThisWeek,
          description: l10n.aiStartWeekThisWeekDesc,
          icon: Icons.calendar_view_week,
          isSelected: startFromThisWeek == true,
          onTap: () => onSelectionChanged(true),
          theme: theme,
        ),
        const SizedBox(height: 12),
        aiWizardStartWeekOption(
          context: context,
          label: l10n.aiStartWeekNextWeek,
          description: l10n.aiStartWeekNextWeekDesc,
          icon: Icons.event_available,
          isSelected: startFromThisWeek == false,
          onTap: () => onSelectionChanged(false),
          theme: theme,
        ),
      ],
    ),
  );
}

/// A single selectable card for the start-week step.
Widget aiWizardStartWeekOption({
  required BuildContext context,
  required String label,
  required String description,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
  required AppThemeData theme,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor.withValues(alpha: 0.15)
              : theme.surfaceColorRaised,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppElevation.resting(theme.shadowColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.accentColor
                    : theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.onAccentColor : theme.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.accentColor : theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.accentColor, size: 24),
          ],
        ),
      ),
    ),
  );
}

/// 新建计划流程「生成提示词」步骤：选开始日期 → 生成 → 复制。
Widget aiWizardPromptStep(
  BuildContext context, {
  required DateTime startDate,
  required String? generatedPrompt,
  required VoidCallback onGeneratePrompt,
  required VoidCallback onCopyToClipboard,
  required ValueChanged<DateTime> onStartDateChanged,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiGeneratePromptHeading,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiGeneratePromptSubheading,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
        ),
        const SizedBox(height: 24),

        Text(
          l10n.aiStartDateLabel,
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  if (child == null) {
                    return const SizedBox.shrink();
                  }
                  return Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.light(
                        primary: theme.accentColor,
                        onPrimary: theme.onAccentColor,
                        secondary: theme.accentColor,
                        surface: theme.surfaceColor,
                        onSurface: theme.textColor,
                        error: theme.errorColor,
                        onError: theme.onAccentColor,
                      ),
                    ),
                    child: child,
                  );
                },
              );
              if (date != null) {
                onStartDateChanged(date);
              }
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.surfaceColorRaised,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: AppElevation.resting(theme.shadowColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.aiDateDisplay(
                      startDate.year,
                      startDate.month,
                      startDate.day,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge!,
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: theme.accentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        PrimaryActionButton(
          label: l10n.aiGeneratePromptButton,
          onPressed: onGeneratePrompt,
          height: 56,
        ),
        const SizedBox(height: 24),

        if (generatedPrompt != null) ...[
          Text(
            l10n.aiGeneratedPromptLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            decoration: BoxDecoration(
              color: theme.surfaceColorRaised,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: AppElevation.resting(theme.shadowColor),
            ),
            child: SingleChildScrollView(
              child: Text(
                generatedPrompt,
                style: Theme.of(context).textTheme.bodyMedium!,
              ),
            ),
          ),
          const SizedBox(height: 16),

          PrimaryActionButton(
            label: l10n.aiCopyToClipboard,
            onPressed: onCopyToClipboard,
            height: 56,
          ),
          const SizedBox(height: 16),

          Text(
            l10n.aiCopyHint,
            style: Theme.of(context).textTheme.bodySmall!,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}
