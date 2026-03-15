import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/weekly_plan_import.dart';
import 'package:workout_timer/models/user_profile.dart';
import 'package:workout_timer/services/ai_prompt_service.dart';
import 'package:workout_timer/services/exercise_matcher_service.dart';

// Helper to create test exercises with minimal boilerplate
Exercise _createTestExercise({
  required String id,
  required String nameEn,
  required PrimaryMuscleGroup primaryMuscle,
  List<SecondaryMuscleGroup> secondaryMuscles = const [],
  String equipment = 'barbell',
}) {
  return Exercise(
    id: id,
    name: nameEn,
    nameEn: nameEn,
    primaryMuscle: primaryMuscle,
    secondaryMuscles: secondaryMuscles,
    equipment: equipment,
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  );
}

void main() {
  group('AI Plan Import E2E Tests', () {
    
    group('UserProfile Model', () {
      test('creates profile with all required fields', () {
        final profile = UserProfile(
          goal: 'muscle_building',
          weeklyFrequency: 4,
          sessionDuration: 60,
          experience: 'intermediate',
          equipment: 'gym',
          focusAreas: ['chest', 'back'],
          startDate: DateTime(2024, 1, 1),
        );
        
        expect(profile.goal, 'muscle_building');
        expect(profile.weeklyFrequency, 4);
        expect(profile.sessionDuration, 60);
        expect(profile.experience, 'intermediate');
        expect(profile.equipment, 'gym');
        expect(profile.focusAreas, ['chest', 'back']);
      });
      
      test('serializes and deserializes correctly', () {
        final profile = UserProfile(
          goal: 'strength',
          weeklyFrequency: 5,
          sessionDuration: 90,
          experience: 'advanced',
          equipment: 'home_dumbbell',
          focusAreas: ['legs'],
          startDate: DateTime(2024, 3, 15),
        );
        
        final map = profile.toMap();
        final restored = UserProfile.fromMap(map);
        
        expect(restored.goal, profile.goal);
        expect(restored.weeklyFrequency, profile.weeklyFrequency);
        expect(restored.sessionDuration, profile.sessionDuration);
        expect(restored.experience, profile.experience);
        expect(restored.equipment, profile.equipment);
        expect(restored.focusAreas, profile.focusAreas);
      });
    });
    
    group('AIPromptService', () {
      test('generates prompt with all profile fields', () {
        final service = AIPromptService();
        final profile = UserProfile(
          goal: 'muscle_building',
          weeklyFrequency: 4,
          sessionDuration: 60,
          experience: 'intermediate',
          equipment: 'gym',
          focusAreas: ['chest', 'back'],
          startDate: DateTime(2024, 1, 1),
        );
        
        final prompt = service.generatePrompt(profile);
        
        expect(prompt.contains('Muscle Building'), isTrue);
        expect(prompt.contains('4'), isTrue);
        expect(prompt.contains('60 minutes'), isTrue);
        expect(prompt.contains('Intermediate'), isTrue);
        expect(prompt.contains('Full Gym'), isTrue);
        expect(prompt.contains('Chest, Back'), isTrue);
      });
      
      test('handles empty focus areas', () {
        final service = AIPromptService();
        final profile = UserProfile(
          goal: 'fat_loss',
          weeklyFrequency: 3,
          sessionDuration: 45,
          experience: 'beginner',
          equipment: 'bodyweight',
          focusAreas: [],
          startDate: DateTime(2024, 1, 1),
        );
        
        final prompt = service.generatePrompt(profile);
        
        expect(prompt.contains('None specified'), isTrue);
      });
      
      test('includes JSON format specification', () {
        final service = AIPromptService();
        final profile = UserProfile(
          goal: 'muscle_building',
          weeklyFrequency: 4,
          sessionDuration: 60,
          experience: 'intermediate',
          equipment: 'gym',
          focusAreas: [],
          startDate: DateTime(2024, 1, 1),
        );
        
        final prompt = service.generatePrompt(profile);
        
        expect(prompt.contains('dayOfWeek'), isTrue);
        expect(prompt.contains('exerciseName'), isTrue);
        expect(prompt.contains('targetSets'), isTrue);
      });
    });
    
    group('WeeklyPlanImport Model', () {
      test('parses valid JSON', () {
        const jsonString = '''
        {
          "name": "Test Plan",
          "days": [
            {
              "dayOfWeek": 1,
              "targetMuscles": ["chest", "shoulders"],
              "exercises": [
                {"exerciseName": "Barbell Bench Press", "targetSets": 4},
                {"exerciseName": "Incline Dumbbell Press", "targetSets": 3}
              ]
            },
            {
              "dayOfWeek": 3,
              "targetMuscles": ["back"],
              "exercises": [
                {"exerciseName": "Pull-up", "targetSets": 3}
              ]
            }
          ]
        }
        ''';
        
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final plan = WeeklyPlanImport.fromJson(jsonMap);
        
        expect(plan.name, 'Test Plan');
        expect(plan.days.length, 2);
        expect(plan.days[0].dayOfWeek, 1);
        expect(plan.days[0].exercises.length, 2);
        expect(plan.days[0].exercises[0].exerciseName, 'Barbell Bench Press');
        expect(plan.days[0].exercises[0].targetSets, 4);
      });
      
      test('handles empty days', () {
        const jsonString = '{"name": "Empty Plan", "days": []}';
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final plan = WeeklyPlanImport.fromJson(jsonMap);
        
        expect(plan.name, 'Empty Plan');
        expect(plan.days.isEmpty, isTrue);
      });
      
      test('clamps invalid dayOfWeek values', () {
        const jsonString = '''
        {
          "name": "Test",
          "days": [
            {"dayOfWeek": 0, "targetMuscles": [], "exercises": []},
            {"dayOfWeek": 10, "targetMuscles": [], "exercises": []}
          ]
        }
        ''';
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final plan = WeeklyPlanImport.fromJson(jsonMap);
        
        expect(plan.days[0].dayOfWeek, 1); // Clamped from 0 to 1
        expect(plan.days[1].dayOfWeek, 7); // Clamped from 10 to 7
      });
      
      test('defaults targetSets to 3 when not provided', () {
        const jsonString = '''
        {
          "name": "Test",
          "days": [
            {
              "dayOfWeek": 1,
              "targetMuscles": [],
              "exercises": [
                {"exerciseName": "Test Exercise"}
              ]
            }
          ]
        }
        ''';
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final plan = WeeklyPlanImport.fromJson(jsonMap);
        
        expect(plan.days[0].exercises[0].targetSets, 3);
      });
    });
    
    group('ExerciseMatcherService', () {
      late ExerciseMatcherService matcher;
      
      setUp(() {
        final exercises = [
          _createTestExercise(
            id: 'barbell_bench_press',
            nameEn: 'Barbell Bench Press',
            primaryMuscle: PrimaryMuscleGroup.chest,
            secondaryMuscles: [SecondaryMuscleGroup.triceps, SecondaryMuscleGroup.frontDelt],
            equipment: 'barbell',
          ),
          _createTestExercise(
            id: 'incline_dumbbell_press',
            nameEn: 'Incline Dumbbell Press',
            primaryMuscle: PrimaryMuscleGroup.chest,
            secondaryMuscles: [SecondaryMuscleGroup.frontDelt],
            equipment: 'dumbbell',
          ),
          _createTestExercise(
            id: 'pull_up',
            nameEn: 'Pull-up',
            primaryMuscle: PrimaryMuscleGroup.back,
            secondaryMuscles: [SecondaryMuscleGroup.biceps],
            equipment: 'body only',
          ),
        ];
        matcher = ExerciseMatcherService(exercises: exercises);
      });
      
      test('matches exact exercise name', () async {
        final result = await matcher.matchExercise('Barbell Bench Press');
        
        expect(result.isSuccess, isTrue);
        expect(result.exercise?.id, 'barbell_bench_press');
      });
      
      test('matches case-insensitively', () async {
        final result = await matcher.matchExercise('barbell bench press');
        
        expect(result.isSuccess, isTrue);
        expect(result.exercise?.id, 'barbell_bench_press');
      });
      
      test('matches normalized names (hyphens, underscores)', () async {
        final result = await matcher.matchExercise('Barbell-Bench_Press');
        
        expect(result.isSuccess, isTrue);
      });
      
      test('returns candidates for partial match', () async {
        // Use a more specific partial match that should return candidates
        final result = await matcher.matchExercise('Bench Press');
        // Could be success (high confidence) or candidates (multiple matches)
        expect(result.isSuccess || result.hasCandidates, isTrue);
        if (result.hasCandidates) {
          // Should return at least one candidate with "Bench" in the name
          expect(result.candidates.any((e) => e.nameEn.contains('Bench')), isTrue);
        }
      });
      
      test('returns failure for unknown exercise', () async {
        final result = await matcher.matchExercise('Unknown Exercise XYZ 123');
        
        expect(result.isFailure, isTrue);
      });
      
      test('batch matches multiple names', () async {
        final results = await matcher.matchAll([
          'Barbell Bench Press',
          'Pull-up',
          'Unknown Exercise',
        ]);
        
        expect(results.length, 3);
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect(results[2].isFailure, isTrue);
      });
    });
    
    group('Integration: Full Flow', () {
      test('user profile to prompt generation', () {
        // Step 1: Create user profile
        final profile = UserProfile(
          goal: 'muscle_building',
          weeklyFrequency: 4,
          sessionDuration: 60,
          experience: 'intermediate',
          equipment: 'gym',
          focusAreas: ['chest', 'back', 'legs'],
          startDate: DateTime(2024, 1, 8), // Monday
        );
        
        // Step 2: Generate prompt
        final promptService = AIPromptService();
        final prompt = promptService.generatePrompt(profile);
        
        // Verify prompt contains all necessary information
        expect(prompt.isNotEmpty, isTrue);
        expect(prompt.contains('Muscle Building'), isTrue);
        expect(prompt.contains('4'), isTrue);
        expect(prompt.contains('60 minutes'), isTrue);
        expect(prompt.contains('Intermediate'), isTrue);
        expect(prompt.contains('Full Gym'), isTrue);
        expect(prompt.contains('Chest'), isTrue);
        expect(prompt.contains('Back'), isTrue);
        expect(prompt.contains('Legs'), isTrue);
      });
      
      test('JSON parsing to exercise matching', () async {
        // Step 1: Parse AI-generated JSON
        const jsonString = '''
        {
          "name": "Push Day",
          "days": [
            {
              "dayOfWeek": 1,
              "targetMuscles": ["chest"],
              "exercises": [
                {"exerciseName": "Barbell Bench Press", "targetSets": 4},
                {"exerciseName": "Incline Dumbbell Press", "targetSets": 3}
              ]
            }
          ]
        }
        ''';
        
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final plan = WeeklyPlanImport.fromJson(jsonMap);
        
        // Step 2: Match exercises
        final exercises = [
          _createTestExercise(
            id: 'barbell_bench_press',
            nameEn: 'Barbell Bench Press',
            primaryMuscle: PrimaryMuscleGroup.chest,
            equipment: 'barbell',
          ),
          _createTestExercise(
            id: 'incline_dumbbell_press',
            nameEn: 'Incline Dumbbell Press',
            primaryMuscle: PrimaryMuscleGroup.chest,
            equipment: 'dumbbell',
          ),
        ];
        
        final matcher = ExerciseMatcherService(exercises: exercises);
        
        final exerciseNames = plan.days
            .expand((day) => day.exercises)
            .map((e) => e.exerciseName)
            .toList();
        
        final results = await matcher.matchAll(exerciseNames);
        
        // Verify all exercises matched
        expect(results.every((r) => r.isSuccess), isTrue);
      });
    });
  });
}
