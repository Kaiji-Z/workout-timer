# AGENTS.md - WorkoutTimer Flutter App

**Updated:** 2026-06-04
**Branch:** master

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, SQLite-backed workout history, AI plan generation, per-set recording, and bodyweight volume tracking. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10.7+ / sqflite + sqflite_common_ffi / provider / flutter_local_notifications / uuid / intl / fuzzy / fl_chart / cached_network_image / google_fonts / string_similarity.
**Design System**: "Flat Vitality" — warm gradients, deep indigo accent (#1A237E), white circular buttons.
**Database**: SQLite v4 with incremental migrations (v1→v2→v3→v4).

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

# Install to phone (NEVER uninstall first — always overwrite)
adb install -r build/app/outputs/flutter-apk/app-debug.apk  # Overwrite install (preserves data)
# Do NOT use `flutter install` — it uninstalls first, wiping all user data

# Test
flutter test                                    # Run all unit tests
flutter test test/widget_test.dart              # Run single test file
flutter test test/services/exercise_matcher_service_test.dart  # Run specific test
flutter test test/services/database_migration_test.dart       # DB migration tests
flutter test --name "exact match"               # Run tests matching name
flutter test --reporter expanded                # Verbose output
flutter test integration_test/                  # Integration tests (ai_plan_import_e2e_test, detailed_recording_e2e_test)

# Analyze & Format
flutter analyze                    # Static analysis (all files)
flutter analyze lib/bloc/          # Analyze specific directory
dart format lib/ test/             # Format code
dart fix --apply                   # Auto-fix issues

# Clean
flutter clean && flutter pub get   # Clean and reinstall
```

> **CRITICAL**: Always use `--no-tree-shake-icons` for release builds to prevent Material Icons from displaying as garbled text.

### CI
GitHub Actions on push/PR to `master`/`main`:
- `android-build.yml`: Java 17 → Flutter stable → `flutter pub get` → `flutter test` → `flutter build apk --debug`
- `ios-build.yml`: macOS runner, iOS build verification

### Linting
Uses `package:flutter_lints/flutter.yaml` — no custom rule overrides. Standard Flutter lint set.

---

## STRUCTURE

```
lib/
├── main.dart                 # Entry point, MultiProvider, bottom nav
├── animations/               # Page transitions and list animations
│   ├── list_animations.dart
│   └── page_transitions.dart # FadeUpPageRoute (slide-up transition)
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
│   ├── exercise.dart         # Exercise definition (870+ exercises)
│   ├── muscle_group.dart     # Muscle group enums + utilities
│   ├── set_data.dart         # Single set: setNumber, reps, weight
│   ├── calendar_plan.dart    # Date → plan mapping
│   ├── user_profile.dart     # AI plan profile: goal, frequency, equipment
│   └── weekly_plan_import.dart # JSON import for weekly plans
├── screens/                  # UI screens (full pages)
│   ├── timer_screen.dart     # Timer wrapper
│   ├── plan_screen.dart      # Workout plans + calendar
│   ├── plan_form_screen.dart # Plan creation/editing (924 lines)
│   ├── ai_plan_wizard_screen.dart # AI-powered plan generation
│   ├── ai_analysis_screen.dart    # AI analysis dashboard (1163 lines)
│   ├── exercise_selection_screen.dart # Exercise picker (811 lines)
│   ├── history_screen.dart   # Workout history list
│   ├── record_detail_screen.dart   # Detailed record view (832 lines)
│   ├── stats_screen.dart     # Statistics dashboard
│   ├── user_preferences_screen.dart # Training preferences (531 lines)
│   └── settings_screen.dart  # User preferences
├── widgets/                  # Reusable UI components
│   ├── training_widget.dart  # Main training UI
│   ├── timer_widget.dart     # Timer display
│   ├── animated_timer_widget.dart # Animated timer variant
│   ├── rest_timer_widget.dart     # Rest timer component
│   ├── session_stopwatch_widget.dart # Session stopwatch
│   ├── calendar_widget.dart  # Month calendar (LayoutBuilder for exact height)
│   ├── exercise_selector.dart     # Exercise selection with search/filter
│   ├── muscle_selector.dart       # Muscle group selection
│   ├── plan_card.dart       # Plan card with swipe actions
│   ├── duration_picker.dart # Duration selection UI
│   ├── weight_input_dialog.dart   # Weight input dialog
│   ├── set_record_dialog.dart     # Set recording dialog
│   ├── bulk_exercise_data_dialog.dart # Bulk import dialog
│   ├── fullscreen_image_viewer.dart    # Image viewer
│   ├── glass_widgets.dart    # CircularControlButton, PressableMixin, Flat Vitality UI
│   ├── circular_progress_painter.dart # Progress ring painter
│   └── completed_medal_display.dart   # Completed workout medal
├── theme/                    # Flat Vitality theme (5 themes)
│   ├── app_theme.dart        # Theme data models
│   └── theme_provider.dart   # Theme state + persistence
├── services/                 # Database, notifications, repositories
│   ├── database_helper.dart  # SQLite singleton, v4 schema, migrations
│   ├── notification_service.dart # Local notifications
│   ├── exercise_service.dart # Exercise data loading
│   ├── exercise_matcher_service.dart # Fuzzy exercise name matching
│   ├── ai_prompt_service.dart # AI plan prompt generation
│   ├── stats_calculator_service.dart # Strength data, volume, 1RM estimation
│   ├── bodyweight_coefficient_service.dart # Bodyweight exercise volume estimation
│   ├── user_preferences_service.dart # Training preferences persistence
│   ├── timer_service.dart    # Android foreground service via MethodChannel
│   ├── workout_repository.dart   # Session data
│   ├── plan_repository.dart      # Plan CRUD
│   └── record_repository.dart    # Record CRUD
├── utils/                    # Color utilities, vocabulary
│   └── dimensions.dart       # AppDimensions: nav bar sizes, spacing, responsive helpers
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
- **Widget private classes**: Prefix with `_` (`_PresetChip`, `_CircleControlButton`)

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

### Dark Mode Color Handling
Always access colors via `AppThemeData` from `ThemeProvider`, never hardcode:
```dart
// GOOD - theme-aware, works in both modes
final theme = context.watch<ThemeProvider>().currentTheme;
Container(color: theme.surfaceColor);

// BAD - hardcoded, breaks in dark mode
Container(color: Colors.white);
```
Dark mode uses derived colors from light theme via `AppThemeData.dark` getter.

---

## DATABASE

### Schema (v4)
8 tables with foreign keys and indexes:
- `workout_sessions` — Legacy simple session (id, sets, rest_time_ms, created_at)
- `exercises` — Exercise definitions (id, name, name_en, primary_muscle, secondary_muscles, equipment, level, image_url, muscle_image_url, recommended_sets/reps/rest)
- `workout_plans` — Plan templates (id, name, target_muscles, estimated_duration)
- `plan_exercises` — Plan→Exercise join (plan_id, exercise_id, target_sets, custom_sets, exercise_order, unmatched_name)
- `calendar_plans` — Date→Plan scheduling (date, plan_id) with UNIQUE(date, plan_id)
- `workout_records` — Detailed workout records (date, duration_seconds, trained_muscles, plan_id, plan_name, total_sets)
- `record_exercises` — Record→Exercise join (record_id, exercise_id, completed_sets, max_weight, per_set_data)

### Migration History
| Version | Changes |
|---------|---------|
| v1 | Initial: `workout_sessions` table only |
| v2 | Added 6 tables: exercises, workout_plans, plan_exercises, calendar_plans, workout_records, record_exercises + indexes |
| v3 | Added `per_set_data TEXT` column to `record_exercises` (JSON-encoded SetData array) |
| v4 | Added `unmatched_name TEXT` column to `plan_exercises` (for unmatched custom exercises) |

### Migration Rules
- All migrations in `database_helper.dart:_onUpgrade()` — sequential `if (oldVersion < N)` blocks
- Always use `ALTER TABLE ADD COLUMN` for additive changes
- `workout_sessions` table preserved across all migrations for backward compatibility

### Web vs Native
- **Web**: `sqfliteFfiInit()` + in-memory database (`databaseFactoryFfi`)
- **Native**: Persistent file via `getDatabasesPath()`
- Both paths use the same schema and migration logic

---

## TESTING

### Test Structure
```
test/
├── widget_test.dart                          # Basic widget test
├── helpers/
│   └── test_fixtures.dart                    # Shared sample exercises (sampleExercises list)
├── models/
│   ├── set_data_test.dart
│   ├── user_profile_test.dart
│   ├── weekly_plan_import_test.dart
│   └── workout_record_test.dart
├── services/
│   ├── exercise_matcher_service_test.dart    # Fuzzy matching (uses test_fixtures.dart)
│   ├── stats_calculator_service_test.dart
│   ├── database_migration_test.dart           # v2→v3 migration (sqflite_ffi)
│   └── ai_prompt_service_test.dart
├── widgets/
│   └── ai_plan_wizard_screen_test.dart
└── integration/
    ├── ai_plan_import_e2e_test.dart           # Full AI plan import flow
    └── detailed_recording_e2e_test.dart       # Detailed recording with per-set data
```

### Critical: sqflite_ffi Initialization
Database tests MUST initialize sqflite_ffi before any DB operations:
```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});
```
Without this, tests crash with platform errors on desktop/web.

### Test Fixtures
`test/helpers/test_fixtures.dart` exports `sampleExercises` — a `List<Exercise>` with bilingual names and full muscle group data. Used by matcher tests and AI prompt tests.

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

---

## DESIGN SYSTEM (Flat Vitality)

### Color Usage
| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | Warm gradient (primary → secondary) | Darkened gradient (preserves hue) |
| Accent/Interactive | Deep indigo (#1A237E) | Same accent |
| Progress Ring | `accentColor`, 10px stroke | Same |
| Buttons | White circular with accent icons | Dark surface circular |
| Cards/Surfaces | White (#FFFFFF) | #2A2A3C |
| Base surface | #FFFFFF | #1E1E2E |
| Text (primary) | #212121 | #E8E8E8 |
| Text (secondary) | #757575 | #9E9E9E |
| Active indicators | `accentColor.withValues(alpha: 0.15)` | Same |
| Borders | `accentColor.withValues(alpha: 0.3-0.4)` | Same |
| Error | #E53935 | #EF5350 |
| Success | #4CAF50 | #66BB6A |
| Error background | #F5E6E6 | #3E2723 |
| Divider | #E0E0E0 | #3A3A4A |

### Fonts
- Display: `.SF Pro Display` (system font)
- Body: `.SF Pro Text` (system font)
- Timer: `Orbitron`, `Rajdhani` (custom fonts, bundled in `fonts/`)

### Navigation Bar
- Floating design with `extendBody: true`
- 5 buttons: Plan, History, Timer (center), Stats, Settings
- Center timer button: 70x70 circle, gradient, aligned at bottom
- Nav bar: 4-corner radius (25px), white background

### Custom Widgets
- `CircularControlButton` — 56px white circle with shadow, PressableMixin for scale animation
- `FadeUpPageRoute` — slide-up page transition used across all navigation

---

## KEY LOCATIONS

| Task | Location |
|------|----------|
| Timer countdown | `bloc/timer_provider.dart` (`_tick()`) |
| Preset times | `bloc/timer_provider.dart:20` (`[30, 60, 90, 120]`) |
| Training states | `bloc/training_provider.dart` (`TrainingState` enum) |
| DB schema + migrations | `services/database_helper.dart` (`_onCreate()`, `_onUpgrade()`) |
| Theme definitions | `theme/app_theme.dart` |
| Dark theme getter | `theme/app_theme.dart:79-118` (`AppThemeData.dark`) |
| Dark mode toggle | `theme/theme_provider.dart` (`isDarkMode`, `setDarkMode()`) |
| Dark mode UI | `screens/settings_screen.dart` ("深色模式" switch) |
| Exercise data loading | `services/exercise_service.dart` |
| Exercise fuzzy matching | `services/exercise_matcher_service.dart` |
| AI prompt generation | `services/ai_prompt_service.dart` |
| Stats / 1RM calculation | `services/stats_calculator_service.dart` |
| Bodyweight volume coeff | `services/bodyweight_coefficient_service.dart` |
| User preferences | `services/user_preferences_service.dart` |
| Bottom navigation | `main.dart` (`MainNavigation` widget) |
| AI plan wizard | `screens/ai_plan_wizard_screen.dart` |
| AI analysis dashboard | `screens/ai_analysis_screen.dart` |
| Exercise selection | `screens/exercise_selection_screen.dart` |
| Plan form | `screens/plan_form_screen.dart` |
| Record detail | `screens/record_detail_screen.dart` |
| User preferences screen | `screens/user_preferences_screen.dart` |
| Calendar widget | `widgets/calendar_widget.dart` |
| Glass/circular buttons | `widgets/glass_widgets.dart` |
| Dimensions/spacing | `utils/dimensions.dart` (`AppDimensions`) |
| Shared test fixtures | `test/helpers/test_fixtures.dart` |

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

## GIT COMMIT RULES

### Atomic Commit Principle

**One commit = one logical change.** 每个提交只做一件事，可以独立 review、独立 revert、独立 cherry-pick。

### Commit Scope Rules

| 维度 | 规则 | 说明 |
|------|------|------|
| **功能** | 一个 commit 只包含一个功能/修复 | 修 bug 不混新功能，新功能不混重构 |
| **层级** | 一个 commit 尽量只动一个层级 | model / service / widget / screen 分开提交 |
| **文件** | 单个 commit 不超过 10 个文件 | 超过则拆分：先 data 层，再 service 层，再 UI 层 |
| **TDD** | RED 和 GREEN 分开提交 | 测试文件单独一个 commit，实现代码单独一个 commit |
| **lint** | lint 修复单独提交 | 不混入功能代码 |
| **文档/配置** | AGENTS.md / pubspec.yaml / CI 配置单独提交 | 不混入业务代码 |

### Commit Message Format

```
<type>(<scope>): <简短描述>

[可选：详细说明为什么改、改了什么]
```

**Type**:
- `feat(scope)` — 新功能
- `fix(scope)` — 修复 bug
- `refactor(scope)` — 重构（不改变行为）
- `test(scope)` — 添加/修改测试
- `chore` — 构建/CI/配置/依赖
- `docs` — 文档更新
- `style(scope)` — 格式/lint 修复

**Scope**: 可选，建议填写。例：`training`, `stats`, `favorites`, `sound`, `theme`, `db`

### Examples (GOOD)

```
test(training): add failing tests for rest timer pause (RED)
feat(training): add pauseRest/resumeRest to TrainingProvider (GREEN)
fix(volume): integrate bodyweight coefficient into RecordedExercise
feat(favorites): add exercise favorites DB v5 migration
feat(favorites): add favorites filter chip to exercise selection screen
fix(theme): replace hardcoded Colors.white in plan screens
chore: remove dead widgets rest_timer_widget and session_stopwatch_widget
refactor(training): replace !kIsWeb with _canUsePlatformServices helper
```

### Anti-Patterns (BAD)

```
# ❌ 混合多个不相关变更
feat: implement audit findings - P0 bug fixes, P1 features, P2 enhancements, cleanup, dark mode

# ❌ 测试和实现混在一起
feat: add favorites with tests

# ❌ 过于笼统
fix: bug fix

# ❌ 一个 commit 25 个文件
feat: everything
```

### Staging Rules

1. 提交前用 `git diff --cached --name-status` 确认暂存区只有本次提交相关的文件
2. 如果 staged files 超过 10 个，拆分成多个 commit
3. 每次提交前确保 `flutter test` 和 `flutter analyze` 通过
4. 不要提交与本次功能无关的文件（其他任务的半成品、IDE 配置等）

---

## ANTI-PATTERNS (AVOID)

| Pattern | Issue | Instead |
|---------|-------|---------|
| Empty catch blocks | Silent failures | Log + rethrow/continue |
| `!` operator | Runtime crashes | Null check `if (x != null)` |
| Service in Provider | Hard to test | Constructor injection |
| Release without `--no-tree-shake-icons` | Icons show as garbled | Use `build_release.sh` |
| Direct color values | Breaks theming | Use `AppThemeData` fields |
| `Colors.white` / `Colors.black` | Breaks dark mode | Use `theme.surfaceColor` / `theme.textColor` |
| Hardcoded dark colors in light mode | Wrong appearance | Use `ThemeProvider.currentTheme` |
| Bottom padding in main content | Nav bar overlap | Use `extendBody: true`, add padding per-screen |
| GridView with shrinkWrap in scrollable | Extra blank rows | Use LayoutBuilder + SizedBox with calculated height |
| Fixed height SizedBox for variable content | Content clipped | Remove constraint, let content size naturally |
| Skipping sqflite_ffi init in tests | Platform crash | Always call `sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi` in `setUpAll` |

---

## KNOWN ISSUES

- **bloc/ naming**: Directory uses Provider (ChangeNotifier), not BLoC pattern
- **No dependency injection**: Services instantiated inside providers
- **Mixed comments**: Code uses both English and Chinese comments
- **Large screen files**: `stats_screen.dart` (2549 lines), `exercise_selection_screen.dart` (811 lines), `ai_analysis_screen.dart` (1163 lines) — consider splitting

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
