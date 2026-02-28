# AGENTS.md - Screens

**Generated:** 2026-02-28

## OVERVIEW

UI screens/pages for the WorkoutTimer app. Each screen is a standalone page with its own state management via Provider.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `timer_screen.dart` | 38 | Main timer page with app bar actions |
| `history_screen.dart` | 263 | Workout history list with swipe-to-delete |
| `settings_screen.dart` | 96 | User preferences (sound, vibration, message) |
| `stats_screen.dart` | - | Statistics dashboard |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add nav button | `timer_screen.dart:14-33` (AppBar actions) |
| History list UI | `history_screen.dart:121-133` (ListView.builder) |
| Session card | `history_screen.dart:140-261` (_SessionCard widget) |
| Settings switches | `settings_screen.dart:58-73` |
| Clear history | `settings_screen.dart:41-48` |

## PATTERNS

**StatefulWidget** for screens with async data (history, settings). **StatelessWidget** for simple displays (timer).

**Navigation**: Named routes via `Navigator.pushNamed(context, '/history')`.

**Data Loading**: `FutureBuilder` pattern in history_screen for async list loading.

## KNOWN ISSUES

- `history_screen.dart:28` — Empty catch block (silent failure on delete)
- `history_screen.dart:87,120` — Uses `!` operator instead of null check
