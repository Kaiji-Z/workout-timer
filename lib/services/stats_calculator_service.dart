import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/muscle_group.dart';

/// 力量记录数据点
class StrengthDataPoint {
  final DateTime date;
  final double weight;
  final int? reps;
  final double estimated1RM;

  const StrengthDataPoint({
    required this.date,
    required this.weight,
    this.reps,
    required this.estimated1RM,
  });
}

/// Service for calculating workout statistics
class StatsCalculatorService {
  /// Calculate total volume (sets × reps × weight) for all records
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  double calculateTotalVolume(List<WorkoutRecord> records, {double? bodyWeight}) {
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
    List<WorkoutRecord> records,
    {double? bodyWeight}
  ) {
    final distribution = <PrimaryMuscleGroup, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        // Skip exercises without loaded exercise reference
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        final muscle = exercise.primaryMuscle;
        final volume = recordedExercise.bodyweightAdjustedVolume(bodyWeight);
        distribution[muscle] = (distribution[muscle] ?? 0) + volume;
      }
    }

    return distribution;
  }

  /// Calculate weekly volume trend
  /// Returns map of week start date (Monday) to total volume
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  Map<DateTime, double> calculateWeeklyVolumeTrend(
    List<WorkoutRecord> records,
    int weeks,
    {double? bodyWeight}
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
          (sum, e) => sum + e.bodyweightAdjustedVolume(bodyWeight),
        );
        result[recordWeekStart] = (result[recordWeekStart] ?? 0) + recordVolume;
      }
    }

    return result;
  }

  /// Calculate personal records per exercise (max weight)
  Map<String, double> calculateMaxWeightsByExercise(
    List<WorkoutRecord> records,
  ) {
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

  /// Calculate estimated 1RM using Epley formula: weight × (1 + reps / 30)
  /// Returns max estimated 1RM per exercise name across all records
  Map<String, double> calculateEstimated1RM(List<WorkoutRecord> records) {
    final estimated1RMs = <String, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final name = recordedExercise.name;
        final key = name.isNotEmpty ? name : 'exercise_${recordedExercise.exerciseId}';

        // 从每组数据中计算最大预估1RM
        final sets = recordedExercise.setsData;
        if (sets != null && sets.isNotEmpty) {
          for (final set in sets) {
            if (set.weight == null || set.weight == 0) continue;
            if (set.reps == null || set.reps! > 10) continue;
            final reps = set.reps!;
            // Epley 公式：weight × (1 + reps / 30)
            final e1rm = set.weight! * (1 + reps / 30);
            final currentMax = estimated1RMs[key];
            if (currentMax == null || e1rm > currentMax) {
              estimated1RMs[key] = e1rm;
            }
          }
        } else if (recordedExercise.maxWeight != null &&
            recordedExercise.maxWeight! > 0) {
          // 回退：没有每组数据时，使用最大重量作为1RM的保守估计
          // 注意：这会低估实际1RM（例如 80kg×8 实际1RM约103kg）
          final currentMax = estimated1RMs[key];
          if (currentMax == null || recordedExercise.maxWeight! > currentMax) {
            estimated1RMs[key] = recordedExercise.maxWeight!;
          }
        }
      }
    }

    return estimated1RMs;
  }

  /// Calculate strength trend for a specific exercise
  /// Returns chronological list of data points (date → max weight + estimated 1RM)
  List<StrengthDataPoint> calculateExerciseStrengthTrend(
    List<WorkoutRecord> records,
    String exerciseName,
  ) {
    final dataPoints = <StrengthDataPoint>[];

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        if (recordedExercise.name != exerciseName) continue;

        double maxWeight = 0;
        double best1RM = 0;
        int? bestReps;

        final sets = recordedExercise.setsData;
        if (sets != null && sets.isNotEmpty) {
          for (final set in sets) {
            if (set.weight != null && set.weight! > maxWeight) {
              maxWeight = set.weight!;
              bestReps = set.reps;
            }
            if (set.weight != null && set.weight! > 0) {
              final reps = set.reps ?? 1;
              final e1rm = set.weight! * (1 + reps / 30);
              if (e1rm > best1RM) best1RM = e1rm;
            }
          }
        } else if (recordedExercise.maxWeight != null) {
          maxWeight = recordedExercise.maxWeight!;
          best1RM = maxWeight;
          bestReps = null; // no reps data available
        }

        if (maxWeight > 0) {
          dataPoints.add(
            StrengthDataPoint(
              date: record.date,
              weight: maxWeight,
              reps: bestReps,
              estimated1RM: best1RM,
            ),
          );
        }
      }
    }

    // 按日期排序
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    return dataPoints;
  }

  /// Calculate secondary muscle group recovery data
  /// Returns map of secondary muscle group → days since last trained
  /// Uses Exercise.secondaryMuscles for accurate sub-muscle tracking
  Map<SecondaryMuscleGroup, int> calculateSecondaryMuscleRecovery(
    List<WorkoutRecord> records,
  ) {
    final lastTrainingDates = <SecondaryMuscleGroup, DateTime>{};
    final now = DateTime.now();

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        // 收集该动作刺激的所有子肌群（主肌群的子分类 + 次要肌群）
        final stimulatedMuscles = <SecondaryMuscleGroup>{};

        // 主肌群的所有子分类
        for (final sub in exercise.primaryMuscle.secondaryMuscles) {
          stimulatedMuscles.add(sub);
        }

        // 次要肌群
        for (final sub in exercise.secondaryMuscles) {
          stimulatedMuscles.add(sub);
        }

        // 更新最后训练日期
        for (final muscle in stimulatedMuscles) {
          if (lastTrainingDates[muscle] == null ||
              record.date.isAfter(lastTrainingDates[muscle]!)) {
            lastTrainingDates[muscle] = record.date;
          }
        }
      }
    }

    // 计算恢复天数
    final recoveryData = <SecondaryMuscleGroup, int>{};
    for (final entry in lastTrainingDates.entries) {
      recoveryData[entry.key] = now.difference(entry.value).inDays;
    }

    return recoveryData;
  }

  /// 计算次级肌群的容量分布
  /// 
  /// 采用 70/30 分配模型：主肌群下属的次级肌群获得 70% 的训练容量，
  /// 辅助肌群获得 30%（稳定肌/协同肌）。
  /// 当某个肌群没有定义次级肌群时，其份额全部分配给主肌群下属。
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  /// Returns map of secondary muscle group → total volume (reps × weight)
  Map<SecondaryMuscleGroup, double> calculateSecondaryMuscleVolumeDistribution(
    List<WorkoutRecord> records,
    {double? bodyWeight}
  ) {
    final distribution = <SecondaryMuscleGroup, double>{};

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exercise = recordedExercise.exercise;
        if (exercise == null) continue;

        final volume = recordedExercise.bodyweightAdjustedVolume(bodyWeight);
        if (volume <= 0) continue;

        // 主肌群的子分类均分容量
        final primarySubs = exercise.primaryMuscle.secondaryMuscles;
        if (primarySubs.isNotEmpty) {
          final sharePerSub = volume * 0.7 / primarySubs.length; // 70% 给主肌群子分类
          for (final sub in primarySubs) {
            distribution[sub] = (distribution[sub] ?? 0) + sharePerSub;
          }
        }

        // 次要肌群均分剩余容量
        final secondarySubs = exercise.secondaryMuscles;
        if (secondarySubs.isNotEmpty) {
          final sharePerSub = volume * 0.3 / secondarySubs.length; // 30% 给次要肌群
          for (final sub in secondarySubs) {
            distribution[sub] = (distribution[sub] ?? 0) + sharePerSub;
          }
        }
      }
    }

    return distribution;
  }

  /// Get the Monday of the week for a given date
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }

  /// Calculate daily volume trend
  /// Returns map of date (normalized to midnight) to total volume
  /// When [bodyWeight] is provided (>0), bodyweight exercises use adjusted volume
  Map<DateTime, double> calculateDailyVolumeTrend(List<WorkoutRecord> records, {double? bodyWeight}) {
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
        (sum, e) => sum + e.bodyweightAdjustedVolume(bodyWeight),
      );
      result[normalizedDate] = (result[normalizedDate] ?? 0) + recordVolume;
    }

    return result;
  }
}
