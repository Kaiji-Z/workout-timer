# Audit Implementation Plan

**Generated**: 2026-06-03
**Tasks**: 20 (T1–T20)
**Waves**: 5
**Critical Path**: T1→T2→T3 (bodyweight) | T4→T5→T6 (pause)

---

## Task Dependency Graph

| Task | Depends On | Reason |
|------|------------|--------|
| T1: Bodyweight volume tests (RED) | None | Starting point |
| T2: Bodyweight volume impl (GREEN) | T1 | Makes tests pass |
| T3: Bodyweight volume integration tests | T2 | Full pipeline test |
| T4: Pause rest tests (RED) | None | Starting point |
| T5: Pause rest impl (GREEN) | T4 | Makes tests pass |
| T6: Pause rest wire into training_widget | T5 | UI integration |
| T7: Dead code analysis | None | Independent |
| T8: Dead code removal | T7 | Must analyze first |
| T9: Dark mode fix (plan screens) | None | Independent UI fix |
| T10: e1RM trend chart tests (RED) | T8 | fl_chart decision needed |
| T11: e1RM trend chart impl (GREEN) | T10 | Makes tests pass |
| T12: Volume trend chart tests (RED) | T2, T10 | Needs bodyweight vol + chart framework |
| T13: Volume trend chart impl (GREEN) | T12 | Makes tests pass |
| T14: Exercise favorites tests (RED) | None | Starting point |
| T15: Exercise favorites impl (GREEN) | T14 | Makes tests pass |
| T16: Exercise favorites UI | T15 | Wire into selection screen |
| T17: Custom sounds tests (RED) | None | Starting point |
| T18: Custom sounds impl (GREEN) | T17 | Makes tests pass |
| T19: Kotlin 3-2-1 countdown beeps | T18 | Native-side beep |
| T20: Sound picker UI | T18 | Settings screen |

---

## Parallel Execution Waves

```
Wave 1 (Start immediately — P0 bugs + independent analysis):
├── T1: Bodyweight volume tests (RED)
├── T4: Pause rest tests (RED)
├── T7: Dead code analysis
├── T9: Dark mode fix (plan screens)
└── T14: Exercise favorites tests (RED)

Wave 2 (After Wave 1):
├── T2: Bodyweight volume impl (GREEN) [depends: T1]
├── T5: Pause rest impl (GREEN) [depends: T4]
├── T8: Dead code removal [depends: T7]
└── T15: Exercise favorites impl (GREEN) [depends: T14]

Wave 3 (After Wave 2):
├── T3: Bodyweight volume integration tests [depends: T2]
├── T6: Pause rest wire into training_widget [depends: T5]
├── T10: e1RM trend chart tests (RED) [depends: T8]
├── T16: Exercise favorites UI [depends: T15]
└── T17: Custom sounds tests (RED) [no strict dep]

Wave 4 (After Wave 3):
├── T11: e1RM trend chart impl (GREEN) [depends: T10]
├── T12: Volume trend chart tests (RED) [depends: T2, T10]
├── T18: Custom sounds impl (GREEN) [depends: T17]
└── T19: Kotlin 3-2-1 countdown beeps [depends: T18]

Wave 5 (After Wave 4):
├── T13: Volume trend chart impl (GREEN) [depends: T12]
└── T20: Sound picker UI [depends: T18]
```

---

## Task Details

### T1: Bodyweight Volume Bug — Tests (RED) — P0-3 — S
- **NEW file**: `test/services/bodyweight_volume_test.dart`
- **Test** `RecordedExercise.bodyweightAdjustedVolume(70.0)` for bodyweight exercise returns non-zero
- **Test** `totalVolume` still returns raw `reps * weight` (backward compat)
- **Test** non-bodyweight `bodyweightAdjustedVolume()` returns same as `totalVolume`
- **Test** `SetData.volume` with weight=0 returns 0 (unchanged)
- QA: `flutter test test/services/bodyweight_volume_test.dart` — FAIL (expected)

### T2: Bodyweight Volume Bug — Implementation (GREEN) — P0-3 — M
- **Files**: `lib/models/workout_record.dart`, `lib/services/stats_calculator_service.dart`, `lib/services/record_repository.dart`
- Add `bodyweightAdjustedVolume(double bodyWeight)` getter to `RecordedExercise`
- Update 5 methods in StatsCalculatorService to use adjusted volume when bodyweight > 0
- Update `record_repository.dart:getTotalVolume()` (line 348)
- Do NOT touch `record_detail_screen.dart:639`
- QA: tests GREEN, `flutter test` all pass

### T3: Bodyweight Volume — Integration Tests — P0-3 — S
- **NEW file**: `test/services/bodyweight_volume_integration_test.dart`
- Full pipeline test: WorkoutRecord with bodyweight exercises → StatsCalculatorService → non-zero volume
- QA: all pass

### T4: Pause Timer During Set Dialog — Tests (RED) — P0-4 — S
- **NEW file**: `test/bloc/training_provider_rest_pause_test.dart`
- Test `pauseRest()` from `resting` state → `restPaused`, timer canceled, remaining preserved
- Test `resumeRest()` from `restPaused` → `resting`, timer restarts with remaining
- Test guards: no-op from wrong states
- QA: FAIL (expected)

### T5: Pause Timer — Implementation (GREEN) — P0-4 — M
- **Files**: `lib/bloc/training_provider.dart`, `lib/services/timer_service.dart`
- Add `TrainingState.restPaused` to enum
- Add `pauseRest()`: cancel `_timer`, preserve `_restRemaining`, set state, pause native countdown
- Add `resumeRest()`: restart `_startRestTimer()`, resume native countdown
- QA: tests GREEN

### T6: Pause Timer — Wire into TrainingWidget — P0-4 — S
- **File**: `lib/widgets/training_widget.dart`
- Wrap `SetRecordDialog.show()` in `_showSetRecordDialog()` with pauseRest/resumeRest
- QA: manual test

### T7: Dead Code Analysis — Cleanup — S
- **NEW file**: `.omo/plans/dead-code-analysis.md`
- Confirm dead widgets: rest_timer_widget.dart, session_stopwatch_widget.dart
- Confirm dead methods: goToExercise(), nextExercise() in training_progress_provider.dart
- Decide fl_chart: keep (use for charts) or remove
- Report with recommendations

### T8: Dead Code Removal — Cleanup — S
- DELETE `lib/widgets/rest_timer_widget.dart`
- DELETE `lib/widgets/session_stopwatch_widget.dart`
- Remove dead methods from `training_progress_provider.dart`
- Keep fl_chart in pubspec.yaml
- QA: `flutter test` + `flutter analyze`

### T9: Dark Mode Fix — Plan Screens — P1 — S
- **Files**: `lib/screens/plan_screen.dart` (8 instances), `lib/screens/plan_form_screen.dart` (10 instances)
- Replace hardcoded `Colors.white` with theme tokens
- Context analysis needed per instance (some white-on-gradient may be intentional)
- QA: `flutter analyze`, visual check in dark mode

### T10: e1RM Trend Chart — Tests (RED) — P1-2 — S
- **NEW file**: `test/widgets/strength_trend_chart_test.dart`
- Test StrengthTrendChart widget renders with sample data
- QA: FAIL (widget doesn't exist)

### T11: e1RM Trend Chart — Implementation (GREEN) — P1-2 — M
- **NEW file**: `lib/widgets/strength_trend_chart.dart`
- **File**: `lib/screens/stats_screen.dart`
- fl_chart LineChart, Flat Vitality styling
- Exercise name selector, date x-axis, e1RM y-axis
- Wire into stats_screen after muscle distribution
- QA: tests GREEN

### T12: Volume Trend Charts — Tests (RED) — P1-3 — S
- **NEW file**: `test/widgets/volume_trend_chart_test.dart`
- Test WeeklyVolumeChart, DailyVolumeChart, SecondaryMuscleVolumeChart
- Uses bodyweight-adjusted volume
- QA: FAIL

### T13: Volume Trend Charts — Implementation (GREEN) — P1-3 — M
- **NEW file**: `lib/widgets/volume_trend_chart.dart`
- **File**: `lib/screens/stats_screen.dart`
- fl_chart BarChart (weekly), LineChart (daily), PieChart (secondary muscle)
- Add to stats_screen after e1RM section
- QA: all pass

### T14: Exercise Favorites — Tests (RED) — P1-7 — S
- **NEW file**: `test/services/exercise_favorites_service_test.dart`
- Test toggle, isFavorite, getFavoriteIds, DB migration v4→v5
- sqfliteFfiInit() in setUpAll
- QA: FAIL

### T15: Exercise Favorites — Implementation (GREEN) — P1-7 — M
- **Files**: `lib/services/database_helper.dart` (v5 migration)
- **NEW file**: `lib/services/exercise_favorites_service.dart`
- `favorite_exercises` table (exercise_id PK, created_at)
- toggleFavorite, isFavorite, getFavoriteIds, getFavoriteExercises
- QA: tests GREEN + migration tests pass

### T16: Exercise Favorites — UI — P1-7 — M
- **File**: `lib/screens/exercise_selection_screen.dart`
- Favorites filter chip following equipment chip pattern (lines 287-333)
- Heart toggle icon on list items
- QA: manual test

### T17: Custom Sounds — Tests (RED) — P2 — S
- **NEW file**: `test/services/notification_sound_service_test.dart`
- Test getSelectedSound, setSelectedSound, getAvailableSounds
- QA: FAIL

### T18: Custom Sounds — Implementation (GREEN) — P2 — M
- **NEW file**: `lib/services/notification_sound_service.dart`
- **File**: `lib/services/notification_service.dart`
- **Dir**: `android/app/src/main/res/raw/` (MP3 assets)
- Wire RawResourceAndroidNotificationSound
- QA: tests GREEN

### T19: Kotlin 3-2-1 Countdown Beeps — P2 — S
- **File**: `android/app/src/main/kotlin/com/kaiji/workouttimer/TimerService.kt`
- SoundPool beeps in onTick() when remaining <= 3
- QA: manual test

### T20: Sound Picker UI — P2 — S
- **File**: `lib/screens/settings_screen.dart`
- Sound picker ListTile in notification section
- QA: manual test

---

## Key Decisions

| Decision | Recommendation | Reason |
|----------|---------------|--------|
| Bodyweight integration | Option C: new `bodyweightAdjustedVolume` getter | Backward compat, minimal call site changes |
| Chart framework | **fl_chart** (RECOMMENDED) | Already in pubspec.yaml, production-quality |
| Favorites storage | Separate SQLite table (not column on exercises) | Exercises are static JSON, read-only |
| Dead fl_chart dependency | Keep and use | Resurrects dead code, better charts |

---

## Success Criteria

1. `flutter test` — all tests pass
2. `flutter analyze` — no errors
3. Bodyweight exercises show non-zero volume in stats (P0-3)
4. Rest timer pauses when set dialog opens, resumes when closed (P0-4)
5. Dead widgets and methods removed, no dangling imports
6. Plan screens render correctly in dark mode
7. e1RM and volume trend charts display in stats screen (P1-2, P1-3)
8. Exercise favorites persist across sessions (P1-7)
9. Custom notification sounds play on timer completion (P2)
10. 3-2-1 countdown beeps play in Android foreground service (P2)
