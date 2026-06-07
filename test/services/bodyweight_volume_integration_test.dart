import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/services/bodyweight_coefficient_service.dart';
import '../helpers/test_fixtures.dart';

void main() {
  // ============================================================
  // Fixtures: exercises with IDs matching the coefficient map
  // ============================================================

  // Pushups: id='Pushups', coefficient=0.64
  final pushups = Exercise(
    id: 'Pushups',
    name: '俯卧撑',
    nameEn: 'Push-ups',
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: [SecondaryMuscleGroup.triceps],
    equipment: 'body only',
    level: 'beginner',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 10,
      maxReps: 20,
      restSeconds: 60,
    ),
  );

  // Pullups: id='Pullups', coefficient=0.70
  final pullups = Exercise(
    id: 'Pullups',
    name: '引体向上',
    nameEn: 'Pull-ups',
    primaryMuscle: PrimaryMuscleGroup.back,
    secondaryMuscles: [SecondaryMuscleGroup.biceps],
    equipment: 'body only',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 6,
      maxReps: 12,
      restSeconds: 90,
    ),
  );

  // Bodyweight Squat: id='Bodyweight_Squat', coefficient=1.00
  final bodyweightSquat = Exercise(
    id: 'Bodyweight_Squat',
    name: '自重深蹲',
    nameEn: 'Bodyweight Squat',
    primaryMuscle: PrimaryMuscleGroup.legs,
    secondaryMuscles: [SecondaryMuscleGroup.glutes],
    equipment: 'body only',
    level: 'beginner',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 15,
      maxReps: 25,
      restSeconds: 60,
    ),
  );

  // Weighted exercise from existing fixtures
  final benchPress = findExerciseByName('Barbell Bench Press')!;

  const bodyWeight = 70.0;

  group('bodyweightAdjustedVolume integration', () {
    // ----------------------------------------------------------
    // T1: Single bodyweight exercise returns non-zero volume
    // Pushups: coeff=0.64, eqWeight=70*0.64=44.8
    // 3 sets × 10 reps × 44.8 = 1344.0
    // ----------------------------------------------------------
    test('bodyweight exercise with weight=0 returns non-zero volume', () {
      final recorded = RecordedExercise(
        exerciseId: pushups.id,
        exercise: pushups,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 0),
          SetData(setNumber: 2, reps: 10, weight: 0),
          SetData(setNumber: 3, reps: 10, weight: 0),
        ],
      );

      expect(
        recorded.bodyweightAdjustedVolume(bodyWeight),
        closeTo(1344.0, 0.01),
      );
    });

    // ----------------------------------------------------------
    // T2: totalVolume ≠ bodyweightAdjustedVolume for bodyweight
    // ----------------------------------------------------------
    test('totalVolume and bodyweightAdjustedVolume differ for bodyweight', () {
      final recorded = RecordedExercise(
        exerciseId: pullups.id,
        exercise: pullups,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 8, weight: 0),
          SetData(setNumber: 2, reps: 8, weight: 0),
          SetData(setNumber: 3, reps: 8, weight: 0),
        ],
      );

      // totalVolume = 3 × 8 × 0 = 0
      expect(recorded.totalVolume, 0.0);

      // Pullups coeff=0.70, eqWeight=70*0.70=49
      // 3 × 8 × 49 = 1176
      expect(
        recorded.bodyweightAdjustedVolume(bodyWeight),
        closeTo(1176.0, 0.01),
      );
      expect(
        recorded.bodyweightAdjustedVolume(bodyWeight),
        isNot(equals(recorded.totalVolume)),
      );
    });

    // ----------------------------------------------------------
    // T3: Coefficient lookup with exercises in the map
    // ----------------------------------------------------------
    test('coefficient lookup uses exact map value, not default', () {
      expect(BodyweightCoefficientService.getCoefficient(pushups), 0.64);
      expect(BodyweightCoefficientService.getCoefficient(pullups), 0.70);
      expect(
        BodyweightCoefficientService.getCoefficient(bodyweightSquat),
        1.00,
      );
    });

    test('unmapped bodyweight exercise falls back to default 0.50', () {
      final unknown = Exercise(
        id: 'custom_bodyweight_exercise',
        name: '自定义自重',
        nameEn: 'Custom Bodyweight',
        primaryMuscle: PrimaryMuscleGroup.chest,
        secondaryMuscles: [],
        equipment: 'body only',
        level: 'beginner',
        recommendation: const ExerciseRecommendation(
          recommendedSets: 3,
          minReps: 10,
          maxReps: 15,
          restSeconds: 60,
        ),
      );

      expect(
        BodyweightCoefficientService.getCoefficient(unknown),
        BodyweightCoefficientService.defaultCoefficient,
      );
    });

    // ----------------------------------------------------------
    // T4: Mixed WorkoutRecord — bodyweight + weighted exercises
    // ----------------------------------------------------------
    test('WorkoutRecord with mixed exercises computes volume correctly', () {
      final record = WorkoutRecord(
        id: 'test-record-001',
        date: DateTime(2026, 6, 3),
        durationSeconds: 3600,
        trainedMuscles: [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.back],
        exercises: [
          // Bodyweight: pushups, 3 sets × 10 reps, weight=0
          RecordedExercise(
            exerciseId: pushups.id,
            exercise: pushups,
            completedSets: 3,
            setsData: [
              SetData(setNumber: 1, reps: 10, weight: 0),
              SetData(setNumber: 2, reps: 10, weight: 0),
              SetData(setNumber: 3, reps: 10, weight: 0),
            ],
          ),
          // Weighted: bench press, 3 sets × 10 reps × 50kg
          RecordedExercise(
            exerciseId: benchPress.id,
            exercise: benchPress,
            completedSets: 3,
            setsData: [
              SetData(setNumber: 1, reps: 10, weight: 50),
              SetData(setNumber: 2, reps: 10, weight: 50),
              SetData(setNumber: 3, reps: 10, weight: 50),
            ],
          ),
        ],
        totalSets: 6,
        createdAt: DateTime(2026, 6, 3),
      );

      // Pushups: coeff=0.64, eqWeight=44.8
      // adjusted = 3 × 10 × 44.8 = 1344
      expect(
        record.exercises[0].bodyweightAdjustedVolume(bodyWeight),
        closeTo(1344.0, 0.01),
      );

      // Bench press: weighted, so bodyweightAdjustedVolume == totalVolume
      // totalVolume = 3 × 10 × 50 = 1500
      expect(record.exercises[1].totalVolume, 1500.0);
      expect(record.exercises[1].bodyweightAdjustedVolume(bodyWeight), 1500.0);

      // Sum of all bodyweightAdjustedVolume: 1344 + 1500 = 2844
      final totalAdjusted = record.exercises.fold<double>(
        0.0,
        (sum, e) => sum + e.bodyweightAdjustedVolume(bodyWeight),
      );
      expect(totalAdjusted, closeTo(2844.0, 0.01));

      // Sum of all totalVolume (without bodyweight adjustment): 0 + 1500 = 1500
      final totalRaw = record.exercises.fold<double>(
        0.0,
        (sum, e) => sum + e.totalVolume,
      );
      expect(totalRaw, 1500.0);

      // Bodyweight exercises contribute extra volume
      expect(totalAdjusted, greaterThan(totalRaw));
    });

    // ----------------------------------------------------------
    // T5: Bodyweight with additional weight (weighted vest)
    // Dips: coeff=0.85, eqWeight=70*0.85=59.5 + 10 = 69.5
    // 3 sets × 10 reps × 69.5 = 2085
    // ----------------------------------------------------------
    test('bodyweight exercise with additional weight adds correctly', () {
      final dips = Exercise(
        id: 'Dips_-_Triceps_Version',
        name: '双杠臂屈伸',
        nameEn: 'Dips',
        primaryMuscle: PrimaryMuscleGroup.arms,
        secondaryMuscles: [SecondaryMuscleGroup.lowerChest],
        equipment: 'body only',
        level: 'intermediate',
        recommendation: const ExerciseRecommendation(
          recommendedSets: 3,
          minReps: 8,
          maxReps: 12,
          restSeconds: 90,
        ),
      );

      final recorded = RecordedExercise(
        exerciseId: dips.id,
        exercise: dips,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 10), // 10kg added
          SetData(setNumber: 2, reps: 10, weight: 10),
          SetData(setNumber: 3, reps: 10, weight: 10),
        ],
      );

      // coeff=0.85, eqWeight=70*0.85+10=69.5
      // 3 × 10 × 69.5 = 2085
      expect(
        recorded.bodyweightAdjustedVolume(bodyWeight),
        closeTo(2085.0, 0.01),
      );

      // Raw totalVolume = 3 × 10 × 10 = 300
      expect(recorded.totalVolume, 300.0);
    });

    // ----------------------------------------------------------
    // T6: Full WorkoutRecord with multiple bodyweight exercises
    // Pushups(0.64) + Pullups(0.70) + BodyweightSquat(1.00)
    // ----------------------------------------------------------
    test(
      'full WorkoutRecord with multiple bodyweight exercises sums correctly',
      () {
        final record = WorkoutRecord(
          id: 'test-record-002',
          date: DateTime(2026, 6, 3),
          durationSeconds: 2700,
          trainedMuscles: [
            PrimaryMuscleGroup.chest,
            PrimaryMuscleGroup.back,
            PrimaryMuscleGroup.legs,
          ],
          exercises: [
            RecordedExercise(
              exerciseId: pushups.id,
              exercise: pushups,
              completedSets: 3,
              setsData: [
                SetData(setNumber: 1, reps: 10, weight: 0),
                SetData(setNumber: 2, reps: 10, weight: 0),
                SetData(setNumber: 3, reps: 10, weight: 0),
              ],
            ),
            RecordedExercise(
              exerciseId: pullups.id,
              exercise: pullups,
              completedSets: 3,
              setsData: [
                SetData(setNumber: 1, reps: 8, weight: 0),
                SetData(setNumber: 2, reps: 8, weight: 0),
                SetData(setNumber: 3, reps: 8, weight: 0),
              ],
            ),
            RecordedExercise(
              exerciseId: bodyweightSquat.id,
              exercise: bodyweightSquat,
              completedSets: 3,
              setsData: [
                SetData(setNumber: 1, reps: 15, weight: 0),
                SetData(setNumber: 2, reps: 15, weight: 0),
                SetData(setNumber: 3, reps: 15, weight: 0),
              ],
            ),
          ],
          totalSets: 9,
          createdAt: DateTime(2026, 6, 3),
        );

        // Pushups: 3×10×(70*0.64) = 3×10×44.8 = 1344
        // Pullups: 3×8×(70*0.70) = 3×8×49 = 1176
        // Squat:   3×15×(70*1.00) = 3×15×70 = 3150
        // Total adjusted: 1344 + 1176 + 3150 = 5670
        final totalAdjusted = record.exercises.fold<double>(
          0.0,
          (sum, e) => sum + e.bodyweightAdjustedVolume(bodyWeight),
        );
        expect(totalAdjusted, closeTo(5670.0, 0.01));

        // Raw totalVolume: all weight=0 → 0
        final totalRaw = record.exercises.fold<double>(
          0.0,
          (sum, e) => sum + e.totalVolume,
        );
        expect(totalRaw, 0.0);

        // All exercises are bodyweight
        expect(totalAdjusted, greaterThan(totalRaw));
      },
    );

    // ----------------------------------------------------------
    // T7: No exercise object → fallback to totalVolume
    // ----------------------------------------------------------
    test('returns totalVolume when exercise is null', () {
      final recorded = RecordedExercise(
        exerciseId: 'unknown_id',
        exercise: null,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 20),
          SetData(setNumber: 2, reps: 10, weight: 20),
          SetData(setNumber: 3, reps: 10, weight: 20),
        ],
      );

      // No exercise attached → cannot determine bodyweight status
      expect(
        recorded.bodyweightAdjustedVolume(bodyWeight),
        recorded.totalVolume,
      );
      expect(recorded.bodyweightAdjustedVolume(bodyWeight), 600.0);
    });

    // ----------------------------------------------------------
    // T8: JSON round-trip preserves setsData for volume calc
    // ----------------------------------------------------------
    test('JSON round-trip preserves bodyweight volume calculation', () {
      final original = RecordedExercise(
        exerciseId: pushups.id,
        exercise: pushups,
        completedSets: 3,
        setsData: [
          SetData(setNumber: 1, reps: 10, weight: 0),
          SetData(setNumber: 2, reps: 10, weight: 0),
          SetData(setNumber: 3, reps: 10, weight: 0),
        ],
      );

      final json = original.toJson();
      final restored = RecordedExercise.fromJson(
        json,
      ).copyWith(exercise: pushups);

      expect(
        restored.bodyweightAdjustedVolume(bodyWeight),
        closeTo(1344.0, 0.01),
      );
      expect(
        restored.bodyweightAdjustedVolume(bodyWeight),
        original.bodyweightAdjustedVolume(bodyWeight),
      );
    });

    // ----------------------------------------------------------
    // T9: setsData is null → fallback to completedSets * maxWeight
    // For bodyweight with no setsData and maxWeight=0 → volume=0
    // ----------------------------------------------------------
    test('null setsData falls back to completedSets formula', () {
      final recorded = RecordedExercise(
        exerciseId: pushups.id,
        exercise: pushups,
        completedSets: 3,
        maxWeight: 0,
        setsData: null,
      );

      // No setsData → bodyweightAdjustedVolume returns totalVolume
      // totalVolume = completedSets * maxWeight = 3 * 0 = 0
      expect(recorded.bodyweightAdjustedVolume(bodyWeight), 0.0);
      expect(recorded.totalVolume, 0.0);
    });

    // ----------------------------------------------------------
    // T10: Verify different body weights produce proportional results
    // ----------------------------------------------------------
    test('different body weights produce proportional volume', () {
      final recorded = RecordedExercise(
        exerciseId: pushups.id,
        exercise: pushups,
        completedSets: 1,
        setsData: [SetData(setNumber: 1, reps: 10, weight: 0)],
      );

      // 60kg: 10 × (60*0.64) = 384
      expect(recorded.bodyweightAdjustedVolume(60.0), closeTo(384.0, 0.01));

      // 70kg: 10 × (70*0.64) = 448
      expect(recorded.bodyweightAdjustedVolume(70.0), closeTo(448.0, 0.01));

      // 80kg: 10 × (80*0.64) = 512
      expect(recorded.bodyweightAdjustedVolume(80.0), closeTo(512.0, 0.01));

      // Proportional check: 70/60 × 384 = 448 ✓
      expect(
        recorded.bodyweightAdjustedVolume(70.0) /
            recorded.bodyweightAdjustedVolume(60.0),
        closeTo(70.0 / 60.0, 0.001),
      );
    });
  });
}
