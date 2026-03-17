# AGENTS.md - WorkoutTimer Flutter App

**Updated:** 2026-03-17
**Branch:** master

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, and SQLite-backed workout history. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10.7+ / sqflite / provider / flutter_local_notifications / uuid / intl / fuzzy / fl_chart.
**Design System**: "Flat Vitality" — warm gradients, deep indigo accent (#1A237E), white circular buttons.

---

## COMMANDS

```bash
# Install & Run
flutter pub get                    # Install dependencies
flutter run                        # Run on device/emulator
flutter run -d chrome              # Web
flutter run -d windows             # Desktop

# Build
flutter build apk --debug          # Debug APK
./build_release.sh                 # Release APK (with --no-tree-shake-icons)
flutter build apk --release --no-tree-shake-icons  # Direct release build
flutter build web                  # Web build

# Test
flutter test                                    # Run all unit tests
flutter test test/widget_test.dart              # Run single test file
flutter test test/services/exercise_matcher_service_test.dart  # Run specific test
flutter test --name "exact match"               # Run tests matching name
flutter test --reporter expanded                # Verbose output
flutter test integration_test/                  # Integration tests

# Analyze & Format
flutter analyze                    # Static analysis (all files)
flutter analyze lib/bloc/          # Analyze specific directory
flutter analyze lib/main.dart      # Analyze single file
dart format lib/ test/             # Format code
dart fix --apply                   # Auto-fix issues

# Clean
flutter clean && flutter pub get   # Clean and reinstall
```

> **CRITICAL**: Always use `--no-tree-shake-icons` for release builds to prevent Material Icons from displaying as garbled text.

---

## STRUCTURE

```
lib/
├── main.dart                 # Entry point, MultiProvider, bottom nav
├── bloc/                     # State providers (ChangeNotifier, NOT BLoC)
│   ├── timer_provider.dart   # Timer countdown, sets counter
│   ├── training_provider.dart # Training mode state machine
│   ├── plan_provider.dart    # Workout plan CRUD
│   ├── record_provider.dart  # History and stats
│   └── training_progress_provider.dart # Real-time training tracking
├── models/                   # Data models with fromMap/toMap
│   ├── workout_session.dart  # Simple session (sets, rest time)
│   ├── workout_record.dart   # Detailed record (exercises, weights)
│   ├── workout_plan.dart     # Plan template
│   ├── exercise.dart         # Exercise definition
│   ├── recorded_exercise.dart # Exercise instance in a workout (uses exercise.name getter)
│   └── muscle_group.dart     # Muscle group enums
├── screens/                  # UI screens (full pages)
│   ├── timer_screen.dart     # Timer wrapper
│   ├── plan_screen.dart      # Workout plans + calendar
│   ├── ai_plan_wizard_screen.dart # AI-powered plan generation
│   ├── history_screen.dart   # Workout history list
│   ├── stats_screen.dart     # Statistics dashboard
│   └── settings_screen.dart  # User preferences
├── widgets/                  # Reusable UI components
│   ├── training_widget.dart  # Main training UI
│   ├── timer_widget.dart     # Timer display
│   ├── calendar_widget.dart  # Month calendar (uses LayoutBuilder for exact height)
│   └── charts/               # fl_chart visualizations
├── theme/                    # Flat Vitality theme (5 themes)
│   ├── app_theme.dart        # Theme data models
│   └── theme_provider.dart   # Theme state + persistence
├── services/                 # Database, notifications, repositories
│   ├── database_helper.dart  # SQLite singleton
│   ├── notification_service.dart # Local notifications
│   ├── exercise_service.dart # Exercise data loading
│   └── *_repository.dart     # Data access layers
├── utils/                    # Color utilities, vocabulary
└── data/                     # Static exercise data (JSON)
```

---

## CODE STYLE

### Naming
- **Classes**: PascalCase (`TimerProvider`, `WorkoutSession`)
- **Methods/Variables**: camelCase (`startTimer`, `remainingSeconds`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_HISTORY_RECORDS`, `tableWorkoutSessions`)
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
// GOOD - null check before use
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
// GOOD - log and continue/rethrow
try {
  await _repository.saveSession(sets, time);
} catch (e) {
  debugPrint('Error saving session: $e');
  // rethrow; // if caller should handle
}

// NEVER - empty catch
try { ... } catch (e) {}
```

### Models Pattern
```dart
class WorkoutSession {
  final String id;
  final int sets;
  // ... fields

  Map<String, dynamic> toMap() => {'id': id, 'sets': sets, ...};
  
  factory WorkoutSession.fromMap(Map<String, dynamic> map) =>
      WorkoutSession(id: map['id'], sets: map['sets'], ...);
  
  WorkoutSession copyWith({String? id, int? sets, ...}) =>
      WorkoutSession(id: id ?? this.id, sets: sets ?? this.sets, ...);
}
```

### GridView Height Pattern (CRITICAL)
When using GridView inside SingleChildScrollView, `shrinkWrap: true` miscalculates height. Use LayoutBuilder:
```dart
return LayoutBuilder(
  builder: (context, constraints) {
    final cellWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
    final gridHeight = rows * cellWidth + (rows - 1) * mainAxisSpacing;
    
    return SizedBox(
      height: gridHeight,
      child: GridView.count(
        crossAxisCount: columns,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  },
);
```

### Widget Testing Pattern
```dart
await tester.pumpWidget(MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TimerProvider()),
    ChangeNotifierProvider.value(value: trainingProvider),
  ],
  child: const MaterialApp(home: TrainingWidget()),
));
await tester.pump(const Duration(seconds: 1));  // For animations
expect(find.text('开始运动'), findsOneWidget);
```

### Unit Testing Pattern
```dart
void main() {
  late ExerciseMatcherService service;

  setUp(() {
    service = ExerciseMatcherService(exercises: sampleExercises);
  });

  group('ExerciseMatcherService', () {
    test('returns success for exact match', () async {
      final result = await service.matchExercise('Barbell Bench Press');
      expect(result.isSuccess, isTrue);
      expect(result.exercise, isNotNull);
    });
  });
}
```

---

## DESIGN SYSTEM (Flat Vitality)

### Color Usage
| Element | Color/Pattern |
|---------|---------------|
| Background | Warm gradient (primaryColor → secondaryColor) |
| Accent/Interactive | Deep indigo (#1A237E) via `accentColor` |
| Progress Ring | `accentColor`, 10px stroke |
| Buttons | White circular with accent icons |
| Cards/Surfaces | White (#FFFFFF) |
| Text | #212121 primary, #757575 secondary |
| Active indicators | `accentColor.withValues(alpha: 0.15)` |
| Borders | `accentColor.withValues(alpha: 0.3-0.4)` |

### Fonts
- Display: `.SF Pro Display` (system font)
- Body: `.SF Pro Text` (system font)
- Timer: `Orbitron`, `Rajdhani` (custom fonts)

### Navigation Bar
- Floating design with `extendBody: true`
- 5 buttons: Plan, History, Timer (center), Stats, Settings
- Center timer button: 70x70 circle, gradient, aligned at bottom
- Nav bar: 4-corner radius (25px), white background

---

## KEY LOCATIONS

| Task | Location |
|------|----------|
| Timer countdown | `bloc/timer_provider.dart` (`_tick()`) |
| Preset times | `bloc/timer_provider.dart:20` (`[30, 60, 90, 120]`) |
| Training states | `bloc/training_provider.dart` (`TrainingState` enum) |
| Database schema | `services/database_helper.dart` (`_onCreate()`) |
| Theme definitions | `theme/app_theme.dart` |
| Exercise data | `services/exercise_service.dart` |
| Bottom navigation | `main.dart` (`MainNavigation` widget) |
| AI plan wizard | `screens/ai_plan_wizard_screen.dart` |
| Calendar widget | `widgets/calendar_widget.dart` |

---

## PLATFORM GUARDS

Use `kIsWeb` for platform-specific features:
```dart
if (!kIsWeb) {
  TimerService.startService();
  _notificationService.showNotification();
}
```

Web uses in-memory SQLite database; native uses persistent storage.

---

## ANTI-PATTERNS (AVOID)

| Pattern | Issue | Instead |
|---------|-------|---------|
| Empty catch blocks | Silent failures | Log + rethrow/continue |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| Service in Provider | Hard to test | Constructor injection |
| Release without `--no-tree-shake-icons` | Icons show as garbled | Use `build_release.sh` |
| Direct color values | Breaks thememing | Use `AppThemeData` fields |
| Bottom padding in main content | Nav bar overlap | Use `extendBody: true`, add padding per-screen |
| GridView with shrinkWrap in scrollable | Extra blank rows | Use LayoutBuilder + SizedBox with calculated height |
| Fixed height SizedBox for variable content | Content clipped | Remove constraint, let content size naturally |

---

## KNOWN ISSUES

- **bloc/ naming**: Directory uses Provider (ChangeNotifier), not BLoC pattern
- **No dependency injection**: Services instantiated inside providers
- **Mixed comments**: Code uses both English and Chinese comments
- **Unused variables**: Some `allPlans` variables flagged by analyzer

---

## DATA SOURCES

| Resource | Source | License |
|----------|--------|---------|
| Exercise database | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | CC0 Public Domain |
| Fonts (Orbitron, Rajdhani) | Google Fonts | SIL Open Font License |

---

## IMAGE URLS

Use Gitee mirror for exercise images in China:
```
https://gitee.com/kaiji-z/free-exercise-db/raw/main/exercises/{exercise_id}/images/{image_id}.jpg
```
