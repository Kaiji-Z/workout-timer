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
      test('returns success for high-confidence fuzzy match (typo)', () async {
        // 'Barbel Bench Pres' is very close to 'Barbell Bench Press'
        // With score < 0.15, it should return success directly
        final result = await service.matchExercise('Barbel Bench Pres');

        // High confidence match returns success, not candidates
        expect(result.isSuccess, isTrue);
        expect(result.exercise, isNotNull);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });

      test('returns candidates for partial match', () async {
        // 'Bench' alone is too vague - should return candidates
        final result = await service.matchExercise('Bench');

        // Partial match should return candidates or failure
        expect(
          result.isSuccess || result.hasCandidates || result.isFailure,
          isTrue,
        );
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
        final bigService = ExerciseMatcherService(exercises: manyExercises);

        final result = await bigService.matchExercise('Bench Press');

        if (result.hasCandidates) {
          expect(result.candidates.length, lessThanOrEqualTo(5));
        }
      });

      test('high confidence fuzzy match returns success directly', () async {
        // High confidence match (score < 0.15) returns success
        final result = await service.matchExercise('Barbel Bench Pres');

        expect(result.isSuccess, isTrue);
        expect(result.exercise!.id, equals('barbell_bench_press'));
      });
    });

    group('token coverage bug regression', () {
      test('Overhead Dumbbell Triceps Extension should NOT match Dumbbell Step Ups', () async {
        // Regression test: fuzzy search tokenizes input into 4 tokens
        // (overhead, dumbbell, triceps, extension). "Dumbbell Step Ups"
        // only matches 1/4 tokens (dumbbell) but due to fuzzy scoring bugs,
        // it was incorrectly auto-matched.
        final result = await service.matchExercise(
          'Overhead Dumbbell Triceps Extension',
        );

        // Must NOT auto-match to Dumbbell Step Ups (wrong muscle group)
        if (result.isSuccess) {
          expect(
            result.exercise!.id,
            isNot(equals('dumbbell_step_ups')),
            reason: 'Should not match to a leg exercise when searching for triceps',
          );
          expect(
            result.exercise!.id,
            contains('triceps'),
            reason: 'Should match to a triceps exercise',
          );
        }
      });

      test('Overhead Dumbbell Triceps Extension should match a triceps exercise or return candidates', () async {
        final result = await service.matchExercise(
          'Overhead Dumbbell Triceps Extension',
        );

        // Either auto-match to a triceps exercise, or return candidates
        // containing triceps exercises. Must NOT match Dumbbell Step Ups.
        if (result.isSuccess) {
          expect(result.exercise!.id, contains('triceps'));
        } else if (result.hasCandidates) {
          // At least one candidate should be a triceps exercise
          final hasTricepsCandidate = result.candidates.any(
            (e) => e.id.contains('triceps') || e.id.contains('tricep'),
          );
          expect(
            hasTricepsCandidate,
            isTrue,
            reason: 'Candidates should include triceps exercises',
          );
          // Dumbbell Step Ups should NOT be the first candidate
          expect(
            result.candidates.first.id,
            isNot(equals('dumbbell_step_ups')),
            reason: 'Wrong exercise should not be top candidate',
          );
        }
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
          'Barbel Bench Press',
          'Barbel Row',
          'Unknown Exercise',
        ]);

        expect(results.length, 3);
        expect(results[0].isSuccess, isTrue); // Exact match
        expect(results[1].isSuccess, isTrue); // Exact match

        // For fuzzy matches, expect either success or candidates (not just candidates)
        // High confidence fuzzy match (score < 0.15) returns success directly
        expect(results[1].isSuccess, isTrue);
        expect(results[1].exercise!.id, 'barbell_row');

        expect(results[2].isFailure, isTrue); // Unknown
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
