import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/services/error_reporter_service.dart';
import 'package:workout_timer/services/notification_service.dart';
import 'package:workout_timer/services/plan_repository.dart';
import 'package:workout_timer/services/record_repository.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/services/user_preferences_service.dart';
import 'package:workout_timer/services/workout_repository.dart';

void main() {
  // ServiceLocator holds static state - isolate each test with a fresh slate.
  setUp(ServiceLocator.reset);
  tearDown(ServiceLocator.reset);

  group('ServiceLocator.register / get', () {
    test('returns the instance registered for a type', () {
      final repo = WorkoutRepository();
      ServiceLocator.register<WorkoutRepository>(repo);

      expect(ServiceLocator.get<WorkoutRepository>(), same(repo));
    });

    test('isRegistered reports registration status', () {
      expect(ServiceLocator.isRegistered<WorkoutRepository>(), isFalse);
      ServiceLocator.register<WorkoutRepository>(WorkoutRepository());
      expect(ServiceLocator.isRegistered<WorkoutRepository>(), isTrue);
    });

    test(
      'throws StateError for an unregistered type with an actionable hint',
      () {
        expect(
          () => ServiceLocator.get<PlanRepository>(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('PlanRepository is not registered'),
            ),
          ),
        );
      },
    );

    test('a later register overrides an earlier one (last-wins)', () {
      final first = WorkoutRepository();
      final second = WorkoutRepository();
      ServiceLocator.register<WorkoutRepository>(first);
      ServiceLocator.register<WorkoutRepository>(second);

      expect(ServiceLocator.get<WorkoutRepository>(), same(second));
    });
  });

  group('ServiceLocator.registerLazy', () {
    test('does not invoke the factory until get() is called', () {
      var callCount = 0;
      ServiceLocator.registerLazy<PlanRepository>(() {
        callCount++;
        return PlanRepository();
      });

      expect(callCount, 0);
      ServiceLocator.get<PlanRepository>();
      expect(callCount, 1);
    });

    test('caches the instance - factory runs only once', () {
      var callCount = 0;
      ServiceLocator.registerLazy<PlanRepository>(() {
        callCount++;
        return PlanRepository();
      });

      final first = ServiceLocator.get<PlanRepository>();
      final second = ServiceLocator.get<PlanRepository>();

      expect(callCount, 1);
      expect(second, same(first));
    });
  });

  group('ServiceLocator.setup', () {
    test('marks the locator as initialized', () {
      expect(ServiceLocator.isInitialized, isFalse);
      ServiceLocator.setup();
      expect(ServiceLocator.isInitialized, isTrue);
    });

    test('registers all production dependencies', () {
      ServiceLocator.setup();

      // Every type documented in setup() must resolve without throwing.
      expect(ServiceLocator.get<NotificationService>(), isNotNull);
      expect(ServiceLocator.get<WorkoutRepository>(), isNotNull);
      expect(ServiceLocator.get<PlanRepository>(), isNotNull);
      expect(ServiceLocator.get<RecordRepository>(), isNotNull);
      expect(ServiceLocator.get<StatsCalculatorService>(), isNotNull);
      expect(ServiceLocator.get<ErrorReporter>(), isNotNull);
    });

    test('UserPreferencesService is registered lazily', () {
      ServiceLocator.setup();

      // Lazy registration resolves on demand and returns a stable instance.
      final first = ServiceLocator.get<UserPreferencesService>();
      final second = ServiceLocator.get<UserPreferencesService>();
      expect(second, same(first));
    });

    test('is idempotent - calling setup twice yields fresh instances', () {
      ServiceLocator.setup();
      final firstRepo = ServiceLocator.get<WorkoutRepository>();

      ServiceLocator.setup();
      final secondRepo = ServiceLocator.get<WorkoutRepository>();

      // Re-setup replaces registrations (important for hot restart).
      expect(secondRepo, isNot(same(firstRepo)));
    });
  });

  group('ServiceLocator.reset', () {
    test('clears all registrations', () {
      ServiceLocator.register<WorkoutRepository>(WorkoutRepository());
      expect(ServiceLocator.isRegistered<WorkoutRepository>(), isTrue);

      ServiceLocator.reset();

      expect(ServiceLocator.isRegistered<WorkoutRepository>(), isFalse);
      expect(ServiceLocator.isInitialized, isFalse);
    });
  });
}
