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

      test(
        'calculates total volume without setsData (uses completedSets × maxWeight)',
        () {
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
        },
      );

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
          _createRecord(id: '1', durationSeconds: 0, totalSets: 10),
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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 100)],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Squat',
                  muscle: PrimaryMuscleGroup.legs,
                ),
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 200)],
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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 80)],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Press',
                  muscle: PrimaryMuscleGroup.shoulders,
                ),
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 50)],
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
                setsData: [const SetData(setNumber: 1, reps: 12, weight: 60)],
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
                setsData: [const SetData(setNumber: 1, reps: 12, weight: 65)],
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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 60)],
              ),
              _createRecordedExercise(
                exerciseId: 'ex2',
                exercise: _createExercise(
                  id: 'ex2',
                  name: 'Row',
                  muscle: PrimaryMuscleGroup.back,
                ),
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 70)],
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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 80)],
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
                setsData: [const SetData(setNumber: 1, reps: 15, weight: 20)],
              ),
              _createRecordedExercise(
                exerciseId: 'ex1',
                exercise: _createExercise(
                  id: 'ex1',
                  name: 'Curl',
                  muscle: PrimaryMuscleGroup.arms,
                ),
                setsData: [const SetData(setNumber: 1, reps: 8, weight: 30)],
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
        final records = [_createRecord(id: '1', exercises: [], totalSets: 0)];

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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 0)],
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
                setsData: [const SetData(setNumber: 1, reps: 10, weight: 0)],
              ),
            ],
          ),
        ];

        final volume = service.calculateTotalVolume(records, bodyWeight: 0.0);
        expect(volume, equals(0.0));
      });

      test(
        'calculates adjusted volume for bodyweight exercise with bodyWeight',
        () {
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
                  setsData: [const SetData(setNumber: 1, reps: 10, weight: 0)],
                ),
              ],
            ),
          ];

          // Pushups coefficient = 0.64, eqWeight = 70 × 0.64 = 44.8
          // volume = 10 × (0 + 44.8) = 448.0
          final volume = service.calculateTotalVolume(
            records,
            bodyWeight: 70.0,
          );
          expect(volume, closeTo(448.0, 0.01));
        },
      );

      test(
        'calculates adjusted volume for bodyweight exercise with added weight',
        () {
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
                  setsData: [const SetData(setNumber: 1, reps: 8, weight: 10)],
                ),
              ],
            ),
          ];

          // Pullups coefficient = 0.70, eqWeight = 70 × 0.70 = 49.0
          // volume = 8 × (10 + 49.0) = 8 × 59.0 = 472.0
          final volume = service.calculateTotalVolume(
            records,
            bodyWeight: 70.0,
          );
          expect(volume, closeTo(472.0, 0.01));
        },
      );

      test(
        'returns totalVolume for weighted exercise even with bodyWeight',
        () {
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
          final volume = service.calculateTotalVolume(
            records,
            bodyWeight: 70.0,
          );
          expect(volume, equals(1000.0));
        },
      );

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
                setsData: [const SetData(setNumber: 1, reps: 15, weight: 0)],
              ),
            ],
          ),
        ];

        // Squat coefficient = 1.00, eqWeight = 70 × 1.00 = 70
        // volume = 15 × (0 + 70) = 1050.0
        final distribution = service.calculateMuscleVolumeDistribution(
          records,
          bodyWeight: 70.0,
        );
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
                setsData: [const SetData(setNumber: 1, reps: 15, weight: 0)],
              ),
            ],
          ),
        ];

        // Squat coefficient = 1.00, volume = 15 × 70 = 1050.0
        final trend = service.calculateDailyVolumeTrend(
          records,
          bodyWeight: 70.0,
        );
        expect(trend.length, equals(1));
        expect(trend.values.first, closeTo(1050.0, 0.01));
      });

      test(
        'bodyweight volume without exercise reference falls back to totalVolume',
        () {
          final records = [
            _createRecord(
              id: '1',
              exercises: [
                _createRecordedExercise(
                  exerciseId: 'Pushups',
                  exercise: null, // No exercise reference loaded
                  setsData: [const SetData(setNumber: 1, reps: 10, weight: 0)],
                ),
              ],
            ),
          ];

          // No exercise reference → can't determine bodyweight → totalVolume = 0
          final volume = service.calculateTotalVolume(
            records,
            bodyWeight: 70.0,
          );
          expect(volume, equals(0.0));
        },
      );
    });
  });

  // ==================== 滚动窗口指标（问题驱动统计页 P1/P2） ====================
  // 设计依据 .goal/SPEC.md §3.2：身体的问题用滚动窗口（锚定 asOf 当天），
  // 习惯的问题用日历周。所有方法显式接收 asOf/today，服务内部不取当前时间。

  group('rolling window metrics', () {
    final today = DateTime(2026, 9, 30); // 周三

    WorkoutRecord _rec(
      String id,
      DateTime date, {
      List<RecordedExercise> exercises = const [],
      List<PrimaryMuscleGroup> muscles = const [],
    }) {
      return WorkoutRecord(
        id: id,
        date: date,
        durationSeconds: 1800,
        trainedMuscles: muscles,
        exercises: exercises,
        totalSets: 0,
        createdAt: date,
      );
    }

    RecordedExercise _ex(
      String id,
      PrimaryMuscleGroup muscle, {
      int sets = 1,
      double weight = 100,
      int reps = 10,
    }) {
      return RecordedExercise(
        exerciseId: id,
        exercise: _createExercise(id: id, name: id, muscle: muscle),
        completedSets: sets,
        setsData: List.generate(
          sets,
          (i) => SetData(setNumber: i + 1, reps: reps, weight: weight),
        ),
      );
    }

    test('volume landmark constants match SPEC defaults', () {
      expect(StatsCalculatorService.weeklyMevSets, 10);
      expect(StatsCalculatorService.weeklyMrvSets, 20);
    });

    group('filterRollingWindow', () {
      test('window [asOf-(N-1), asOf] inclusive of both ends', () {
        final records = [
          _rec('a', today),                       // +0d  in
          _rec('b', DateTime(2026, 9, 24, 8)),    // -6d  in
          _rec('c', DateTime(2026, 9, 23, 8)),    // -7d  out
          _rec('d', DateTime(2026, 10, 1, 8)),    // +1d  out (future)
        ];
        final filtered = service.filterRollingWindow(
          records,
          asOf: today,
          windowDays: 7,
        );
        expect(filtered.map((r) => r.id), unorderedEquals(['a', 'b']));
      });
    });

    group('rollingVolume', () {
      test('sums volume of records inside 7d window only', () {
        final records = [
          _rec('in1', today, exercises: [_ex('bench', PrimaryMuscleGroup.chest)]),
          _rec(
            'in2',
            DateTime(2026, 9, 24),
            exercises: [_ex('squat', PrimaryMuscleGroup.legs)],
          ),
          _rec(
            'out',
            DateTime(2026, 9, 22),
            exercises: [_ex('row', PrimaryMuscleGroup.back)],
          ),
        ];
        final volume = service.rollingVolume(
          records,
          asOf: today,
          windowDays: 7,
        );
        // 2 × (1 set × 10 reps × 100kg)
        expect(volume, closeTo(2000.0, 0.01));
      });
    });

    group('daysSinceLastTrained', () {
      test('per-muscle recency with time-of-day ignored', () {
        final records = [
          _rec('a', DateTime(2026, 9, 30, 20), exercises: [
            _ex('bench', PrimaryMuscleGroup.chest),
          ]),
          _rec('b', DateTime(2026, 9, 29, 7), exercises: [
            _ex('row', PrimaryMuscleGroup.back),
          ]),
          _rec('c', DateTime(2026, 9, 20), exercises: [
            _ex('squat', PrimaryMuscleGroup.legs),
          ]),
        ];
        final recency = service.daysSinceLastTrained(records, today: today);
        expect(recency[PrimaryMuscleGroup.chest], 0);
        expect(recency[PrimaryMuscleGroup.back], 1);
        expect(recency[PrimaryMuscleGroup.legs], 10);
        // 从未练过的肌群不出现在结果里（UI 视为 noData）
        expect(recency.containsKey(PrimaryMuscleGroup.shoulders), isFalse);
      });

      test('falls back to record.trainedMuscles when no exercise detail', () {
        final records = [
          _rec('a', DateTime(2026, 9, 28), muscles: [PrimaryMuscleGroup.core]),
        ];
        final recency = service.daysSinceLastTrained(records, today: today);
        expect(recency[PrimaryMuscleGroup.core], 2);
      });
    });

    group('recoveryLevel', () {
      test('classifies boundaries: 48h recovering, 2-7 recovered, >7 stale', () {
        expect(service.recoveryLevel(null), RecoveryLevel.noData);
        expect(service.recoveryLevel(0), RecoveryLevel.recovering);
        expect(service.recoveryLevel(1), RecoveryLevel.recovering);
        expect(service.recoveryLevel(2), RecoveryLevel.recovered);
        expect(service.recoveryLevel(7), RecoveryLevel.recovered);
        expect(service.recoveryLevel(8), RecoveryLevel.stale);
      });
    });

    group('acuteChronicRatio', () {
      test('null when chronic window has no volume', () {
        final records = [
          _rec('a', today, exercises: [
            _ex('bench', PrimaryMuscleGroup.chest),
          ]),
        ];
        final ratio = service.acuteChronicRatio(records, asOf: today);
        expect(ratio, isNull);
      });

      test('ratio = volume(7d) / (volume(28d)/4)', () {
        // 28 天里 9/24 和今天各 1000，急性期(9/24-9/30)只含今天
        final records = [
          _rec('acute', today, exercises: [
            _ex('bench', PrimaryMuscleGroup.chest),
          ]),
          _rec('chronic', DateTime(2026, 9, 24), exercises: [
            _ex('squat', PrimaryMuscleGroup.legs),
          ]),
          _rec('old', DateTime(2026, 9, 2), exercises: [
            _ex('row', PrimaryMuscleGroup.back),
          ]),
        ];
        final ratio = service.acuteChronicRatio(records, asOf: today);
        // 1000 / ((1000+1000)/4) = 2.0
        expect(ratio, closeTo(2.0, 0.001));
      });
    });

    group('loadRatioBand', () {
      test('0.8 and 1.3 are inside the normal band', () {
        expect(service.loadRatioBand(null), LoadRatioBand.noData);
        expect(service.loadRatioBand(0.79), LoadRatioBand.low);
        expect(service.loadRatioBand(0.8), LoadRatioBand.normal);
        expect(service.loadRatioBand(1.3), LoadRatioBand.normal);
        expect(service.loadRatioBand(1.31), LoadRatioBand.high);
      });
    });

    group('doseStatusPerMuscle', () {
      test('all six muscles noData when window has no records', () {
        final status = service.doseStatusPerMuscle(
          [],
          asOf: today,
        );
        expect(status.length, PrimaryMuscleGroup.values.length);
        expect(status.values.every((s) => s == DoseStatus.noData), isTrue);
      });

      test('0 sets is belowMev, 15 in range, 25 above Mrv', () {
        final records = [
          _rec('a', today, exercises: [
            _ex(
              'bench',
              PrimaryMuscleGroup.chest,
              sets: 15,
              weight: 0,
              reps: 0, // 容量无关，只看组数
            ),
            _ex(
              'curl',
              PrimaryMuscleGroup.arms,
              sets: 25,
              weight: 0,
              reps: 0,
            ),
          ]),
        ];
        final status = service.doseStatusPerMuscle(records, asOf: today);
        expect(status[PrimaryMuscleGroup.chest], DoseStatus.inRange);
        expect(status[PrimaryMuscleGroup.arms], DoseStatus.aboveMrv);
        // 窗口内有记录但某肌群 0 组 → belowMev（完全没练）
        expect(status[PrimaryMuscleGroup.legs], DoseStatus.belowMev);
      });
    });

    group('weeklyRollingVolumeTrend', () {
      test('builds N 7-day windows ending at asOf, oldest first', () {
        final records = [
          _rec('newest', DateTime(2026, 9, 29), exercises: [
            _ex('bench', PrimaryMuscleGroup.chest),
          ]),
          _rec('middle', DateTime(2026, 9, 20), exercises: [
            _ex('squat', PrimaryMuscleGroup.legs),
          ]),
          _rec('oldest', DateTime(2026, 9, 10), exercises: [
            _ex('row', PrimaryMuscleGroup.back),
          ]),
          _rec('excluded', DateTime(2026, 9, 9), exercises: [
            _ex('pull', PrimaryMuscleGroup.back),
          ]),
        ];
        final trend = service.weeklyRollingVolumeTrend(
          records,
          asOf: today,
          weeks: 3,
        );
        expect(trend.length, 3);
        // 窗口末日：9/16、9/23、9/30
        expect(trend[0].windowEnd, DateTime(2026, 9, 16));
        expect(trend[1].windowEnd, DateTime(2026, 9, 23));
        expect(trend[2].windowEnd, DateTime(2026, 9, 30));
        expect(trend[0].volume, closeTo(1000.0, 0.01)); // oldest
        expect(trend[1].volume, closeTo(1000.0, 0.01)); // middle
        expect(trend[2].volume, closeTo(1000.0, 0.01)); // newest; excluded 不进任何窗口
      });
    });

    group('linearSlope', () {
      test('null for fewer than 2 points', () {
        expect(service.linearSlope(const [1.0]), isNull);
        expect(service.linearSlope(const []), isNull);
      });

      test('positive and negative slopes', () {
        expect(service.linearSlope(const [1, 2, 3]), closeTo(1.0, 0.001));
        expect(service.linearSlope(const [3, 2, 1]), closeTo(-1.0, 0.001));
      });
    });

    group('habit helpers', () {
      test('sessionsThisWeek counts Monday..today', () {
        // 2026-09-30 是周三，本周一为 9/28
        final dates = [
          DateTime(2026, 9, 28),
          DateTime(2026, 9, 30, 21),
          DateTime(2026, 9, 27), // 上周日，不计
        ];
        expect(service.sessionsThisWeek(dates, today: today), 2);
      });

      test('consecutiveQualifyingWeeks skips unmet current week, breaks at gap',
          () {
        // 本周(9/28-)2次未达标→跳过；9/21-27 3次✓；9/14-20 3次✓；9/7-13 2次✗断
        final dates = [
          DateTime(2026, 9, 28),
          DateTime(2026, 9, 29),
          DateTime(2026, 9, 21),
          DateTime(2026, 9, 23),
          DateTime(2026, 9, 25),
          DateTime(2026, 9, 15),
          DateTime(2026, 9, 17),
          DateTime(2026, 9, 19),
          DateTime(2026, 9, 8),
          DateTime(2026, 9, 9),
        ];
        expect(
          service.consecutiveQualifyingWeeks(dates, today: today,
              weeklyTarget: 3),
          2,
        );
      });

      test('consecutiveQualifyingWeeks includes met current week', () {
        final dates = [
          DateTime(2026, 9, 28),
          DateTime(2026, 9, 29),
          DateTime(2026, 9, 30),
          DateTime(2026, 9, 21),
          DateTime(2026, 9, 22),
          DateTime(2026, 9, 24),
        ];
        expect(
          service.consecutiveQualifyingWeeks(dates, today: today,
              weeklyTarget: 3),
          2,
        );
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
