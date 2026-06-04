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

    group('calculateSetsPerMuscleGroup', () {
      test('returns empty map for empty records list', () {
        final result = service.calculateSetsPerMuscleGroup([]);
        expect(result, isEmpty);
      });

      test('counts sets per primary muscle group using setsData', () {
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
                  const SetData(setNumber: 1, reps: 10, weight: 80),
                  const SetData(setNumber: 2, reps: 10, weight: 80),
                  const SetData(setNumber: 3, reps: 10, weight: 80),
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
                  const SetData(setNumber: 1, reps: 8, weight: 120),
                  const SetData(setNumber: 2, reps: 8, weight: 120),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateSetsPerMuscleGroup(records);
        expect(result[PrimaryMuscleGroup.chest], equals(3));
        expect(result[PrimaryMuscleGroup.legs], equals(2));
      });

      test('falls back to completedSets when no setsData', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Row',
                  muscle: PrimaryMuscleGroup.back,
                ),
                completedSets: 4,
              ),
            ],
          ),
        ];

        final result = service.calculateSetsPerMuscleGroup(records);
        expect(result[PrimaryMuscleGroup.back], equals(4));
      });

      test('skips exercises with null exercise reference', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: null,
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 80),
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Press',
                  muscle: PrimaryMuscleGroup.shoulders,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 50),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateSetsPerMuscleGroup(records);
        expect(result.length, equals(1));
        expect(result[PrimaryMuscleGroup.shoulders], equals(1));
      });

      test('aggregates across multiple records', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 80),
                  const SetData(setNumber: 2, reps: 10, weight: 80),
                ],
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
                  name: 'Bench',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 85),
                  const SetData(setNumber: 2, reps: 10, weight: 85),
                  const SetData(setNumber: 3, reps: 10, weight: 85),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateSetsPerMuscleGroup(records);
        expect(result[PrimaryMuscleGroup.chest], equals(5)); // 2 + 3
      });
    });

    group('estimate1RM', () {
      test('returns 0 for zero or negative weight', () {
        expect(StatsCalculatorService.estimate1RM(0, 10), equals(0.0));
        expect(StatsCalculatorService.estimate1RM(-10, 10), equals(0.0));
      });

      test('returns 0 for zero or negative reps', () {
        expect(StatsCalculatorService.estimate1RM(100, 0), equals(0.0));
        expect(StatsCalculatorService.estimate1RM(100, -5), equals(0.0));
      });

      test('1RM at 1 rep equals weight × ~1.09', () {
        // Mayhew at r=1: 100*100 / (52.2 + 41.9*e^(-0.055))
        // e^(-0.055) ≈ 0.9465 → denominator ≈ 52.2 + 39.66 ≈ 91.86
        // 1RM ≈ 10000/91.86 ≈ 108.86
        final e1RM = StatsCalculatorService.estimate1RM(100, 1);
        expect(e1RM, closeTo(108.86, 0.5));
      });

      test('1RM at 10 reps', () {
        // Mayhew: 100*100 / (52.2 + 41.9*e^(-0.55)) ≈ 10000/76.37 ≈ 130.9
        final e1RM = StatsCalculatorService.estimate1RM(100, 10);
        expect(e1RM, closeTo(130.9, 0.5));
      });

      test('1RM at 12 reps (user hypertrophy range)', () {
        // Mayhew: 100*80 / (52.2 + 41.9*e^(-0.66)) ≈ 8000/73.86 ≈ 108.3
        final e1RM = StatsCalculatorService.estimate1RM(80, 12);
        expect(e1RM, closeTo(108.3, 0.5));
      });

      test('1RM at 15 reps (upper validation limit)', () {
        // Mayhew: 100*70 / (52.2 + 41.9*e^(-0.825)) ≈ 7000/70.56 ≈ 99.2
        final e1RM = StatsCalculatorService.estimate1RM(70, 15);
        expect(e1RM, closeTo(99.2, 0.5));
      });

      test('higher reps at same weight gives higher 1RM', () {
        // More reps at same weight = stronger → higher 1RM estimate
        final at5 = StatsCalculatorService.estimate1RM(100, 5);
        final at10 = StatsCalculatorService.estimate1RM(100, 10);
        final at15 = StatsCalculatorService.estimate1RM(100, 15);
        expect(at15, greaterThan(at10));
        expect(at10, greaterThan(at5));
      });
    });

    group('calculateEstimated1RMTrend', () {
      test('returns empty map for empty records list', () {
        final result = service.calculateEstimated1RMTrend([]);
        expect(result, isEmpty);
      });

      test('returns empty when exercises have no setsData', () {
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
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result, isEmpty);
      });

      test('calculates 1RM from best set in a single session', () {
        final records = [
          _createRecord(
            id: '1',
            date: DateTime(2026, 1, 1),
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench Press',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 12, weight: 80),
                  const SetData(setNumber: 2, reps: 8, weight: 85),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result.length, equals(1));
        expect(result['Bench Press'], isNotNull);
        expect(result['Bench Press']!.length, equals(1));

        // Best 1RM set: 85×8 vs 80×12
        // 85×8: 100*85/(52.2+41.9*e^(-0.44)) = 8500/(52.2+26.98) = 8500/79.18 ≈ 107.3
        // 80×12: 100*80/(52.2+41.9*e^(-0.66)) = 8000/(52.2+21.55) = 8000/73.75 ≈ 108.5
        // 80×12 should win (higher 1RM)
        final point = result['Bench Press']![0];
        expect(point.estimated1RM, closeTo(108.5, 0.5));
        expect(point.weight, equals(80.0));
        expect(point.reps, equals(12));
      });

      test('tracks 1RM trend across multiple sessions', () {
        final records = [
          _createRecord(
            id: '1',
            date: DateTime(2026, 1, 1),
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 12, weight: 60),
                ],
              ),
            ],
          ),
          _createRecord(
            id: '2',
            date: DateTime(2026, 1, 8),
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 12, weight: 65),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result['Squat']!.length, equals(2));
        // Points should be sorted by date
        expect(result['Squat']![0].date, equals(DateTime(2026, 1, 1)));
        expect(result['Squat']![1].date, equals(DateTime(2026, 1, 8)));
        // 1RM should increase
        expect(
          result['Squat']![1].estimated1RM,
          greaterThan(result['Squat']![0].estimated1RM),
        );
      });

      test('handles multiple exercises in same session', () {
        final records = [
          _createRecord(
            id: '1',
            date: DateTime(2026, 1, 1),
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Bench',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 60),
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Row',
                  muscle: PrimaryMuscleGroup.back,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 70),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result.length, equals(2));
        // Bench 60×10: 6000/76.37 ≈ 78.6
        expect(result['Bench']![0].estimated1RM, closeTo(78.6, 0.5));
        // Row 70×10: 7000/76.37 ≈ 91.6
        expect(result['Row']![0].estimated1RM, closeTo(91.6, 0.5));
      });

      test('ignores sets with zero or null weight', () {
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
                  const SetData(setNumber: 1, reps: 10, weight: 0),
                  const SetData(setNumber: 2, reps: 10, weight: null),
                  const SetData(setNumber: 3, reps: 10, weight: 80),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result.length, equals(1));
        expect(result['Bench Press']![0].weight, equals(80.0));
      });

      test('ignores sets with zero or null reps', () {
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
                  const SetData(setNumber: 1, reps: 0, weight: 80),
                  const SetData(setNumber: 2, reps: null, weight: 80),
                  const SetData(setNumber: 3, reps: 10, weight: 80),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result.length, equals(1));
        expect(result['Bench Press']![0].reps, equals(10));
      });

      test('ignores exercises with empty name', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: null,
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 80),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result, isEmpty);
      });

      test('takes highest 1RM set when same exercise appears multiple times', () {
        // If an exercise name appears twice in the same session (e.g. superserset),
        // the highest estimated1RM point should be recorded
        final records = [
          _createRecord(
            id: '1',
            date: DateTime(2026, 1, 1),
            exercises: [
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Curl',
                  muscle: PrimaryMuscleGroup.arms,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 15, weight: 20),
                ],
              ),
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Curl',
                  muscle: PrimaryMuscleGroup.arms,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 8, weight: 30),
                ],
              ),
            ],
          ),
        ];

        final result = service.calculateEstimated1RMTrend(records);
        expect(result['Curl']!.length, equals(1));
        // 30×8 gives higher 1RM than 20×15
        expect(result['Curl']![0].weight, equals(30.0));
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
        expect(service.calculateEstimated1RMTrend(records), isEmpty);
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

    group('bodyweight volume integration', () {
      test('returns totalVolume when bodyWeight is null', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Pushups',
                exercise: _createBodyweightExercise(
                  id: 'Pushups',
                  name: 'Pushups',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 0),
                ],
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records);
        expect(volume, equals(0.0));
      });

      test('returns totalVolume when bodyWeight is 0', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Pushups',
                exercise: _createBodyweightExercise(
                  id: 'Pushups',
                  name: 'Pushups',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 0),
                ],
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records, bodyWeight: 0.0);
        expect(volume, equals(0.0));
      });

      test('calculates adjusted volume for bodyweight exercise with bodyWeight', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Pushups',
                exercise: _createBodyweightExercise(
                  id: 'Pushups',
                  name: 'Pushups',
                  muscle: PrimaryMuscleGroup.chest,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 0),
                ],
              ),
            ],
          ),
        ];

        // Pushups coefficient = 0.64, eqWeight = 70 × 0.64 = 44.8
        // volume = 10 × (0 + 44.8) = 448.0
        final volume = service.calculateTotalVolume(records, bodyWeight: 70.0);
        expect(volume, closeTo(448.0, 0.01));
      });

      test('calculates adjusted volume for bodyweight exercise with added weight', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Pullups',
                exercise: _createBodyweightExercise(
                  id: 'Pullups',
                  name: 'Pullups',
                  muscle: PrimaryMuscleGroup.back,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 8, weight: 10),
                ],
              ),
            ],
          ),
        ];

        // Pullups coefficient = 0.70, eqWeight = 70 × 0.70 = 49.0
        // volume = 8 × (10 + 49.0) = 8 × 59.0 = 472.0
        final volume = service.calculateTotalVolume(records, bodyWeight: 70.0);
        expect(volume, closeTo(472.0, 0.01));
      });

      test('returns totalVolume for weighted exercise even with bodyWeight', () {
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
                  const SetData(setNumber: 1, reps: 10, weight: 100),
                ],
              ),
            ],
          ),
        ];

        // Bench Press is barbell (NOT bodyweight) → uses totalVolume
        final volume = service.calculateTotalVolume(records, bodyWeight: 70.0);
        expect(volume, equals(1000.0));
      });

      test('bodyweight volume in muscle distribution', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Bodyweight_Squat',
                exercise: _createBodyweightExercise(
                  id: 'Bodyweight_Squat',
                  name: 'Bodyweight Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 15, weight: 0),
                ],
              ),
            ],
          ),
        ];

        // Squat coefficient = 1.00, eqWeight = 70 × 1.00 = 70
        // volume = 15 × (0 + 70) = 1050.0
        final distribution = service.calculateMuscleVolumeDistribution(records, bodyWeight: 70.0);
        expect(distribution[PrimaryMuscleGroup.legs], closeTo(1050.0, 0.01));
      });

      test('bodyweight volume in daily trend', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Bodyweight_Squat',
                exercise: _createBodyweightExercise(
                  id: 'Bodyweight_Squat',
                  name: 'Bodyweight Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [
                  const SetData(setNumber: 1, reps: 15, weight: 0),
                ],
              ),
            ],
          ),
        ];

        // Squat coefficient = 1.00, volume = 15 × 70 = 1050.0
        final trend = service.calculateDailyVolumeTrend(records, bodyWeight: 70.0);
        expect(trend.length, equals(1));
        expect(trend.values.first, closeTo(1050.0, 0.01));
      });

      test('bodyweight volume without exercise reference falls back to totalVolume', () {
        final records = [
          _createRecord(
            id: '1',
            exercises: [
              _createRecordedExercise(
                exerciseId: 'Pushups',
                exercise: null, // No exercise reference loaded
                setsData: [
                  const SetData(setNumber: 1, reps: 10, weight: 0),
                ],
              ),
            ],
          ),
        ];

        // No exercise reference → can't determine bodyweight → totalVolume = 0
        final volume = service.calculateTotalVolume(records, bodyWeight: 70.0);
        expect(volume, equals(0.0));
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

Exercise _createBodyweightExercise({
  required String id,
  required String name,
  required PrimaryMuscleGroup muscle,
  String equipment = 'body only',
}) {
  return Exercise(
    id: id,
    name: name,
    nameEn: name,
    primaryMuscle: muscle,
    secondaryMuscles: [],
    equipment: equipment,
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 60,
    ),
  );
}
