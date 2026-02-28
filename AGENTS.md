# AGENTS.md - WorkoutTimer Flutter App

**Generated:** 2026-02-28
**Commit:** 2130aff
**Branch:** master

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, and SQLite-backed workout history. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10+ / sqflite / provider / flutter_local_notifications / uuid / intl / shared_preferences.

**Design System**: "Flat Vitality" — warm gradients (amber/orange/green/pink/blue), deep indigo accent (#1A237E), white circular buttons, flat design. Custom fonts: .SF Pro Display/Text.

## STRUCTURE

```
lib/
├── main.dart                 # Entry point, routing, MultiProvider setup
├── bloc/                     # Timer & Training providers (ChangeNotifier, NOT BLoC despite dir name)
├── models/
│   └── workout_session.dart   # WorkoutSession model
├── screens/                  # See lib/screens/AGENTS.md
├── widgets/                  # See lib/widgets/AGENTS.md
├── theme/
│   ├── app_theme.dart         # Flat Vitality theme system (5 themes)
│   └── theme_provider.dart    # Theme state management
├── animations/
│   ├── list_animations.dart   # List animation widgets
│   └── page_transitions.dart  # Page transition utilities
├── utils/
│   └── color_extension.dart   # Color utilities
└── services/                 # See lib/services/AGENTS.md
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Timer countdown logic | `bloc/timer_provider.dart:86-97` | `_tick()` method, Timer.periodic |
| Add new screen | `lib/screens/` + route in `main.dart:56-59` | Traditional MaterialApp.routes map |
| Notification config | `services/notification_service.dart` | Android/iOS notifications, skipped on web |
| Database schema | `services/database_helper.dart` | `_onCreate()` - sessions table |
| Preset times | `bloc/timer_provider.dart:18` | `presetTimes = [30, 60, 90, 120]` |
| Flat Vitality themes | `theme/app_theme.dart:212-358` | 5 themes: amberGold, coralOrange, mintGreen, rosePink, skyBlue |
| Theme switching | `main.dart:46-49` | MultiProvider setup with ThemeProvider |
| Main navigation | `main.dart:123-268` | Custom `MainNavigation` with bottom nav bar |
| China mirror setup | `setup_mirrors.sh`, `android/build.gradle.kts` | Aliyun maven mirrors |

## CONVENTIONS

**Naming**: PascalCase classes, camelCase methods/vars, UPPER_SNAKE_CASE constants, `_` prefix for private.

**Imports**: `dart:` → `package:flutter/` → third-party → relative. Use relative imports within package.

**Null Safety**: Use `late` for lazy init, `final` for immutables, avoid `!` operator (use null checks).

**State**: ChangeNotifier pattern. `context.read<T>()` for actions, `Consumer<T>` or `context.watch<T>()` for UI.

**Design System**: Flat Vitality themes use `AppThemeType` enum with 5 preset themes. Deep indigo (#1A237E) for progress rings/accents, warm gradients for backgrounds.

**Testing**: Widget tests use `pump(Duration(seconds: 1))` instead of `pumpAndSettle()` for continuous animations. Integration tests use proper `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.

**Error Handling**: Try-catch with `debugPrint` logging + rethrow. NEVER empty catch blocks.

## ANTI-PATTERNS (THIS PROJECT)

| Pattern | Why Bad | Instead |
|---------|---------|---------|
| Empty catch blocks | Silent failures | Log + rethrow |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| `bloc/` directory naming | Misleading - contains Provider, not BLoC | Rename to `providers/` or keep with comment |
| Service instantiation in Provider | Testing harder | Provider injection |

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
- Use `Timer.periodic` for countdown in `TimerProvider._tick()`
- Cancel timers in `dispose()`
- Handle app background/foreground transitions
- Android foreground service via MethodChannel (`TimerService`)

### Database
- Max 1000 history records (auto-cleanup in `WorkoutRepository`)
- Use transactions for multi-step ops
- In-memory DB fallback for web (`kIsWeb` check in `DatabaseHelper`)

### Notifications
- Request permissions on first launch
- Check vibration capability before use
- Skipped on web platform

### UI - Flat Vitality Design System
- 5 preset themes: amberGold (default), coralOrange, mintGreen, rosePink, skyBlue
- Deep indigo accent (#1A237E or #0D47A1) for progress rings, icons, active states
- Warm gradient backgrounds (primaryColor → secondaryColor)
- White circular buttons with shadow, flat design (no glow/glass effects)
- 10px stroke width for progress rings
- Material 3 design with `.SF Pro Display/Text` fonts
- `ThemeProvider` for theme switching with `shared_preferences` persistence

## NOTES

- **No CI/CD**: Project lacks `.github/workflows` — manual testing required
- **Design system evolution**: Originally "Neon Tempus" (cyan/purple/pink), now "Flat Vitality" (warm gradients + deep indigo)
- **bloc/ naming**: Directory misnamed — contains Provider (ChangeNotifier), not BLoC
- **Service instantiation**: Services created inside `TimerProvider`, not injected via Provider
- **Package naming**: Two MainActivity.kt files with different package names (inconsistent)
- **Web support**: Database and notifications have web fallbacks (`kIsWeb` checks)
