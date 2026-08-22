import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/weekly_plan_import.dart';
import '../services/exercise_matcher_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// AI 计划向导「导入预览」组件（自 ai_plan_wizard_screen.dart 拆出）。
///
/// 匹配汇总、逐日卡片、逐动作行与候选选择 bottom sheet。共享状态
/// （editableSets / matchResults / manualSelections）以 Map 引用传入并
/// 原地修改，宿主通过 [setState] 回调触发重建 —— 与拆分前行为一致。

/// Build match summary banner showing matched/candidate/unmatched counts.
Widget aiWizardMatchSummary(
  BuildContext context, {
  required WeeklyPlanImport parsedPlan,
  required Map<String, MatchResult> matchResults,
  required Map<String, Exercise> manualSelections,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  int matched = 0;
  int candidates = 0;
  int unmatched = 0;

  for (final day in parsedPlan.days) {
    for (final exercise in day.exercises) {
      final key = 'day${day.dayOfWeek}-${exercise.exerciseName}';
      final hasManual = manualSelections.containsKey(key);
      final result = matchResults[key];

      if (hasManual || (result?.isSuccess ?? false)) {
        matched++;
      } else if (result != null && result.candidates.isNotEmpty) {
        candidates++;
      } else {
        unmatched++;
      }
    }
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.accentColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: theme.accentColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.aiMatchSummary(matched, candidates, unmatched),
            style: context.bodyMedium.copyWith(color: theme.textColor),
          ),
        ),
      ],
    ),
  );
}

/// Locale-aware weekday name (1=Mon..7=Sun).
String _dayName(int dayOfWeek, AppLocalizations l10n) {
  switch (dayOfWeek) {
    case 1:
      return l10n.aiDayNameMon;
    case 2:
      return l10n.aiDayNameTue;
    case 3:
      return l10n.aiDayNameWed;
    case 4:
      return l10n.aiDayNameThu;
    case 5:
      return l10n.aiDayNameFri;
    case 6:
      return l10n.aiDayNameSat;
    case 7:
      return l10n.aiDayNameSun;
    default:
      return '';
  }
}

Widget aiWizardDayCard(
  BuildContext context, {
  required DailyPlanImport day,
  required Map<String, int> editableSets,
  required Map<String, MatchResult> matchResults,
  required Map<String, Exercise> manualSelections,
  required bool isMatching,
  required void Function(void Function()) setState,
  required void Function(
    String key,
    String originalName,
    MatchResult result,
    AppThemeData theme,
  )
  onShowCandidates,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final dayName = _dayName(day.dayOfWeek, l10n);

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: theme.surfaceColor,
    child: Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.aiDayTitle(day.dayOfWeek, dayName),
                style: context.titleLarge,
              ),
              Text(
                day.exercises.isEmpty
                    ? l10n.aiRestDay
                    : l10n.aiExerciseCountSuffix(day.exercises.length),
                style: context.bodyMedium.copyWith(
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (day.targetMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.aiTargetMusclesLabel(day.targetMuscles.join(', ')),
              style: context.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          ...day.exercises.map(
            (exercise) => _buildExerciseRow(
              context,
              exercise: exercise,
              dayOfWeek: day.dayOfWeek,
              editableSets: editableSets,
              matchResults: matchResults,
              manualSelections: manualSelections,
              isMatching: isMatching,
              setState: setState,
              onShowCandidates: onShowCandidates,
              theme: theme,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildExerciseRow(
  BuildContext context, {
  required ExerciseEntryImport exercise,
  required int dayOfWeek,
  required Map<String, int> editableSets,
  required Map<String, MatchResult> matchResults,
  required Map<String, Exercise> manualSelections,
  required bool isMatching,
  required void Function(void Function()) setState,
  required void Function(
    String key,
    String originalName,
    MatchResult result,
    AppThemeData theme,
  )
  onShowCandidates,
  required AppThemeData theme,
}) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return const SizedBox.shrink();
  final exerciseKey = 'day$dayOfWeek-${exercise.exerciseName}';
  final currentSets = editableSets[exerciseKey] ?? exercise.targetSets;

  // --- Match status ---
  final matchResult = matchResults[exerciseKey];
  final hasManualSelection = manualSelections.containsKey(exerciseKey);
  final isMatched = hasManualSelection || (matchResult?.isSuccess ?? false);

  // Display name: manual selection > auto-match > original
  final manualSelection = manualSelections[exerciseKey];
  final matchedExercise = matchResult?.exercise;
  final displayName = manualSelection != null
      ? manualSelection.name
      : (matchResult?.isSuccess == true && matchedExercise != null
            ? matchedExercise.name
            : exercise.exerciseName);

  // Build status badge widget
  Widget? statusBadge;
  if (isMatching) {
    statusBadge = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.accentColor,
      ),
    );
  } else if (isMatched) {
    statusBadge = Icon(Icons.check_circle, color: theme.successColor, size: 20);
  } else if (matchResult != null && matchResult.candidates.isNotEmpty) {
    statusBadge = GestureDetector(
      onTap: () => onShowCandidates(
        exerciseKey,
        exercise.exerciseName,
        matchResult,
        theme,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.warningColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: theme.warningColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, size: 14, color: theme.warningColor),
            const SizedBox(width: 4),
            Text(
              l10n.aiCandidatesBadge(matchResult.candidates.length),
              style: context.bodySmall.copyWith(
                fontSize: 11,
                color: theme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    statusBadge = Icon(
      Icons.help_outline,
      color: theme.secondaryTextColor,
      size: 20,
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: context.bodyMedium),
              if (displayName != exercise.exerciseName)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.aiOriginalLabel(exercise.exerciseName),
                    style: context.bodySmall.copyWith(
                      color: theme.secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: statusBadge,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.aiDecreaseSets,
              icon: Icon(
                Icons.remove_circle_outline,
                color: theme.accentColor,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  final newSets = currentSets - 1;
                  if (newSets >= 1) {
                    editableSets[exerciseKey] = newSets;
                  }
                });
              },
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                '$currentSets',
                style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: l10n.aiIncreaseSets,
              icon: Icon(
                Icons.add_circle_outline,
                color: theme.accentColor,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  editableSets[exerciseKey] = currentSets + 1;
                });
              },
            ),
            const SizedBox(width: 4),
            Text(l10n.aiSetsUnit, style: context.bodySmall),
          ],
        ),
      ],
    ),
  );
}

/// Show bottom sheet for user to select a matching exercise from candidates.
void aiWizardCandidateSheet(
  BuildContext context, {
  required String matchKey,
  required String originalName,
  required MatchResult matchResult,
  required Map<String, Exercise> manualSelections,
  required void Function(void Function()) setState,
  required AppThemeData theme,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusSheet),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXxs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.aiSelectMatchTitle,
                    style: context.headlineLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.aiSelectMatchSubtitle(
                      originalName,
                      matchResult.candidates.length,
                    ),
                    style: context.bodyMedium.copyWith(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Candidate list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matchResult.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = matchResult.candidates[index];
                  final isSelected =
                      manualSelections[matchKey]?.id == candidate.id;
                  final l10n = AppLocalizations.of(context);
                  if (l10n == null) return const SizedBox.shrink();

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.accentColor
                            : theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.fitness_center,
                        color: isSelected
                            ? theme.onAccentColor
                            : theme.accentColor,
                        size: 20,
                      ),
                    ),
                    title: Text(candidate.name),
                    subtitle: Text(
                      '${candidate.primaryMuscle.displayName}'
                      ' · ${candidate.equipmentDisplayName(l10n)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: theme.accentColor)
                        : null,
                    onTap: () {
                      setState(() {
                        manualSelections[matchKey] = candidate;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            // Keep as unmatched option
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      manualSelections.remove(matchKey);
                    });
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: theme.secondaryTextColor),
                  label: Text(
                    AppLocalizations.of(context)!.aiKeepUnmatched,
                    style: TextStyle(color: theme.secondaryTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
