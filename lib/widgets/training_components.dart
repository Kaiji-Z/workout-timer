// 训练页的进度条与工具函数（从 training_widget.dart 拆分）。
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../providers/training_progress_provider.dart';
import '../theme/app_theme.dart';
import '../theme/build_context_text_styles.dart';
import 'plan_card.dart';

/// 计划模式下的紧凑进度条 + 下一个动作提示。
Widget buildTrainingCompactProgress(
  BuildContext context, {
  required TrainingProgressProvider progressProvider,
  required AppThemeData theme,
  required bool isPlanMode,
}) {
  final currentExercise = progressProvider.currentExercise;
  if (currentExercise == null) return const SizedBox.shrink();

  // 计算下一个动作提示
  String? nextHint;
  if (isPlanMode && progressProvider.currentPlan != null) {
    final nextExercise = progressProvider.getNextExercise();
    if (nextExercise != null) {
      nextHint = context.l10n.trainingNextExercise(nextExercise.name);
    } else {
      nextHint = context.l10n.trainingNextDone;
    }
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        PlanProgressCompact(
          exerciseName: currentExercise.name,
          currentSet: progressProvider.currentSetInExercise + 1,
          totalSets: currentExercise.effectiveSets,
          totalProgress: progressProvider.progressPercentage,
        ),
        if (nextHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(nextHint, style: context.bodySmall),
          ),
      ],
    ),
  );
}

/// 「X h Y min」时长格式化。
String formatTrainingHoursMinutes(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours h $mins min' : '$hours h';
  }
  return '$minutes min';
}

/// Map a save-workout exception to a short user-facing message.
///
/// The raw exception + stack trace are logged via [debugPrint] by the
/// caller; this function only decides what the user sees. Unknown failures
/// fall back to a generic retry prompt instead of leaking `error.toString()`.
String translateTrainingSaveError(Object e, AppLocalizations l10n) {
  final raw = e.toString().toLowerCase();
  if (raw.contains('database') ||
      raw.contains('sqlite') ||
      raw.contains('sqflite')) {
    return l10n.trainingSaveFailedDb;
  }
  if (raw.contains('filesystem') ||
      raw.contains('no space') ||
      raw.contains('disk') ||
      raw.contains('storage')) {
    return l10n.trainingSaveFailedStorage;
  }
  return l10n.trainingSaveFailedGeneric;
}
