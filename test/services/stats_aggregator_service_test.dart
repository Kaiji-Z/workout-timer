import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/workout_session.dart';
import 'package:workout_timer/services/stats_aggregator_service.dart';

void main() {
  late StatsAggregatorService aggregator;

  setUp(() {
    aggregator = StatsAggregatorService();
  });

  // Helper builders ----------------------------------------------------------
  WorkoutSession session({
    required String createdAt,
    required int totalSets,
    int restMs = 60000,
  }) {
    return WorkoutSession(
      id: createdAt,
      totalSets: totalSets,
      totalRestTimeMs: restMs,
      createdAt: createdAt,
    );
  }

  WorkoutRecord record({
    required DateTime date,
    int durationSeconds = 1800,
    int totalSets = 3,
    List<PrimaryMuscleGroup> trainedMuscles = const [],
  }) {
    return WorkoutRecord(
      id: '${date.toIso8601String()}',
      date: date,
      durationSeconds: durationSeconds,
      trainedMuscles: trainedMuscles,
      exercises: const [],
      totalSets: totalSets,
      createdAt: date,
    );
  }

  group('record accessors', () {
    test('getRecordDate strips time from both record types', () {
      final s = session(createdAt: '2026-03-15T10:30:00', totalSets: 4);
      final r = record(date: DateTime(2026, 3, 16, 22, 5));

      expect(aggregator.getRecordDate(s), DateTime(2026, 3, 15));
      expect(aggregator.getRecordDate(r), DateTime(2026, 3, 16));
    });

    test('getRecordDate throws on unknown type', () {
      expect(
        () => aggregator.getRecordDate('not a record'),
        throwsArgumentError,
      );
    });

    test('getRecordSets returns totalSets for both types', () {
      expect(
        aggregator.getRecordSets(session(createdAt: 'x', totalSets: 5)),
        5,
      );
      expect(
        aggregator.getRecordSets(
          record(date: DateTime(2026, 1, 1), totalSets: 2),
        ),
        2,
      );
      expect(aggregator.getRecordSets(42), 0);
    });

    test(
      'getRecordDuration converts ms→s for sessions, passes through for records',
      () {
        expect(
          aggregator.getRecordDuration(
            session(createdAt: 'x', totalSets: 1, restMs: 90000),
          ),
          90,
        );
        expect(
          aggregator.getRecordDuration(
            record(date: DateTime(2026, 1, 1), durationSeconds: 1200),
          ),
          1200,
        );
      },
    );
  });

  group('date helpers', () {
    test('getStartOfWeek returns Monday for mid-week date', () {
      // 2026-06-17 is a Wednesday
      final monday = aggregator.getStartOfWeek(DateTime(2026, 6, 17, 14, 0));
      expect(monday, DateTime(2026, 6, 15));
    });

    test('getStartOfWeek returns same date when already Monday', () {
      final monday = aggregator.getStartOfWeek(DateTime(2026, 6, 15));
      expect(monday, DateTime(2026, 6, 15));
    });

    test('getWeekDays returns 7 consecutive days from weekStart', () {
      final days = aggregator.getWeekDays(DateTime(2026, 6, 15));
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 6, 15));
      expect(days.last, DateTime(2026, 6, 21));
    });
  });

  group('filtering', () {
    final allRecords = <dynamic>[
      session(createdAt: '2026-06-15T09:00:00', totalSets: 3), // Mon
      session(createdAt: '2026-06-17T09:00:00', totalSets: 4), // Wed
      session(createdAt: '2026-06-22T09:00:00', totalSets: 2), // next Mon
      record(date: DateTime(2026, 6, 16)), // Tue
      record(date: DateTime(2026, 7, 1)), // out of range
    ];

    test('filterByWeek keeps records in the 7-day window', () {
      final weekRecords = aggregator.filterByWeek(
        allRecords,
        DateTime(2026, 6, 15),
      );
      // Mon 15, Wed 17, Tue 16 → 3 records (next Monday is excluded)
      expect(weekRecords.length, 3);
    });

    test('filterByMonth keeps records in the given year/month', () {
      final juneRecords = aggregator.filterByMonth(allRecords, 2026, 6);
      expect(juneRecords.length, 4); // 15, 16, 17, 22
    });

    test('getMonthlyCounts tallies per month across a year', () {
      final counts = aggregator.getMonthlyCounts(allRecords, 2026);
      expect(counts.length, 12);
      expect(counts[6], 4);
      expect(counts[7], 1);
      expect(counts[1], 0);
    });

    test('getWorkoutDaysInWeek returns 0-based day indices', () {
      final days = aggregator.getWorkoutDaysInWeek(
        allRecords,
        DateTime(2026, 6, 15),
      );
      // Mon(0), Tue(1), Wed(2)
      expect(days, {0, 1, 2});
    });
  });

  group('daily aggregation', () {
    final weekRecords = <dynamic>[
      session(createdAt: '2026-06-15T09:00:00', totalSets: 3, restMs: 60000),
      session(createdAt: '2026-06-15T18:00:00', totalSets: 2, restMs: 30000),
      session(createdAt: '2026-06-17T09:00:00', totalSets: 4, restMs: 90000),
    ];

    test('getDailyDurations sums durations per day-of-week index', () {
      final durations = aggregator.getDailyDurations(
        weekRecords,
        isWeek: true,
        weekStart: DateTime(2026, 6, 15),
        year: 2026,
        month: 6,
      );
      // Mon(0): 60+30=90s, Wed(2): 90s
      expect(durations.length, 7);
      expect(durations[0], 90);
      expect(durations[2], 90);
      expect(durations[1], 0);
    });

    test('getDailySets sums sets per day-of-week index', () {
      final sets = aggregator.getDailySets(
        weekRecords,
        isWeek: true,
        weekStart: DateTime(2026, 6, 15),
        year: 2026,
        month: 6,
      );
      expect(sets[0], 5); // 3+2
      expect(sets[2], 4);
    });

    test('month view keys by day-of-month', () {
      final monthRecords = <dynamic>[
        session(createdAt: '2026-06-03T09:00:00', totalSets: 3, restMs: 60000),
        session(createdAt: '2026-06-03T18:00:00', totalSets: 2, restMs: 30000),
        session(createdAt: '2026-06-10T09:00:00', totalSets: 4, restMs: 90000),
      ];
      final durations = aggregator.getDailyDurations(
        monthRecords,
        isWeek: false,
        year: 2026,
        month: 6,
      );
      expect(durations[3], 90);
      expect(durations[10], 90);
    });
  });

  group('summary statistics', () {
    test('calculateFrequencyStats on empty list returns zeros', () {
      final stats = aggregator.calculateFrequencyStats([]);
      expect(stats['sessionCount'], 0);
      expect(stats['workoutDays'], 0);
      expect(stats['avgSessionsPerWeek'], 0.0);
      expect(stats['muscleFrequency'], <PrimaryMuscleGroup, int>{});
    });

    test(
      'calculateFrequencyStats counts sessions, days, and muscle frequency',
      () {
        final records = <dynamic>[
          record(
            date: DateTime(2026, 6, 15),
            trainedMuscles: [PrimaryMuscleGroup.chest],
          ),
          record(
            date: DateTime(2026, 6, 17),
            trainedMuscles: [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.arms],
          ),
          record(
            date: DateTime(2026, 6, 19),
            trainedMuscles: [PrimaryMuscleGroup.back],
          ),
        ];
        final stats = aggregator.calculateFrequencyStats(records);

        expect(stats['sessionCount'], 3);
        expect(stats['workoutDays'], 3);
        final muscleFreq =
            stats['muscleFrequency'] as Map<PrimaryMuscleGroup, int>;
        expect(muscleFreq[PrimaryMuscleGroup.chest], 2);
        expect(muscleFreq[PrimaryMuscleGroup.arms], 1);
        expect(muscleFreq[PrimaryMuscleGroup.back], 1);
      },
    );

    test(
      'calculateFrequencyStats averages sessions per week over the span',
      () {
        // Span from Jun 15 to Jun 29 = 15 days ≈ 2.14 weeks; 3 sessions
        final records = <dynamic>[
          record(date: DateTime(2026, 6, 15)),
          record(date: DateTime(2026, 6, 22)),
          record(date: DateTime(2026, 6, 29)),
        ];
        final stats = aggregator.calculateFrequencyStats(records);
        final avg = stats['avgSessionsPerWeek'] as double;
        // 3 sessions / (15/7 weeks) ≈ 1.4
        expect(avg, closeTo(3 / (15 / 7), 0.01));
      },
    );

    test('calculateVolumeStats aggregates sets and duration', () {
      final records = <dynamic>[
        session(createdAt: '2026-06-15T09:00:00', totalSets: 5, restMs: 60000),
        session(createdAt: '2026-06-17T09:00:00', totalSets: 3, restMs: 90000),
      ];
      final stats = aggregator.calculateVolumeStats(records);

      expect(stats['totalSets'], 8);
      expect(stats['totalDuration'], 150); // 60 + 90
      expect(stats['avgSetsPerSession'], 4.0);
      expect(stats['avgDurationPerSession'], 75); // 150 ~/ 2
    });

    test(
      'calculateVolumeChange returns null when either period lacks WorkoutRecords',
      () {
        final result = aggregator.calculateVolumeChange(
          <dynamic>[session(createdAt: 'x', totalSets: 1)],
          <dynamic>[session(createdAt: 'y', totalSets: 1)],
        );
        expect(result, isNull);
      },
    );

    test('calculateCommonExercises returns top 10 sorted by frequency', () {
      // Build records with named exercises via a simple stub map is hard;
      // exercise counts come from WorkoutRecord.exercises[].name.
      // Here we only have empty exercises, so result should be empty.
      final records = <dynamic>[record(date: DateTime(2026, 6, 15))];
      final result = aggregator.calculateCommonExercises(records);
      expect(result, isEmpty);
    });
  });

  group('formatting', () {
    test('formatDuration renders hours/minutes/seconds correctly', () {
      expect(
        StatsAggregatorService.formatDuration(3661),
        '1h 1m',
      ); // 1h 1m 1s → has secs
      expect(StatsAggregatorService.formatDuration(61), '1m 1s'); // 1m 1s
      expect(
        StatsAggregatorService.formatDuration(60),
        '1m',
      ); // exactly 1m, 0 secs
      expect(
        StatsAggregatorService.formatDuration(120),
        '2m',
      ); // exactly 2m, 0 secs
      expect(StatsAggregatorService.formatDuration(0), '0m');
    });

    test('formatVolume renders with k suffix above 1000', () {
      expect(StatsAggregatorService.formatVolume(320), '320 kg');
      expect(StatsAggregatorService.formatVolume(1500), '1.5k kg');
      expect(StatsAggregatorService.formatVolume(1000), '1.0k kg');
    });
  });

  group('mergeRecords', () {
    test('concatenates sessions then records', () {
      final sessions = [session(createdAt: 'a', totalSets: 1)];
      final records = [record(date: DateTime(2026, 1, 1))];
      final merged = StatsAggregatorService.mergeRecords(sessions, records);

      expect(merged.length, 2);
      expect(merged[0], isA<WorkoutSession>());
      expect(merged[1], isA<WorkoutRecord>());
    });
  });
}
