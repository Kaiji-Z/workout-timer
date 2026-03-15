/// Shared test fixtures for AI plan import feature tests
library;

import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';

/// Sample exercises for testing matcher service
final List<Exercise> sampleExercises = [
  Exercise(
    id: 'barbell_bench_press',
    name: '杠铃卧推',
    nameEn: 'Barbell Bench Press',
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: [SecondaryMuscleGroup.triceps, SecondaryMuscleGroup.frontDelt],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  ),
  Exercise(
    id: 'incline_dumbbell_press',
    name: '上斜哑铃卧推',
    nameEn: 'Incline Dumbbell Press',
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: [SecondaryMuscleGroup.frontDelt],
    equipment: 'dumbbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 10,
      maxReps: 12,
      restSeconds: 60,
    ),
  ),
  Exercise(
    id: 'barbell_row',
    name: '杠铃划船',
    nameEn: 'Barbell Row',
    primaryMuscle: PrimaryMuscleGroup.back,
    secondaryMuscles: [SecondaryMuscleGroup.biceps],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 8,
      maxReps: 10,
      restSeconds: 90,
    ),
  ),
  Exercise(
    id: 'pull_up',
    name: '引体向上',
    nameEn: 'Pull-up',
    primaryMuscle: PrimaryMuscleGroup.back,
    secondaryMuscles: [SecondaryMuscleGroup.biceps],
    equipment: 'body only',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  ),
  Exercise(
    id: 'barbell_squat',
    name: '杠铃深蹲',
    nameEn: 'Barbell Squat',
    primaryMuscle: PrimaryMuscleGroup.legs,
    secondaryMuscles: [SecondaryMuscleGroup.glutes],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 6,
      maxReps: 10,
      restSeconds: 120,
    ),
  ),
  Exercise(
    id: 'overhead_press',
    name: '过头推举',
    nameEn: 'Overhead Press',
    primaryMuscle: PrimaryMuscleGroup.shoulders,
    secondaryMuscles: [SecondaryMuscleGroup.triceps],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 8,
      maxReps: 10,
      restSeconds: 90,
    ),
  ),
  Exercise(
    id: 'dumbbell_bicep_curl',
    name: '哑铃弯举',
    nameEn: 'Dumbbell Bicep Curl',
    primaryMuscle: PrimaryMuscleGroup.arms,
    secondaryMuscles: [],
    equipment: 'dumbbell',
    level: 'beginner',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 10,
      maxReps: 12,
      restSeconds: 60,
    ),
  ),
  Exercise(
    id: 'tricep_pushdown',
    name: '三头肌下压',
    nameEn: 'Tricep Pushdown',
    primaryMuscle: PrimaryMuscleGroup.arms,
    secondaryMuscles: [],
    equipment: 'cable',
    level: 'beginner',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 10,
      maxReps: 15,
      restSeconds: 60,
    ),
  ),
];

/// Sample weekly plan JSON from AI
const String sampleWeeklyPlanJson = '''
{
  "name": "Push Pull Legs Split",
  "days": [
    {
      "dayOfWeek": 1,
      "targetMuscles": ["chest", "shoulders", "arms"],
      "exercises": [
        {"exerciseName": "Barbell Bench Press", "targetSets": 4},
        {"exerciseName": "Incline Dumbbell Press", "targetSets": 3},
        {"exerciseName": "Overhead Press", "targetSets": 3},
        {"exerciseName": "Tricep Pushdown", "targetSets": 3}
      ]
    },
    {
      "dayOfWeek": 3,
      "targetMuscles": ["back", "arms"],
      "exercises": [
        {"exerciseName": "Pull-up", "targetSets": 4},
        {"exerciseName": "Barbell Row", "targetSets": 3},
        {"exerciseName": "Dumbbell Bicep Curl", "targetSets": 3}
      ]
    },
    {
      "dayOfWeek": 5,
      "targetMuscles": ["legs"],
      "exercises": [
        {"exerciseName": "Barbell Squat", "targetSets": 4}
      ]
    }
  ]
}
''';

/// Sample weekly plan with unmatched exercise
const String sampleWeeklyPlanWithUnmatchedJson = '''
{
  "name": "Test Plan",
  "days": [
    {
      "dayOfWeek": 1,
      "targetMuscles": ["chest"],
      "exercises": [
        {"exerciseName": "Barbell Bench Press", "targetSets": 4},
        {"exerciseName": "Unknown Exercise XYZ", "targetSets": 3}
      ]
    }
  ]
}
''';

/// Sample malformed JSON
const String malformedJson = '''
{
  "name": "Bad Plan",
  "days": [
    {
      "dayOfWeek": "monday",
      "exercises": "not an array"
    }
  ]
}
''';

/// Helper to find exercise by name
Exercise? findExerciseByName(String nameEn) {
  try {
    return sampleExercises.firstWhere((e) => e.nameEn == nameEn);
  } catch (_) {
    return null;
  }
}
