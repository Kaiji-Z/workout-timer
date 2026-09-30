import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/services/exercise_history_service.dart';

void main() {
  Exercise ex(String id, String name, String nameEn) => Exercise(
        id: id,
        name: name,
        nameEn: nameEn,
        primaryMuscle: PrimaryMuscleGroup.chest,
        secondaryMuscles: [],
        equipment: 'barbell',
        level: 'intermediate',
        recommendation: const ExerciseRecommendation(
          recommendedSets: 3,
          minReps: 8,
          maxReps: 12,
          restSeconds: 60,
        ),
      );

  WorkoutRecord rec(String id, DateTime date,
      {List<RecordedExercise> exercises = const []}) {
    return WorkoutRecord(
      id: id,
      date: date,
      durationSeconds: 1800,
      trainedMuscles: const [],
      exercises: exercises,
      totalSets: 0,
      createdAt: date,
    );
  }

  RecordedExercise withSets(Exercise exercise, List<SetData> sets) =>
      RecordedExercise(
        exerciseId: exercise.id,
        exercise: exercise,
        completedSets: sets.length,
        setsData: sets,
      );

  final bench = ex('bench', '杠铃卧推', 'Barbell Bench Press');
  final squat = ex('squat', '杠铃深蹲', 'Barbell Squat');

  group('searchExerciseHistory', () {
    test('empty or blank query returns nothing', () {
      final records = [
        rec('a', DateTime(2026, 9, 1),
            exercises: [withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 80)])]),
      ];
      expect(searchExerciseHistory(records, ''), isEmpty);
      expect(searchExerciseHistory(records, '   '), isEmpty);
    });

    test('matches Chinese name substring', () {
      final records = [
        rec('a', DateTime(2026, 9, 1),
            exercises: [withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 80)])]),
      ];
      final results = searchExerciseHistory(records, '卧推');
      expect(results, hasLength(1));
      expect(results.first.exerciseName, '杠铃卧推');
    });

    test('matches English name case-insensitively', () {
      final records = [
        rec('a', DateTime(2026, 9, 1),
            exercises: [withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 80)])]),
      ];
      expect(searchExerciseHistory(records, 'BENCH'), hasLength(1));
      expect(searchExerciseHistory(records, 'barbell squat'), isEmpty);
      // 同一记录里另一个动作能被自己的英文名命中
      final both = [
        rec('a', DateTime(2026, 9, 1), exercises: [
          withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 80)]),
          withSets(squat, const [SetData(setNumber: 1, reps: 5, weight: 100)]),
        ]),
      ];
      expect(searchExerciseHistory(both, 'squat'), hasLength(1));
      expect(searchExerciseHistory(both, '杠铃'), hasLength(2));
    });

    test('best set is the one with highest estimated 1RM', () {
      final records = [
        rec('a', DateTime(2026, 9, 1), exercises: [
          withSets(bench, const [
            SetData(setNumber: 1, reps: 10, weight: 50),
            SetData(setNumber: 2, reps: 5, weight: 100), // 明显更高的 e1RM
            SetData(setNumber: 3, reps: 10, weight: 50),
          ]),
        ]),
      ];
      final results = searchExerciseHistory(records, '卧推');
      expect(results.first.bestWeight, 100);
      expect(results.first.bestReps, 5);
      expect(results.first.bestE1RM, isNotNull);
    });

    test('entry included with null best when no valid per-set data', () {
      final records = [
        rec('a', DateTime(2026, 9, 1), exercises: [
          withSets(bench, const [
            SetData(setNumber: 1, reps: null, weight: null), // 无效组
          ]),
        ]),
      ];
      final results = searchExerciseHistory(records, '卧推');
      expect(results, hasLength(1));
      expect(results.first.bestWeight, isNull);
      expect(results.first.bestE1RM, isNull);
    });

    test('results sorted by record date descending', () {
      final records = [
        rec('old', DateTime(2026, 1, 1),
            exercises: [withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 60)])]),
        rec('new', DateTime(2026, 9, 1),
            exercises: [withSets(bench, const [SetData(setNumber: 1, reps: 5, weight: 100)])]),
      ];
      final results = searchExerciseHistory(records, '卧推');
      expect(results.map((e) => e.record.id), ['new', 'old']);
    });

    test('exercises without a loaded reference are skipped', () {
      final records = [
        rec('a', DateTime(2026, 9, 1), exercises: [
          RecordedExercise(exerciseId: 'x', completedSets: 3),
        ]),
      ];
      expect(searchExerciseHistory(records, '卧推'), isEmpty);
    });
  });
}
