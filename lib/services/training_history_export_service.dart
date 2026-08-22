import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../core/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/muscle_group.dart';
import '../models/set_data.dart';
import '../models/workout_record.dart';
import '../models/workout_session.dart';
import 'user_preferences_service.dart';

/// Result of a training-history export.
class ExportResult {
  /// The complete markdown document (narrative sections + embedded JSON block).
  final String markdown;

  /// Suggested file name, e.g. `training_history_2026-04-27_to_2026-07-27.md`.
  final String fileName;

  const ExportResult({required this.markdown, required this.fileName});
}

/// Generates a Markdown training-history archive intended to be shared with an
/// external AI agent.
///
/// The output is a single Markdown file with two parts:
///   1. A human-readable narrative of every training session in the range
///      (sets, reps, weight, volume per exercise).
///   2. An embedded ```json``` code block containing the same data in a
///      structured form that an AI agent can ingest directly.
///
/// Design notes:
/// - No DB access. Records are passed in by the caller (typically the history
///   screen, which already has them loaded).
/// - Mixed input: accepts both [WorkoutRecord] (full per-set data) and legacy
///   [WorkoutSession] (sets + rest only). Legacy sessions are emitted with
///   `"type": "legacy"` so an AI agent can skip or special-case them.
/// - Legacy-format [WorkoutRecord]s (those with `completedSets > 0` but no
///   per-set data) are normalized via [RecordedExercise.migrateToSetData] so
///   the exported `sets[]` array is always non-empty.
class TrainingHistoryExportService {
  static const int _exportVersion = 1;
  static const String _appVersion = '1.0.0';
  static const String _appName = 'Workout Timer';

  /// Resolve the current [AppLocalizations] for service-layer use (no
  /// BuildContext available). Falls back to Chinese if not registered yet.
  AppLocalizations _currentLocalizations() {
    try {
      final locale = ServiceLocator.get<ValueNotifier<Locale>>().value;
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('zh'));
    }
  }

  /// Build the training-history archive for the given time range.
  ///
  /// [records] may contain a mix of [WorkoutRecord] and [WorkoutSession]
  /// objects (the same shape [HistoryScreen._loadAllRecords] produces).
  /// [profile] is the user's training preferences, included as metadata.
  ExportResult export({
    required DateTime from,
    required DateTime to,
    required List<dynamic> records,
    required UserPreferences profile,
  }) {
    final l10n = _currentLocalizations();
    final normalized = _normalizeAndFilter(records, from, to);

    final markdown = _buildMarkdown(
      l10n: l10n,
      from: from,
      to: to,
      normalized: normalized,
      profile: profile,
    );

    final fileName =
        'training_history_${_dateOnly(from)}_to_${_dateOnly(to)}.md';

    return ExportResult(markdown: markdown, fileName: fileName);
  }

  // ==================== Normalize + filter ====================

  /// Walks [records], drops any whose date is outside `[from, to]`, normalizes
  /// legacy WorkoutRecord exercises to have per-set data, and returns them
  /// sorted newest-first.
  List<_NormalizedEntry> _normalizeAndFilter(
    List<dynamic> records,
    DateTime from,
    DateTime to,
  ) {
    // Inclusive on both ends: compare date-only to avoid off-by-one with time
    // components on `to`.
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(
      to.year,
      to.month,
      to.day,
    ).add(const Duration(days: 1)); // exclusive upper bound (start of next day)

    final result = <_NormalizedEntry>[];

    for (final record in records) {
      final DateTime? date = _recordDate(record);
      if (date == null) continue;

      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(fromDay) || !day.isBefore(toDay)) continue;

      if (record is WorkoutRecord) {
        final migrated = record.copyWith(
          exercises: record.exercises.map((e) => e.migrateToSetData()).toList(),
        );
        result.add(_NormalizedEntry(type: _Type.detailed, record: migrated));
      } else if (record is WorkoutSession) {
        result.add(_NormalizedEntry(type: _Type.legacy, session: record));
      }
    }

    // Sort newest first.
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  DateTime? _recordDate(dynamic record) {
    if (record is WorkoutRecord) return record.date;
    if (record is WorkoutSession) {
      try {
        return DateTime.parse(record.createdAt);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ==================== Markdown building ====================

  String _buildMarkdown({
    required AppLocalizations l10n,
    required DateTime from,
    required DateTime to,
    required List<_NormalizedEntry> normalized,
    required UserPreferences profile,
  }) {
    final buffer = StringBuffer();

    // --- Header ---
    buffer.writeln('# ${l10n.exportMarkdownH1}');
    buffer.writeln();
    buffer.writeln(
      '> ${l10n.exportMarkdownGeneratedAt}: ${_formatDateTime(DateTime.now())} · App: $_appName',
    );
    final sessionCount = normalized.length;
    final totalSets = _sumSets(normalized);
    buffer.writeln(
      '> ${l10n.exportMarkdownRange}: ${_dateOnly(from)} → ${_dateOnly(to)} · '
      '${l10n.exportMarkdownSessions}: $sessionCount · '
      '${l10n.exportMarkdownSessionSets}: $totalSets',
    );
    buffer.writeln();
    buffer.writeln();

    // --- Profile ---
    buffer.writeln('## ${l10n.exportMarkdownProfile}');
    buffer.writeln(
      '- ${l10n.exportMarkdownGoal}: ${_goalLabel(l10n, profile.goal)}',
    );
    buffer.writeln(
      '- ${l10n.exportMarkdownExperience}: ${_experienceLabel(l10n, profile.experience)}',
    );
    buffer.writeln('- ${l10n.exportMarkdownFrequency}: ${profile.frequency}');
    buffer.writeln(
      '- ${l10n.exportMarkdownEquipment}: ${_equipmentLabel(l10n, profile.equipment)}',
    );
    final focusAreas = profile.focusAreasList;
    if (focusAreas.isNotEmpty) {
      buffer.writeln(
        '- ${l10n.exportMarkdownFocusAreas}: ${focusAreas.map((m) => _muscleLabel(l10n, m)).join(', ')}',
      );
    }
    buffer.writeln();
    buffer.writeln();

    // --- Records (narrative) ---
    buffer.writeln('## ${l10n.exportMarkdownRecords}');
    buffer.writeln();

    for (final entry in normalized) {
      if (entry.type == _Type.detailed) {
        final record = entry.record;
        if (record != null) {
          buffer.writeln(_buildDetailedNarrative(l10n, record));
        }
      } else {
        final session = entry.session;
        if (session != null) {
          buffer.writeln(_buildLegacyNarrative(l10n, session));
        }
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    // --- Structured data (embedded JSON) ---
    buffer.writeln('## ${l10n.exportMarkdownStructured}');
    buffer.writeln();
    buffer.writeln('```json');
    buffer.writeln(_buildJson(from, to, normalized, profile));
    buffer.writeln('```');

    return buffer.toString();
  }

  String _buildDetailedNarrative(AppLocalizations l10n, WorkoutRecord record) {
    final buffer = StringBuffer();
    final weekday = _weekdayShort(record.date.weekday);
    final muscles = record.trainedMuscles.isEmpty
        ? ''
        : ' — ${record.trainedMuscles.map((m) => m.displayName).join(', ')}';

    buffer.writeln('### ${_dateOnly(record.date)} $weekday$muscles');

    final metaParts = <String>[
      '${l10n.exportMarkdownSessionDuration}: ${_formatDuration(record.durationSeconds)}',
      '${l10n.exportMarkdownSessionSets}: ${record.totalSets}',
    ];
    if ((record.planName ?? '').isNotEmpty) {
      metaParts.add('${l10n.exportMarkdownSessionPlan}: ${record.planName}');
    }
    buffer.writeln(metaParts.join(' · '));
    buffer.writeln();

    if (record.exercises.isEmpty) {
      buffer.writeln('_${l10n.exportMarkdownLegacyNote}_');
      return buffer.toString();
    }

    var i = 1;
    for (final ex in record.exercises) {
      final name = ex.nameEn.isNotEmpty
          ? ex.nameEn
          : (ex.name.isNotEmpty ? ex.name : ex.exerciseId);
      final muscleLabel = ex.exercise?.primaryMuscle.displayName ?? '';
      final equip = ex.exercise?.equipment ?? '';
      final qualifier = [
        muscleLabel,
        equip,
      ].where((s) => s.isNotEmpty).join(' · ');
      buffer.writeln(
        '$i. **$name**${qualifier.isNotEmpty ? ' ($qualifier)' : ''}',
      );

      final sets = ex.setsData ?? const <SetData>[];
      for (final s in sets) {
        buffer.writeln(
          '   - ${l10n.exportMarkdownSet(s.setNumber)}: ${s.displayText}',
        );
      }
      final vol = ex.totalVolume;
      if (vol > 0) {
        buffer.writeln(
          '   - _${l10n.exportMarkdownVolumeNote}: ${vol.toStringAsFixed(1)}kg_',
        );
      }
      i++;
    }

    return buffer.toString();
  }

  String _buildLegacyNarrative(AppLocalizations l10n, WorkoutSession session) {
    final buffer = StringBuffer();
    final date = _recordDate(session) ?? DateTime.now();
    final weekday = _weekdayShort(date.weekday);

    buffer.writeln('### ${_dateOnly(date)} $weekday');
    buffer.writeln(
      '_${l10n.exportMarkdownLegacyNote} · '
      '${l10n.exportMarkdownSessionSets}: ${session.totalSets} · '
      '${l10n.exportMarkdownSessionDuration}: ${(session.totalRestTimeMs / 1000).round()}s_',
    );
    return buffer.toString();
  }

  // ==================== JSON building ====================

  String _buildJson(
    DateTime from,
    DateTime to,
    List<_NormalizedEntry> normalized,
    UserPreferences profile,
  ) {
    final legacyCount = normalized.where((e) => e.type == _Type.legacy).length;
    final totalSets = _sumSets(normalized);
    final totalDuration = normalized.fold<int>(
      0,
      (sum, e) => sum + e.durationSeconds,
    );

    final data = <String, dynamic>{
      'exportVersion': _exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': _appVersion,
      'range': {'from': _dateOnly(from), 'to': _dateOnly(to)},
      'profile': {
        'goal': profile.goal,
        'experience': profile.experience,
        'frequency': profile.frequency,
        'equipment': profile.equipment,
        'focusAreas': profile.focusAreasList,
      },
      'summary': {
        'sessionCount': normalized.length,
        'totalSets': totalSets,
        'totalDurationSeconds': totalDuration,
        'legacyCount': legacyCount,
      },
      'records': normalized.map(_entryToJson).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Map<String, dynamic> _entryToJson(_NormalizedEntry entry) {
    final record = entry.record;
    if (entry.type == _Type.detailed && record != null) {
      return {
        'type': 'detailed',
        'id': record.id,
        'date': _dateOnly(record.date),
        'weekday': record.date.weekday,
        'durationSeconds': record.durationSeconds,
        'trainedMuscles': record.trainedMuscles.map((m) => m.name).toList(),
        'totalSets': record.totalSets,
        if ((record.planId ?? '').isNotEmpty) 'planId': record.planId,
        if ((record.planName ?? '').isNotEmpty) 'planName': record.planName,
        'exercises': record.exercises.map(_exerciseToJson).toList(),
      };
    }

    final session = entry.session;
    final date = session != null ? _recordDate(session) : null;
    return {
      'type': 'legacy',
      'id': session?.id ?? '',
      'date': date != null ? _dateOnly(date) : null,
      if (date != null) 'weekday': date.weekday,
      'sets': session?.totalSets ?? 0,
      'restTimeSeconds': ((session?.totalRestTimeMs ?? 0) / 1000).round(),
    };
  }

  Map<String, dynamic> _exerciseToJson(RecordedExercise ex) {
    final exercise = ex.exercise;
    final maxWeight = ex.maxWeight;
    return {
      'exerciseId': ex.exerciseId,
      if (exercise != null && exercise.name.isNotEmpty) 'name': exercise.name,
      if (exercise != null && exercise.nameEn.isNotEmpty)
        'nameEn': exercise.nameEn,
      if (exercise != null) 'primaryMuscle': exercise.primaryMuscle.name,
      if (exercise != null && exercise.equipment.isNotEmpty)
        'equipment': exercise.equipment,
      'completedSets': ex.completedSets,
      if (maxWeight != null && maxWeight > 0) 'maxWeight': maxWeight,
      'sets': (ex.setsData ?? const <SetData>[]).map(_setDataToJson).toList(),
    };
  }

  Map<String, dynamic> _setDataToJson(SetData s) {
    return {
      'setNumber': s.setNumber,
      if (s.reps != null) 'reps': s.reps,
      if (s.weight != null) 'weight': s.weight,
    };
  }

  // ==================== Helpers ====================

  int _sumSets(List<_NormalizedEntry> entries) {
    return entries.fold<int>(0, (sum, e) {
      final record = e.record;
      if (e.type == _Type.detailed && record != null) {
        return sum + record.totalSets;
      }
      final session = e.session;
      if (session != null) {
        return sum + session.totalSets;
      }
      return sum;
    });
  }

  String _dateOnly(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDateTime(DateTime d) {
    final date = _dateOnly(d);
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$date $h:$min';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m${s}s';
  }

  String _weekdayShort(int weekday) {
    // weekday: 1=Monday ... 7=Sunday
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return names[weekday - 1];
  }

  String _goalLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'muscle_building':
        return l10n.anGoalMuscleBuilding;
      case 'fat_loss':
        return l10n.anGoalFatLoss;
      case 'strength':
        return l10n.anGoalStrength;
      case 'endurance':
        return l10n.anGoalEndurance;
      default:
        return code;
    }
  }

  String _experienceLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'beginner':
        return l10n.prefExperienceBeginner;
      case 'intermediate':
        return l10n.prefExperienceIntermediate;
      case 'advanced':
        return l10n.prefExperienceAdvanced;
      default:
        return code;
    }
  }

  String _equipmentLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'gym':
        return l10n.prefEquipmentGym;
      case 'home_dumbbell':
        return l10n.prefEquipmentHomeDumbbell;
      case 'bodyweight':
        return l10n.prefEquipmentBodyweight;
      default:
        return code;
    }
  }

  String _muscleLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'chest':
        return l10n.prefFocusAreaChest;
      case 'back':
        return l10n.prefFocusAreaBack;
      case 'shoulders':
        return l10n.prefFocusAreaShoulders;
      case 'arms':
        return l10n.prefFocusAreaArms;
      case 'legs':
        return l10n.prefFocusAreaLegs;
      case 'core':
        return l10n.prefFocusAreaCore;
      default:
        return code;
    }
  }
}

/// Internal normalized entry: either a migrated [WorkoutRecord] (detailed) or
/// a legacy [WorkoutSession] (legacy).
class _NormalizedEntry {
  final _Type type;
  final WorkoutRecord? record;
  final WorkoutSession? session;

  const _NormalizedEntry({required this.type, this.record, this.session})
    : assert(
        (type == _Type.detailed && record != null) ||
            (type == _Type.legacy && session != null),
        'entry must match its type',
      );

  DateTime get date {
    final record = this.record;
    if (record != null) return record.date;
    // Legacy session: parse createdAt (already validated in _recordDate).
    return DateTime.parse(session!.createdAt);
  }

  int get durationSeconds {
    final record = this.record;
    if (record != null) return record.durationSeconds;
    return 0;
  }
}

enum _Type { detailed, legacy }
