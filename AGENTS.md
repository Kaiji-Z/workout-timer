# AGENTS.md - WorkoutTimer Flutter App

**Updated:** 2026-06-22
**Branch:** master

## OVERVIEW

Cross-platform Flutter workout rest timer with preset durations (30s/60s/90s/120s), multi-channel notifications, SQLite-backed workout history, AI plan generation, per-set recording, and bodyweight volume tracking. Supports Android, iOS, Web, and Desktop.

**Architecture**: MVVM with Provider (ChangeNotifier), services layer, local SQLite.
**Stack**: Flutter 3.10+ / Dart 3.10.7+ / sqflite + sqflite_common_ffi / provider / flutter_local_notifications / uuid / intl / fuzzy / fl_chart / cached_network_image / google_fonts / string_similarity / flutter_localizations (gen-l10n).
**Design System**: "Flat Vitality" — warm gradients, deep indigo accent (#1A237E), white circular buttons.
**Database**: SQLite v5 with incremental migrations (v1→v2→v3→v4→v5).

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
flutter analyze lib/providers/      # Analyze specific directory
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
│   ├── animation_primitives.dart # AnimatedCard, CountUp, Shimmer
│   ├── list_animations.dart
│   └── page_transitions.dart # FadeUpPageRoute, ScaleFadePageRoute (slide-up transition)
├── providers/                   # State providers (ChangeNotifier, MVVM)
├── core/                        # ServiceLocator (dependency injection)
├── l10n/                        # Generated AppLocalizations + arb files
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
│   ├── ui_components.dart    # SheetDragHandle, SectionHeader, InfoBanner, EmptyState
│   ├── circular_progress_painter.dart # Progress ring painter
│   ├── completed_medal_display.dart   # Completed workout medal
│   ├── touch_target.dart    # Touch target size helpers (accessibility)
│   ├── semantics_helpers.dart # Semantic labeling helpers
│   └── volume_trend_charts.dart # Volume trend chart widgets
├── theme/                    # Flat Vitality theme (3 themes: amberGold, coralOrange, skyBlue)
│   ├── app_theme.dart        # Theme data models
│   └── theme_provider.dart   # Theme state + persistence
├── services/                 # Database, notifications, repositories
│   ├── database_helper.dart  # SQLite singleton, v5 schema, migrations
│   ├── notification_service.dart # Local notifications
│   ├── notification_sound_service.dart # Notification sound playback
│   ├── exercise_service.dart # Exercise data loading
│   ├── exercise_matcher_service.dart # Fuzzy exercise name matching
│   ├── exercise_favorites_service.dart # Exercise favorites CRUD
│   ├── ai_prompt_service.dart # AI plan prompt generation
│   ├── stats_calculator_service.dart # Strength data, volume, 1RM estimation
│   ├── bodyweight_coefficient_service.dart # Bodyweight exercise volume estimation
│   ├── battery_optimization_service.dart # Battery optimization request (Android)
│   ├── user_preferences_service.dart # Training preferences persistence
│   ├── timer_service.dart    # Android foreground service via MethodChannel
│   ├── data_transfer_service.dart # Data export/import (JSON)
│   ├── workout_repository.dart   # Session data
│   ├── plan_repository.dart      # Plan CRUD
│   └── record_repository.dart    # Record CRUD
├── utils/                    # Design tokens, vocabulary
│   └── dimensions.dart       # AppDimensions: radius tokens (8 levels), screenPadding, nav bar sizes, responsive helpers
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

// DATA-LOSS PATH - surface to user via ErrorReporter (injected via ServiceLocator)
try {
  await _repository.saveRecord(record);
} catch (e, st) {
  _errorReporter.report(e, severity: ErrorSeverity.userWarning,
    stackTrace: st, message: '记录保存失败，请重试');
  rethrow;
}

// NEVER - empty catch
try { ... } catch (e) {}
```

### Dependency Injection
Services are registered in `ServiceLocator.setup()` (called once in `main()`).
Providers resolve them via optional constructor params defaulting to the registry,
so production call sites stay unchanged but tests can inject mocks:
```dart
// Provider - production gets the real service, tests pass a mock
TimerProvider({
  NotificationService? notificationService,
  WorkoutRepository? repository,
  ErrorReporter? errorReporter,
})  : _notificationService =
          notificationService ?? ServiceLocator.get<NotificationService>(),
      ...;

// Test
final provider = TimerProvider(repository: mockRepo);
```
Static facade classes (`TimerService`, `ExerciseService`, `DatabaseHelper`) are
NOT registered — they have no per-instance state and are consumed via static methods.

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

## OEM 后台保活 (Background Keep-Alive on Chinese ROMs)

国产 ROM 的"自启动"和"省电/后台耗电"是**两套独立**的设置。仅开自启动无法保证 app 切到后台后继续倒计时——真正决定后台存活的是省电设置。设置页提供两层引导:

1. **标准"后台运行"卡片** → `requestIgnoreBatteryOptimizations()`:标准 Android 电池优化白名单。
2. **"厂商后台管理"卡片** → `requestOemAutoStart()`:打开厂商专属省电页(由 `MainActivity.getOemAutoStartIntents()` 跳转)。

**各厂商后台计时存活的关键设置**(intent 列表在 `MainActivity.kt` 按此优先级排序,省电页面优先、自启动降级):

| 厂商 | 关键设置(决定后台存活) | intent 入口 |
|------|------------------------|------------|
| 华为/荣耀 HarmonyOS | 应用启动管理→关自动管理→勾"允许后台活动" | `StartupNormalAppListActivity` |
| 小米 MIUI/HyperOS | 省电策略→"无限制"(核心);神隐模式白名单(旧版) | `powerkeeper/HiddenAppsContainerManagementActivity` |
| OPPO ColorOS | 关闭"耗电保护"/后台冻结 | `safecenter/StartupAppListActivity` |
| vivo OriginOS | "后台高耗电"→允许(核心);电池白名单 | `AddWhiteListActivity` / `ExcessivePowerManagerActivity` |
| 三星 One UI | 电池→"不受限制"(包名多变) | `lool/BatteryActivity` |
| 魅族 Flyme | 智能休眠白名单 | `SmartBGActivity` |
| 一加 OxygenOS | 电池优化→"不优化" | `ChainLaunchAppListActivity` |

**探测逻辑**:`requestOemAutoStart` 遍历 intent 列表,用 `resolveActivity` 找第一个存在的并打开(try-catch 兜底回退到应用详情页)。修改某厂商跳转目标时,**调整列表顺序即可**,探测逻辑无需动。

**维护提示**:各厂商不同系统版本的 Activity 类名会变。更新时保持"省电/电池页面在前、自启动在后"的优先级,并广撒网(多个已知 ComponentName)让 `resolveActivity` 自动兜底。不要把自启动页排在最前——否则会复现"跳到自启动而非后台耗电"的 bug。

---

## DATABASE

### Schema (v5)
9 tables with foreign keys and indexes:
- `workout_sessions` — Legacy simple session (id, sets, rest_time_ms, created_at)
- `exercises` — Exercise definitions (id, name, name_en, primary_muscle, secondary_muscles, equipment, level, image_url, muscle_image_url, recommended_sets/reps/rest)
- `workout_plans` — Plan templates (id, name, target_muscles, estimated_duration)
- `plan_exercises` — Plan→Exercise join (plan_id, exercise_id, target_sets, custom_sets, exercise_order, unmatched_name)
- `calendar_plans` — Date→Plan scheduling (date, plan_id) with UNIQUE(date, plan_id)
- `workout_records` — Detailed workout records (date, duration_seconds, trained_muscles, plan_id, plan_name, total_sets)
- `record_exercises` — Record→Exercise join (record_id, exercise_id, completed_sets, max_weight, per_set_data)
- `favorite_exercises` — Exercise favorites (exercise_id PK, created_at)

### Migration History
| Version | Changes |
|---------|---------|
| v1 | Initial: `workout_sessions` table only |
| v2 | Added 6 tables: exercises, workout_plans, plan_exercises, calendar_plans, workout_records, record_exercises + indexes |
| v3 | Added `per_set_data TEXT` column to `record_exercises` (JSON-encoded SetData array) |
| v4 | Added `unmatched_name TEXT` column to `plan_exercises` (for unmatched custom exercises) |
| v5 | Added `favorite_exercises` table (exercise_id PK, created_at) for exercise favorites |

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
├── theme/
│   ├── design_tokens_test.dart               # Token existence + isDark field tests
│   └── compliance_guardrail_test.dart        # Source-scan: no hardcoded values outside exempt files
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
| Timer countdown | `providers/timer_provider.dart` (`_tick()`) |
| Preset times | `providers/timer_provider.dart:20` (`[30, 60, 90, 120]`) |
| Training states | `providers/training_provider.dart` (`TrainingState` enum) |
| DB schema + migrations | `services/database_helper.dart` (`_onCreate()`, `_onUpgrade()`) |
| Theme definitions | `theme/app_theme.dart` |
| Dark theme getter | `theme/app_theme.dart:79-118` (`AppThemeData.dark`) |
| Dark mode toggle | `theme/theme_provider.dart` (`isDarkMode`, `setDarkMode()`) |
| Dark mode UI | `screens/settings_screen.dart` ("深色模式" switch) |
| Exercise data loading | `services/exercise_service.dart` |
| Exercise fuzzy matching | `services/exercise_matcher_service.dart` |
| AI prompt generation | `services/ai_prompt_service.dart` |
| **Dependency injection** | `core/service_locator.dart` (`ServiceLocator.setup/get`) |
| Stats aggregation | `services/stats_aggregator_service.dart` |
| Error reporting | `services/error_reporter_service.dart` (`ErrorSeverity.userWarning`) |
| Localization | `lib/l10n/` (arb + generated `AppLocalizations`) |
| Stats / 1RM calculation | `services/stats_calculator_service.dart` |
| Bodyweight volume coeff | `services/bodyweight_coefficient_service.dart` |
| Exercise favorites | `services/exercise_favorites_service.dart` |
| Battery optimization | `services/battery_optimization_service.dart` |
| Data export/import | `services/data_transfer_service.dart` |
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

## GIT REMOTES & 推送规则

**主仓库是 GitHub**(CI 在 GitHub Actions 上跑),Gitee 是国内镜像副仓。

| Remote | URL | 角色 |
|--------|-----|------|
| `origin` | `github.com/Kaiji-Z/workout-timer` | **主仓库**,跑 CI,默认 push/pull 目标 |
| `gitee` | `gitee.com/kaiji1126/workout-timer` | 国内镜像副仓,需显式推送 |

### 推送命令

```bash
git push                 # → GitHub(默认,触发 CI)
git push origin          # → 同上
git push gitee master    # → Gitee(显式,同步镜像)
git pushall              # → 两边都推(见下方 alias)
```

master 的 upstream 已设为 `origin/master`,所以 `git push`/`git pull` 默认走 GitHub。

### 双推 alias(可选,推荐)

```bash
git config alias.pushall '!git push origin && git push gitee'
# 以后 git pushall 一条命令推两边
```

### 踩过的坑(别再踩)

1. **`origin` 曾是 Gitee**:历史上 `origin` 指向 Gitee,导致只 `git push` 不触发 GitHub CI。已于 2026-06-22 对调,`origin` 现为 GitHub。**接手时先 `git remote -v` 确认**。
2. **改了 workflow 自身不一定触发该 workflow**:Android workflow 的 `paths-ignore` 含 `.github/workflows/ios-build.yml`(反之亦然)。改 workflow 文件本身后,push 可能因 paths 规则不触发对应 CI。**保险做法:改完 workflow 后用 `gh workflow run "<name>" --ref master` 手动补一次验证**。
3. **国内镜像只在本地有用,在海外 CI 上有害**:阿里云/清华镜像在 GitHub runner(美国机房)上会拉不到依赖或超时。镜像配置规则见下方「CI 镜像规则」。

---

## CI 镜像规则(国内镜像 vs 海外 CI)

项目本地用国内镜像加速依赖下载,但这些镜像在 GitHub Actions runner(海外)上会拖慢甚至搞挂构建。两类处理方式:

| 场景 | 做法 | 本次案例 |
|------|------|---------|
| 镜像对本地无实际价值 | 直接换成官方 CDN 源 | iOS Podfile → `cdn.cocoapods.org`(原来是清华镜像) |
| 镜像对本地真有用 | CI 里 sed 临时删镜像行,git 仓库文件不动 | Android gradle → CI-only sed 去阿里云镜像 |

### 当前镜像配置位置

- **Android**:`android/settings.gradle.kts`、`android/build.gradle.kts` 的 `maven.aliyun.com` / `mirrors.tencent.com` 行。CI 在 `android-build.yml` 的 `Strip China mirrors from Gradle (CI-only)` 步骤用 sed 删除(仅 CI 工作副本)。
- **iOS**:`ios/Podfile` 已改为官方 CDN(`cdn.cocoapods.org`),本地构建不受影响(开发者本就不在 Windows 跑 iOS)。

### 加镜像前的自检

> 凡是要加国内镜像源,先问:这个镜像在 GitHub runner(海外)上会怎样?想清楚再写,并配套 CI 处理。

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

- **Mixed comments**: Code uses both English and Chinese comments
- **Large screen files**: `stats_screen.dart` (~2150 lines, aggregation logic extracted into StatsAggregatorService), `plan_form_screen.dart` (~1040 lines), `exercise_selection_screen.dart` (872 lines), `ai_analysis_screen.dart` (899 lines)
- **Force-non-null (`!`)**: ~450 usages remain; convert to explicit null checks incrementally
- **i18n partial**: gen-l10n framework is in place but most UI strings are still hardcoded Chinese

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

---

## Design Context

视觉设计规范文档见 `PRODUCT.md`(战略)与 `DESIGN.md`(视觉系统)。以下是精炼摘要,便于 agent 快速对齐:

- **Register**: product(应用 UI,设计服务于产品)
- **创意北极星**: "汗水与冷静" — 暖背景(汗水)对决深靛蓝 #1A237E(冷静),缺一不可。
- **品牌人格**: 温暖 · 克制 · 专一(Warm · Disciplined · Single-minded)。
- **5 条设计原则**: 单核不妥协 / 温暖即立场 / 克制比丰富更难 / 扫一眼就懂 / 数据归用户。

**必守的命名规则**(变体生成与改稿时强制遵守):
- **The Duality Rule** — 暖背景与深靛蓝必须同场;不能只有暖色或只有深蓝。
- **The 15% Tint Rule** — 激活态背景统一 `accentColor.withValues(alpha: 0.15)`。
- **The No-Glow Rule** — 禁止发光/玻璃/彩色光晕;仅进度环抗锯齿柔化例外。
- **The Tabular-Numbers Rule** — 所有会变化的数字用 `FontFeature.tabularFigures()`。
- **The One Display Font Rule** — Orbitron/Rajdhani 只用于计时器倒计时数字。

**反例(永远不做)**:广告堆满的健身 App / 冷冰冰的临床记录器 / 过度玻璃动画堆砌 / 千篇一律的 SaaS 仪表盘。

**取色铁律**: 永远走 `ThemeProvider.currentTheme`,永不硬编码 `Colors.white`/`Colors.black`。图表用 `ChartPalette`(Okabe-Ito 色盲安全),不用品牌深靛蓝。

> 完整 token、组件规范、Do's/Don'ts 见 `DESIGN.md`;机器可读 sidecar 见 `.impeccable/design.json`。
