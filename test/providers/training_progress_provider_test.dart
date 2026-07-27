import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_plan.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';

void main() {
  /// Build a plan with N exercises, each with the given target sets.
  /// If only one of [exerciseIds] / [targetSets] is given, the other defaults
  /// to a 3-set-per-exercise / e1..eN-id list sized to match.
  WorkoutPlan planFixture({
    String id = 'plan-1',
    String name = 'Test Plan',
    List<String>? exerciseIds,
    List<int>? targetSets,
  }) {
    final int n = (exerciseIds?.length ?? targetSets?.length ?? 3);
    final ids = exerciseIds ??
        List<String>.generate(n, (i) => 'e${i + 1}');
    final sets = targetSets ?? List<int>.filled(n, 3);

    final exercises = <PlanExercise>[];
    for (var i = 0; i < n; i++) {
      exercises.add(PlanExercise(
        exerciseId: ids[i],
        targetSets: sets[i],
        order: i,
      ));
    }
    return WorkoutPlan(
      id: id,
      name: name,
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: exercises,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  late TrainingProgressProvider provider;

  setUp(() {
    provider = TrainingProgressProvider();
  });

  group('TrainingProgressProvider — initial state', () {
    test('has no plan and reports not in plan mode', () {
      expect(provider.currentPlan, isNull);
      expect(provider.isPlanMode, isFalse);
      expect(provider.currentExercise, isNull);
      expect(provider.getNextExercise(), isNull);
      expect(provider.totalCompletedSets, 0);
      expect(provider.totalTargetSets, 0);
      expect(provider.progressPercentage, 0.0);
      expect(provider.isCurrentExerciseComplete, isFalse);
      expect(provider.isAllExercisesComplete, isFalse);
      expect(provider.startTime, isNull);
      expect(provider.trainingDurationSeconds, 0);
    });

    test('currentSetInExercise starts at 0', () {
      expect(provider.currentSetInExercise, 0);
    });

    test('completedSets getter returns an unmodifiable map', () {
      // Without starting a plan the map is empty but still unmodifiable.
      final map = provider.completedSets;
      expect(() => map['x'] = 1, throwsUnsupportedError);
    });

    test('getCompletedSets / getExerciseWeight default to 0 / null', () {
      expect(provider.getCompletedSets('any-id'), 0);
      expect(provider.getExerciseWeight('any-id'), isNull);
      expect(provider.getExerciseSetsData('any-id'), isEmpty);
    });
  });

  group('TrainingProgressProvider.startPlan', () {
    test('stores the plan and records the start time', () {
      final plan = planFixture();
      provider.startPlan(plan);

      expect(provider.currentPlan, same(plan));
      expect(provider.isPlanMode, isTrue);
      expect(provider.startTime, isNotNull);
      expect(provider.currentExerciseIndex, 0);
      expect(provider.currentSetInExercise, 0);
    });

    test('initialises completedSets to 0 for every exercise', () {
      provider.startPlan(planFixture());
      expect(provider.completedSets, {'e1': 0, 'e2': 0, 'e3': 0});
    });

    test('totalTargetSets sums every exercise.effectiveSets', () {
      provider.startPlan(planFixture(targetSets: [3, 4, 5]));
      expect(provider.totalTargetSets, 12);
    });

    test('uses customSets over targetSets when present', () {
      final plan = WorkoutPlan(
        id: 'p',
        name: 'p',
        targetMuscles: const [PrimaryMuscleGroup.chest],
        exercises: [
          PlanExercise(
            exerciseId: 'a',
            targetSets: 5,
            customSets: 2, // overrides
            order: 0,
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
      );
      provider.startPlan(plan);
      expect(provider.totalTargetSets, 2);
    });

    test('clears previous plan state when called twice', () {
      provider
        ..startPlan(planFixture(exerciseIds: ['a', 'b']))
        ..completeSet() // progress a bit
        ..startPlan(planFixture(exerciseIds: ['x', 'y', 'z']));

      // New plan should reset progress.
      expect(provider.completedSets.keys, containsAll(['x', 'y', 'z']));
      expect(provider.completedSets.containsKey('a'), isFalse);
      expect(provider.currentExerciseIndex, 0);
      expect(provider.currentSetInExercise, 0);
    });

    test('notifies listeners', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.startPlan(planFixture());
      expect(notifyCount, 1);
    });
  });

  group('TrainingProgressProvider.completeSet — auto-advance', () {
    test('increments currentSetInExercise within the same exercise', () {
      provider.startPlan(planFixture(targetSets: [3, 3, 3]));
      provider.completeSet();
      expect(provider.currentSetInExercise, 1);
      expect(provider.currentExerciseIndex, 0);
      expect(provider.getCompletedSets('e1'), 1);
    });

    test('auto-advances to next exercise when current finishes', () {
      provider.startPlan(planFixture(targetSets: [3, 3, 3]));
      // 3 sets = fill the first exercise.
      provider.completeSet();
      provider.completeSet();
      provider.completeSet();

      expect(provider.currentExerciseIndex, 1,
          reason: 'should have advanced after 3 sets of e1');
      expect(provider.currentSetInExercise, 0);
      expect(provider.getCompletedSets('e1'), 3);
      expect(provider.getCompletedSets('e2'), 0);
    });

    test('does NOT advance past the last exercise', () {
      // Single-exercise plan, do more sets than target.
      provider.startPlan(planFixture(
        exerciseIds: ['only'],
        targetSets: [2],
      ));
      provider.completeSet();
      provider.completeSet();
      provider.completeSet(); // overflow
      provider.completeSet(); // overflow

      expect(provider.currentExerciseIndex, 0);
      // _currentSetInExercise just keeps incrementing (it's a per-exercise
      // counter, not capped), but currentExerciseIndex must stay put.
      expect(provider.getCompletedSets('only'), 4);
    });

    test('isCurrentExerciseComplete reflects target being met', () {
      provider.startPlan(planFixture(targetSets: [2, 2]));
      expect(provider.isCurrentExerciseComplete, isFalse);
      provider.completeSet();
      expect(provider.isCurrentExerciseComplete, isFalse); // 1 < 2
      provider.completeSet();
      // After the 2nd set, e1 is complete AND we've auto-advanced to e2,
      // so currentExercise is now e2 with 0/2 sets.
      expect(provider.getCompletedSets('e1'), 2);
      expect(provider.isCurrentExerciseComplete, isFalse); // e2: 0/2
    });

    test('isAllExercisesComplete only when every exercise is done', () {
      provider.startPlan(planFixture(targetSets: [2, 2]));
      expect(provider.isAllExercisesComplete, isFalse);
      provider.completeSet();
      provider.completeSet();
      expect(provider.isAllExercisesComplete, isFalse); // e1 done, e2 not
      provider.completeSet();
      provider.completeSet();
      expect(provider.isAllExercisesComplete, isTrue);
    });

    test('progressPercentage updates with each completed set', () {
      provider.startPlan(planFixture(targetSets: [4, 4])); // total = 8
      expect(provider.progressPercentage, 0.0);
      provider.completeSet();
      expect(provider.progressPercentage, closeTo(0.125, 0.001));
      provider.completeSet();
      provider.completeSet();
      provider.completeSet();
      // 4 sets done -> 0.5; auto-advance happened after the 4th set.
      expect(provider.progressPercentage, closeTo(0.5, 0.001));
    });

    test('completeSet is a no-op when no plan is loaded', () {
      // Without a plan, currentExercise is null; completeSet should not throw.
      provider.completeSet();
      expect(provider.totalCompletedSets, 0);
    });
  });

  group('TrainingProgressProvider.getNextExercise', () {
    test('returns the next exercise in plan order', () {
      provider.startPlan(planFixture());
      // currentExercise is e1, next should be e2.
      expect(provider.getNextExercise()?.exerciseId, 'e2');
    });

    test('returns null when on the last exercise', () {
      provider.startPlan(planFixture(exerciseIds: ['x'], targetSets: [3]));
      expect(provider.getNextExercise(), isNull);
    });

    test('returns null when no plan', () {
      expect(provider.getNextExercise(), isNull);
    });
  });

  group('TrainingProgressProvider weight tracking', () {
    test('setWeight stores and getExerciseWeight retrieves', () {
      provider.setWeight('e1', 80.0);
      expect(provider.getExerciseWeight('e1'), 80.0);
    });

    test('getMaxWeight derives from per-set data when present', () {
      provider.addSetData('e1', const SetData(setNumber: 1, reps: 8, weight: 60));
      provider.addSetData('e1', const SetData(setNumber: 2, reps: 6, weight: 80));
      provider.addSetData('e1', const SetData(setNumber: 3, reps: 0, weight: 0));
      expect(provider.getMaxWeight('e1'), 80.0);
    });

    test('getMaxWeight returns null when no sets recorded', () {
      expect(provider.getMaxWeight('e1'), isNull);
    });
  });

  group('TrainingProgressProvider addSetData / replaceSetsData / clear', () {
    test('addSetData appends and notifies', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.addSetData('e1', const SetData(setNumber: 1, reps: 8, weight: 60));
      expect(provider.getExerciseSetsData('e1').length, 1);
      expect(notifyCount, 1);
    });

    test('replaceSetsData overwrites existing per-set list', () {
      provider.addSetData('e1', const SetData(setNumber: 1, reps: 8, weight: 60));
      provider.replaceSetsData('e1', const [
        SetData(setNumber: 1, reps: 10, weight: 50),
        SetData(setNumber: 2, reps: 10, weight: 50),
      ]);
      expect(provider.getExerciseSetsData('e1').length, 2);
      expect(provider.getExerciseSetsData('e1').first.reps, 10);
    });

    test('clearSetsData wipes the per-set map', () {
      provider.addSetData('e1', const SetData(setNumber: 1, reps: 8));
      provider.addSetData('e2', const SetData(setNumber: 1, reps: 8));
      provider.clearSetsData();
      expect(provider.getExerciseSetsData('e1'), isEmpty);
      expect(provider.getExerciseSetsData('e2'), isEmpty);
    });
  });

  group('TrainingProgressProvider.toggleExpanded', () {
    test('flips the isExpanded flag', () {
      expect(provider.isExpanded, isFalse);
      provider.toggleExpanded();
      expect(provider.isExpanded, isTrue);
      provider.toggleExpanded();
      expect(provider.isExpanded, isFalse);
    });
  });

  group('TrainingProgressProvider.endPlan', () {
    test('resets all plan state', () {
      provider
        ..startPlan(planFixture())
        ..completeSet()
        ..setWeight('e1', 80)
        ..addSetData('e1', const SetData(setNumber: 1))
        ..toggleExpanded();

      provider.endPlan();

      expect(provider.currentPlan, isNull);
      expect(provider.isPlanMode, isFalse);
      expect(provider.completedSets, isEmpty);
      expect(provider.startTime, isNull);
      expect(provider.isExpanded, isFalse);
      expect(provider.getExerciseSetsData('e1'), isEmpty);
    });
  });

  group('TrainingProgressProvider.generateRecord', () {
    test('produces a WorkoutRecord carrying plan id/name and total sets', () {
      provider.startPlan(planFixture(
        id: 'pid',
        name: 'Push Day',
        targetSets: [2, 1],
      ));
      provider.completeSet();
      provider.completeSet(); // e1 done (2 sets), auto-advance to e2
      provider.completeSet(); // e2 done (1 set)

      final record = provider.generateRecord();

      expect(record.planId, 'pid');
      expect(record.planName, 'Push Day');
      expect(record.totalSets, 3);
      expect(record.trainedMuscles, [PrimaryMuscleGroup.chest]);
      // Both exercises appear because both have completedSets > 0.
      expect(record.exercises.length, 2);
    });

    test('skips exercises with zero completed sets', () {
      provider.startPlan(planFixture(
        exerciseIds: ['a', 'b', 'c'],
        targetSets: [2, 2, 2],
      ));
      // Only finish exercise 'a'.
      provider.completeSet();
      provider.completeSet();

      final record = provider.generateRecord();

      expect(record.exercises.length, 1);
      expect(record.exercises.first.exerciseId, 'a');
    });

    test('prefers per-set maxWeight over the manual setWeight value', () {
      provider.startPlan(planFixture(targetSets: [1]));
      provider.setWeight('e1', 50); // legacy/manual
      provider.addSetData('e1', const SetData(setNumber: 1, reps: 8, weight: 70));
      provider.completeSet();

      final record = provider.generateRecord();

      expect(record.exercises.single.maxWeight, 70.0);
    });

    test('falls back to manual weight when no per-set data', () {
      provider.startPlan(planFixture(targetSets: [1]));
      provider.setWeight('e1', 50);
      provider.completeSet();

      final record = provider.generateRecord();

      expect(record.exercises.single.maxWeight, 50.0);
    });

    test('records a unique id (uuid v4) per call', () {
      provider.startPlan(planFixture(targetSets: [1]));
      provider.completeSet();

      final a = provider.generateRecord();
      final b = provider.generateRecord();

      expect(a.id, isNot(b.id));
      expect(a.id.length, greaterThan(0));
    });

    test('durationSeconds is non-negative after startPlan', () async {
      provider.startPlan(planFixture(targetSets: [1]));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      provider.completeSet();

      final record = provider.generateRecord();
      expect(record.durationSeconds, greaterThanOrEqualTo(0));
    });
  });

  group('TrainingProgressProvider.trainingDurationText', () {
    test('formats seconds-only durations', () {
      // We can't easily fake the clock; just assert it ends with 秒 when
      // startPlan was called moments ago.
      provider.startPlan(planFixture());
      final text = provider.trainingDurationText;
      // For a sub-minute duration, the text is "N秒".
      expect(text.endsWith('秒'), isTrue);
    });
  });

  group('TrainingProgressProvider.dispose', () {
    test('clears internal maps and is safe to call', () {
      provider.startPlan(planFixture());
      provider.addSetData('e1', const SetData(setNumber: 1));
      provider.dispose();
      // No assertions on private fields; just confirm no exceptions.
      expect(provider.isPlanMode, isFalse);
    });
  });
}
