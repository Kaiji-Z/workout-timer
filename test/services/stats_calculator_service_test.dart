import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';

void main() {
  late StatsCalculatorService service;

  setUp(() {
    service = StatsCalculatorService();
  });

  group('StatsCalculatorService', () {
    group('calculateTotalVolume', () {
      test('returns 0 for empty records list', () {
        final volume = service.calculateTotalVolume([]);
        expect(volume, equals(0.0));
      });

      test('calculates total volume with setsData', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100), // 1000
                  const SetData(setNumber: 2, reps: 10, weight: 100), // 1000
                ],
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records);
        expect(volume, equals(2000.0));
      });

      test('calculates total volume without setsData (uses completedSets × maxWeight)', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                completedSets: 3,
                maxWeight: 200,
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records);
        expect(volume, equals(600.0));
      });

      test('calculates total volume with mixed data', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100), // 1000
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                completedSets: 3,
                maxWeight: 200, // 600
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records);
        expect(volume, equals(1600.0));
      });

      test('handles multiple records', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 50), // 500
                ],
              ),
            ],
          ),
          _createRecord(
            id: '2',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex2',
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100), // 1000
                ],
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records);
        expect(volume, equals(1500.0));
      });
    });

    group('calculateDensity', () {
      test('returns 0 for empty records list', () {
        final density = service.calculateDensity([]);
        expect(density, equals(0.0));
      });

      test('calculates density correctly', () {
        final records = [
          _createRecord(
            id: '1',
            durationSeconds: 1800, // 30 minutes
            totalSets: 15,
          ),
        ];

        final density = service.calculateDensity(records);
        expect(density, closeTo(0.5, 0.001)); // 15 sets / 30 min
      });

      test('calculates density with multiple records', () {
        final records = [
          _createRecord(
            id: '1',
            durationSeconds: 1800, // 30 minutes
            totalSets: 15,
          ),
          _createRecord(
            id: '2',
            durationSeconds: 1800, // 30 minutes
            totalSets: 15,
          ),
        ];

        final density = service.calculateDensity(records);
        expect(density, closeTo(0.5, 0.001)); // 30 sets / 60 min
      });

      test('returns 0 when total duration is 0', () {
        final records = [
          _createRecord(
            id: '1',
            durationSeconds: 0,
            totalSets: 10,
          ),
        ];

        final density = service.calculateDensity(records);
        expect(density, equals(0.0));
      });
    });

    group('calculateMuscleVolumeDistribution', () {
      test('returns empty map for empty records list', () {
        final distribution = service.calculateMuscleVolumeDistribution([]);
        expect(distribution, isEmpty);
      });

      test('aggregates volume by muscle group', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100), // 1000
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Incline Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 80), // 800
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex3',
                exercise: _createExercise(
                  id: 'ex3',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 200), // 2000
                ],
              ),
            ],
          ),
        ];

        final distribution = service.calculateMuscleVolumeDistribution(records);
        expect(distribution[PrimaryMuscleGroup.chest], equals(1800.0));
        expect(distribution[PrimaryMuscleGroup.legs], equals(2000.0));
        expect(distribution.keys.length, equals(2));
      });

      test('handles exercises with null exercise reference', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: null, // No exercise loaded
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100),
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 200),
                ],
              ),
            ],
          ),
        ];

        final distribution = service.calculateMuscleVolumeDistribution(records);
        // Only the exercise with non-null reference should be counted
        expect(distribution.keys.length, equals(1));
        expect(distribution[PrimaryMuscleGroup.legs], equals(2000.0));
      });
    });

    group('calculateWeeklyVolumeTrend', () {
      test('returns empty map for 0 weeks', () {
        final records = [
          _createRecord(
            id: '1',
            date: DateTime.now(),
          ),
        ];

        final trend = service.calculateWeeklyVolumeTrend(records, 0);
        expect(trend, isEmpty);
      });

      test('returns empty map for negative weeks', () {
        final records = [
          _createRecord(
            id: '1',
            date: DateTime.now(),
          ),
        ];

        final trend = service.calculateWeeklyVolumeTrend(records, -1);
        expect(trend, isEmpty);
      });

      test('returns map with correct number of weeks', () {
        final trend = service.calculateWeeklyVolumeTrend([], 4);
        expect(trend.length, equals(4));
      });

      test('fills missing weeks with 0', () {
        final trend = service.calculateWeeklyVolumeTrend([], 3);
        for (final volume in trend.values) {
          expect(volume, equals(0.0));
        }
      });

      test('groups records by week', () {
        final now = DateTime.now();
        final thisMonday = _getWeekStart(now);

        final records = [
          _createRecord(
            id: '1',
            date: thisMonday, // This week's Monday
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100), // 1000
                ],
              ),
            ],
          ),
          _createRecord(
            id: '2',
            date: thisMonday.add(const Duration(days: 2)), // Wednesday
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex2',
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 50), // 500
                ],
              ),
            ],
          ),
        ];

        final trend = service.calculateWeeklyVolumeTrend(records, 1);
        expect(trend.length, equals(1));
        // Both records should be grouped into the same week
        expect(trend[thisMonday], equals(1500.0));
      });

      test('handles records outside the requested weeks', () {
        final now = DateTime.now();
        final oldDate = now.subtract(const Duration(days: 30));

        final records = [
          _createRecord(
            id: '1',
            date: oldDate,
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 100),
                ],
              ),
            ],
          ),
        ];

        final trend = service.calculateWeeklyVolumeTrend(records, 2);
        // Old record should not be included
        for (final volume in trend.values) {
          expect(volume, equals(0.0));
        }
      });
    });

    group('calculateMaxWeightsByExercise', () {
      test('returns empty map for empty records list', () {
        final maxWeights = service.calculateMaxWeightsByExercise([]);
        expect(maxWeights, isEmpty);
      });

      test('finds max weight for each exercise', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: 100,
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                maxWeight: 200,
              ),
            ],
          ),
        ];

        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights['Bench Press'], equals(100.0));
        expect(maxWeights['Squat'], equals(200.0));
      });

      test('updates max weight when higher weight found', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: 100,
              ),
            ],
          ),
          _createRecord(
            id: '2',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: 120,
              ),
            ],
          ),
        ];

        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights['Bench Press'], equals(120.0));
      });

      test('keeps lower weight when no higher found', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: 120,
              ),
            ],
          ),
          _createRecord(
            id: '2',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: 100,
              ),
            ],
          ),
        ];

        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights['Bench Press'], equals(120.0));
      });

      test('ignores null and zero maxWeight', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                maxWeight: null,
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                maxWeight: 0,
              ),
            ],
          ),
        ];

        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights, isEmpty);
      });

      test('ignores exercises with empty name', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: null, // name will be empty
                maxWeight: 100,
              ),
            ],
          ),
        ];

        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights, isEmpty);
      });
    });

    group('null safety', () {
      test('handles records with empty exercises list', () {
        // WorkoutRecord.exercises is non-nullable, so this tests empty exercises
        final records = [
          _createRecord(id: '1', exercises: [], totalSets: 0),
        ];

        expect(service.calculateTotalVolume(records), equals(0.0));
        expect(service.calculateDensity(records), equals(0.0));
        expect(service.calculateMuscleVolumeDistribution(records), isEmpty);
        expect(service.calculateMaxWeightsByExercise(records), isEmpty);
      });

      test('handles empty exercises within records', () {
        final records = [
          _createRecord(id: '1', exercises: []),
          _createRecord(id: '2', exercises: []),
        ];

        expect(service.calculateTotalVolume(records), equals(0.0));
        expect(service.calculateMuscleVolumeDistribution(records), isEmpty);
      });
    });
  });
}

// Helper functions to create test fixtures

WorkoutRecord _createRecord({
  required String id,
  DateTime? date,
  int durationSeconds = 1800,
  int totalSets = 10,
  List<RecordedExercise>? exercises,
}) {
  return WorkoutRecord(
    id: id,
    date: date ?? DateTime.now(),
    durationSeconds: durationSeconds,
    trainedMuscles: [],
    exercises: exercises ?? [],
    totalSets: totalSets,
    createdAt: DateTime.now(),
  );
}

RecordedExercise _createRecordedExercise({
  required String exerciseId,
  Exercise? exercise,
  int completedSets = 3,
  double? maxWeight,
  List<SetData>? setsData,
}) {
  return RecordedExercise(
    exerciseId: exerciseId,
    exercise: exercise,
    completedSets: completedSets,
    maxWeight: maxWeight,
    setsData: setsData,
  );
}

Exercise _createExercise({
  required String id,
  required String name,
  required PrimaryMuscleGroup muscle,
}) {
  return Exercise(
    id: id,
    name: name,
    nameEn: name,
    primaryMuscle: muscle,
    secondaryMuscles: [],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 60,
    ),
  );
}

DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day).subtract(
    Duration(days: weekday - 1),
  );
}
