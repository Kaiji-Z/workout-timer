import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/providers/training_provider.dart';

/// Companion test file to training_provider_rest_pause_test.dart.
/// Covers everything *except* pauseRest / resumeRest (already exhaustive there):
/// - lifecycle: startExercise / endWorkout / resetWorkout / resumeExercise
/// - transitions: startRest / skipRest / pauseExercise / resumeFromPause
/// - read-only getters: statusText, sessionDurationFormatted, getWorkoutData
/// - guard clauses: each method is a no-op from the wrong state
void main() {
  late TrainingProvider provider;

  setUp(() {
    provider = TrainingProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  /// Drive the provider into the exercising state with one set in flight.
  void exercise() {
    provider.setRestDuration(60);
    provider.startExercise();
  }

  group('TrainingProvider — initial state', () {
    test('starts idle with no progress', () {
      expect(provider.state, TrainingState.idle);
      expect(provider.currentSet, 0);
      expect(provider.isPaused, isFalse);
      expect(provider.isIdle, isTrue);
      expect(provider.isExercising, isFalse);
      expect(provider.isCompleted, isFalse);
    });

    test('default restDuration is 60s', () {
      expect(provider.restDuration, 60);
    });

    test('statusText reads idle prompt when idle', () {
      expect(provider.statusText, contains('准备开始'));
    });

    test('sessionDurationFormatted is 00:00 before any exercise', () {
      expect(provider.sessionDurationFormatted, '00:00');
    });
  });

  group('TrainingProvider.setRestDuration', () {
    test('updates restDuration while idle', () {
      provider.setRestDuration(90);
      expect(provider.restDuration, 90);
    });

    test('is rejected once training has started', () {
      exercise();
      final before = provider.restDuration;
      provider.setRestDuration(120);
      expect(provider.restDuration, before, reason: 'must not change mid-workout');
    });
  });

  group('TrainingProvider.startExercise', () {
    test('moves from idle to exercising and bumps currentSet to 1', () {
      provider.startExercise();
      expect(provider.state, TrainingState.exercising);
      expect(provider.currentSet, 1);
      expect(provider.isPaused, isFalse);
      expect(provider.exerciseTime, 0);
      expect(provider.totalExerciseTime, 0);
      expect(provider.totalRestTime, 0);
    });

    test('can be called from the completed state (new round)', () {
      exercise();
      provider.endWorkout();
      expect(provider.state, TrainingState.completed);

      provider.startExercise();
      expect(provider.state, TrainingState.exercising);
      expect(provider.currentSet, 1);
    });

    test('is a no-op when already exercising', () {
      exercise();
      provider.startExercise(); // second call
      expect(provider.currentSet, 1, reason: 'must not stack');
    });

    test('is a no-op while resting', () {
      exercise();
      provider.startRest();
      provider.startExercise();
      expect(provider.state, TrainingState.resting);
    });

    test('statusText reflects current set while exercising', () {
      exercise();
      expect(provider.statusText, contains('第1组'));
    });

    test('notifies listeners', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.startExercise();
      expect(notifyCount, greaterThan(0));
    });
  });

  group('TrainingProvider.pauseExercise / resumeFromPause', () {
    test('pauseExercise transitions exercising -> exercisePaused', () {
      exercise();
      provider.pauseExercise();
      expect(provider.state, TrainingState.exercisePaused);
      expect(provider.isPaused, isTrue);
      expect(provider.isExercisePaused, isTrue);
    });

    test('resumeFromPause transitions back to exercising and clears pause flag', () {
      exercise();
      provider.pauseExercise();
      provider.resumeFromPause();
      expect(provider.state, TrainingState.exercising);
      expect(provider.isPaused, isFalse);
    });

    test('pauseExercise is a no-op when not exercising', () {
      // idle
      provider.pauseExercise();
      expect(provider.state, TrainingState.idle);
      // resting
      exercise();
      provider.startRest();
      provider.pauseExercise();
      expect(provider.state, TrainingState.resting);
    });

    test('resumeFromPause is a no-op when not exercisePaused', () {
      exercise(); // exercising
      provider.resumeFromPause();
      expect(provider.state, TrainingState.exercising);
    });

    test('statusText reflects paused state', () {
      exercise();
      provider.pauseExercise();
      expect(provider.statusText, contains('已暂停'));
    });
  });

  group('TrainingProvider.startRest / skipRest', () {
    test('startRest transitions exercising -> resting with full countdown', () {
      provider.setRestDuration(45);
      provider.startExercise();
      provider.startRest();
      expect(provider.state, TrainingState.resting);
      expect(provider.restRemaining, 45);
      expect(provider.isResting, isTrue);
    });

    test('startRest is a no-op when not exercising', () {
      // From idle
      provider.startRest();
      expect(provider.state, TrainingState.idle);
      // From exercisePaused
      exercise();
      provider.pauseExercise();
      provider.startRest();
      expect(provider.state, TrainingState.exercisePaused);
    });

    test('skipRest advances to next set and returns to exercising', () {
      exercise();
      provider.startRest();
      expect(provider.currentSet, 1);
      provider.skipRest();
      expect(provider.state, TrainingState.exercising);
      expect(provider.currentSet, 2);
    });

    test('skipRest is a no-op when not resting', () {
      exercise();
      provider.skipRest();
      expect(provider.state, TrainingState.exercising);
      expect(provider.currentSet, 1);
    });

    test('statusText reads "resting, next set N+1" while resting', () {
      exercise(); // currentSet = 1
      provider.startRest();
      // Should reference both the completed set and the upcoming set.
      expect(provider.statusText, contains('1'));
      expect(provider.statusText, contains('2'));
    });
  });

  group('TrainingProvider.endWorkout', () {
    test('from exercising -> completed', () {
      exercise();
      provider.endWorkout();
      expect(provider.state, TrainingState.completed);
      expect(provider.isCompleted, isTrue);
      expect(provider.isPaused, isFalse);
    });

    test('from exercisePaused -> completed', () {
      exercise();
      provider.pauseExercise();
      provider.endWorkout();
      expect(provider.state, TrainingState.completed);
    });

    test('is a no-op from idle', () {
      provider.endWorkout();
      expect(provider.state, TrainingState.idle);
    });

    test('is a no-op from resting', () {
      exercise();
      provider.startRest();
      provider.endWorkout();
      expect(provider.state, TrainingState.resting);
    });

    test('is a no-op from completed (no double-end)', () {
      exercise();
      provider.endWorkout();
      provider.endWorkout();
      expect(provider.state, TrainingState.completed);
    });

    test('statusText reports completion', () {
      exercise();
      provider.endWorkout();
      expect(provider.statusText, contains('完成'));
    });
  });

  group('TrainingProvider.resumeExercise (post-completion restart)', () {
    test('transitions completed -> exercising', () {
      exercise();
      provider.endWorkout();
      provider.resumeExercise();
      expect(provider.state, TrainingState.exercising);
      expect(provider.isPaused, isFalse);
    });

    test('is a no-op from non-completed states', () {
      // idle
      provider.resumeExercise();
      expect(provider.state, TrainingState.idle);

      // exercising
      exercise();
      provider.resumeExercise();
      expect(provider.state, TrainingState.exercising);
    });
  });

  group('TrainingProvider.resetWorkout', () {
    test('returns to idle from any state and zeroes counters', () {
      exercise();
      provider.startRest();
      provider.skipRest(); // currentSet = 2, exercising

      provider.resetWorkout();

      expect(provider.state, TrainingState.idle);
      expect(provider.currentSet, 0);
      expect(provider.exerciseTime, 0);
      expect(provider.restRemaining, 0);
      expect(provider.totalExerciseTime, 0);
      expect(provider.totalRestTime, 0);
      expect(provider.sessionDuration, 0);
      expect(provider.isPaused, isFalse);
    });

    test('works from idle (idempotent)', () {
      provider.resetWorkout();
      expect(provider.state, TrainingState.idle);
    });
  });

  group('TrainingProvider.getWorkoutData', () {
    test('returns a Map with the four expected keys', () {
      final data = provider.getWorkoutData();
      expect(data.keys, containsAll([
        'totalSets',
        'totalExerciseTimeMs',
        'totalRestTimeMs',
        'sessionDurationMs',
      ]));
    });

    test('reports currentSet as totalSets', () {
      exercise();
      expect(provider.getWorkoutData()['totalSets'], 1);
    });

    test('reports times in milliseconds', () {
      final data = provider.getWorkoutData();
      expect(data['totalExerciseTimeMs'], isA<int>());
      expect(data['totalRestTimeMs'], isA<int>());
      expect(data['sessionDurationMs'], isA<int>());
    });
  });

  group('TrainingProvider full cycle (smoke)', () {
    test('exercise -> rest -> skip -> end produces coherent state', () {
      provider.setRestDuration(30);
      provider.startExercise();
      expect(provider.currentSet, 1);

      provider.startRest();
      expect(provider.restRemaining, 30);
      expect(provider.state, TrainingState.resting);

      provider.skipRest();
      expect(provider.currentSet, 2);
      expect(provider.state, TrainingState.exercising);

      provider.startRest();
      provider.skipRest();
      expect(provider.currentSet, 3);

      provider.endWorkout();
      expect(provider.state, TrainingState.completed);
      expect(provider.getWorkoutData()['totalSets'], 3);
    });

    test('pause/resume cycle preserves set count', () {
      exercise();
      provider.pauseExercise();
      expect(provider.currentSet, 1);
      provider.resumeFromPause();
      expect(provider.currentSet, 1);
      expect(provider.state, TrainingState.exercising);
    });

    test('reset clears timers cleanly without throwing', () {
      // Spin up timers by exercising + resting, then reset.
      exercise();
      provider.startRest();
      provider.resetWorkout();
      expect(provider.state, TrainingState.idle);
      // tearDown will dispose the provider; this verifies reset didn't leave
      // any dangling timer references that would crash dispose.
    });
  });

  group('TrainingProvider boolean state getters', () {
    test('each getter tracks the corresponding state', () {
      // idle
      expect(provider.isIdle, isTrue);
      expect(provider.isExercising, isFalse);
      expect(provider.isExercisePaused, isFalse);
      expect(provider.isResting, isFalse);
      expect(provider.isRestPaused, isFalse);
      expect(provider.isCompleted, isFalse);

      exercise();
      expect(provider.isIdle, isFalse);
      expect(provider.isExercising, isTrue);

      provider.pauseExercise();
      expect(provider.isExercising, isFalse);
      expect(provider.isExercisePaused, isTrue);

      provider.resumeFromPause();
      provider.startRest();
      expect(provider.isExercising, isFalse);
      expect(provider.isResting, isTrue);

      provider.pauseRest();
      expect(provider.isRestPaused, isTrue);

      provider.resumeRest();
      provider.skipRest();
      provider.endWorkout();
      expect(provider.isCompleted, isTrue);
    });
  });
}
