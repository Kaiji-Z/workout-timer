import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import '../helpers/test_fixtures.dart';

void main() {
  // Pull-up from fixtures: equipment='body only', so isBodyweight=true
  // Coefficient: not in _coefficientMap → defaultCoefficient = 0.50
  // equivalentWeight = 70 * 0.50 = 35
  // 10 reps × 35 = 350.0
  final bodyweightExercise = findExerciseByName('Pull-up')!;

  // Barbell bench press: equipment='barbell', NOT bodyweight
  final weightedExercise = findExerciseByName('Barbell Bench Press')!;

  group('bodyweightAdjustedVolume', () {
    test('returns non-zero volume for bodyweight exercise with weight=0', () {
      final recorded = RecordedExercise(
        exerciseId: bodyweightExercise.id,
        exercise: bodyweightExercise,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 0),
          SetData(setNumber: 2, reps: 10, weight: 0),
          SetData(setNumber: 3, reps: 10, weight: 0),
        ],
      );

      // bodyweight=70, coefficient=0.50 → eqWeight=35
      // 3 sets × 10 reps × 35 = 1050
      expect(recorded.bodyweightAdjustedVolume(70.0), 1050.0);
    });

    test('totalVolume still returns raw reps×weight (backward compat)', () {
      final recorded = RecordedExercise(
        exerciseId: bodyweightExercise.id,
        exercise: bodyweightExercise,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 0),
          SetData(setNumber: 2, reps: 10, weight: 0),
          SetData(setNumber: 3, reps: 10, weight: 0),
        ],
      );

      // Raw volume must remain 0 — this getter must NOT be changed
      expect(recorded.totalVolume, 0.0);
    });

    test('returns same as totalVolume for non-bodyweight exercise', () {
      final recorded = RecordedExercise(
        exerciseId: weightedExercise.id,
        exercise: weightedExercise,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 50),
          SetData(setNumber: 2, reps: 10, weight: 50),
          SetData(setNumber: 3, reps: 10, weight: 50),
        ],
      );

      // Non-bodyweight: should ignore bodyWeight param, return raw volume
      expect(recorded.bodyweightAdjustedVolume(70.0), recorded.totalVolume);
      expect(recorded.bodyweightAdjustedVolume(70.0), 1500.0);
    });

    test('returns totalVolume when bodyWeight is 0', () {
      final recorded = RecordedExercise(
        exerciseId: bodyweightExercise.id,
        exercise: bodyweightExercise,
        completedSets: 1,
        setsData: [SetData(setNumber: 1, reps: 10, weight: 0)],
      );

      // No bodyweight data → fallback to raw volume (0)
      expect(recorded.bodyweightAdjustedVolume(0), recorded.totalVolume);
      expect(recorded.bodyweightAdjustedVolume(0), 0.0);
    });

    test('returns totalVolume when bodyWeight is null', () {
      final recorded = RecordedExercise(
        exerciseId: bodyweightExercise.id,
        exercise: bodyweightExercise,
        completedSets: 1,
        setsData: [SetData(setNumber: 1, reps: 10, weight: 0)],
      );

      // null bodyWeight → fallback to raw volume (0)
      expect(recorded.bodyweightAdjustedVolume(null), recorded.totalVolume);
      expect(recorded.bodyweightAdjustedVolume(null), 0.0);
    });
  });
}
