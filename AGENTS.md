# AGENTS.md - WorkoutTimer Flutter App

**Generated:** 2026-02-13
**Commit:** 8e53cc6
**Branch:** feature/digital-vitality-ui

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, and SQLite-backed workout history. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10+ / sqflite / provider / flutter_local_notifications / uuid / intl / shared_preferences.

**Design System**: "Neon Tempus" — dark theme with cyan (#00f0ff), purple (#bf00ff), pink (#ff00aa) on black (#0a0a12). Custom fonts: Orbitron (display), Rajdhani (UI).

## STRUCTURE
```
lib/
├── main.dart                 # Entry point, routing, Provider setup
├── bloc/timer_provider.dart  # State (ChangeNotifier, NOT BLoC despite dir name)
├── models/workout_session.dart
├── screens/                  # See lib/screens/AGENTS.md
├── widgets/timer_widget.dart # 418 lines: circular progress, chips, buttons
└── services/                 # See lib/services/AGENTS.md
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Timer countdown logic | `bloc/timer_provider.dart:87-98` | `_tick()` method |
| Add new screen | `lib/screens/` + route in `main.dart:53-56` | |
| Notification config | `services/notification_service.dart:35-64` | |
| Database schema | `services/database_helper.dart:45-54` | `_onCreate()` |
| Preset times | `bloc/timer_provider.dart:19` | `presetTimes = [30, 60, 90, 120]` |
| Design colors | `widgets/timer_widget.dart` + `docs/design_philosophy.md` | |
| China mirror setup | `setup_mirrors.sh`, `android/build.gradle.kts` | |

## CONVENTIONS

**Naming**: PascalCase classes, camelCase methods/vars, UPPER_SNAKE_CASE constants, `_` prefix for private.

**Imports**: `dart:` → `package:flutter/` → third-party → relative. Use relative imports within package.

**Null Safety**: Use `late` for lazy init, `final` for immutables, avoid `!` operator (use null checks).

**State**: ChangeNotifier pattern. `context.read<T>()` for actions, `Consumer<T>` or `context.watch<T>()` for UI.

**Error Handling**: Try-catch with logging + rethrow. NEVER empty catch blocks.

## ANTI-PATTERNS (THIS PROJECT)

| Pattern | Why Bad | Instead |
|---------|---------|---------|
| Empty catch blocks | Silent failures | Log + rethrow |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| Singleton services | Testing harder | Provider injection |
| Async in initState blocking | UI freeze | Call async method without await |
| Magic numbers | Unclear intent | Named constants |

## COMMANDS

```bash
# Install (China mirrors)
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get

# Run
flutter run

# Build
flutter build apk --debug
flutter build apk --release

# Test
flutter test
flutter test integration_test/

# Analyze
flutter analyze
dart format lib/ test/
dart fix --apply
```

## SPECIFIC RULES

### Timer Logic
- Use `Timer.periodic` for countdown
- Cancel timers in `dispose()`
- Handle app background/foreground transitions

### Database
- Max 1000 history records (auto-cleanup)
- Use transactions for multi-step ops

### Notifications
- Request permissions on first launch
- Check vibration capability before use
- User prefs via `shared_preferences`

### UI
- Support portrait + landscape
- Material 3 design
- Neon Tempus color palette (see `docs/design_philosophy.md`)

## NOTES

- **No CI/CD**: Project lacks `.github/workflows` — manual testing required
- **Release signing**: Uses debug keystore (not Play Store ready)
- **Service instantiation**: Services created inside `TimerProvider`, not injected via Provider
- **bloc/ naming**: Directory misnamed — contains Provider (ChangeNotifier), not BLoC