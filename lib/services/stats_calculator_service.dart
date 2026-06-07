import 'dart:math' as math;

import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/muscle_group.dart';

/// Estimated 1RM data point for a single exercise over time
class Estimated1RMPoint {
  final DateTime date;
  final double estimated1RM;
  final double weight;
  final int? reps;

  const Estimated1RMPoint({
    required this.date,
    required this.estimated1RM,
    required this.weight,
    this.reps,
  });
}

/// Service for calculating workout statistics
class StatsCalculatorService {
  /// Estimate 1RM using Mayhew et al. (1992) exponential formula.
  ///
  /// Best classical formula for 10-15 rep range. Derived from 435 college
  /// students. Error margin ±5-8kg at 12 reps.
  ///
  /// Formula: 1RM = 100w / (52.2 + 41.9 × e^(-0.055 × r))
  static double estimate1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    return 100 * weight / (52.2 + 41.9 * math.exp(-0.055 * reps));
  }

  /// Calculate total volume (sets × reps × weight) for all records
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  double calculateTotalVolume(
    List<WorkoutRecord> records, {
    double? bodyWeight,
  }) {
    double totalVolume = 0.0;
    for (final record in records) {
      for (final exercise in record.exercises) {
        totalVolume += exercise.bodyweightAdjustedVolume(bodyWeight);
      }
    }
    return totalVolume;
  }

  /// Calculate average workout density (sets per minute)
  double calculateDensity(List<WorkoutRecord> records) {
    if (records.isEmpty) return 0.0;

    final totalSets = records.fold<int>(0, (sum, r) => sum + r.totalSets);
    final totalDurationMinutes =
        records.fold<int>(0, (sum, r) => sum + r.durationSeconds) / 60.0;

    if (totalDurationMinutes == 0) return 0.0;
    return totalSets / totalDurationMinutes;
  }

  /// Calculate muscle group distribution with volume
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  Map<PrimaryMuscleGroup, double> calculateMuscleVolumeDistribution(
    List<WorkoutRecord> records, {
    double? bodyWeight,
  }) {
    final distribution = <PrimaryMuscleGroup, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        final muscle = exercise.primaryMuscle;
        final volume = recordedExercise.bodyweightAdjustedVolume(bodyWeight);
        distribution[muscle] = (distribution[muscle] ?? 0) + volume;
      }
    }

    return distribution;
  }

  /// Calculate total completed sets per primary muscle group
  Map<PrimaryMuscleGroup, int> calculateSetsPerMuscleGroup(
    List<WorkoutRecord> records,
  ) {
    final result = <PrimaryMuscleGroup, int>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        final muscle = exercise.primaryMuscle;
        final sets =
            recordedExercise.setsData != null &&
                recordedExercise.setsData!.isNotEmpty
            ? recordedExercise.setsData!.length
            : recordedExercise.completedSets;
        result[muscle] = (result[muscle] ?? 0) + sets;
      }
    }

    return result;
  }

  /// Calculate estimated 1RM trend over time for each exercise.
  ///
  /// For each exercise in each session, computes the Mayhew estimated 1RM for
  /// every set and records the highest. Returns map of exercise name → list of
  /// (date, estimated1RM) sorted by date.
  ///
  /// Exercises without per-set reps data are skipped (can't estimate 1RM
  /// without reps).
  Map<String, List<Estimated1RMPoint>> calculateEstimated1RMTrend(
    List<WorkoutRecord> records,
  ) {
    final result = <String, List<Estimated1RMPoint>>{};

    for (final record in records) {
      // Track best 1RM per exercise name in this session
      final sessionBest = <String, Estimated1RMPoint>{};

      for (final recordedExercise in record.exercises) {
        final name = recordedExercise.name;
        if (name.isEmpty) continue;

        final sets = recordedExercise.setsData;
        if (sets == null || sets.isEmpty) continue;

        for (final set in sets) {
          if (set.weight == null || set.weight! <= 0) continue;
          if (set.reps == null || set.reps! <= 0) continue;

          final e1RM = estimate1RM(set.weight!, set.reps!);
          final current = sessionBest[name];
          if (current == null || e1RM > current.estimated1RM) {
            sessionBest[name] = Estimated1RMPoint(
              date: record.date,
              estimated1RM: e1RM,
              weight: set.weight!,
              reps: set.reps,
            );
          }
        }
      }

      // Add session bests to result
      for (final entry in sessionBest.entries) {
        result.putIfAbsent(entry.key, () => []);
        result[entry.key]!.add(entry.value);
      }
    }

    // Sort each exercise's points by date
    for (final points in result.values) {
      points.sort((a, b) => a.date.compareTo(b.date));
    }

    return result;
  }

  /// Calculate daily volume trend
  /// Returns map of date (normalized to midnight) to total volume
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  Map<DateTime, double> calculateDailyVolumeTrend(
    List<WorkoutRecord> records, {
    double? bodyWeight,
  }) {
    final result = <DateTime, double>{};

    for (final record in records) {
      final normalizedDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      final recordVolume = record.exercises.fold<double>(
        0.0,
        (sum, e) => sum + e.bodyweightAdjustedVolume(bodyWeight),
      );
      result[normalizedDate] = (result[normalizedDate] ?? 0) + recordVolume;
    }

    return result;
  }
}
