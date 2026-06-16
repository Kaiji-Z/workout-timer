import '../services/error_reporter_service.dart';
import '../services/notification_service.dart';
import '../services/record_repository.dart';
import '../services/plan_repository.dart';
import '../services/workout_repository.dart';
import '../services/stats_calculator_service.dart';
import '../services/user_preferences_service.dart';

/// A lightweight service locator (IoC container) for dependency injection.
///
/// Replaces `final _x = XService()` field initializers inside Providers with
/// a central registry, so that:
/// - Production wiring lives in one place ([setup]).
/// - Tests can override any dependency via [register] / [registerLazy] after
///   calling [reset].
///
/// Static facade classes ([TimerService], [ExerciseService], [DatabaseHelper])
/// are intentionally NOT adapted here: they carry no per-instance state and
/// are consumed through static methods, so wrapping them would add cost with
/// no testability benefit.
class ServiceLocator {
  ServiceLocator._();

  static final _instances = <Type, _Registration>{};

  /// Whether [setup] has run. Guards against accidental use before init.
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Register a singleton instance.
  static void register<T extends Object>(T instance) {
    _instances[T] = _InstanceRegistration<T>(instance);
  }

  /// Register a lazy factory — the instance is created on first [get].
  static void registerLazy<T extends Object>(T Function() factory) {
    _instances[T] = _LazyRegistration<T>(factory);
  }

  /// Retrieve a registered dependency.
  /// Throws a clear [StateError] (instead of returning null) so misuse fails
  /// fast with an actionable message.
  static T get<T extends Object>() {
    final registration = _instances[T];
    if (registration == null) {
      throw StateError(
        'ServiceLocator: $T is not registered. '
        'Did you forget to call ServiceLocator.setup() or register<$T>?',
      );
    }
    return registration.resolve() as T;
  }

  /// Whether [T] is currently registered.
  static bool isRegistered<T extends Object>() => _instances.containsKey(T);

  /// Register all production dependencies.
  ///
  /// Call once at app startup (in `main()`), before `runApp`.
  /// Repositories share the [DatabaseHelper] singleton internally.
  static void setup() {
    // Clear any previous state (safe to call multiple times, e.g. hot restart).
    _instances.clear();

    register<NotificationService>(NotificationService());
    register<WorkoutRepository>(WorkoutRepository());
    register<PlanRepository>(PlanRepository());
    register<RecordRepository>(RecordRepository());
    register<StatsCalculatorService>(StatsCalculatorService());
    register<ErrorReporter>(ErrorReporter());

    // UserPreferencesService performs async I/O per call; create lazily so the
    // first request pays the cost instead of blocking startup.
    registerLazy<UserPreferencesService>(() => UserPreferencesService());

    _isInitialized = true;
  }

  /// Clear all registrations. Intended for tests to isolate DI state.
  static void reset() {
    _instances.clear();
    _isInitialized = false;
  }
}

/// Internal: a single registration entry, either eager or lazy.
abstract class _Registration {
  Object resolve();
}

class _InstanceRegistration<T> implements _Registration {
  _InstanceRegistration(this.instance);
  final T instance;
  @override
  Object resolve() => instance as Object;
}

class _LazyRegistration<T> implements _Registration {
  _LazyRegistration(this.factory);
  final T Function() factory;
  T? _instance;
  bool _created = false;

  @override
  Object resolve() {
    if (!_created) {
      _instance = factory();
      _created = true;
    }
    return _instance as Object;
  }
}
