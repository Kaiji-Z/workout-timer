# AGENTS.md - WorkoutTimer Flutter App

**Updated:** 2026-03-08
**Branch:** master

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, and SQLite-backed workout history. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10+ / sqflite / provider / flutter_local_notifications / uuid / intl.

**Design System**: "Flat Vitality" — warm gradients, deep indigo accent (#1A237E), white circular buttons. Fonts: Rajdhani, Orbitron.

## COMMANDS

### Install & Run
```bash
flutter pub get                    # Install dependencies
flutter run                        # Run on device/emulator
flutter run -d chrome              # Web
flutter run -d windows             # Desktop
```

### Build
```bash
flutter build apk --debug          # Debug APK
./build_release.sh                 # Release APK (with --no-tree-shake-icons)
flutter build web                  # Web build
```

> **IMPORTANT**: Always use `--no-tree-shake-icons` for release builds to prevent Material Icons from displaying as garbled text.

### Test
```bash
flutter test                       # Run all unit tests
flutter test test/widget_test.dart # Run single test file
flutter test --name "testName"     # Run specific test by name
flutter test --reporter expanded   # Verbose output
flutter test integration_test/     # Integration tests
```

### Analyze & Format
```bash
flutter analyze                    # Static analysis
flutter analyze lib/bloc/          # Analyze specific directory
dart format lib/ test/             # Format code
dart fix --apply                   # Auto-fix issues
```

### Clean
```bash
flutter clean && flutter pub get
```

## STRUCTURE

```
lib/
├── main.dart                 # Entry point, MultiProvider, navigation
├── bloc/                     # State providers (ChangeNotifier, NOT BLoC)
│   ├── timer_provider.dart   # Timer countdown, sets counter
│   ├── training_provider.dart # Training mode state machine
│   ├── plan_provider.dart    # Workout plan CRUD
│   └── record_provider.dart  # History and stats
├── models/                   # Data models with fromMap/toMap
├── screens/                  # UI screens
├── widgets/                  # Reusable UI components
├── theme/                    # Flat Vitality theme (5 themes)
├── services/                 # Database, notifications, repositories
├── utils/                    # Color utilities, vocabulary
└── data/                     # Static exercise data (JSON)
```

## CODE STYLE

### Naming
- **Classes**: PascalCase (`TimerProvider`, `WorkoutSession`)
- **Methods/Variables**: camelCase (`startTimer`, `remainingSeconds`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_HISTORY_RECORDS`)
- **Private members**: Prefix with `_` (`_timer`, `_tick()`)
- **Files**: snake_case (`timer_provider.dart`)

### Import Order
```dart
import 'dart:async';                        // 1. Dart SDK
import 'package:flutter/foundation.dart';   // 2. Flutter SDK
import 'package:provider/provider.dart';    // 3. Third-party packages
import '../services/notification_service.dart';  // 4. Relative imports
```

### Null Safety
```dart
// GOOD - null check
if (session != null) {
  await _repository.saveSession(session);
}

// BAD - can crash at runtime
await _repository.saveSession(session!);
```

### State Management
- All providers extend `ChangeNotifier`
- Use `context.read<T>()` for actions (no rebuild)
- Use `context.watch<T>()` or `Consumer<T>` for UI (rebuilds)
- Always cancel timers in `dispose()`:
```dart
@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

### Error Handling
```dart
// GOOD - log and rethrow
try {
  await _repository.saveSession(sets, time);
} catch (e) {
  debugPrint('Error saving session: $e');
  rethrow;
}

// BAD - silent failure
try { ... } catch (e) { debugPrint('$e'); }
// NEVER - empty catch
try { ... } catch (e) {}
```

### Testing
```dart
// Widget test pattern
await tester.pumpWidget(MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TimerProvider()),
    ChangeNotifierProvider.value(value: trainingProvider),
  ],
  child: const MaterialApp(home: TrainingWidget()),
));
await tester.pump(const Duration(seconds: 1));  // For animations
```

## KEY LOCATIONS

| Task | Location |
|------|----------|
| Timer countdown | `bloc/timer_provider.dart` (`_tick()`) |
| Preset times | `bloc/timer_provider.dart:20` (`[30, 60, 90, 120]`) |
| Training states | `bloc/training_provider.dart` (`TrainingState` enum) |
| Database schema | `services/database_helper.dart` (`_onCreate()`) |
| Theme definitions | `theme/app_theme.dart` |
| Exercise data | `services/exercise_service.dart` |

## PLATFORM GUARDS

Use `kIsWeb` for platform-specific features:
```dart
if (!kIsWeb) {
  TimerService.startService();
  _notificationService.showNotification();
}
```

## DATA SOURCES

| Resource | Source | License |
|----------|--------|---------|
| Exercise database | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | Public Domain (CC0) |
| Exercise images | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | Public Domain (CC0) |
| Fonts (Orbitron, Rajdhani) | Google Fonts | SIL Open Font License |

## ANTI-PATTERNS (AVOID)

| Pattern | Issue | Instead |
|---------|-------|---------|
| Empty catch blocks | Silent failures | Log + rethrow |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| Service in Provider | Hard to test | Constructor injection |
| Release without `--no-tree-shake-icons` | Icons show as garbled | Use `build_release.sh` |

## KNOWN ISSUES

- **bloc/ naming**: Directory uses Provider (ChangeNotifier), not BLoC pattern
- **No CI/CD**: Manual testing required
- **No dependency injection**: Services instantiated inside providers

## CONFIGURATION FILES

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Dependencies, assets, fonts |
| `analysis_options.yaml` | Linting (flutter_lints) |
| `build_release.sh` / `.bat` | Release build with icon fix |
| `setup_mirrors.sh` | China mirror configuration |
