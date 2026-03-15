import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('create profile with all required fields', () {
      final startDate = DateTime(2026, 3, 14);
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 4,
        sessionDuration: 60,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: ['chest', 'back'],
        startDate: startDate,
      );

      expect(profile.goal, 'muscle_building');
      expect(profile.weeklyFrequency, 4);
      expect(profile.sessionDuration, 60);
      expect(profile.experience, 'intermediate');
      expect(profile.equipment, 'gym');
      expect(profile.focusAreas, ['chest', 'back']);
      expect(profile.startDate, startDate);
    });

    test('copy with modified fields preserves others', () {
      final startDate = DateTime(2026, 3, 14);
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 4,
        sessionDuration: 60,
        experience: 'intermediate',
        equipment: 'gym',
        focusAreas: ['chest'],
        startDate: startDate,
      );

      final modified = profile.copyWith(
        goal: 'fat_loss',
        sessionDuration: 45,
      );

      expect(modified.goal, 'fat_loss');
      expect(modified.weeklyFrequency, 4); // preserved
      expect(modified.sessionDuration, 45); // modified
      expect(modified.experience, 'intermediate'); // preserved
      expect(modified.equipment, 'gym'); // preserved
      expect(modified.focusAreas, ['chest']); // preserved
      expect(modified.startDate, startDate); // preserved
    });

    test('serialize/deserialize via toMap/fromMap', () {
      final startDate = DateTime(2026, 3, 14, 10, 30);
      final profile = UserProfile(
        goal: 'strength',
        weeklyFrequency: 5,
        sessionDuration: 90,
        experience: 'advanced',
        equipment: 'home_dumbbell',
        focusAreas: ['legs', 'core'],
        startDate: startDate,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.goal, profile.goal);
      expect(restored.weeklyFrequency, profile.weeklyFrequency);
      expect(restored.sessionDuration, profile.sessionDuration);
      expect(restored.experience, profile.experience);
      expect(restored.equipment, profile.equipment);
      expect(restored.focusAreas, profile.focusAreas);
      expect(restored.startDate, profile.startDate);
    });

    test('default focusAreas is empty list', () {
      final profile = UserProfile(
        goal: 'endurance',
        weeklyFrequency: 3,
        sessionDuration: 30,
        experience: 'beginner',
        equipment: 'bodyweight',
        startDate: DateTime.now(),
      );

      expect(profile.focusAreas, isEmpty);
      expect(profile.focusAreas, []);
    });

    test('startDate serialization preserves date correctly', () {
      final originalDate = DateTime(2026, 3, 14, 10, 30, 45);
      final profile = UserProfile(
        goal: 'muscle_building',
        weeklyFrequency: 4,
        sessionDuration: 60,
        experience: 'intermediate',
        equipment: 'gym',
        startDate: originalDate,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.startDate.year, originalDate.year);
      expect(restored.startDate.month, originalDate.month);
      expect(restored.startDate.day, originalDate.day);
      expect(restored.startDate.hour, originalDate.hour);
      expect(restored.startDate.minute, originalDate.minute);
      expect(restored.startDate.second, originalDate.second);
    });
  });
}
