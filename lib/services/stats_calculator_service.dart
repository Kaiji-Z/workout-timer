import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/muscle_group.dart';

/// Service for calculating workout statistics
class StatsCalculatorService {
  /// Calculate total volume (sets × reps × weight) for all records
  double calculateTotalVolume(List<WorkoutRecord> records) {
    double totalVolume = 0.0;
    for (final record in records) {
      for (final exercise in record.exercises) {
        totalVolume += exercise.totalVolume;
      }
    }
    return totalVolume;
  }

  /// Calculate average workout density (sets per minute)
  double calculateDensity(List<WorkoutRecord> records) {
    if (records.isEmpty) return 0.0;

    final totalSets = records.fold<int>(0, (sum, r) => sum + r.totalSets);
    final totalDurationMinutes = records.fold<int>(
      0,
      (sum, r) => sum + r.durationSeconds,
    ) / 60.0;

    if (totalDurationMinutes == 0) return 0.0;
    return totalSets / totalDurationMinutes;
  }

  /// Calculate muscle group distribution with volume
  Map<PrimaryMuscleGroup, double> calculateMuscleVolumeDistribution(
    List<WorkoutRecord> records,
  ) {
    final distribution = <PrimaryMuscleGroup, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        // Skip exercises without loaded exercise reference
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        final muscle = exercise.primaryMuscle;
        final volume = recordedExercise.totalVolume;
        distribution[muscle] = (distribution[muscle] ?? 0) + volume;
      }
    }

    return distribution;
  }

  /// Calculate weekly volume trend
  /// Returns map of week start date (Monday) to total volume
  Map<DateTime, double> calculateWeeklyVolumeTrend(
    List<WorkoutRecord> records,
    int weeks,
  ) {
    final result = <DateTime, double>{};

    if (weeks <= 0) return result;

    // Get the current week's Monday
    final now = DateTime.now();
    final currentMonday = _getWeekStart(now);

    // Initialize all weeks with 0 volume
    for (int i = 0; i < weeks; i++) {
      final weekStart = currentMonday.subtract(Duration(days: 7 * i));
      result[weekStart] = 0.0;
    }

    // Aggregate volume by week
    for (final record in records) {
      final recordWeekStart = _getWeekStart(record.date);

      // Only include if within the requested weeks range
      if (result.containsKey(recordWeekStart)) {
        final recordVolume = record.exercises.fold<double>(
          0.0,
          (sum, e) => sum + e.totalVolume,
        );
        result[recordWeekStart] = (result[recordWeekStart] ?? 0) + recordVolume;
      }
    }

    return result;
  }

  /// Calculate personal records per exercise (max weight)
  Map<String, double> calculateMaxWeightsByExercise(List<WorkoutRecord> records) {
    final maxWeights = <String, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exerciseName = recordedExercise.name;
        if (exerciseName.isEmpty) continue;

        final weight = recordedExercise.maxWeight;
        if (weight == null || weight == 0) continue;

        final currentMax = maxWeights[exerciseName];
        if (currentMax == null || weight > currentMax) {
          maxWeights[exerciseName] = weight;
        }
      }
    }

    return maxWeights;
  }

  /// Get the Monday of the week for a given date
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: weekday - 1),
    );
  }

  /// Calculate daily volume trend
  /// Returns map of date (normalized to midnight) to total volume
  Map<DateTime, double> calculateDailyVolumeTrend(List<WorkoutRecord> records) {
    final result = <DateTime, double>{};

    for (final record in records) {
      // Normalize date to midnight
      final normalizedDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      final recordVolume = record.exercises.fold<double>(
        0.0,
        (sum, e) => sum + e.totalVolume,
      );
      result[normalizedDate] = (result[normalizedDate] ?? 0) + recordVolume;
    }

    return result;
  }
}
