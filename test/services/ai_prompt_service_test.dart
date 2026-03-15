import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/user_profile.dart';
import 'package:workout_timer/services/ai_prompt_service.dart';

void main() {
  late AIPromptService service;

  setUp(() {
    service = AIPromptService();
  });

  group('generatePrompt', () {
    test('generates prompt with all profile fields', () {
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 4,
        sessionDuration: 60,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: ['chest', 'back'],
        startDate: DateTime(2026, 1, 1),
      );

      final prompt = service.generatePrompt(profile);

      expect(prompt, contains('**Goal**: Muscle Building'));
      expect(prompt, contains('**Weekly Frequency**: 4'));
      expect(prompt, contains('**Session Duration**: 60 minutes'));
      expect(prompt, contains('**Experience Level**: Intermediate'));
      expect(prompt, contains('**Equipment Access**: Full Gym'));
      expect(prompt, contains('**Focus Areas**: Chest, Back'));
      expect(prompt, contains('based on 60 minutes'));
      expect(prompt, contains('based on 4 frequency'));
    });

    test('handles empty focus areas as "None specified"', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'home_dumbbell',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );

      final prompt = service.generatePrompt(profile);

      expect(prompt, contains('**Focus Areas**: None specified'));
    });

    test('includes exercise database section', () {
      final profile = UserProfile(
        goal: 'fat_loss',
        weeklyFrequency: 5,
        sessionDuration: 30,
        experience: 'advanced',
        equipment: 'bodyweight',
        focusAreas: ['legs'],
        startDate: DateTime(2026, 1, 1),
      );

      final prompt = service.generatePrompt(profile);

      expect(prompt, contains('free-exercise-db'));
      expect(prompt, contains('Barbell Bench Press'));
      expect(prompt, contains('Compound movements'));
      expect(prompt, contains('Isolation movements'));
    });

    test('includes output format section', () {
      final profile = UserProfile(
        goal: 'endurance',
        weeklyFrequency: 6,
        sessionDuration: 45,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: ['core'],
        startDate: DateTime(2026, 1, 1),
      );

      final prompt = service.generatePrompt(profile);

      expect(prompt, contains('Output ONLY valid JSON'));
      expect(prompt, contains('"dayOfWeek"'));
      expect(prompt, contains('"targetMuscles"'));
      expect(prompt, contains('"exerciseName"'));
      expect(prompt, contains('"targetSets"'));
    });

    test('includes rules section', () {
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 4,
        sessionDuration: 60,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );

      final prompt = service.generatePrompt(profile);

      expect(prompt, contains('1=Monday ... 7=Sunday'));
      expect(prompt, contains('chest, back, shoulders, arms, legs, core'));
      expect(prompt, contains('3-5 per exercise'));
      expect(prompt, contains('4-6 exercises per session'));
      expect(prompt, contains('Compound first, isolation last'));
    });
  });

  group('goal formatting', () {
    test('formats muscle_building', () {
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Goal**: Muscle Building'));
    });

    test('formats fat_loss', () {
      final profile = UserProfile(
        goal: 'fat_loss',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Goal**: Fat Loss'));
    });

    test('formats strength', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Goal**: Strength'));
    });

    test('formats endurance', () {
      final profile = UserProfile(
        goal: 'endurance',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Goal**: Endurance'));
    });

    test('returns unknown goal as-is', () {
      final profile = UserProfile(
        goal: 'custom_goal',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Goal**: custom_goal'));
    });
  });

  group('experience level formatting', () {
    test('formats beginner', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Experience Level**: Beginner'));
    });

    test('formats intermediate', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Experience Level**: Intermediate'));
    });

    test('formats advanced', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'advanced',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Experience Level**: Advanced'));
    });

    test('returns unknown experience as-is', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'expert',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Experience Level**: expert'));
    });
  });

  group('equipment formatting', () {
    test('formats gym', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Equipment Access**: Full Gym'));
    });

    test('formats home_dumbbell', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'home_dumbbell',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Equipment Access**: Home Dumbbells'));
    });

    test('formats bodyweight', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'bodyweight',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Equipment Access**: Bodyweight Only'));
    });

    test('returns unknown equipment as-is', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'kettlebell',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Equipment Access**: kettlebell'));
    });
  });

  group('focus areas formatting', () {
    test('formats multiple focus areas', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: ['chest', 'back', 'shoulders'],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Focus Areas**: Chest, Back, Shoulders'));
    });

    test('formats single focus area', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: ['legs'],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Focus Areas**: Legs'));
    });

    test('handles empty focus areas', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: [],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Focus Areas**: None specified'));
    });

    test('formats all muscle groups', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'],
        startDate: DateTime(2026, 1, 1),
      );
      final prompt = service.generatePrompt(profile);
      expect(prompt, contains('Chest, Back, Shoulders, Arms, Legs, Core'));
    });

    test('returns unknown muscle as-is', () {
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 3,
        sessionDuration: 45,
        experience: 'beginner',
        equipment: 'gym',
        focusAreas: ['calves'],
        startDate: DateTime(2026, 1, 1),
      );
      expect(service.generatePrompt(profile), contains('**Focus Areas**: calves'));
    });
  });
}
