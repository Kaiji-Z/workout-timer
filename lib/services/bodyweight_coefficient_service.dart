import 'package:flutter/foundation.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing body weight coefficients for bodyweight exercises.
///
/// Uses biomechanical research to estimate the percentage of body weight
/// lifted during bodyweight exercises, enabling fair volume comparison
/// with weighted exercises.
///
/// Formula: equivalentWeight = bodyWeight × coefficient + additionalWeight
/// Volume = reps × equivalentWeight (same as weighted exercises)
class BodyweightCoefficientService {
  static const String _keyBodyWeight = 'pref_body_weight';

  /// Body weight coefficient mapping by exercise ID.
  /// Based on biomechanical research (ACE, NSCA guidelines).
  /// Values represent the fraction of body weight actively moved.
  static const Map<String, double> _coefficientMap = {
    // ==================== CHEST (push-ups) ====================
    // Standard push-ups: ~64% of body weight
    'Pushups': 0.64,
    'Push-Up_Wide': 0.64,
    'Incline_Push-Up': 0.50, // easier = less % of BW
    'Incline_Push-Up_Medium': 0.55,
    'Incline_Push-Up_Wide': 0.50,
    'Incline_Push-Up_Reverse_Grip': 0.55,
    'Incline_Push-Up_Close-Grip': 0.55,
    'Clock_Push-Up': 0.64,
    'Plyo_Push-up': 0.64,
    'Push-Ups_With_Feet_Elevated': 0.75, // harder = more % of BW
    'Push_Up_to_Side_Plank': 0.64,
    'Pushups_Close_and_Wide_Hand_Positions': 0.64,
    'Push-Ups_-_Close_Triceps_Position': 0.64,
    'Single-Arm_Push-Up': 0.64,
    'Close-Grip_Push-Up_off_of_a_Dumbbell': 0.64,
    'Isometric_Chest_Squeezes': 0.30, // isometric, low % BW
    'Isometric_Wipers': 0.50,
    'Spider_Crawl': 0.64, // moving push-up
    // ==================== BACK (pull-ups) ====================
    // Pull-ups: ~70% of body weight (full body minus hands/grip)
    'Pullups': 0.70,
    'Chin-Up': 0.70,
    'Wide-Grip_Rear_Pull-Up': 0.70,
    'V-Bar_Pullup': 0.70,
    'Gorilla_Chin_Crunch': 0.70,

    // ==================== SHOULDERS ====================
    // Handstand push-ups: ~100% of body weight (pressing full BW)
    'Handstand_Push-Ups': 1.00,
    'Seated_Front_Deltoid': 0.30, // isometric, partial
    // ==================== TRICEPS (dips & push-up variants) ====================
    // Dips: ~85% of body weight
    'Bench_Dips': 0.70, // bench dips easier than full dips
    'Dips_-_Triceps_Version': 0.85,
    'Body-Up': 0.70,
    'Body_Tricep_Press': 0.50,
    'Overhead_Triceps': 0.30,
    'Standing_Towel_Triceps_Extension': 0.20,

    // ==================== LEGS - QUADS ====================
    // Squats: ~100% of body weight
    'Bodyweight_Squat': 1.00,
    'Freehand_Jump_Squat': 1.00,
    'Rocket_Jump': 1.00,
    'Scissors_Jump': 1.00,
    'Split_Jump': 1.00,
    'Star_Jump': 1.00,
    'Standing_Long_Jump': 1.00,
    'Bench_Jump': 1.00,
    'Fast_Skipping': 0.80,
    'Double_Leg_Butt_Kick': 0.50,
    'Single_Leg_Butt_Kick': 0.50,
    'Rear_Leg_Raises': 0.50,
    'Lying_Prone_Quadriceps': 0.30,
    'All_Fours_Quad_Stretch': 0.20, // stretch, minimal load
    // ==================== LEGS - HAMSTRINGS ====================
    '90_90_Hamstring': 0.30,
    'Front_Leg_Raises': 0.30,
    'Inchworm': 0.50,
    'Knee_Tuck_Jump': 0.80,
    'Natural_Glute_Ham_Raise': 0.60,

    // ==================== LEGS - GLUTES ====================
    'Butt_Lift_Bridge': 0.50,
    'Flutter_Kicks': 0.30,
    'Glute_Kickback': 0.30,
    'Leg_Lift': 0.30,
    'Lying_Glute': 0.30,
    'Seated_Glute': 0.30,
    'Single_Leg_Glute_Bridge': 0.50,
    'Step-up_with_Knee_Raise': 0.70, // step-up moves significant BW
    'Lateral_Bound': 0.80,

    // ==================== CORE (abs) ====================
    // Most core exercises use ~30% of BW for active loading
    '3_4_Sit-Up': 0.30,
    'Air_Bike': 0.30,
    'Alternate_Heel_Touchers': 0.30,
    'Bent-Knee_Hip_Raise': 0.30,
    'Bottoms_Up': 0.30,
    'Butt-Ups': 0.30,
    'Cocoons': 0.30,
    'Cross-Body_Crunch': 0.25,
    'Crunch_-_Hands_Overhead': 0.25,
    'Crunch_-_Legs_On_Exercise_Ball': 0.25,
    'Crunches': 0.25,
    'Dead_Bug': 0.25,
    'Decline_Crunch': 0.30,
    'Decline_Oblique_Crunch': 0.30,
    'Decline_Reverse_Crunch': 0.30,
    'Elbow_to_Knee': 0.30,
    'Flat_Bench_Leg_Pull-In': 0.30,
    'Flat_Bench_Lying_Leg_Raise': 0.30,
    'Frog_Sit-Ups': 0.30,
    'Hanging_Leg_Raise': 0.40, // legs are heavier
    'Hanging_Pike': 0.40,
    'Jackknife_Sit-Up': 0.35,
    'Janda_Sit-Up': 0.30,
    'Leg_Pull-In': 0.30,
    'Lower_Back_Curl': 0.25,
    'Oblique_Crunches': 0.25,
    'Oblique_Crunches_-_On_The_Floor': 0.25,
    'Plank': 0.00, // isometric hold, zero volume contribution
    'Reverse_Crunch': 0.30,
    'Russian_Twist': 0.25,
    'Scissor_Kick': 0.25,
    'Seated_Flat_Bench_Leg_Pull-In': 0.30,
    'Seated_Leg_Tucks': 0.30,
    'Side_Bridge': 0.25,
    'Side_Jackknife': 0.30,
    'Sit-Up': 0.30,
    'Stomach_Vacuum': 0.00, // isometric, zero volume
    'Toe_Touchers': 0.30,
    'Tuck_Crunch': 0.30,
    'Wind_Sprints': 0.00, // cardio, not strength
    // ==================== LOWER BACK ====================
    'Hyperextensions_With_No_Hyperextension_Bench': 0.50,
    'Superman': 0.30,

    // ==================== ADDUCTORS / ABDUCTORS ====================
    'Hip_Circles_prone': 0.20,
    'Lying_Crossover': 0.20,
    'Standing_Hip_Circles': 0.20,
    'Groiners': 0.30,
    'Side_Leg_Raises': 0.25,

    // ==================== CALVES ====================
    'Knee_Circles': 0.15,

    // ==================== BICEPS ====================
    'Seated_Biceps': 0.20, // isometric bicep hold
    // ==================== FOREARMS ====================
    'Wrist_Circles': 0.05, // mobility, minimal load
    // ==================== NECK ====================
    'Isometric_Neck_Exercise_-_Front_And_Back': 0.05,
    'Isometric_Neck_Exercise_-_Sides': 0.05,
  };

  /// Default coefficient for bodyweight exercises not in the map.
  /// Conservative estimate for unknown bodyweight exercises.
  static const double defaultCoefficient = 0.50;

  /// Check if an exercise is a bodyweight exercise based on equipment field.
  static bool isBodyweightExercise(Exercise? exercise) {
    if (exercise == null) return false;
    final eq = exercise.equipment.toLowerCase();
    return eq == 'body only' ||
        eq == 'bodyweight' ||
        eq == 'none' ||
        eq.isEmpty;
  }

  /// Get the body weight coefficient for a specific exercise.
  /// Falls back to [defaultCoefficient] if not explicitly mapped.
  static double getCoefficient(Exercise? exercise) {
    if (exercise == null) return 0.0;
    return _coefficientMap[exercise.id] ?? defaultCoefficient;
  }

  /// Calculate the equivalent weight for a bodyweight exercise.
  /// equivalentWeight = bodyWeight × coefficient + additionalWeight
  ///
  /// [exercise] - The exercise being performed
  /// [bodyWeight] - User's body weight in kg
  /// [additionalWeight] - Extra weight added (e.g., weighted vest, dip belt)
  static double calculateEquivalentWeight({
    required Exercise? exercise,
    required double bodyWeight,
    double additionalWeight = 0.0,
  }) {
    if (!isBodyweightExercise(exercise) || bodyWeight <= 0) {
      return additionalWeight;
    }
    final coefficient = getCoefficient(exercise);
    return bodyWeight * coefficient + additionalWeight;
  }

  /// Load user's body weight from SharedPreferences.
  /// Returns null if not set.
  static Future<double?> loadBodyWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_keyBodyWeight);
    } catch (e) {
      return null;
    }
  }

  /// Save user's body weight to SharedPreferences.
  static Future<void> saveBodyWeight(double weight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyBodyWeight, weight);
    } catch (e) {
      debugPrint('Error saving body weight: $e');
    }
  }
}
