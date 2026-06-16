import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/workout_session.dart';
import 'stats_calculator_service.dart';

/// Pure aggregation logic extracted from the Stats screen.
///
/// Every method is side-effect free and takes its inputs explicitly (the
/// selected week/month, the record list, the user's body weight), so they can
/// be unit tested without a widget tree. The Stats screen now only owns UI
/// state and delegates computation here.
///
/// Records are passed as `List<dynamic>` because the history merges the legacy
/// [WorkoutSession] model with the richer [WorkoutRecord] model; the dynamic
/// accessors below normalize that difference.
class StatsAggregatorService {
  StatsAggregatorService({StatsCalculatorService? statsCalculator})
    : _statsCalc = statsCalculator ?? StatsCalculatorService();

  final StatsCalculatorService _statsCalc;

  // ── Record accessors (normalize WorkoutSession vs WorkoutRecord) ──────────

  /// Merge legacy sessions and new records into a single list.
  static List<dynamic> mergeRecords(
    List<WorkoutSession> sessions,
    List<WorkoutRecord> records,
  ) {
    return [...sessions, ...records];
  }

  /// Date portion (time stripped) of a record, regardless of its concrete type.
  DateTime getRecordDate(dynamic record) {
    if (record is WorkoutSession) {
      final parsed = DateTime.parse(record.createdAt);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } else if (record is WorkoutRecord) {
      return DateTime(record.date.year, record.date.month, record.date.day);
    }
    throw ArgumentError('Unknown record type: ${record.runtimeType}');
  }

  /// Number of sets in a record.
  int getRecordSets(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalSets;
    } else if (record is WorkoutRecord) {
      return record.totalSets;
    }
    return 0;
  }

  /// Duration of a record in seconds.
  int getRecordDuration(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalRestTimeMs ~/ 1000;
    } else if (record is WorkoutRecord) {
      return record.durationSeconds;
    }
    return 0;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Monday of the week containing [date] (time stripped).
  DateTime getStartOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: date.weekday - 1));
  }

  /// The 7 days of the week starting at [weekStart].
  List<DateTime> getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  /// Records that fall within the week containing [weekStart].
  List<dynamic> filterByWeek(List<dynamic> allRecords, DateTime weekStart) {
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return allRecords.where((record) {
      final date = getRecordDate(record);
      return date.isAfter(
            startOfWeek.subtract(const Duration(milliseconds: 1)),
          ) &&
          date.isBefore(endOfWeek);
    }).toList();
  }

  /// Records that fall within [month] of [year].
  List<dynamic> filterByMonth(List<dynamic> allRecords, int year, int month) {
    return allRecords.where((record) {
      final date = getRecordDate(record);
      return date.year == year && date.month == month;
    }).toList();
  }

  /// Workout count per month (1–12) for a given [year].
  Map<int, int> getMonthlyCounts(List<dynamic> allRecords, int year) {
    final counts = <int, int>{};
    for (int i = 1; i <= 12; i++) {
      counts[i] = 0;
    }

    for (final record in allRecords) {
      final date = getRecordDate(record);
      if (date.year == year) {
        counts[date.month] = (counts[date.month] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Day-of-week indices (0=Mon … 6=Sun) that have a workout, within the week
  /// starting at [weekStart].
  Set<int> getWorkoutDaysInWeek(List<dynamic> allRecords, DateTime weekStart) {
    final days = <int>{};
    final records = filterByWeek(allRecords, weekStart);

    for (final record in records) {
      final date = getRecordDate(record);
      final dayIndex = date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        days.add(dayIndex);
      }
    }

    return days;
  }

  // ── Daily aggregation ─────────────────────────────────────────────────────

  /// Per-day durations. For a week view [isWeek]=true keys are 0–6 (day-of-week
  /// index relative to [weekStart]); for a month view keys are 1..daysInMonth
  /// (day-of-month), scoped to [year]/[month].
  Map<int, int> getDailyDurations(
    List<dynamic> records, {
    required bool isWeek,
    DateTime? weekStart,
    required int year,
    required int month,
  }) {
    final durations = <int, int>{};

    if (isWeek) {
      final start = getStartOfWeek(weekStart ?? DateTime.now());
      for (int i = 0; i < 7; i++) {
        durations[i] = 0;
      }

      for (final record in records) {
        final date = getRecordDate(record);
        final dayIndex = date.difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          durations[dayIndex] =
              (durations[dayIndex] ?? 0) + getRecordDuration(record);
        }
      }
    } else {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        durations[i] = 0;
      }

      for (final record in records) {
        final date = getRecordDate(record);
        if (date.year == year && date.month == month) {
          durations[date.day] =
              (durations[date.day] ?? 0) + getRecordDuration(record);
        }
      }
    }

    return durations;
  }

  /// Per-day sets. Same keying convention as [getDailyDurations].
  Map<int, int> getDailySets(
    List<dynamic> records, {
    required bool isWeek,
    DateTime? weekStart,
    required int year,
    required int month,
  }) {
    final sets = <int, int>{};

    if (isWeek) {
      final start = getStartOfWeek(weekStart ?? DateTime.now());
      for (int i = 0; i < 7; i++) {
        sets[i] = 0;
      }

      for (final record in records) {
        final date = getRecordDate(record);
        final dayIndex = date.difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          sets[dayIndex] = (sets[dayIndex] ?? 0) + getRecordSets(record);
        }
      }
    } else {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        sets[i] = 0;
      }

      for (final record in records) {
        final date = getRecordDate(record);
        if (date.year == year && date.month == month) {
          sets[date.day] = (sets[date.day] ?? 0) + getRecordSets(record);
        }
      }
    }

    return sets;
  }

  // ── Summary statistics ────────────────────────────────────────────────────

  /// Frequency stats: total sessions, distinct workout days, weekly average,
  /// and per-primary-muscle occurrence counts.
  Map<String, dynamic> calculateFrequencyStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'sessionCount': 0,
        'workoutDays': 0,
        'avgSessionsPerWeek': 0.0,
        'muscleFrequency': <PrimaryMuscleGroup, int>{},
      };
    }

    final uniqueDays = <String>{};
    final muscleFrequency = <PrimaryMuscleGroup, int>{};

    for (final record in records) {
      final date = getRecordDate(record);
      uniqueDays.add('${date.year}-${date.month}-${date.day}');

      if (record is WorkoutRecord && record.trainedMuscles.isNotEmpty) {
        for (final muscle in record.trainedMuscles) {
          muscleFrequency[muscle] = (muscleFrequency[muscle] ?? 0) + 1;
        }
      }
    }

    // Calculate actual sessions per week based on the time span
    final dates = uniqueDays.map((d) {
      final parts = d.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList();
    dates.sort();

    final double avgSessionsPerWeek;
    if (dates.length >= 2) {
      final spanDays = dates.last.difference(dates.first).inDays + 1;
      final spanWeeks = spanDays / 7.0;
      avgSessionsPerWeek = spanWeeks > 0
          ? records.length / spanWeeks
          : records.length.toDouble();
    } else {
      // Single day of data — can't compute meaningful weekly average
      avgSessionsPerWeek = records.length.toDouble();
    }

    return {
      'sessionCount': records.length,
      'workoutDays': uniqueDays.length,
      'avgSessionsPerWeek': avgSessionsPerWeek,
      'muscleFrequency': muscleFrequency,
    };
  }

  /// Volume/sets/duration aggregates over a record list.
  Map<String, dynamic> calculateVolumeStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'totalSets': 0,
        'totalDuration': 0,
        'avgSetsPerSession': 0.0,
        'avgDurationPerSession': 0,
      };
    }

    int totalSets = 0;
    int totalDuration = 0;

    for (final record in records) {
      totalSets += getRecordSets(record);
      totalDuration += getRecordDuration(record);
    }

    return {
      'totalSets': totalSets,
      'totalDuration': totalDuration,
      'avgSetsPerSession': totalSets / records.length,
      'avgDurationPerSession': totalDuration ~/ records.length,
    };
  }

  /// Percentage change in total volume between two periods.
  /// Returns null when either period lacks volume data.
  double? calculateVolumeChange(
    List<dynamic> currentRecords,
    List<dynamic> previousRecords, {
    double? bodyWeight,
  }) {
    final currentWorkoutRecords = currentRecords
        .whereType<WorkoutRecord>()
        .toList();
    final previousWorkoutRecords = previousRecords
        .whereType<WorkoutRecord>()
        .toList();

    if (currentWorkoutRecords.isEmpty || previousWorkoutRecords.isEmpty) {
      return null;
    }

    final currentVolume = _statsCalc.calculateTotalVolume(
      currentWorkoutRecords,
      bodyWeight: bodyWeight,
    );
    final previousVolume = _statsCalc.calculateTotalVolume(
      previousWorkoutRecords,
      bodyWeight: bodyWeight,
    );

    if (previousVolume == 0) return null;

    return ((currentVolume - previousVolume) / previousVolume) * 100;
  }

  /// Top-10 most frequent exercises across the records.
  Map<String, int> calculateCommonExercises(List<dynamic> records) {
    final exerciseCounts = <String, int>{};

    for (final record in records) {
      if (record is WorkoutRecord) {
        for (final exercise in record.exercises) {
          final name = exercise.name;
          if (name.isNotEmpty) {
            exerciseCounts[name] = (exerciseCounts[name] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(10));
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  /// Format a duration (seconds) as e.g. "1h 5m", "5m 30s", "12m".
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (secs > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${minutes}m';
    }
  }

  /// Format a volume with thousand separators (e.g. "1.5k kg", "320 kg").
  static String formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${volume.toStringAsFixed(0)} kg';
  }
}
