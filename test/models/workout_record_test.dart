import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/set_data.dart';

void main() {
  group('RecordedExercise', () {
    group('setsData serialization', () {
      test('toJson includes sets_data when setsData is not null', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0),
            SetData(setNumber: 2, reps: 8, weight: 50.0),
            SetData(setNumber: 3, reps: 6, weight: 55.0),
          ],
        );

        final json = exercise.toJson();

        expect(json.containsKey('sets_data'), isTrue);
        expect(json['sets_data'], isNotNull);

        // Verify it can be decoded
        final decoded = jsonDecode(json['sets_data'] as String) as List;
        expect(decoded.length, 3);
        expect(decoded[0]['set_number'], 1);
        expect(decoded[0]['reps'], 10);
        expect(decoded[0]['weight'], 45.0);
      });

      test('toJson sets sets_data to null when setsData is null', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: null,
        );

        final json = exercise.toJson();

        expect(json['sets_data'], isNull);
      });

      test('fromJson parses sets_data correctly', () {
        final setsJson = jsonEncode([
          {'set_number': 1, 'reps': 10, 'weight': 45.0},
          {'set_number': 2, 'reps': 8, 'weight': 50.0},
        ]);

        final json = {
          'exerciseId': 'ex-001',
          'completedSets': 2,
          'maxWeight': 50.0,
          'sets_data': setsJson,
        };

        final exercise = RecordedExercise.fromJson(json);

        expect(exercise.setsData, isNotNull);
        expect(exercise.setsData!.length, 2);
        expect(exercise.setsData![0].setNumber, 1);
        expect(exercise.setsData![0].reps, 10);
        expect(exercise.setsData![0].weight, 45.0);
        expect(exercise.setsData![1].setNumber, 2);
      });

      test('fromJson handles null sets_data', () {
        final json = {
          'exerciseId': 'ex-001',
          'completedSets': 3,
          'maxWeight': 50.0,
          'sets_data': null,
        };

        final exercise = RecordedExercise.fromJson(json);

        expect(exercise.setsData, isNull);
      });

      test('toMap includes per_set_data for database storage', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 2,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0),
            SetData(setNumber: 2, reps: 8, weight: 50.0),
          ],
        );

        final map = exercise.toMap('record-001');

        expect(map.containsKey('per_set_data'), isTrue);
        expect(map['per_set_data'], isNotNull);

        final decoded = jsonDecode(map['per_set_data'] as String) as List;
        expect(decoded.length, 2);
      });

      test('fromMap parses per_set_data correctly', () {
        final setsJson = jsonEncode([
          {'set_number': 1, 'reps': 12, 'weight': 40.0},
          {'set_number': 2, 'reps': 10, 'weight': 45.0},
        ]);

        final map = {
          'exercise_id': 'ex-001',
          'completed_sets': 2,
          'max_weight': 45.0,
          'per_set_data': setsJson,
        };

        final exercise = RecordedExercise.fromMap(map);

        expect(exercise.setsData, isNotNull);
        expect(exercise.setsData!.length, 2);
        expect(exercise.setsData![0].reps, 12);
        expect(exercise.setsData![1].weight, 45.0);
      });

      test('fromMap handles null per_set_data', () {
        final map = {
          'exercise_id': 'ex-001',
          'completed_sets': 3,
          'max_weight': 50.0,
          'per_set_data': null,
        };

        final exercise = RecordedExercise.fromMap(map);

        expect(exercise.setsData, isNull);
      });
    });

    group('totalVolume calculation', () {
      test('sums volume from all sets when setsData is available', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0), // 450
            SetData(setNumber: 2, reps: 8, weight: 50.0), // 400
            SetData(setNumber: 3, reps: 6, weight: 55.0), // 330
          ],
        );

        expect(exercise.totalVolume, 1180.0);
      });

      test('returns 0 when setsData is empty', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 0,
          maxWeight: 50.0,
          setsData: [],
        );

        expect(exercise.totalVolume, 0.0);
      });

      test('falls back to completedSets × maxWeight when setsData is null', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: null,
        );

        expect(exercise.totalVolume, 150.0); // 3 × 50
      });

      test('returns 0 when setsData is null and maxWeight is null', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: null,
          setsData: null,
        );

        expect(exercise.totalVolume, 0.0);
      });

      test('handles sets with null reps or weight in setsData', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0), // 450
            SetData(setNumber: 2, reps: null, weight: 50.0), // 0
            SetData(setNumber: 3, reps: 6, weight: null), // 0
          ],
        );

        expect(exercise.totalVolume, 450.0);
      });
    });

    group('backward compatibility (null setsData)', () {
      test('fromJson without sets_data field works correctly', () {
        final json = {
          'exerciseId': 'ex-001',
          'completedSets': 3,
          'maxWeight': 50.0,
          // No sets_data field
        };

        final exercise = RecordedExercise.fromJson(json);

        expect(exercise.exerciseId, 'ex-001');
        expect(exercise.completedSets, 3);
        expect(exercise.maxWeight, 50.0);
        expect(exercise.setsData, isNull);
      });

      test('fromMap without per_set_data field works correctly', () {
        final map = {
          'exercise_id': 'ex-001',
          'completed_sets': 3,
          'max_weight': 50.0,
          // No per_set_data field
        };

        final exercise = RecordedExercise.fromMap(map);

        expect(exercise.exerciseId, 'ex-001');
        expect(exercise.completedSets, 3);
        expect(exercise.maxWeight, 50.0);
        expect(exercise.setsData, isNull);
      });

      test('old records can still calculate totalVolume via fallback', () {
        // Simulate an old record without setsData
        final json = {
          'exerciseId': 'ex-001',
          'completedSets': 4,
          'maxWeight': 60.0,
        };

        final exercise = RecordedExercise.fromJson(json);

        // Should use fallback calculation
        expect(exercise.totalVolume, 240.0); // 4 × 60
      });
    });

    group('copyWith with setsData', () {
      test('preserves setsData when not provided', () {
        final original = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0),
          ],
        );

        final copy = original.copyWith(maxWeight: 55.0);

        expect(copy.setsData, isNotNull);
        expect(copy.setsData!.length, 1);
        expect(copy.maxWeight, 55.0);
      });

      test('can update setsData', () {
        final original = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 2,
          maxWeight: 40.0,
          setsData: null,
        );

        final copy = original.copyWith(
          setsData: [
            SetData(setNumber: 1, reps: 12, weight: 45.0),
            SetData(setNumber: 2, reps: 10, weight: 50.0),
          ],
        );

        expect(copy.setsData, isNotNull);
        expect(copy.setsData!.length, 2);
      });
    });

    group('roundtrip serialization', () {
      test('toJson/fromJson preserves all data', () {
        final original = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 3,
          maxWeight: 55.5,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 45.0),
            SetData(setNumber: 2, reps: 8, weight: 50.0),
            SetData(setNumber: 3, reps: 6, weight: 55.0),
          ],
        );

        final json = original.toJson();
        final restored = RecordedExercise.fromJson(json);

        expect(restored.exerciseId, original.exerciseId);
        expect(restored.completedSets, original.completedSets);
        expect(restored.maxWeight, original.maxWeight);
        expect(restored.setsData!.length, original.setsData!.length);
        expect(restored.totalVolume, original.totalVolume);
      });

      test('toMap/fromMap preserves all data', () {
        final original = RecordedExercise(
          exerciseId: 'ex-001',
          completedSets: 2,
          maxWeight: 50.0,
          setsData: [
            SetData(setNumber: 1, reps: 12, weight: 40.0),
            SetData(setNumber: 2, reps: 10, weight: 45.0),
          ],
        );

        final map = original.toMap('record-123');
        final restored = RecordedExercise.fromMap(map);

        expect(restored.exerciseId, original.exerciseId);
        expect(restored.completedSets, original.completedSets);
        expect(restored.maxWeight, original.maxWeight);
        expect(restored.setsData!.length, original.setsData!.length);
      });
    });

    group('migration', () {
      test('needsMigration returns true for legacy record with null setsData', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 3,
          maxWeight: 60.0,
          setsData: null,
        );
        expect(legacy.needsMigration, isTrue);
      });

      test('needsMigration returns true for legacy record with empty setsData', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 3,
          maxWeight: 60.0,
          setsData: [],
        );
        expect(legacy.needsMigration, isTrue);
      });

      test('needsMigration returns false for modern record with setsData', () {
        final modern = RecordedExercise(
          exerciseId: 'test',
          completedSets: 3,
          setsData: [SetData(setNumber: 1, reps: 10, weight: 60.0)],
        );
        expect(modern.needsMigration, isFalse);
      });

      test('needsMigration returns false when completedSets is zero', () {
        final empty = RecordedExercise(
          exerciseId: 'test',
          completedSets: 0,
          setsData: null,
        );
        expect(empty.needsMigration, isFalse);
      });

      test('migrateToSetData creates correct number of sets', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 4,
          maxWeight: 50.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.setsData, isNotNull);
        expect(migrated.setsData!.length, equals(4));
      });

      test('migrateToSetData preserves maxWeight in all sets', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 2,
          maxWeight: 80.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.setsData![0].weight, equals(80.0));
        expect(migrated.setsData![1].weight, equals(80.0));
      });

      test('migrateToSetData sets correct set numbers', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 3,
          maxWeight: 50.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.setsData![0].setNumber, equals(1));
        expect(migrated.setsData![1].setNumber, equals(2));
        expect(migrated.setsData![2].setNumber, equals(3));
      });

      test('migrateToSetData sets reps to null for migrated sets', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 2,
          maxWeight: 60.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.setsData![0].reps, isNull);
        expect(migrated.setsData![1].reps, isNull);
      });

      test('migrateToSetData preserves exerciseId', () {
        final legacy = RecordedExercise(
          exerciseId: 'barbell-bench-press',
          completedSets: 3,
          maxWeight: 100.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.exerciseId, equals('barbell-bench-press'));
      });

      test('migrateToSetData preserves completedSets and maxWeight', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 5,
          maxWeight: 75.5,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.completedSets, equals(5));
        expect(migrated.maxWeight, equals(75.5));
      });

      test('migrateToSetData returns self when migration not needed', () {
        final modern = RecordedExercise(
          exerciseId: 'test',
          completedSets: 3,
          setsData: [SetData(setNumber: 1, reps: 10, weight: 60.0)],
        );
        final result = modern.migrateToSetData();
        // Should return same instance since no migration needed
        expect(identical(result, modern), isTrue);
      });

      test('migrateToSetData handles null maxWeight', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 2,
          maxWeight: null,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        expect(migrated.setsData!.length, equals(2));
        expect(migrated.setsData![0].weight, isNull);
        expect(migrated.setsData![1].weight, isNull);
      });

      test('migrated record can be serialized and deserialized', () {
        final legacy = RecordedExercise(
          exerciseId: 'test',
          completedSets: 2,
          maxWeight: 50.0,
          setsData: null,
        );
        final migrated = legacy.migrateToSetData();
        final json = migrated.toJson();
        final restored = RecordedExercise.fromJson(json);

        expect(restored.setsData, isNotNull);
        expect(restored.setsData!.length, equals(2));
        expect(restored.setsData![0].weight, equals(50.0));
        expect(restored.needsMigration, isFalse);
      });
    });
  });
}
