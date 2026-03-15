import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/services/exercise_matcher_service.dart';

import '../helpers/test_fixtures.dart';

void main() {
  late ExerciseMatcherService service;

  setUp(() {
    service = ExerciseMatcherService(exercises: sampleExercises);
  });

  group('ExerciseMatcherService', () {
    group('exact match', () {
      test('returns success for exact match', () async {
        final result = await service.matchExercise('Barbell Bench Press');

        expect(result.isSuccess, isTrue);
        expect(result.exercise, isNotNull);
        expect(result.exercise!.id, equals('barbell_bench_press'));
        expect(result.exercise!.nameEn, equals('Barbell Bench Press'));
      });

      test('returns success for case-insensitive match', () async {
        final result = await service.matchExercise('barbell bench press');

        expect(result.isSuccess, isTrue);
        expect(result.exercise, isNotNull);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });

      test('returns success for different case variations', () async {
        final result = await service.matchExercise('BARBELL BENCH PRESS');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });
    });

    group('normalized match', () {
      test('returns success for name with hyphens', () async {
        final result = await service.matchExercise('Barbell-Bench-Press');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });

      test('returns success for name with underscores', () async {
        final result = await service.matchExercise('Barbell_Bench_Press');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });

      test('returns success for name with extra spaces', () async {
        final result = await service.matchExercise('  Barbell  Bench  Press  ');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });

      test('returns success for mixed separators', () async {
        final result = await service.matchExercise('Barbell_Bench-Press');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });
    });

    group('fuzzy match (candidates)', () {
      test('returns candidates for typo in name', () async {
        final result = await service.matchExercise('Barbel Bench Pres');

        expect(result.hasCandidates, isTrue);
        expect(result.candidates, isNotEmpty);
        // Barbell Bench Press should be among candidates
        expect(
          result.candidates.any((e) => e.id == 'barbell_bench_press'),
          isTrue,
        );
      });

      test('returns candidates for partial match', () async {
        final result = await service.matchExercise('Bench Press');

        expect(result.hasCandidates, isTrue);
        expect(result.candidates, isNotEmpty);
      });

      test('limits candidates to top 5', () async {
        // Create service with many similar exercises
        final manyExercises = List.generate(
          20,
          (i) => sampleExercises.first.copyWith(
            id: 'bench_press_$i',
            nameEn: 'Bench Press Variation $i',
          ),
        );
        final bigService =
            ExerciseMatcherService(exercises: manyExercises);

        final result = await bigService.matchExercise('Bench Press');

        if (result.hasCandidates) {
          expect(result.candidates.length, lessThanOrEqualTo(5));
        }
      });

      test('candidates are sorted by similarity (highest first)', () async {
        final result = await service.matchExercise('Barbel Bench Pres');

        expect(result.hasCandidates, isTrue);
        // First candidate should be most similar
        expect(
          result.candidates.first.id,
          equals('barbell_bench_press'),
        );
      });
    });

    group('failure cases', () {
      test('returns failure for unknown exercise', () async {
        final result = await service.matchExercise('Unknown Exercise XYZ');

        expect(result.isFailure, isTrue);
        expect(result.error, isNotNull);
        expect(result.error, contains('Unknown Exercise XYZ'));
      });

      test('returns failure for empty string', () async {
        final result = await service.matchExercise('');

        expect(result.isFailure, isTrue);
        expect(result.error, contains('empty'));
      });

      test('returns failure for whitespace only', () async {
        final result = await service.matchExercise('   ');

        expect(result.isFailure, isTrue);
      });

      test('returns failure for completely unrelated name', () async {
        final result = await service.matchExercise('ZZZZZZZZZZZZZ');

        expect(result.isFailure, isTrue);
      });
    });

    group('matchAll (batch)', () {
      test('returns list of results for multiple names', () async {
        final results = await service.matchAll([
          'Barbell Bench Press',
          'Pull-up',
          'Barbell Squat',
        ]);

        expect(results.length, equals(3));
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect(results[2].isSuccess, isTrue);
      });

      test('handles mixed success and failure', () async {
        final results = await service.matchAll([
          'Barbell Bench Press',
          'Unknown Exercise XYZ',
          'Pull-up',
        ]);

        expect(results.length, equals(3));
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isFailure, isTrue);
        expect(results[2].isSuccess, isTrue);
      });

      test('handles empty list', () async {
        final results = await service.matchAll([]);

        expect(results, isEmpty);
      });

      test('handles fuzzy matches in batch', () async {
        final results = await service.matchAll([
          'Barbel Bench Pres', // typo
          'Pull-up',
        ]);

        expect(results.length, equals(2));
        expect(results[0].hasCandidates, isTrue);
        expect(results[1].isSuccess, isTrue);
      });
    });

    group('MatchResult', () {
      test('success factory creates correct result', () {
        final exercise = sampleExercises.first;
        final result = MatchResult.success(exercise: exercise);

        expect(result.isSuccess, isTrue);
        expect(result.hasCandidates, isFalse);
        expect(result.isFailure, isFalse);
        expect(result.exercise, equals(exercise));
        expect(result.candidates, isEmpty);
        expect(result.error, isNull);
      });

      test('candidates factory creates correct result', () {
        final candidates = sampleExercises.take(3).toList();
        final result = MatchResult.candidates(candidates: candidates);

        expect(result.isSuccess, isFalse);
        expect(result.hasCandidates, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.exercise, isNull);
        expect(result.candidates, equals(candidates));
        expect(result.error, isNull);
      });

      test('failure factory creates correct result', () {
        const errorMessage = 'No match found';
        final result = MatchResult.failure(error: errorMessage);

        expect(result.isSuccess, isFalse);
        expect(result.hasCandidates, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.exercise, isNull);
        expect(result.candidates, isEmpty);
        expect(result.error, equals(errorMessage));
      });
    });
  });
}
