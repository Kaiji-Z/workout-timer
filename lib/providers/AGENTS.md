# AGENTS.md - State Providers

**Generated:** 2026-03-01

## OVERVIEW

State management layer using Provider (ChangeNotifier) — **NOT BLoC** despite directory name. Contains 5 providers for timer, training, plans, records, and progress tracking.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `timer_provider.dart` | 128 | Rest timer countdown, sets counter, preset times |
| `training_provider.dart` | 363 | Training mode state machine, exercise/rest cycles |
| `plan_provider.dart` | 211 | Workout plan CRUD, calendar integration |
| `record_provider.dart` | 149 | Workout record history, stats aggregation |
| `training_progress_provider.dart` | 228 | Real-time training progress tracking |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Timer countdown | `timer_provider.dart:86-97` (`_tick()`) |
| Preset times | `timer_provider.dart:18` (`[30, 60, 90, 120]`) |
| Start timer | `timer_provider.dart:34-44` |
| Save session | `timer_provider.dart:71-84` (`finishWorkout()`) |
| Training states | `training_provider.dart:7-13` (`TrainingState` enum) |
| Start exercise | `training_provider.dart:86-100` |
| Load plans | `plan_provider.dart:27-51` |
| Load records | `record_provider.dart:21-45` |

## PATTERNS

**State Class**: All providers extend `ChangeNotifier`, use private fields with public getters.

**Timer Pattern**: `Timer.periodic` in `_tick()`, cancel in `dispose()`.

**Service Instantiation** (anti-pattern):
```dart
// Inside provider - makes testing harder
final NotificationService _notificationService = NotificationService();
final WorkoutRepository _repository = WorkoutRepository();
```

**Web Support**: `if (!kIsWeb)` guards for platform-specific features.

## ANTI-PATTERNS

| Pattern | Location | Issue |
|---------|----------|-------|
| Service instantiation | `timer_provider.dart:8-9` | Should inject via Provider |
| Service instantiation | `training_provider.dart:17` | Should inject via Provider |
| Silent failure | `plan_provider.dart:67-69` | Catch with only debugPrint |

## KNOWN ISSUES

- **Directory naming**: Named `bloc/` but uses Provider pattern — misleading
- **No dependency injection**: Services created inside providers, not injected
