# AGENTS.md - Screens

**Generated:** 2026-03-01

## OVERVIEW

UI screens/pages for the WorkoutTimer app. Each screen is a standalone page with its own state management via Provider.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `timer_screen.dart` | 38 | Main timer page with app bar actions |
| `history_screen.dart` | 572 | Workout history list with swipe-to-delete |
| `settings_screen.dart` | 96 | User preferences (sound, vibration, message) |
| `stats_screen.dart` | 1545 | Statistics dashboard with calendar navigation |
| `plan_screen.dart` | 801 | Workout plan list |
| `plan_form_screen.dart` | 724 | Plan creation/editing form |
| `record_detail_screen.dart` | 731 | Detailed record view |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add nav button | `timer_screen.dart:14-33` (AppBar actions) |
| History list UI | `history_screen.dart:121-133` (ListView.builder) |
| Session card | `history_screen.dart:140-261` (_SessionCard widget) |
| Settings switches | `settings_screen.dart:58-73` |
| Clear history | `settings_screen.dart:41-48` |
| Stats week view | `stats_screen.dart:1058-1088` (`_buildWeekView`) |
| Stats month view | `stats_screen.dart:1124-1169` (`_buildMonthView`) |
| Stats chart | `stats_screen.dart:1446-1544` (`_buildDailyDurationChart`) |

## PATTERNS

**StatefulWidget** for screens with async data (history, settings). **StatelessWidget** for simple displays (timer).

**Navigation**: Named routes via `Navigator.pushNamed(context, '/history')`.

**Data Loading**: `FutureBuilder` pattern in history_screen for async list loading.

**TabController**: stats_screen uses `SingleTickerProviderStateMixin` for tab navigation.

## KNOWN ISSUES

- `history_screen.dart:55-75` — Catch blocks with only debugPrint (silent failure)
- `history_screen.dart:155,189` — Uses `!` operator on snapshot.data
