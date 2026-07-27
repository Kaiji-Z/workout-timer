import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';

void main() {
  /// Minimal JSON shape compatible with the yuhonas/free-exercise-db schema.
  Map<String, dynamic> jsonFixture({
    String id = 'bench_press',
    String? name,
    String? nameZh,
    List<String>? primaryMuscles = const ['chest'],
    List<String>? secondaryMuscles = const ['triceps'],
    String? equipment = 'barbell',
    String level = 'intermediate',
    List<String>? images,
    List<String>? instructions,
  }) {
    return {
      'id': id,
      'name': name ?? 'Bench Press',
      if (nameZh != null) 'nameZh': nameZh, // ignore: use_null_aware_elements
      'primaryMuscles': primaryMuscles ?? const [],
      'secondaryMuscles': secondaryMuscles ?? const [],
      'equipment': equipment,
      'level': level,
      if (images != null) 'images': images, // ignore: use_null_aware_elements
      // ignore: use_null_aware_elements
      if (instructions != null) 'instructions': instructions,
    };
  }

  group('Exercise.fromJson — equipment normalization (_normalizeEquipment)', () {
    /// Helper: pull the equipment value out of a fromJson fixture.
    String equipOf(String? raw) =>
        Exercise.fromJson(jsonFixture(equipment: raw)).equipment;

    test('null equipment falls back to "body only"', () {
      expect(equipOf(null), 'body only');
    });

    test('barbell / ez-barbell collapse to "barbell"', () {
      expect(equipOf('barbell'), 'barbell');
      expect(equipOf('Barbell'), 'barbell'); // case-insensitive
      expect(equipOf('BARBELL'), 'barbell');
      expect(equipOf('ez-barbell'), 'barbell');
    });

    test('dumbbell(s) collapse to "dumbbell"', () {
      expect(equipOf('dumbbell'), 'dumbbell');
      expect(equipOf('dumbbells'), 'dumbbell');
      expect(equipOf('Dumbbells'), 'dumbbell');
    });

    test('cable(s) collapse to "cable"', () {
      expect(equipOf('cable'), 'cable');
      expect(equipOf('cables'), 'cable');
    });

    test('leverage machine collapses to "machine"', () {
      expect(equipOf('machine'), 'machine');
      expect(equipOf('leverage machine'), 'machine');
    });

    test('bodyweight variants collapse to "body only"', () {
      expect(equipOf('body only'), 'body only');
      expect(equipOf('bodyweight'), 'body only');
      expect(equipOf('Bodyweight'), 'body only');
    });

    test('kettlebell(s) collapse to "kettlebells"', () {
      expect(equipOf('kettlebell'), 'kettlebells');
      expect(equipOf('kettlebells'), 'kettlebells');
    });

    test('band/bands collapse to "bands"', () {
      expect(equipOf('band'), 'bands');
      expect(equipOf('bands'), 'bands');
    });

    test('medicine ball, exercise ball, foam roll, other pass through', () {
      expect(equipOf('medicine ball'), 'medicine ball');
      expect(equipOf('exercise ball'), 'exercise ball');
      expect(equipOf('foam roll'), 'foam roll');
      expect(equipOf('other'), 'other');
    });

    test('unknown equipment falls through as lowercase', () {
      expect(equipOf('Sandbag'), 'sandbag');
      expect(equipOf('WEIRD-Thing'), 'weird-thing');
    });
  });

  group('Exercise.fromJson — field parsing', () {
    test('parses basic fields', () {
      final e = Exercise.fromJson(jsonFixture(
        id: 'squat',
        name: 'Squat',
        equipment: 'barbell',
        level: 'beginner',
      ));
      expect(e.id, 'squat');
      expect(e.nameEn, 'Squat');
      expect(e.equipment, 'barbell');
      expect(e.level, 'beginner');
    });

    test('prefers nameZh for the localised name when present', () {
      final e = Exercise.fromJson(jsonFixture(
        name: 'Pull-up',
        nameZh: '引体向上',
      ));
      expect(e.name, '引体向上');
      expect(e.nameEn, 'Pull-up');
      expect(e.nameZh, '引体向上');
    });

    test('falls back to English name when nameZh missing', () {
      final e = Exercise.fromJson(jsonFixture(name: 'Pull-up'));
      expect(e.name, 'Pull-up');
      expect(e.nameEn, 'Pull-up');
      expect(e.nameZh, isNull);
    });

    test('parses primary + secondary muscle groups', () {
      final e = Exercise.fromJson(jsonFixture(
        primaryMuscles: ['chest'],
        // 'triceps' and 'front delt' (with space) are valid source strings.
        secondaryMuscles: ['triceps', 'front delt'],
      ));
      expect(e.primaryMuscle, PrimaryMuscleGroup.chest);
      expect(e.secondaryMuscles.length, 2);
    });

    test('falls back to chest when primaryMuscles missing or unrecognised',
        () {
      final e1 = Exercise.fromJson(jsonFixture(primaryMuscles: []));
      expect(e1.primaryMuscle, PrimaryMuscleGroup.chest);

      final e2 = Exercise.fromJson(jsonFixture(primaryMuscles: ['nonexistent']));
      expect(e2.primaryMuscle, PrimaryMuscleGroup.chest);
    });

    test('skips unrecognised secondary muscle names', () {
      final e = Exercise.fromJson(jsonFixture(
        secondaryMuscles: ['triceps', 'unknown_muscle'],
      ));
      // Only 'triceps' survives.
      expect(e.secondaryMuscles.length, 1);
    });
  });

  group('Exercise.fromJson — recommendation by level', () {
    ExerciseRecommendation recFor(String level) =>
        Exercise.fromJson(jsonFixture(level: level)).recommendation;

    test('beginner -> 3 sets, 10-15 reps, 60s rest', () {
      final r = recFor('beginner');
      expect(r.recommendedSets, 3);
      expect(r.minReps, 10);
      expect(r.maxReps, 15);
      expect(r.restSeconds, 60);
    });

    test('intermediate -> 4 sets, 8-12 reps, 90s rest', () {
      final r = recFor('intermediate');
      expect(r.recommendedSets, 4);
      expect(r.minReps, 8);
      expect(r.maxReps, 12);
      expect(r.restSeconds, 90);
    });

    test('advanced / expert -> 5 sets, 6-10 reps, 120s rest', () {
      for (final lvl in ['advanced', 'expert']) {
        final r = recFor(lvl);
        expect(r.recommendedSets, 5, reason: lvl);
        expect(r.minReps, 6, reason: lvl);
        expect(r.maxReps, 10, reason: lvl);
        expect(r.restSeconds, 120, reason: lvl);
      }
    });

    test('unknown level -> default recommendation (3/8-12/60)', () {
      final r = recFor('totally_made_up');
      expect(r.recommendedSets, 3);
      expect(r.minReps, 8);
      expect(r.maxReps, 12);
      expect(r.restSeconds, 60);
    });
  });

  group('Exercise.fromJson — images + instructions', () {
    test('builds full gitee URLs from relative image paths', () {
      final e = Exercise.fromJson(jsonFixture(
        images: ['bench_press/images/0.jpg', 'bench_press/images/1.jpg'],
      ));
      expect(e.images.length, 2);
      expect(
        e.images[0],
        'https://gitee.com/kaiji1126/free-exercise-db/raw/main/exercises/bench_press/images/0.jpg',
      );
      // imageUrl is the first image.
      expect(e.imageUrl, e.images.first);
    });

    test('no images -> empty list and null imageUrl', () {
      final e = Exercise.fromJson(jsonFixture());
      expect(e.images, isEmpty);
      expect(e.imageUrl, isNull);
    });

    test('preserves instruction strings', () {
      final e = Exercise.fromJson(jsonFixture(
        instructions: ['Lie on bench', 'Lower bar to chest', 'Press up'],
      ));
      expect(e.instructions.length, 3);
      expect(e.instructions[1], 'Lower bar to chest');
    });

    test('filters out non-string instruction entries defensively', () {
      final e = Exercise.fromJson({
        'id': 'x',
        'name': 'X',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': <String>[],
        'equipment': 'barbell',
        'level': 'beginner',
        'instructions': <dynamic>['Step 1', 42, null, 'Step 4'],
      });
      expect(e.instructions, ['Step 1', 'Step 4']);
    });
  });

  group('Exercise.toMap / fromMap round-trip', () {
    test('toMap emits snake_case DB shape', () {
      final e = Exercise.fromJson(jsonFixture());
      final map = e.toMap();
      expect(map['id'], e.id);
      expect(map['name_en'], e.nameEn);
      expect(map['name_zh'], e.nameZh);
      expect(map['primary_muscle'], 'chest');
      expect(map['secondary_muscles'], isA<String>()); // JSON-encoded
      // Recommendation flattened to flat columns.
      expect(map['recommended_sets'], e.recommendation.recommendedSets);
      expect(map['recommended_min_reps'], e.recommendation.minReps);
      expect(map['recommended_max_reps'], e.recommendation.maxReps);
      expect(map['rest_seconds'], e.recommendation.restSeconds);
    });

    test('secondary_muscles column is a JSON-encoded list of names', () {
      final e = Exercise.fromJson(jsonFixture(
        secondaryMuscles: ['triceps', 'shoulders'],
      ));
      final map = e.toMap();
      final decoded = jsonDecode(map['secondary_muscles'] as String) as List;
      // Names map back to JSON-encoded enum names.
      expect(decoded, isA<List>());
    });

    test('fromMap restores all fields that toMap emits', () {
      final original = Exercise.fromJson(jsonFixture(
        id: 'deadlift',
        name: 'Hardlift',
        nameZh: '硬拉',
        primaryMuscles: ['back'],
        secondaryMuscles: ['forearms'],
        equipment: 'barbell',
        level: 'expert',
      ));
      final restored = Exercise.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.nameEn, original.nameEn);
      expect(restored.nameZh, original.nameZh);
      expect(restored.primaryMuscle, original.primaryMuscle);
      expect(restored.equipment, original.equipment);
      expect(restored.level, original.level);
      expect(restored.recommendation.recommendedSets,
          original.recommendation.recommendedSets);
    });
  });

  group('Exercise equality / toString', () {
    test('two exercises with the same id are equal', () {
      final a = Exercise.fromJson(jsonFixture(id: 'x'));
      final b = Exercise.fromJson(jsonFixture(
        id: 'x',
        equipment: 'cable', // different other fields
        level: 'expert',
      ));
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains the id', () {
      final e = Exercise.fromJson(jsonFixture(id: 'press'));
      expect(e.toString(), contains('press'));
    });
  });
}
