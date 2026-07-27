import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/services/bodyweight_coefficient_service.dart';

void main() {
  /// Helper: minimal Exercise fixture with given id + equipment.
  Exercise ex({
    required String id,
    String equipment = 'Body Only',
    PrimaryMuscleGroup muscle = PrimaryMuscleGroup.chest,
  }) {
    return Exercise(
      id: id,
      name: id,
      nameEn: id,
      primaryMuscle: muscle,
      secondaryMuscles: const [],
      equipment: equipment,
      level: 'Beginner',
      recommendation: const ExerciseRecommendation(
        recommendedSets: 3,
        minReps: 8,
        maxReps: 12,
        restSeconds: 60,
      ),
    );
  };

  group('BodyweightCoefficientService.isBodyweightExercise', () {
    test('returns false for null', () {
      expect(BodyweightCoefficientService.isBodyweightExercise(null), isFalse);
    });

    test('recognises "body only" case-insensitively', () {
      expect(
        BodyweightCoefficientService.isBodyweightExercise(
          ex(id: 'x', equipment: 'Body Only'),
        ),
        isTrue,
      );
      expect(
        BodyweightCoefficientService.isBodyweightExercise(
          ex(id: 'x', equipment: 'BODY ONLY'),
        ),
        isTrue,
      );
    });

    test('recognises "bodyweight" and "none" aliases', () {
      expect(
        BodyweightCoefficientService.isBodyweightExercise(
          ex(id: 'x', equipment: 'bodyweight'),
        ),
        isTrue,
      );
      expect(
        BodyweightCoefficientService.isBodyweightExercise(
          ex(id: 'x', equipment: 'none'),
        ),
        isTrue,
      );
    });

    test('treats empty equipment as bodyweight', () {
      expect(
        BodyweightCoefficientService.isBodyweightExercise(
          ex(id: 'x', equipment: ''),
        ),
        isTrue,
      );
    });

    test('returns false for weighted equipment', () {
      for (final eq in ['Barbell', 'Dumbbell', 'Cable', 'Machine', 'Kettlebell']) {
        expect(
          BodyweightCoefficientService.isBodyweightExercise(
            ex(id: 'x', equipment: eq),
          ),
          isFalse,
          reason: '$eq should not be classified as bodyweight',
        );
      }
    });
  });

  group('BodyweightCoefficientService.getCoefficient', () {
    test('returns 0.0 for null exercise', () {
      expect(BodyweightCoefficientService.getCoefficient(null), 0.0);
    });

    test('returns the mapped coefficient for a known exercise', () {
      // 'Pushups' is mapped to 0.64 in the table.
      expect(
        BodyweightCoefficientService.getCoefficient(ex(id: 'Pushups')),
        0.64,
      );
      // 'Bodyweight_Squat' is mapped to 1.00.
      expect(
        BodyweightCoefficientService.getCoefficient(ex(id: 'Bodyweight_Squat')),
        1.00,
      );
    });

    test('falls back to defaultCoefficient for unknown ids', () {
      expect(
        BodyweightCoefficientService.getCoefficient(ex(id: 'Unknown_Exercise')),
        BodyweightCoefficientService.defaultCoefficient,
      );
    });

    test('defaultCoefficient itself stays in plausible biomech range', () {
      // No coefficient should be negative or exceed 1.0 (you can't move more
      // than 100% of your body weight in this model). Guard against silent
      // data-entry regressions.
      expect(
        BodyweightCoefficientService.defaultCoefficient,
        inInclusiveRange(0.0, 1.0),
      );
    });
  });

  group('BodyweightCoefficientService.calculateEquivalentWeight', () {
    test('returns additionalWeight when exercise is not bodyweight', () {
      final weighted = ex(id: 'Bench_Press', equipment: 'Barbell');
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: weighted,
          bodyWeight: 75,
          additionalWeight: 60,
        ),
        60.0,
      );
    });

    test('returns additionalWeight when bodyWeight is zero or negative', () {
      final pushup = ex(id: 'Pushups', equipment: 'Body Only');
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: pushup,
          bodyWeight: 0,
          additionalWeight: 10,
        ),
        10.0,
      );
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: pushup,
          bodyWeight: -5,
          additionalWeight: 10,
        ),
        10.0,
      );
    });

    test('computes BW * coefficient + additionalWeight for known push-up', () {
      // 70kg user, push-ups (0.64), +0 additional = 44.8kg
      final pushup = ex(id: 'Pushups', equipment: 'Body Only');
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: pushup,
          bodyWeight: 70,
        ),
        closeTo(44.8, 0.001),
      );
    });

    test('adds weighted-vest load on top of bodyweight load', () {
      // 80kg user, bodyweight squat (1.00), +20kg vest = 100kg
      final squat = ex(id: 'Bodyweight_Squat', equipment: 'Body Only');
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: squat,
          bodyWeight: 80,
          additionalWeight: 20,
        ),
        closeTo(100.0, 0.001),
      );
    });

    test('uses defaultCoefficient for unknown bodyweight exercise', () {
      final unknown = ex(id: 'Mystery_Bodyweight_Move', equipment: 'Body Only');
      expect(
        BodyweightCoefficientService.calculateEquivalentWeight(
          exercise: unknown,
          bodyWeight: 70,
        ),
        closeTo(70 * 0.5, 0.001),
      );
    });
  });

  group('BodyweightCoefficientService load/save body weight', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadBodyWeight returns null when not set', () async {
      expect(await BodyweightCoefficientService.loadBodyWeight(), isNull);
    });

    test('saveBodyWeight persists, loadBodyWeight reads it back', () async {
      await BodyweightCoefficientService.saveBodyWeight(72.5);
      expect(await BodyweightCoefficientService.loadBodyWeight(), 72.5);
    });
  });
}
