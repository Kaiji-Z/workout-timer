import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/weekly_plan_import.dart';

void main() {
  group('WeeklyPlanImport', () {
    test('parses valid JSON with all fields', () {
      const jsonString =
          '{"name":"Test Plan","days":[{"dayOfWeek":1,"targetMuscles":["chest"],"exercises":[{"exerciseName":"Barbell Bench Press","targetSets":4}]}]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final plan = WeeklyPlanImport.fromJson(json);

      expect(plan.name, equals('Test Plan'));
      expect(plan.days.length, equals(1));
      expect(plan.days[0].dayOfWeek, equals(1));
      expect(plan.days[0].targetMuscles, equals(['chest']));
      expect(plan.days[0].exercises.length, equals(1));
      expect(plan.days[0].exercises[0].exerciseName, equals('Barbell Bench Press'));
      expect(plan.days[0].exercises[0].targetSets, equals(4));
    });

    test('parses JSON with missing optional fields using defaults', () {
      const jsonString = '{"name":"Minimal Plan"}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final plan = WeeklyPlanImport.fromJson(json);

      expect(plan.name, equals('Minimal Plan'));
      expect(plan.days, isEmpty);
    });

    test('handles empty days array', () {
      const jsonString = '{"name":"Empty Plan","days":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final plan = WeeklyPlanImport.fromJson(json);

      expect(plan.name, equals('Empty Plan'));
      expect(plan.days, isEmpty);
    });

    test('handles missing name field', () {
      const jsonString = '{"days":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final plan = WeeklyPlanImport.fromJson(json);

      expect(plan.name, equals(''));
      expect(plan.days, isEmpty);
    });
  });

  group('DailyPlanImport', () {
    test('handles invalid dayOfWeek values below range (clamp to 1)', () {
      const jsonString =
          '{"dayOfWeek":0,"targetMuscles":["back"],"exercises":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      expect(day.dayOfWeek, equals(1));
    });

    test('handles invalid dayOfWeek values above range (clamp to 7)', () {
      const jsonString =
          '{"dayOfWeek":10,"targetMuscles":["back"],"exercises":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      expect(day.dayOfWeek, equals(7));
    });

    test('handles negative dayOfWeek values (clamp to 1)', () {
      const jsonString =
          '{"dayOfWeek":-5,"targetMuscles":["back"],"exercises":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      expect(day.dayOfWeek, equals(1));
    });

    test('handles missing dayOfWeek (default to 1)', () {
      const jsonString = '{"targetMuscles":["back"],"exercises":[]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      expect(day.dayOfWeek, equals(1));
    });

    test('handles missing targetMuscles', () {
      const jsonString =
          '{"dayOfWeek":3,"exercises":[{"exerciseName":"Squat","targetSets":3}]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      expect(day.targetMuscles, isEmpty);
    });

    test('handles malformed nested JSON gracefully', () {
      const jsonString =
          '{"dayOfWeek":2,"targetMuscles":["invalid",123,null],"exercises":["not a map",{"exerciseName":"Valid","targetSets":3}]}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final day = DailyPlanImport.fromJson(json);

      // Only string values should be kept for muscles
      expect(day.targetMuscles, equals(['invalid']));
      // Only valid map entries should be parsed for exercises
      expect(day.exercises.length, equals(1));
      expect(day.exercises[0].exerciseName, equals('Valid'));
    });
  });

  group('ExerciseEntryImport', () {
    test('parses valid exercise entry', () {
      const jsonString =
          '{"exerciseName":"Deadlift","targetSets":5}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = ExerciseEntryImport.fromJson(json);

      expect(exercise.exerciseName, equals('Deadlift'));
      expect(exercise.targetSets, equals(5));
    });

    test('defaults targetSets to 3 if not provided', () {
      const jsonString = '{"exerciseName":"Pull-up"}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = ExerciseEntryImport.fromJson(json);

      expect(exercise.exerciseName, equals('Pull-up'));
      expect(exercise.targetSets, equals(3));
    });

    test('handles missing exerciseName', () {
      const jsonString = '{"targetSets":4}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = ExerciseEntryImport.fromJson(json);

      expect(exercise.exerciseName, equals(''));
      expect(exercise.targetSets, equals(4));
    });

    test('handles empty JSON object', () {
      const jsonString = '{}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = ExerciseEntryImport.fromJson(json);

      expect(exercise.exerciseName, equals(''));
      expect(exercise.targetSets, equals(3));
    });
  });

  group('toJson', () {
    test('WeeklyPlanImport converts to JSON correctly', () {
      final plan = WeeklyPlanImport(
        name: 'Test Plan',
        days: [
          DailyPlanImport(
            dayOfWeek: 1,
            targetMuscles: ['chest'],
            exercises: [
              const ExerciseEntryImport(
                exerciseName: 'Bench Press',
                targetSets: 4,
              ),
            ],
          ),
        ],
      );

      final json = plan.toJson();

      expect(json['name'], equals('Test Plan'));
      expect(json['days'], isA<List>());
      expect((json['days'] as List).length, equals(1));
    });

    test('DailyPlanImport converts to JSON correctly', () {
      final day = DailyPlanImport(
        dayOfWeek: 3,
        targetMuscles: ['legs', 'glutes'],
        exercises: [
          const ExerciseEntryImport(exerciseName: 'Squat', targetSets: 5),
        ],
      );

      final json = day.toJson();

      expect(json['dayOfWeek'], equals(3));
      expect(json['targetMuscles'], equals(['legs', 'glutes']));
      expect(json['exercises'], isA<List>());
    });

    test('ExerciseEntryImport converts to JSON correctly', () {
      const exercise = ExerciseEntryImport(
        exerciseName: 'Pull-up',
        targetSets: 3,
      );

      final json = exercise.toJson();

      expect(json['exerciseName'], equals('Pull-up'));
      expect(json['targetSets'], equals(3));
    });
  });
}
