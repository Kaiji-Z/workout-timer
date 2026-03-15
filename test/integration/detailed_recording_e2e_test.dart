import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';

void main() {
  group('Detailed Recording E2E Tests', () {
    
    group('SetData Model Tests', () {
      test('SetData serializes and deserializes correctly', () {
        final setData = SetData(setNumber: 1, reps: 10, weight: 50.0);
        
        final map = setData.toMap();
        expect(map['set_number'], 1);
        expect(map['reps'], 10);
        expect(map['weight'], 50.0);
        
        final restored = SetData.fromMap(map);
        expect(restored.setNumber, setData.setNumber);
        expect(restored.reps, setData.reps);
        expect(restored.weight, setData.weight);
      });

      test('SetData displayText formats correctly', () {
        // Note: Implementation uses '×' (Unicode multiplication sign)
        expect(SetData(setNumber: 1, reps: 10, weight: 50.0).displayText, '10 × 50.0kg');
        expect(SetData(setNumber: 1, reps: 10, weight: null).displayText, '10 reps');
        expect(SetData(setNumber: 1, reps: null, weight: 50.0).displayText, '50.0kg');
        expect(SetData(setNumber: 1, reps: null, weight: null).displayText, 'Set 1');
      });

      test('SetData volume calculates correctly', () {
        expect(SetData(setNumber: 1, reps: 10, weight: 50.0).volume, 500.0);
        expect(SetData(setNumber: 1, reps: null, weight: 50.0).volume, 0.0);
        expect(SetData(setNumber: 1, reps: 10, weight: null).volume, 0.0);
        expect(SetData(setNumber: 1, reps: null, weight: null).volume, 0.0);
      });

      test('SetData handles edge cases in serialization', () {
        // Test with null values
        final nullData = SetData(setNumber: 3, reps: null, weight: null);
        final nullMap = nullData.toMap();
        expect(nullMap['set_number'], 3);
        expect(nullMap['reps'], isNull);
        expect(nullMap['weight'], isNull);
        
        final restoredNull = SetData.fromMap(nullMap);
        expect(restoredNull.setNumber, 3);
        expect(restoredNull.reps, isNull);
        expect(restoredNull.weight, isNull);
      });

      test('SetData copyWith works correctly', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        
        final copied = original.copyWith(reps: 12);
        expect(copied.setNumber, 1);
        expect(copied.reps, 12);
        expect(copied.weight, 50.0);
        
        // Original unchanged
        expect(original.reps, 10);
      });
    });

    group('RecordedExercise with setsData Tests', () {
      test('RecordedExercise with setsData calculates totalVolume', () {
        final exercise = RecordedExercise(
          exerciseId: 'test-1',
          completedSets: 3,
          setsData: [
            SetData(setNumber: 1, reps: 10, weight: 50.0),
            SetData(setNumber: 2, reps: 8, weight: 55.0),
            SetData(setNumber: 3, reps: 6, weight: 60.0),
          ],
        );
        
        // Volume: 10*50 + 8*55 + 6*60 = 500 + 440 + 360 = 1300
        expect(exercise.totalVolume, 1300.0);
      });

      test('RecordedExercise without setsData falls back to completedSets * maxWeight', () {
        final exercise = RecordedExercise(
          exerciseId: 'test-1',
          completedSets: 3,
          maxWeight: 50.0,
        );
        
        expect(exercise.totalVolume, 150.0); // 3 * 50
      });

      test('RecordedExercise with empty setsData returns zero volume', () {
        // Note: Empty list is not null, so fold returns 0.0 (not fallback)
        final exercise = RecordedExercise(
          exerciseId: 'test-1',
          completedSets: 5,
          maxWeight: 40.0,
          setsData: [],
        );
        
        // Empty list uses fold which returns 0.0
        expect(exercise.totalVolume, 0.0);
      });

      test('RecordedExercise toJson and fromJson preserve setsData', () {
        final exercise = RecordedExercise(
          exerciseId: 'ex-123',
          completedSets: 2,
          maxWeight: 60.0,
          setsData: [
            SetData(setNumber: 1, reps: 8, weight: 55.0),
            SetData(setNumber: 2, reps: 6, weight: 60.0),
          ],
        );
        
        final json = exercise.toJson();
        final restored = RecordedExercise.fromJson(json);
        
        expect(restored.exerciseId, 'ex-123');
        expect(restored.completedSets, 2);
        expect(restored.maxWeight, 60.0);
        expect(restored.setsData, isNotNull);
        expect(restored.setsData!.length, 2);
        expect(restored.setsData![0].reps, 8);
        expect(restored.setsData![0].weight, 55.0);
        expect(restored.setsData![1].reps, 6);
        expect(restored.setsData![1].weight, 60.0);
      });

      test('RecordedExercise weightText formats correctly', () {
        expect(
          RecordedExercise(exerciseId: '1', completedSets: 3, maxWeight: 75.5).weightText,
          '75.5kg',
        );
        expect(
          RecordedExercise(exerciseId: '1', completedSets: 3, maxWeight: null).weightText,
          '',
        );
        expect(
          RecordedExercise(exerciseId: '1', completedSets: 3, maxWeight: 0).weightText,
          '',
        );
      });
    });

    group('StatsCalculatorService Tests', () {
      test('StatsCalculatorService calculates total volume correctly', () {
        final service = StatsCalculatorService();
        
        final records = [
          WorkoutRecord(
            id: 'record-1',
            date: DateTime(2024, 1, 15),
            durationSeconds: 1800,
            trainedMuscles: [PrimaryMuscleGroup.chest],
            exercises: [
              RecordedExercise(
                exerciseId: 'bench-press',
                completedSets: 3,
                setsData: [
                  SetData(setNumber: 1, reps: 10, weight: 60.0),
                  SetData(setNumber: 2, reps: 8, weight: 65.0),
                  SetData(setNumber: 3, reps: 6, weight: 70.0),
                ],
              ),
            ],
            totalSets: 3,
            createdAt: DateTime(2024, 1, 15),
          ),
          WorkoutRecord(
            id: 'record-2',
            date: DateTime(2024, 1, 16),
            durationSeconds: 2400,
            trainedMuscles: [PrimaryMuscleGroup.back],
            exercises: [
              RecordedExercise(
                exerciseId: 'deadlift',
                completedSets: 4,
                maxWeight: 100.0, // Fallback: 4 * 100 = 400
              ),
            ],
            totalSets: 4,
            createdAt: DateTime(2024, 1, 16),
          ),
        ];
        
        // Bench press: 10*60 + 8*65 + 6*70 = 600 + 520 + 420 = 1540
        // Deadlift: 4 * 100 = 400
        // Total: 1940
        final volume = service.calculateTotalVolume(records);
        expect(volume, 1940.0);
      });

      test('StatsCalculatorService handles empty records', () {
        final service = StatsCalculatorService();
        
        final volume = service.calculateTotalVolume([]);
        expect(volume, 0.0);
      });

      test('StatsCalculatorService calculates density correctly', () {
        final service = StatsCalculatorService();
        
        final records = [
          WorkoutRecord(
            id: 'r1',
            date: DateTime(2024, 1, 15),
            durationSeconds: 1800, // 30 minutes
            trainedMuscles: [],
            exercises: [],
            totalSets: 15,
            createdAt: DateTime(2024, 1, 15),
          ),
          WorkoutRecord(
            id: 'r2',
            date: DateTime(2024, 1, 16),
            durationSeconds: 1800, // 30 minutes
            trainedMuscles: [],
            exercises: [],
            totalSets: 15,
            createdAt: DateTime(2024, 1, 16),
          ),
        ];
        
        // 30 sets / 60 minutes = 0.5 sets per minute
        final density = service.calculateDensity(records);
        expect(density, closeTo(0.5, 0.001));
      });

      test('StatsCalculatorService calculates max weights by exercise', () {
        final service = StatsCalculatorService();
        
        final records = [
          WorkoutRecord(
            id: 'r1',
            date: DateTime(2024, 1, 15),
            durationSeconds: 1800,
            trainedMuscles: [],
            exercises: [
              RecordedExercise(
                exerciseId: 'bench',
                exercise: _createTestExercise(id: 'bench', name: 'Bench Press'),
                completedSets: 3,
                maxWeight: 80.0,
              ),
            ],
            totalSets: 3,
            createdAt: DateTime(2024, 1, 15),
          ),
          WorkoutRecord(
            id: 'r2',
            date: DateTime(2024, 1, 16),
            durationSeconds: 1800,
            trainedMuscles: [],
            exercises: [
              RecordedExercise(
                exerciseId: 'bench',
                exercise: _createTestExercise(id: 'bench', name: 'Bench Press'),
                completedSets: 3,
                maxWeight: 85.0, // New PR
              ),
            ],
            totalSets: 3,
            createdAt: DateTime(2024, 1, 16),
          ),
        ];
        
        final maxWeights = service.calculateMaxWeightsByExercise(records);
        expect(maxWeights['Bench Press'], 85.0);
      });

      test('StatsCalculatorService weekly volume trend aggregates correctly', () {
        final service = StatsCalculatorService();
        
        // Test that volume calculation per record works correctly
        // Note: calculateWeeklyVolumeTrend uses DateTime.now() for current week,
        // so we test with records that may or may not fall in current weeks
        final records = [
          WorkoutRecord(
            id: 'r1',
            date: DateTime.now().subtract(const Duration(days: 1)), // Yesterday
            durationSeconds: 1800,
            trainedMuscles: [],
            exercises: [
              RecordedExercise(
                exerciseId: 'ex1',
                completedSets: 3,
                setsData: [
                  SetData(setNumber: 1, reps: 10, weight: 50.0), // 500
                ],
              ),
            ],
            totalSets: 3,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          WorkoutRecord(
            id: 'r2',
            date: DateTime.now().subtract(const Duration(days: 2)), // 2 days ago
            durationSeconds: 1800,
            trainedMuscles: [],
            exercises: [
              RecordedExercise(
                exerciseId: 'ex2',
                completedSets: 3,
                setsData: [
                  SetData(setNumber: 1, reps: 10, weight: 60.0), // 600
                ],
              ),
            ],
            totalSets: 3,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];
        
        final trend = service.calculateWeeklyVolumeTrend(records, 2);
        
        // Should have 2 weeks initialized
        expect(trend.length, 2);
        
        // Total volume across all weeks should be 1100 (500 + 600)
        final totalWeeklyVolume = trend.values.fold<double>(0.0, (sum, v) => sum + v);
        expect(totalWeeklyVolume, 1100.0);
      });
    });

    group('Integration: Full Recording Flow', () {
      test('Complete workout record with detailed sets data', () {
        // Create a complete workout record with multiple exercises and detailed sets
        final record = WorkoutRecord(
          id: 'workout-complete',
          date: DateTime(2024, 1, 15),
          durationSeconds: 3600, // 1 hour
          trainedMuscles: [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.arms],
          exercises: [
            RecordedExercise(
              exerciseId: 'bench-press',
              exercise: _createTestExercise(
                id: 'bench-press',
                name: 'Bench Press',
                primaryMuscle: PrimaryMuscleGroup.chest,
              ),
              completedSets: 4,
              maxWeight: 80.0,
              setsData: [
                SetData(setNumber: 1, reps: 10, weight: 70.0), // 700
                SetData(setNumber: 2, reps: 8, weight: 75.0),  // 600
                SetData(setNumber: 3, reps: 6, weight: 80.0),  // 480
                SetData(setNumber: 4, reps: 5, weight: 80.0),  // 400
              ],
            ),
            RecordedExercise(
              exerciseId: 'incline-dumbbell',
              exercise: _createTestExercise(
                id: 'incline-dumbbell',
                name: 'Incline Dumbbell Press',
                primaryMuscle: PrimaryMuscleGroup.chest,
              ),
              completedSets: 3,
              maxWeight: 32.0,
              setsData: [
                SetData(setNumber: 1, reps: 12, weight: 28.0), // 336
                SetData(setNumber: 2, reps: 10, weight: 30.0), // 300
                SetData(setNumber: 3, reps: 8, weight: 32.0),  // 256
              ],
            ),
            RecordedExercise(
              exerciseId: 'tricep-pushdown',
              exercise: _createTestExercise(
                id: 'tricep-pushdown',
                name: 'Tricep Pushdown',
                primaryMuscle: PrimaryMuscleGroup.arms,
              ),
              completedSets: 3,
              maxWeight: 25.0, // Using fallback: 3 * 25 = 75
            ),
          ],
          totalSets: 10,
          createdAt: DateTime(2024, 1, 15),
        );

        // Verify serialization/deserialization
        final json = record.toJson();
        final restored = WorkoutRecord.fromJson(json);

        expect(restored.id, 'workout-complete');
        expect(restored.exercises.length, 3);
        
        // Verify first exercise with setsData
        final benchPress = restored.exercises[0];
        expect(benchPress.exerciseId, 'bench-press');
        expect(benchPress.setsData!.length, 4);
        expect(benchPress.totalVolume, 700 + 600 + 480 + 400); // 2180

        // Verify third exercise (fallback volume)
        final tricep = restored.exercises[2];
        expect(tricep.totalVolume, 75.0); // 3 * 25

        // Calculate total volume via service
        final service = StatsCalculatorService();
        final totalVolume = service.calculateTotalVolume([restored]);
        
        // Bench: 2180 + Incline: 336 + 300 + 256 = 892 + Tricep: 75 = 3147
        expect(totalVolume, closeTo(3147.0, 0.1));
      });
    });
  });
}

// Helper to create test exercises
Exercise _createTestExercise({
  required String id,
  required String name,
  PrimaryMuscleGroup primaryMuscle = PrimaryMuscleGroup.chest,
}) {
  return Exercise(
    id: id,
    name: name,
    nameEn: name,
    primaryMuscle: primaryMuscle,
    secondaryMuscles: [],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 4,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  );
}
