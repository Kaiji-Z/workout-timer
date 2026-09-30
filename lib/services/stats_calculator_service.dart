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

/// 恢复分级（今日状态卡 chips 用）
///
/// 依据 24-72h 肌肉蛋白合成窗口：48h 内仍在恢复，2-7 天充分恢复，
/// 超过 7 天视为久未训练（.goal/SPEC.md §3.2-6）。
enum RecoveryLevel { noData, recovering, recovered, stale }

/// 剂量状态（滚动 7 天每肌群组数 vs MEV/MRV 参考带）
enum DoseStatus { noData, belowMev, inRange, aboveMrv }

/// 急慢性负荷比分区（护栏参考，非伤病预测）
enum LoadRatioBand { noData, low, normal, high }

/// 周滚动容量趋势点（窗口末日 + 该窗口总容量）
class RollingVolumePoint {
  final DateTime windowEnd;
  final int windowDays;
  final double volume;

  const RollingVolumePoint({
    required this.windowEnd,
    required this.windowDays,
    required this.volume,
  });
}

/// Service for calculating workout statistics
class StatsCalculatorService {
  // ==================== 滚动窗口参考常量（.goal/SPEC.md §3.2） ====================
  // MEV/MRV 为 Israetel 系实践启发值，UI 需以"参考线"措辞呈现。
  static const int weeklyMevSets = 10;
  static const int weeklyMrvSets = 20;
  static const double loadRatioLowThreshold = 0.8;
  static const double loadRatioHighThreshold = 1.3;
  static const int acuteWindowDays = 7;
  static const int chronicWindowDays = 28;

  /// 剥离时间部分，只保留日期
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
        final setsData = recordedExercise.setsData;
        final sets = setsData != null && setsData.isNotEmpty
            ? setsData.length
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
          final weight = set.weight;
          final reps = set.reps;
          if (weight == null || weight <= 0) continue;
          if (reps == null || reps <= 0) continue;

          final e1RM = estimate1RM(weight, reps);
          final current = sessionBest[name];
          if (current == null || e1RM > current.estimated1RM) {
            sessionBest[name] = Estimated1RMPoint(
              date: record.date,
              estimated1RM: e1RM,
              weight: weight,
              reps: reps,
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

  // ==================== 滚动窗口指标（问题驱动统计页） ====================
  //
  // 身体的问题用滚动窗口（锚定 asOf 当天），习惯的问题用日历周。
  // 所有方法显式接收 asOf/today，服务内部不取当前时间（可测试）。

  /// 滚动窗口过滤：date ∈ [asOf-(windowDays-1), asOf]，含当天共 N 天。
  ///
  /// 时间部分忽略（只比日期），asOf 之后的记录一律排除。
  List<WorkoutRecord> filterRollingWindow(
    List<WorkoutRecord> records, {
    required DateTime asOf,
    required int windowDays,
  }) {
    final end = dateOnly(asOf);
    final start = end.subtract(Duration(days: windowDays - 1));
    return records.where((r) {
      final d = dateOnly(r.date);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  /// 滚动窗口总容量（组×次×重量，可含体重调整）
  double rollingVolume(
    List<WorkoutRecord> records, {
    required DateTime asOf,
    required int windowDays,
    double? bodyWeight,
  }) {
    return calculateTotalVolume(
      filterRollingWindow(records, asOf: asOf, windowDays: windowDays),
      bodyWeight: bodyWeight,
    );
  }

  /// 每主肌群距上次训练的天数（date-only 差）。
  ///
  /// 肌群来源 = exercise.primaryMuscle ∪ record.trainedMuscles（会话级
  /// 摘要同样说明该部位当天练过）。从未练过的肌群不出现在结果里
  /// （UI 视为 noData）。
  Map<PrimaryMuscleGroup, int> daysSinceLastTrained(
    List<WorkoutRecord> records, {
    required DateTime today,
  }) {
    final lastTrained = <PrimaryMuscleGroup, DateTime>{};

    void touch(PrimaryMuscleGroup muscle, DateTime date) {
      final current = lastTrained[muscle];
      if (current == null || date.isAfter(current)) {
        lastTrained[muscle] = date;
      }
    }

    for (final record in records) {
      for (final recordedExercise in record.exercises) {
        final exercise = recordedExercise.exercise;
        if (exercise != null) touch(exercise.primaryMuscle, record.date);
      }
      for (final muscle in record.trainedMuscles) {
        touch(muscle, record.date);
      }
    }

    final todayDate = dateOnly(today);
    return lastTrained.map(
      (muscle, date) =>
          MapEntry(muscle, todayDate.difference(dateOnly(date)).inDays),
    );
  }

  /// 恢复分级：null→noData；0-1 天→recovering（48h 内）；
  /// 2-7 天→recovered；>7 天→stale。
  RecoveryLevel recoveryLevel(int? daysSinceLastTrained) {
    if (daysSinceLastTrained == null) return RecoveryLevel.noData;
    if (daysSinceLastTrained <= 1) return RecoveryLevel.recovering;
    if (daysSinceLastTrained <= 7) return RecoveryLevel.recovered;
    return RecoveryLevel.stale;
  }

  /// 急慢性负荷比（ACWR 简化版）= 近7天容量 / (近28天容量 / 4)。
  ///
  /// 28 天窗口包含急性期；急性期之外没有任何历史容量时比值恒为
  /// "自己比自己"，无参考意义 → 返回 null。仅作护栏参考，不用于
  /// 伤病预测（ACWR 方法学有争议）。
  double? acuteChronicRatio(
    List<WorkoutRecord> records, {
    required DateTime asOf,
    double? bodyWeight,
  }) {
    final acute = rollingVolume(
      records,
      asOf: asOf,
      windowDays: acuteWindowDays,
      bodyWeight: bodyWeight,
    );
    final chronic = rollingVolume(
      records,
      asOf: asOf,
      windowDays: chronicWindowDays,
      bodyWeight: bodyWeight,
    );
    if (chronic <= 0 || chronic - acute <= 0) return null;
    return acute / (chronic / (chronicWindowDays / acuteWindowDays));
  }

  /// 负荷比分区：<0.8 low / 0.8-1.3 normal / >1.3 high
  LoadRatioBand loadRatioBand(double? ratio) {
    if (ratio == null) return LoadRatioBand.noData;
    if (ratio < loadRatioLowThreshold) return LoadRatioBand.low;
    if (ratio > loadRatioHighThreshold) return LoadRatioBand.high;
    return LoadRatioBand.normal;
  }

  /// 滚动窗口每肌群剂量状态（默认 7 天组数 vs MEV/MRV 参考带）。
  ///
  /// 窗口内没有任何记录 → 六个肌群全部 noData；
  /// 窗口内有记录但该肌群 0 组 → belowMev（完全没练是最强的"不足"）。
  Map<PrimaryMuscleGroup, DoseStatus> doseStatusPerMuscle(
    List<WorkoutRecord> records, {
    required DateTime asOf,
    int windowDays = acuteWindowDays,
  }) {
    final window = filterRollingWindow(
      records,
      asOf: asOf,
      windowDays: windowDays,
    );
    if (window.isEmpty) {
      return {
        for (final muscle in PrimaryMuscleGroup.values)
          muscle: DoseStatus.noData,
      };
    }

    final setsPerMuscle = calculateSetsPerMuscleGroup(window);
    return {
      for (final muscle in PrimaryMuscleGroup.values)
        muscle: _classifyDose(setsPerMuscle[muscle] ?? 0),
    };
  }

  DoseStatus _classifyDose(int sets) {
    if (sets < weeklyMevSets) return DoseStatus.belowMev;
    if (sets > weeklyMrvSets) return DoseStatus.aboveMrv;
    return DoseStatus.inRange;
  }

  /// 近 [weeks] 周的每周滚动容量（7 天窗口）。
  ///
  /// 点 i（0 最旧）：窗口末日 = asOf - 7*(weeks-1-i) 天，
  /// 窗口 = [末日-6, 末日]。最新一个窗口以 asOf 结尾。
  List<RollingVolumePoint> weeklyRollingVolumeTrend(
    List<WorkoutRecord> records, {
    required DateTime asOf,
    int weeks = 6,
    double? bodyWeight,
  }) {
    return List.generate(weeks, (i) {
      final windowEnd = dateOnly(
        asOf.subtract(Duration(days: 7 * (weeks - 1 - i))),
      );
      final windowStart = windowEnd.subtract(const Duration(days: 6));
      final volume = calculateTotalVolume(
        records.where((r) {
          final d = dateOnly(r.date);
          return !d.isBefore(windowStart) && !d.isAfter(windowEnd);
        }).toList(),
        bodyWeight: bodyWeight,
      );
      return RollingVolumePoint(
        windowEnd: windowEnd,
        windowDays: 7,
        volume: volume,
      );
    });
  }

  /// 最小二乘线性回归斜率（点数 < 2 时返回 null）
  double? linearSlope(List<double> values) {
    final n = values.length;
    if (n < 2) return null;
    final meanX = (n - 1) / 2.0;
    final meanY = values.reduce((a, b) => a + b) / n;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (i - meanX) * (values[i] - meanY);
      den += (i - meanX) * (i - meanX);
    }
    if (den == 0) return null;
    return num / den;
  }

  // ==================== 习惯区（日历语义，周一为一周之始） ====================

  DateTime _startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// 本周（周一 00:00 至今天结束）训练次数
  int sessionsThisWeek(List<DateTime> trainingDates, {required DateTime today}) {
    final weekStart = _startOfWeek(today);
    final end = dateOnly(today);
    return trainingDates
        .where((d) {
          final date = dateOnly(d);
          return !date.isBefore(weekStart) && !date.isAfter(end);
        })
        .length;
  }

  /// 连续达标周数（每周训练次数 ≥ [weeklyTarget]）。
  ///
  /// 从本周往回数：本周未达标不中断（周还没过完，跳过继续看上周），
  /// 已达标则计入；遇到第一个未达标的完整周即停止。
  int consecutiveQualifyingWeeks(
    List<DateTime> trainingDates, {
    required DateTime today,
    int weeklyTarget = 3,
  }) {
    final weekStart = _startOfWeek(today);
    var streak = 0;

    for (var week = 0; week < 260; week++) {
      final start = weekStart.subtract(Duration(days: 7 * week));
      final end = start.add(const Duration(days: 6));
      final count = trainingDates
          .where((d) {
            final date = dateOnly(d);
            return !date.isBefore(start) && !date.isAfter(end);
          })
          .length;

      if (count >= weeklyTarget) {
        streak++;
      } else if (week > 0) {
        // 本周（week==0）未达标：周还没过完，跳过不计、不中断
        break;
      }
    }
    return streak;
  }
}
