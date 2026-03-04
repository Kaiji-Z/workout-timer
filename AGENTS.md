# AGENTS.md - WorkoutTimer Flutter App

**Generated:** 2026-03-04
**Branch:** feature/workout-plan

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, and SQLite-backed workout history. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10+ / sqflite / provider / flutter_local_notifications / uuid / intl / shared_preferences.

**Design System**: "Flat Vitality" — warm gradients (amber/orange/green/pink/blue), deep indigo accent (#1A237E), white circular buttons, flat design. Custom fonts: .SF Pro Display/Text, Rajdhani, Orbitron.

## STRUCTURE

```
lib/
├── main.dart                 # Entry point, MultiProvider setup, navigation
├── bloc/                     # State providers (ChangeNotifier, NOT BLoC)
│   ├── timer_provider.dart   # Timer countdown, sets counter
│   ├── training_provider.dart # Training mode state machine
│   ├── plan_provider.dart    # Workout plan CRUD
│   ├── record_provider.dart  # History and stats
│   └── training_progress_provider.dart # Real-time progress
├── models/                   # Data models (WorkoutSession, etc.)
├── screens/                  # UI screens (TimerScreen, PlanScreen, etc.)
├── widgets/                  # Reusable UI components
├── theme/
│   ├── app_theme.dart        # Flat Vitality theme system (5 themes)
│   └── theme_provider.dart   # Theme state management
├── animations/               # List animations, page transitions
├── utils/                    # Color utilities
├── data/                     # Static exercise data (JSON)
└── services/                 # Database, notifications, repositories
```

## COMMANDS

### Install & Run
```bash
# Install dependencies (China mirrors recommended)
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get

# Run on device/emulator
flutter run
flutter run -d chrome     # Web
flutter run -d windows    # Desktop
```

### Build
```bash
flutter build apk --debug
flutter build apk --release
flutter build web
flutter build ios
```

### Test
```bash
# Run all unit tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run specific test by name
flutter test --name "TrainingWidget shows training screen"

# Run with verbose output
flutter test --reporter expanded

# Run integration tests
flutter test integration_test/
flutter test integration_test/app_test.dart
```

### Analyze & Format
```bash
# Static analysis
flutter analyze
flutter analyze lib/bloc/timer_provider.dart  # Single file

# Format code
dart format lib/ test/
dart format --set-exit-if-changed lib/  # CI check

# Auto-fix issues
dart fix --apply
dart fix --dry-run  # Preview changes
```

### Clean & Reset
```bash
flutter clean
flutter pub get
rm -rf build/ .dart_tool/
```

## CODE STYLE

### Naming Conventions
- **Classes**: PascalCase (`TimerProvider`, `WorkoutSession`)
- **Methods/Variables**: camelCase (`startTimer`, `remainingSeconds`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_HISTORY_RECORDS`)
- **Private members**: Prefix with `_` (`_timer`, `_tick()`)
- **Files**: snake_case (`timer_provider.dart`)

### Import Order
```dart
import 'dart:async';           // 1. Dart SDK
import 'package:flutter/foundation.dart';  // 2. Flutter SDK
import 'package:provider/provider.dart';   // 3. Third-party packages
import '../services/notification_service.dart';  // 4. Relative imports
```

### Null Safety
- Use `late` for lazy initialization of non-nullable fields
- Use `final` for immutable values
- Prefer null checks over `!` operator:
  ```dart
  // GOOD
  if (session != null) {
    await _repository.saveSession(session);
  }
  // BAD - can crash at runtime
  await _repository.saveSession(session!);
  ```

### State Management
- All providers extend `ChangeNotifier`
- Use `context.read<T>()` for actions (doesn't rebuild)
- Use `context.watch<T>()` or `Consumer<T>` for UI (rebuilds on change)
- Cancel timers and dispose resources in `dispose()`:
  ```dart
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  ```

### Error Handling
- ALWAYS use try-catch with logging and rethrow:
  ```dart
  // GOOD
  try {
    await _repository.saveSession(sets, time);
  } catch (e) {
    debugPrint('Error saving session: $e');
    rethrow;  // Don't swallow errors
  }
  // BAD - silent failure
  try { ... } catch (e) { debugPrint('$e'); }
  // BAD - empty catch
  try { ... } catch (e) {}  // NEVER do this
  ```

### Testing Patterns
- Widget tests: Use `pump(Duration(seconds: 1))` instead of `pumpAndSettle()` for continuous animations
- Integration tests: Must call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
- Always wrap test widgets in required providers:
  ```dart
  await tester.pumpWidget(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => TimerProvider())],
    child: const MaterialApp(home: TimerScreen()),
  ));
  ```

## DESIGN SYSTEM - Flat Vitality

### Theme Colors
- **5 themes**: amberGold (default), coralOrange, mintGreen, rosePink, skyBlue
- **Accent**: Deep indigo (#1A237E or #0D47A1) for progress rings, icons, active states
- **Backgrounds**: Warm gradient (primaryColor → secondaryColor)
- **Buttons**: White circular with shadow, flat design (no glow/glass effects)
- **Progress rings**: 10px stroke width

### UI Rules
- Material 3 design with `.SF Pro Display/Text` fonts
- `ThemeProvider` persists theme choice via `shared_preferences`
- Use `kIsWeb` guard for platform-specific features (notifications, foreground service)

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Timer countdown logic | `bloc/timer_provider.dart:86-97` (`_tick()`) |
| Preset times | `bloc/timer_provider.dart:18` (`[30, 60, 90, 120]`) |
| Add new screen | `lib/screens/` + navigation in `main.dart` |
| Notification config | `services/notification_service.dart` |
| Database schema | `services/database_helper.dart` (`_onCreate()`) |
| Theme definitions | `theme/app_theme.dart:212-358` |
| Stats calendar | `screens/stats_screen.dart:1025-1169` |
| China mirrors | `setup_mirrors.sh`, `android/build.gradle.kts` |

## ANTI-PATTERNS (TO AVOID)

| Pattern | Why Bad | Instead |
|---------|---------|--------|
| Empty catch blocks | Silent failures | Log + rethrow |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| Service in Provider | Testing harder | Constructor injection |
| `as any`, `@ts-ignore` | Type unsafety | Proper type handling |

## KNOWN ISSUES

- **bloc/ naming**: Directory named `bloc/` but uses Provider (ChangeNotifier), not BLoC
- **No CI/CD**: Project lacks `.github/workflows` — manual testing required
- **No dependency injection**: Services instantiated inside providers
- **Package naming inconsistency**: Two MainActivity.kt files with different package names

## CONFIGURATION FILES

| File | Purpose |
|------|----------|
| `pubspec.yaml` | Dependencies, assets, fonts |
| `analysis_options.yaml` | Linting rules (flutter_lints) |
| `setup_mirrors.sh` | China mirror configuration script |
| `android/build.gradle.kts` | Aliyun maven mirrors for Android |
