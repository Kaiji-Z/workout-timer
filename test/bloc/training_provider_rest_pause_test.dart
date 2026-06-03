import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/bloc/training_provider.dart';

void main() {
  late TrainingProvider provider;

  setUp(() {
    provider = TrainingProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  group('pauseRest', () {
    test('pauses rest timer and sets state to restPaused', () {
      // Arrange: start exercise, then rest
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();
      expect(provider.state, TrainingState.resting);
      expect(provider.restRemaining, 60);

      // Act
      provider.pauseRest();

      // Assert
      expect(provider.state, TrainingState.restPaused);
      // Timer should be stopped — restRemaining should NOT change after waiting
      expect(provider.restRemaining, 60);
    });

    test('pauseRest is no-op when state is exercising', () {
      provider.setRestDuration(60);
      provider.startExercise();
      expect(provider.state, TrainingState.exercising);

      provider.pauseRest();

      // State should remain exercising — no-op
      expect(provider.state, TrainingState.exercising);
    });

    test('pauseRest is no-op when state is idle', () {
      expect(provider.state, TrainingState.idle);

      provider.pauseRest();

      expect(provider.state, TrainingState.idle);
    });

    test('pauseRest is no-op when state is exercisePaused', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.pauseExercise();
      expect(provider.state, TrainingState.exercisePaused);

      provider.pauseRest();

      expect(provider.state, TrainingState.exercisePaused);
    });

    test('pauseRest is no-op when state is completed', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.endWorkout();
      expect(provider.state, TrainingState.completed);

      provider.pauseRest();

      expect(provider.state, TrainingState.completed);
    });
  });

  group('resumeRest', () {
    test('resumes rest timer and sets state back to resting', () {
      // Arrange: exercise → rest → pause
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();
      provider.pauseRest();
      expect(provider.state, TrainingState.restPaused);
      expect(provider.restRemaining, 60);

      // Act
      provider.resumeRest();

      // Assert: state returns to resting
      expect(provider.state, TrainingState.resting);
      // restRemaining should still be 60 (preserved from pause)
      expect(provider.restRemaining, 60);
    });

    test('resumeRest is no-op when state is exercising', () {
      provider.setRestDuration(60);
      provider.startExercise();
      expect(provider.state, TrainingState.exercising);

      provider.resumeRest();

      expect(provider.state, TrainingState.exercising);
    });

    test('resumeRest is no-op when state is resting (not paused)', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();
      expect(provider.state, TrainingState.resting);

      provider.resumeRest();

      // Should remain resting (not transition unexpectedly)
      expect(provider.state, TrainingState.resting);
    });

    test('resumeRest is no-op when state is idle', () {
      expect(provider.state, TrainingState.idle);

      provider.resumeRest();

      expect(provider.state, TrainingState.idle);
    });
  });

  group('pause/resume rest cycle', () {
    test('remaining time is preserved across pause and resume', () {
      provider.setRestDuration(90);
      provider.startExercise();
      provider.startRest();

      // Simulate some rest time passing (set remaining to 45)
      // In real timer this would happen via Timer.periodic tick
      // We verify the value is preserved through pause/resume cycle

      // Pause immediately (remaining = 90 since timer hasn't ticked in test)
      provider.pauseRest();
      final remainingAfterPause = provider.restRemaining;
      expect(remainingAfterPause, 90);

      // Resume
      provider.resumeRest();

      // Remaining should be exactly what it was when paused
      expect(provider.restRemaining, remainingAfterPause);
      expect(provider.state, TrainingState.resting);
    });

    test('isRestPaused getter returns true when rest is paused', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();
      expect(provider.isRestPaused, false);

      provider.pauseRest();

      expect(provider.isRestPaused, true);

      provider.resumeRest();

      expect(provider.isRestPaused, false);
    });

    test('double pauseRest is safe (no-op on second call)', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();

      provider.pauseRest();
      expect(provider.state, TrainingState.restPaused);

      // Second pause should be no-op
      provider.pauseRest();
      expect(provider.state, TrainingState.restPaused);
    });

    test('double resumeRest is safe (no-op on second call)', () {
      provider.setRestDuration(60);
      provider.startExercise();
      provider.startRest();
      provider.pauseRest();
      provider.resumeRest();
      expect(provider.state, TrainingState.resting);

      // Second resume should be no-op
      provider.resumeRest();
      expect(provider.state, TrainingState.resting);
    });
  });
}
