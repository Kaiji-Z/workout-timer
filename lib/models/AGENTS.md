# AGENTS.md - Data Models

**Generated:** 2026-03-01

## OVERVIEW

Data models for workout sessions, plans, exercises, and records. Pure Dart classes with `fromMap`/`toMap` for SQLite serialization.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `workout_session.dart` | 47 | Simple session: sets, rest time, timestamp |
| `workout_record.dart` | 300 | Detailed record: exercises, sets, weights, reps |
| `workout_plan.dart` | 255 | Plan template: name, exercises, schedule |
| `calendar_plan.dart` | 93 | Calendar entry: date → plan mapping |
| `exercise.dart` | 368 | Exercise definition: muscle groups, equipment |
| `muscle_group.dart` | 272 | Muscle group enum + utilities |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Session model | `workout_session.dart:1-47` |
| Record model | `workout_record.dart:1-300` |
| Exercise model | `exercise.dart:1-368` |
| Plan model | `workout_plan.dart:1-255` |
| Muscle groups | `muscle_group.dart:5-30` (`PrimaryMuscleGroup` enum) |

## MODELS

### WorkoutSession (simple)
```dart
class WorkoutSession {
  final String id;
  final int totalSets;
  final int totalRestTimeMs;
  final String createdAt;
}
```

### WorkoutRecord (detailed)
```dart
class WorkoutRecord {
  final String id;
  final DateTime date;
  final List<RecordExercise> exercises;
  final int totalSets;
  final int durationSeconds;
}
```

### Exercise
```dart
class Exercise {
  final String id;
  final String name;
  final PrimaryMuscleGroup primaryMuscle;
  final List<SecondaryMuscleGroup> secondaryMuscles;
  final Equipment equipment;
}
```

### WorkoutPlan
```dart
class WorkoutPlan {
  final String id;
  final String name;
  final List<PlanExercise> exercises;
  final List<int> scheduledDays; // 0-6 (Mon-Sun)
}
```

## PATTERNS

**Serialization**: All models have `fromMap()` factory and `toMap()` method for SQLite.

**IDs**: Use `uuid` package for unique identifiers.

**Immutability**: Models use `final` fields, `copyWith()` for modifications.

## RELATIONSHIPS

```
WorkoutPlan (1) ──→ (N) PlanExercise ──→ (1) Exercise
WorkoutRecord (1) ──→ (N) RecordExercise ──→ (1) Exercise
CalendarPlan (1) ──→ (1) WorkoutPlan
WorkoutSession ──→ (legacy, simpler structure)
```
