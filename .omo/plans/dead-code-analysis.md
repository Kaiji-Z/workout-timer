# Dead Code Analysis Report

**Date:** 2026-06-03
**Scope:** Full codebase scan (lib/ + test/)

---

## 1. `lib/widgets/rest_timer_widget.dart`

- **Status:** CONFIRMED DEAD
- **Evidence:** grep for `rest_timer_widget` across entire `lib/` — only match is the filename itself listed in `lib/widgets/AGENTS.md` (documentation reference). Zero Dart imports found.
- **Recommendation:** DELETE
- **Reason:** Completely unused widget. No file imports it, no test references it. Safe to remove.

---

## 2. `lib/widgets/session_stopwatch_widget.dart`

- **Status:** CONFIRMED DEAD
- **Evidence:** grep for `session_stopwatch_widget` across entire `lib/` — only match is the filename listed in `lib/widgets/AGENTS.md` (documentation reference). Zero Dart imports found.
- **Recommendation:** DELETE
- **Reason:** Completely unused widget. No file imports it, no test references it. Safe to remove.

---

## 3. `training_progress_provider.dart` — `goToExercise()`

- **Status:** CONFIRMED DEAD
- **Evidence:** grep for `.goToExercise(` across entire `lib/` and `test/` — zero matches. Only match is the method definition itself (line 187).
- **Recommendation:** DELETE
- **Reason:** Zero callers in production code or tests. Dead method.

---

## 4. `training_progress_provider.dart` — `nextExercise()`

- **Status:** CONFIRMED DEAD
- **Evidence:** grep for `.nextExercise(` across entire `lib/` and `test/` — zero matches. Only match is the method definition itself (line 176). Note: `getNextExercise()` is a DIFFERENT method that IS alive (called from `training_widget.dart` line 186).
- **Recommendation:** DELETE
- **Reason:** Zero callers in production code or tests. Confused with `getNextExercise()` but is a distinct dead method.

---

## 5. `fl_chart` dependency

- **Status:** CONFIRMED DEAD (as dependency)
- **Evidence:** grep for `fl_chart` across entire `lib/` — zero matches. No Dart file imports `fl_chart`.
- **Recommendation:** KEEP (deferred)
- **Reason:** Listed in pubspec.yaml but never imported. Per roadmap P1-2/P1-3, fl_chart will be needed for trend charts. **Keep for now** — removing would just require re-adding later. Add a TODO comment in pubspec.yaml if desired.

---

## 6. `stats_calculator_service.dart` — `calculateExerciseStrengthTrend()`

- **Status:** CONFIRMED DEAD in UI, ALIVE in tests
- **Evidence:** grep for `calculateExerciseStrengthTrend` — only match is the method definition (line 165). No callers in `lib/` or `test/`.
- **Recommendation:** RESURRECT for P1-2
- **Reason:** Intended for strength trend charts. No tests exist for it yet either. Keep the method, wire it into UI during P1-2.

---

## 7. `stats_calculator_service.dart` — `calculateWeeklyVolumeTrend()`

- **Status:** ALIVE (has test coverage)
- **Evidence:** grep for `calculateWeeklyVolumeTrend` — found in:
  - Definition: `stats_calculator_service.dart` line 67
  - Unit tests: `test/services/stats_calculator_service_test.dart` (7 references, test group at line 274)
  - Integration test: `test/integration/detailed_recording_e2e_test.dart` (lines 278, 317)
  - **Zero callers in `lib/` (production UI)**
- **Recommendation:** RESURRECT for P1-3
- **Reason:** Has comprehensive test coverage but is not wired into any UI screen. The method is production-ready — just needs to be connected to the stats screen during P1-3.

---

## 8. `stats_calculator_service.dart` — `calculateDailyVolumeTrend()`

- **Status:** CONFIRMED DEAD (no callers, no tests)
- **Evidence:** grep for `calculateDailyVolumeTrend` — only match is the method definition (line 309). No callers in `lib/` or `test/`.
- **Recommendation:** RESURRECT for P1-3
- **Reason:** Intended for daily volume trend visualization. No tests yet. Keep the method, wire into UI and add tests during P1-3.

---

## 9. `stats_calculator_service.dart` — `calculateSecondaryMuscleVolumeDistribution()`

- **Status:** CONFIRMED DEAD (no callers, no tests)
- **Evidence:** grep for `calculateSecondaryMuscleVolumeDistribution` — only match is the method definition (line 261). No callers in `lib/` or `test/`.
- **Recommendation:** RESURRECT for P1-3
- **Reason:** Intended for secondary muscle group distribution visualization. Keep the method, wire into UI during P1-3.

---

## 10. `lib/screens/plan_screen.dart` — Hardcoded `Colors.white`

- **Status:** CONFIRMED — 8 instances
- **Evidence:** grep for `Colors.white` found 8 matches at lines: 194, 266, 283, 359, 461, 762, 1056, 1061
- **Recommendation:** REPLACE with theme-aware colors
- **Reason:** Hardcoded white breaks dark mode. Replace with `theme.surfaceColor`, `theme.textColor`, or context-appropriate theme fields.

---

## 11. `lib/screens/plan_form_screen.dart` — Hardcoded `Colors.white`

- **Status:** CONFIRMED — 10 instances
- **Evidence:** grep for `Colors.white` found 10 matches at lines: 144, 151, 299, 388, 496, 552, 586, 672, 827, 840
- **Recommendation:** REPLACE with theme-aware colors
- **Reason:** Hardcoded white breaks dark mode. Replace with `theme.surfaceColor`, `theme.textColor`, or context-appropriate theme fields.

---

## Summary Table

| # | Item | Status | Action |
|---|------|--------|--------|
| 1 | `rest_timer_widget.dart` | CONFIRMED DEAD | DELETE |
| 2 | `session_stopwatch_widget.dart` | CONFIRMED DEAD | DELETE |
| 3 | `goToExercise()` | CONFIRMED DEAD | DELETE |
| 4 | `nextExercise()` | CONFIRMED DEAD | DELETE |
| 5 | `fl_chart` dep | Dead dep, future need | KEEP |
| 6 | `calculateExerciseStrengthTrend()` | Dead in UI, no tests | RESURRECT P1-2 |
| 7 | `calculateWeeklyVolumeTrend()` | Dead in UI, has tests | RESURRECT P1-3 |
| 8 | `calculateDailyVolumeTrend()` | Dead everywhere | RESURRECT P1-3 |
| 9 | `calculateSecondaryMuscleVolumeDistribution()` | Dead everywhere | RESURRECT P1-3 |
| 10 | `plan_screen.dart` Colors.white | 8 hardcoded instances | REPLACE |
| 11 | `plan_form_screen.dart` Colors.white | 10 hardcoded instances | REPLACE |

**Immediate actions (safe now):** Items 1-4 can be deleted immediately (dead files + dead methods).
**Deferred actions:** Items 5-9 are keep/revive for future phases. Items 10-11 are dark mode fixes.
