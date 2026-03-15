import '../models/user_profile.dart';

/// Service for generating AI prompts for workout plan generation
class AIPromptService {
  /// Generate a personalized workout plan prompt based on user profile
  String generatePrompt(UserProfile profile) {
    final formattedGoal = _formatGoal(profile.goal);
    final formattedExperience = _formatExperience(profile.experience);
    final formattedEquipment = _formatEquipment(profile.equipment);
    final formattedFocusAreas = _formatFocusAreas(profile.focusAreas);

    return '''You are a professional fitness coach. Generate a personalized weekly workout plan based on my profile.

## My Profile

- **Goal**: $formattedGoal
- **Weekly Frequency**: ${profile.weeklyFrequency}
- **Session Duration**: ${profile.sessionDuration} minutes
- **Experience Level**: $formattedExperience
- **Equipment Access**: $formattedEquipment
- **Focus Areas**: $formattedFocusAreas

## Exercise Database

We use the free-exercise-db database (800+ exercises) with standard English naming conventions:
- Compound movements: Barbell Bench Press, Barbell Squat, Deadlift, Overhead Press, etc.
- Isolation movements: Dumbbell Fly, Cable Crossover, Tricep Pushdown, Bicep Curl, etc.
- Equipment types: Barbell, Dumbbell, Cable, Machine, Body Only, Kettlebell

Naming format examples:
- Barbell Bench Press, Incline Dumbbell Press, Cable Fly
- Pull-up, Chin-up, Dips
- Goblet Squat, Romanian Deadlift, Hip Thrust

If unsure about exact names, use standard exercise terminology and we'll match the closest equivalent.

## Output Format

Output ONLY valid JSON. No explanations or markdown:

{
  "name": "Plan Name",
  "days": [
    {
      "dayOfWeek": 1,
      "targetMuscles": ["chest", "shoulders"],
      "exercises": [
        {"exerciseName": "Barbell Bench Press", "targetSets": 4},
        {"exerciseName": "Incline Dumbbell Press", "targetSets": 3}
      ]
    }
  ]
}

## Rules

1. `dayOfWeek`: 1=Monday ... 7=Sunday
2. `targetMuscles`: chest, back, shoulders, arms, legs, core
3. `targetSets`: 3-5 per exercise
4. 4-6 exercises per session (based on ${profile.sessionDuration} minutes)
5. Compound first, isolation last
6. Include rest days based on ${profile.weeklyFrequency} frequency

Generate my weekly plan. JSON only:''';
  }

  /// Format goal string for display
  String _formatGoal(String goal) {
    switch (goal) {
      case 'muscle_building':
        return 'Muscle Building';
      case 'fat_loss':
        return 'Fat Loss';
      case 'strength':
        return 'Strength';
      case 'endurance':
        return 'Endurance';
      default:
        return goal;
    }
  }

  /// Format experience level for display
  String _formatExperience(String experience) {
    switch (experience) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return experience;
    }
  }

  /// Format equipment type for display
  String _formatEquipment(String equipment) {
    switch (equipment) {
      case 'gym':
        return 'Full Gym';
      case 'home_dumbbell':
        return 'Home Dumbbells';
      case 'bodyweight':
        return 'Bodyweight Only';
      default:
        return equipment;
    }
  }

  /// Format muscle group for display
  String _formatMuscle(String muscle) {
    switch (muscle) {
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'shoulders':
        return 'Shoulders';
      case 'arms':
        return 'Arms';
      case 'legs':
        return 'Legs';
      case 'core':
        return 'Core';
      default:
        return muscle;
    }
  }

  /// Format focus areas list for display
  String _formatFocusAreas(List<String> focusAreas) {
    if (focusAreas.isEmpty) {
      return 'None specified';
    }
    return focusAreas.map(_formatMuscle).join(', ');
  }
}
