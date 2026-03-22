import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User training preferences for AI plan generation and personalization
class UserPreferences {
  final String goal;
  final String experience;
  final String equipment;
  final int frequency;
  final String focusAreas;

  const UserPreferences({
    this.goal = 'muscle_building',
    this.experience = 'intermediate',
    this.equipment = 'gym',
    this.frequency = 4,
    this.focusAreas = '',
  });

  /// Splits comma-separated focus areas into a list
  List<String> get focusAreasList {
    if (focusAreas.isEmpty) return [];
    return focusAreas.split(',').where((s) => s.isNotEmpty).toList();
  }

  UserPreferences copyWith({
    String? goal,
    String? experience,
    String? equipment,
    int? frequency,
    String? focusAreas,
  }) {
    return UserPreferences(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      equipment: equipment ?? this.equipment,
      frequency: frequency ?? this.frequency,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(goal: $goal, experience: $experience, equipment: $equipment, frequency: $frequency, focusAreas: $focusAreas)';
  }
}

/// Service for reading/writing user training preferences via SharedPreferences
class UserPreferencesService {
  static const String _keyGoal = 'pref_goal';
  static const String _keyExperience = 'pref_experience';
  static const String _keyEquipment = 'pref_equipment';
  static const String _keyFrequency = 'pref_frequency';
  static const String _keyFocusAreas = 'pref_focus_areas';

  /// Load user preferences from SharedPreferences
  /// Returns a UserPreferences object with defaults if not set
  Future<UserPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return UserPreferences(
        goal: prefs.getString(_keyGoal) ?? 'muscle_building',
        experience: prefs.getString(_keyExperience) ?? 'intermediate',
        equipment: prefs.getString(_keyEquipment) ?? 'gym',
        frequency: prefs.getInt(_keyFrequency) ?? 4,
        focusAreas: prefs.getString(_keyFocusAreas) ?? '',
      );
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      return const UserPreferences();
    }
  }

  /// Save user preferences to SharedPreferences
  Future<void> savePreferences(UserPreferences prefs) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(_keyGoal, prefs.goal);
      await sharedPreferences.setString(_keyExperience, prefs.experience);
      await sharedPreferences.setString(_keyEquipment, prefs.equipment);
      await sharedPreferences.setInt(_keyFrequency, prefs.frequency);
      await sharedPreferences.setString(_keyFocusAreas, prefs.focusAreas);
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }
}
