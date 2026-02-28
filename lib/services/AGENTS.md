# AGENTS.md - Services

**Generated:** 2026-02-28

## OVERVIEW

Business logic and external service integrations. Follows repository pattern for data access.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `database_helper.dart` | 88 | SQLite singleton, CRUD operations |
| `notification_service.dart` | 74 | Local notifications (Android) |
| `workout_repository.dart` | 63 | Data abstraction layer |
| `timer_service.dart` | 31 | Android foreground service via MethodChannel |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| DB schema | `database_helper.dart:45-54` (`_onCreate`) |
| Insert session | `database_helper.dart:56-59` |
| Query all | `database_helper.dart:61-67` |
| Show notification | `notification_service.dart:35-64` |
| Request permissions | `notification_service.dart:66-73` |
| Save workout | `workout_repository.dart:10-24` |
| Total stats | `workout_repository.dart:54-62` |
| Start foreground | `timer_service.dart:7-13` |

## PATTERNS

**Singleton**: `DatabaseHelper.instance` for single DB connection.

**Repository**: `WorkoutRepository` wraps `DatabaseHelper` with business logic.

**Platform Channel**: `TimerService` uses `MethodChannel` for Android-native foreground service.

## WEB SUPPORT

- `database_helper.dart:28-34` — Uses in-memory DB for web (`kIsWeb` check)
- `notification_service.dart:37` — Skips notifications on web
- `timer_service.dart` — No-op on web (no foreground service)

## NOTES

- Services instantiated inside `TimerProvider`, not injected via Provider
- `debugPrint` used for error logging throughout
