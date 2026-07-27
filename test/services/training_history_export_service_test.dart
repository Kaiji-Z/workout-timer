import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/workout_session.dart';
import 'package:workout_timer/services/training_history_export_service.dart';
import 'package:workout_timer/services/user_preferences_service.dart';

void main() {
  late TrainingHistoryExportService service;

  // Range covers the most recent 90 days (in-scope records dated within,
  // out-of-scope record dated well before).
  final DateTime from = DateTime(2026, 4, 27);
  final DateTime to = DateTime(2026, 7, 27);

  /// A fully-detailed WorkoutRecord with per-set data.
  WorkoutRecord detailedRecord({
    required String id,
    required DateTime date,
    required int durationSeconds,
    required List<PrimaryMuscleGroup> trainedMuscles,
    String? planName,
    required List<RecordedExercise> exercises,
  }) {
    return WorkoutRecord(
      id: id,
      date: date,
      durationSeconds: durationSeconds,
      trainedMuscles: trainedMuscles,
      exercises: exercises,
      planName: planName,
      totalSets: exercises.fold<int>(0, (sum, e) => sum + e.completedSets),
      createdAt: date,
    );
  }

  setUp(() {
    service = TrainingHistoryExportService();
  });

  /// Shared sample data: 4 records (3 in range, 1 out of range).
  /// Returns a list of mixed [WorkoutRecord] and [WorkoutSession] objects,
  /// the same shape the history screen loads.
  List<dynamic> sampleRecords() {
    // 1. Fully-detailed record with complete per-set data.
    final detailed = detailedRecord(
      id: 'detailed-1',
      date: DateTime(2026, 7, 27),
      durationSeconds: 2730,
      trainedMuscles: const [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.arms],
      planName: '推日 A',
      exercises: [
        RecordedExercise(
          exerciseId: 'bench-press',
          exercise:
              null, // Service should still emit exerciseId even without Exercise model
          completedSets: 2,
          maxWeight: 82.5, // matches the heaviest set below
          setsData: const [
            SetData(setNumber: 1, reps: 8, weight: 80.0),
            SetData(setNumber: 2, reps: 6, weight: 82.5),
          ],
        ),
      ],
    );

    // 2. Legacy WorkoutRecord: only completedSets + maxWeight, no per-set data.
    //    Service must call migrateToSetData() so the exported JSON has sets[].
    final legacyDetailed = detailedRecord(
      id: 'detailed-legacy-2',
      date: DateTime(2026, 6, 15),
      durationSeconds: 1800,
      trainedMuscles: const [PrimaryMuscleGroup.legs],
      exercises: [
        RecordedExercise(
          exerciseId: 'squat',
          completedSets: 3,
          maxWeight: 100.0,
          // setsData intentionally null → migration expected
        ),
      ],
    );

    // 3. Legacy simple WorkoutSession: no exercises at all.
    final legacySession = WorkoutSession(
      id: 'session-3',
      totalSets: 5,
      totalRestTimeMs: 60000,
      createdAt: DateTime(2026, 5, 10).toIso8601String(),
    );

    // 4. OUT OF RANGE — must be filtered out.
    final outOfRange = detailedRecord(
      id: 'out-of-range-4',
      date: DateTime(2025, 12, 1), // well before `from`
      durationSeconds: 600,
      trainedMuscles: const [PrimaryMuscleGroup.back],
      exercises: [
        RecordedExercise(
          exerciseId: 'pull-up',
          completedSets: 1,
          maxWeight: 0,
          setsData: const [SetData(setNumber: 1, reps: 5, weight: 0)],
        ),
      ],
    );

    return [detailed, legacyDetailed, legacySession, outOfRange];
  }

  const profile = UserPreferences(
    goal: 'muscle_building',
    experience: 'intermediate',
    equipment: 'gym',
    frequency: 4,
    focusAreas: 'chest,back',
  );

  group('TrainingHistoryExportService.export', () {
    test('returns non-empty markdown and a filename containing from/to', () {
      final result = service.export(
        from: from,
        to: to,
        records: sampleRecords(),
        profile: profile,
      );

      expect(result.markdown, isNotEmpty);
      expect(result.fileName, contains('2026-04-27'));
      expect(result.fileName, contains('2026-07-27'));
      expect(result.fileName, endsWith('.md'));
    });

    test(
      'markdown contains H1, profile section, records section, and JSON block',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        // Top-level markdown section headers.
        expect(result.markdown, contains('# ')); // H1
        expect(result.markdown, contains('```json'));
        expect(result.markdown, contains('```'));
      },
    );

    test('filters out records whose date is outside [from, to]', () {
      final result = service.export(
        from: from,
        to: to,
        records: sampleRecords(),
        profile: profile,
      );

      // The out-of-range record id must NOT appear in either the markdown
      // narrative or the JSON block.
      expect(result.markdown, isNot(contains('out-of-range-4')));
      expect(result.markdown, isNot(contains('2025-12-01')));
    });

    test(
      'embedded JSON is parseable and has the documented top-level shape',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        final json = _extractJsonBlock(result.markdown);
        expect(
          json,
          isNotNull,
          reason: 'markdown must contain a ```json block',
        );

        final decoded = jsonDecode(json!) as Map<String, dynamic>;

        expect(decoded['exportVersion'], 1);
        expect(decoded['exportedAt'], isA<String>());
        expect(decoded['range'], isA<Map>());
        expect((decoded['range'] as Map)['from'], '2026-04-27');
        expect((decoded['range'] as Map)['to'], '2026-07-27');

        // Profile block.
        final profileBlock = decoded['profile'] as Map<String, dynamic>;
        expect(profileBlock['goal'], 'muscle_building');
        expect(profileBlock['experience'], 'intermediate');
        expect(profileBlock['frequency'], 4);
        expect(profileBlock['equipment'], 'gym');
        expect(profileBlock['focusAreas'], ['chest', 'back']);

        // Records: 3 in-range (2 detailed + 1 legacy session).
        final recordsList = decoded['records'] as List<dynamic>;
        expect(recordsList.length, 3);
      },
    );

    test('summary counts sessions, sets, duration, and legacy entries', () {
      final result = service.export(
        from: from,
        to: to,
        records: sampleRecords(),
        profile: profile,
      );

      final json = _extractJsonBlock(result.markdown)!;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final summary = decoded['summary'] as Map<String, dynamic>;

      // 3 in-range records.
      expect(summary['sessionCount'], 3);
      // Legacy count: only the WorkoutSession (1). The legacy-format
      // WorkoutRecord (no per-set data) is still a "detailed" type record,
      // just with migrated synthetic sets.
      expect(summary['legacyCount'], 1);
      expect(summary['totalSets'], isA<int>());
      expect(summary['totalDurationSeconds'], isA<int>());
    });

    test(
      'legacy WorkoutRecord (no per-set data) is migrated to non-empty sets',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        final json = _extractJsonBlock(result.markdown)!;
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final records = decoded['records'] as List<dynamic>;

        // Find the legacy-format detailed record (squat, dated 2026-06-15).
        final squatRecord =
            records.firstWhere(
                  (r) =>
                      (r as Map)['type'] == 'detailed' &&
                      r['date'] == '2026-06-15',
                  orElse: () =>
                      throw StateError('legacy-format detailed record missing'),
                )
                as Map<String, dynamic>;

        final exercises = squatRecord['exercises'] as List<dynamic>;
        expect(exercises, isNotEmpty);

        final firstExercise = exercises.first as Map<String, dynamic>;
        final sets = firstExercise['sets'] as List<dynamic>;
        // Migration synthesizes one SetData per completedSets (3 here).
        expect(sets.length, 3);
        // Each migrated set should carry the maxWeight as its weight.
        for (final s in sets) {
          expect((s as Map)['weight'], 100.0);
        }
      },
    );

    test(
      'WorkoutSession becomes a "legacy" type entry with sets + restTimeSeconds',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        final json = _extractJsonBlock(result.markdown)!;
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final records = decoded['records'] as List<dynamic>;

        final legacyEntry =
            records.firstWhere(
                  (r) => (r as Map)['type'] == 'legacy',
                  orElse: () =>
                      throw StateError('legacy WorkoutSession entry missing'),
                )
                as Map<String, dynamic>;

        expect(legacyEntry['sets'], 5);
        expect(legacyEntry['restTimeSeconds'], 60);
        expect(legacyEntry['date'], '2026-05-10');
        // Legacy entries must NOT carry the full detailed-exercise shape.
        expect(legacyEntry.containsKey('exercises'), isFalse);
      },
    );

    test(
      'detailed record preserves exerciseId, name fields, and per-set data',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        final json = _extractJsonBlock(result.markdown)!;
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final records = decoded['records'] as List<dynamic>;

        final benchRecord =
            records.firstWhere(
                  (r) =>
                      (r as Map)['type'] == 'detailed' &&
                      r['date'] == '2026-07-27',
                )
                as Map<String, dynamic>;

        expect(benchRecord['durationSeconds'], 2730);
        expect(benchRecord['planName'], '推日 A');
        expect(benchRecord['trainedMuscles'], ['chest', 'arms']);
        expect(benchRecord['totalSets'], 2);

        final ex =
            (benchRecord['exercises'] as List).first as Map<String, dynamic>;
        expect(ex['exerciseId'], 'bench-press');
        expect(ex['completedSets'], 2);
        expect(ex['maxWeight'], 82.5);

        final sets = ex['sets'] as List<dynamic>;
        expect(sets.length, 2);
        expect((sets[0] as Map)['reps'], 8);
        expect((sets[0] as Map)['weight'], 80.0);
        expect((sets[1] as Map)['reps'], 6);
        expect((sets[1] as Map)['weight'], 82.5);
      },
    );

    test('range.from == range.to filters records to a single day', () {
      final result = service.export(
        from: DateTime(2026, 7, 27),
        to: DateTime(2026, 7, 27),
        records: sampleRecords(),
        profile: profile,
      );

      final json = _extractJsonBlock(result.markdown)!;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final records = decoded['records'] as List<dynamic>;

      expect(records.length, 1);
      expect((records[0] as Map)['date'], '2026-07-27');
    });

    test('handles empty records list without throwing', () {
      final result = service.export(
        from: from,
        to: to,
        records: <dynamic>[],
        profile: profile,
      );

      expect(result.markdown, isNotEmpty);
      final json = _extractJsonBlock(result.markdown)!;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect((decoded['records'] as List).length, 0);
      expect((decoded['summary'] as Map)['sessionCount'], 0);
    });

    test(
      'records are emitted in reverse-chronological order (newest first)',
      () {
        final result = service.export(
          from: from,
          to: to,
          records: sampleRecords(),
          profile: profile,
        );

        final json = _extractJsonBlock(result.markdown)!;
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        final records = decoded['records'] as List<dynamic>;

        final dates = records.map((r) => (r as Map)['date'] as String).toList();
        final sortedDesc = List<String>.from(dates)
          ..sort((a, b) => b.compareTo(a));
        expect(dates, sortedDesc);
      },
    );
  });
}

/// Extracts the contents of the first ```json fenced code block in [markdown].
/// Returns null if no such block exists.
String? _extractJsonBlock(String markdown) {
  final start = markdown.indexOf('```json');
  if (start < 0) return null;
  final afterFence = markdown.indexOf('\n', start) + 1;
  final end = markdown.indexOf('```', afterFence);
  if (end < 0) return null;
  return markdown.substring(afterFence, end).trim();
}
