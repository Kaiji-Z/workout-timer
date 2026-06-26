import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/utils/localized_display.dart';

void main() {
  group('LocalizedDisplay.primaryMuscle', () {
    test('returns Chinese displayName for zh locale', () {
      expect(
        LocalizedDisplay.primaryMuscle(
          PrimaryMuscleGroup.chest,
          const Locale('zh'),
        ),
        '胸',
      );
      expect(
        LocalizedDisplay.primaryMuscle(
          PrimaryMuscleGroup.shoulders,
          const Locale('zh'),
        ),
        '肩',
      );
    });

    test('returns English nameEn for en locale', () {
      expect(
        LocalizedDisplay.primaryMuscle(
          PrimaryMuscleGroup.chest,
          const Locale('en'),
        ),
        'Chest',
      );
      expect(
        LocalizedDisplay.primaryMuscle(
          PrimaryMuscleGroup.shoulders,
          const Locale('en'),
        ),
        'Shoulders',
      );
    });
  });

  group('LocalizedDisplay.secondaryMuscle', () {
    test('zh uses displayName', () {
      expect(
        LocalizedDisplay.secondaryMuscle(
          SecondaryMuscleGroup.upperChest,
          const Locale('zh'),
        ),
        '上胸',
      );
    });

    test('en uses nameEn', () {
      expect(
        LocalizedDisplay.secondaryMuscle(
          SecondaryMuscleGroup.upperChest,
          const Locale('en'),
        ),
        'Upper Chest',
      );
    });
  });

  group('LocalizedDisplay.exerciseName', () {
    test('zh returns the (Chinese) name field', () {
      final exercise = _exercise(name: '杠铃卧推', nameEn: 'Barbell Bench Press');
      expect(
        LocalizedDisplay.exerciseName(exercise, const Locale('zh')),
        '杠铃卧推',
      );
    });

    test('en returns nameEn', () {
      final exercise = _exercise(name: '杠铃卧推', nameEn: 'Barbell Bench Press');
      expect(
        LocalizedDisplay.exerciseName(exercise, const Locale('en')),
        'Barbell Bench Press',
      );
    });

    test('en falls back to name when nameEn empty', () {
      final exercise = _exercise(name: '自定义动作', nameEn: '');
      expect(
        LocalizedDisplay.exerciseName(exercise, const Locale('en')),
        '自定义动作',
      );
    });
  });
}

Exercise _exercise({required String name, required String nameEn}) {
  return Exercise(
    id: 'test',
    name: name,
    nameEn: nameEn,
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: const [],
    equipment: 'barbell',
    level: 'beginner',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 60,
    ),
  );
}
