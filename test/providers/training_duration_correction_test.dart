import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/providers/training_provider.dart';

/// 方案 B（时长修正）+ 方案 A（空闲提醒状态机集成）的单元测试。
///
/// 真实时长由墙钟计算（无法在测试中快进 4 小时），所以用
/// `debugSetSessionDuration` 注入伪造时长来测启发式逻辑。
void main() {
  late TrainingProvider provider;

  setUp(() {
    provider = TrainingProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  /// Drive to completed state with a faked session duration.
  void completeWith({
    required int durationSeconds,
    int sets = 1,
  }) {
    provider.startExercise();
    for (int i = 1; i < sets; i++) {
      provider.startRest();
      provider.skipRest();
    }
    provider.endWorkout();
    provider.debugSetSessionDuration(durationSeconds);
  }

  group('hasAbnormalDuration heuristic', () {
    test('40-minute session is never abnormal (below 45min floor)', () {
      completeWith(durationSeconds: 40 * 60, sets: 8);
      expect(provider.hasAbnormalDuration, isFalse);
    });

    test('45-minute session with normal per-set average is not abnormal', () {
      // 12 sets × ~4 min/set = 48 min — a long but legitimate workout
      completeWith(durationSeconds: 48 * 60, sets: 12);
      expect(provider.hasAbnormalDuration, isFalse);
    });

    test('forgotten timer (4h, 8 sets) is abnormal', () {
      // 4h12m / 8 sets ≈ 31.5 min per set — the user's real-world case
      completeWith(durationSeconds: 4 * 3600 + 12 * 60, sets: 8);
      expect(provider.hasAbnormalDuration, isTrue);
    });

    test('forgotten timer (4h, single set) is abnormal', () {
      // Never pressed rest once: 1 set, 4 hours
      completeWith(durationSeconds: 4 * 3600, sets: 1);
      expect(provider.hasAbnormalDuration, isTrue);
    });

    test('50-minute session with 3 heavy sets (16.7min/set) is abnormal', () {
      // Borderline legitimate case (heavy compounds + long rests) — the
      // dialog still asks; user can keep the original value.
      completeWith(durationSeconds: 50 * 60, sets: 3);
      expect(provider.hasAbnormalDuration, isTrue);
    });
  });

  group('estimatedSessionDuration', () {
    test('estimates sets × 5 minutes', () {
      completeWith(durationSeconds: 4 * 3600, sets: 8);
      expect(provider.estimatedSessionDuration, 40 * 60);
    });

    test('floors at 5 minutes for a single set', () {
      completeWith(durationSeconds: 2 * 3600, sets: 1);
      expect(provider.estimatedSessionDuration, 5 * 60);
    });

    test('never exceeds the recorded duration', () {
      // 20 sets × 5 min = 100 min estimate, but session was only 30 min
      completeWith(durationSeconds: 30 * 60, sets: 20);
      expect(provider.estimatedSessionDuration, 30 * 60);
    });
  });

  group('correctSessionDuration', () {
    test('applies correction after endWorkout', () {
      completeWith(durationSeconds: 4 * 3600, sets: 8);
      provider.correctSessionDuration(40 * 60);
      expect(provider.sessionDuration, 40 * 60);
    });

    test('clamps correction to not exceed original duration', () {
      completeWith(durationSeconds: 30 * 60, sets: 6);
      provider.correctSessionDuration(2 * 3600);
      expect(provider.sessionDuration, 30 * 60);
    });

    test('rejects non-positive values', () {
      completeWith(durationSeconds: 30 * 60, sets: 6);
      provider.correctSessionDuration(0);
      provider.correctSessionDuration(-100);
      expect(provider.sessionDuration, 30 * 60);
    });

    test('is a no-op before the session ends', () {
      provider.startExercise();
      provider.correctSessionDuration(300);
      expect(provider.isExercising, isTrue);
    });
  });

  group('idle reminder state machine integration', () {
    test('rest cancels pending reminder without crash', () {
      provider.startExercise();
      provider.startRest();
      expect(provider.isResting, isTrue);
    });

    test('pause/resume/end cycle stays consistent', () {
      provider.startExercise();
      provider.pauseExercise();
      expect(provider.isExercisePaused, isTrue);
      provider.resumeFromPause();
      expect(provider.isExercising, isTrue);
      provider.endWorkout();
      expect(provider.isCompleted, isTrue);
    });

    test('skipRest returns to exercising (fresh reminder segment)', () {
      provider.startExercise();
      provider.startRest();
      provider.skipRest();
      expect(provider.isExercising, isTrue);
      expect(provider.currentSet, 2);
    });
  });
}
