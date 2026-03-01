# AGENTS.md - Widgets

**Generated:** 2026-03-01

## OVERVIEW

Reusable UI components for the WorkoutTimer app following Flat Vitality design system. 12 widget files with varying complexity.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `timer_widget.dart` | 439 | Main timer component (circular progress, chips, buttons) |
| `glass_widgets.dart` | 565 | Circular control buttons, shared Flat Vitality UI |
| `training_widget.dart` | 732 | Training mode component with state machine |
| `exercise_selector.dart` | 750 | Exercise selection UI with search/filter |
| `plan_card.dart` | 621 | Plan card display with swipe actions |
| `calendar_widget.dart` | 560 | Calendar picker for plan scheduling |
| `animated_timer_widget.dart` | - | Animated timer variant |
| `circular_progress_painter.dart` | - | Progress ring painter |
| `duration_picker.dart` | - | Duration selection UI |
| `rest_timer_widget.dart` | - | Rest timer component |
| `session_stopwatch_widget.dart` | 79 | Session stopwatch |
| `muscle_selector.dart` | - | Muscle group selection |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Progress ring painter | `timer_widget.dart:243-293` (`_CircularProgressPainter`) |
| Preset chips | `timer_widget.dart:295-342` (`_PresetChip`) |
| Control buttons | `timer_widget.dart:209-239` (primary), 344-382 (circular) |
| Circular button | `glass_widgets.dart:26-44` (`CircularControlButton`) |
| Status badge | `timer_widget.dart:113-142` (`_buildStatusBadge`) |
| Completed sets display | `timer_widget.dart:167-207` (`_buildCompletedSets`) |

## CONVENTIONS

**Widget Structure**: Private widget classes prefixed with `_` (e.g., `_PresetChip`, `_CircleControlButton`).

**Flat Vitality Design**:
- White circular buttons (56px) with shadow
- Deep indigo accent (#1A237E) for icons, progress rings
- 10px stroke width for progress rings
- Warm gradient backgrounds (from theme)
- No glow/glass effects - flat design
- `.SF Pro Display/Text` fonts
- Material 3 components with custom styling

**State Management**: Use `context.watch<T>()` in widgets to rebuild on state changes.

**Animations**: Use `SingleTickerProviderStateMixin` for custom animations, `AnimationController` with proper disposal.

## ANTI-PATTERNS

| Pattern | Why Bad | Instead |
|---------|---------|---------|
| Hardcoded colors | Breaks theming | Use theme.accentColor, theme.textColor |
| Magic dimensions | Inconsistent UI | Use named constants or theme values |
| Missing null checks | Runtime crashes | Validate required parameters |
