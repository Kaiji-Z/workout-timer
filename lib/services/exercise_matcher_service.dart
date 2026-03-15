import 'package:string_similarity/string_similarity.dart';
import '../models/exercise.dart';

/// Status of an exercise match attempt
enum MatchStatus { success, candidates, failure }

/// Result of matching an exercise name
class MatchResult {
  final MatchStatus status;
  final Exercise? exercise;
  final List<Exercise> candidates;
  final String? error;

  const MatchResult._({
    required this.status,
    this.exercise,
    this.candidates = const [],
    this.error,
  });

  /// Successful match with single exercise
  factory MatchResult.success({required Exercise exercise}) => MatchResult._(
        status: MatchStatus.success,
        exercise: exercise,
        candidates: const [],
      );

  /// Multiple candidate matches found
  factory MatchResult.candidates({required List<Exercise> candidates}) =>
      MatchResult._(
        status: MatchStatus.candidates,
        exercise: null,
        candidates: candidates,
      );

  /// No match found
  factory MatchResult.failure({required String error}) => MatchResult._(
        status: MatchStatus.failure,
        exercise: null,
        candidates: const [],
        error: error,
      );

  bool get isSuccess => status == MatchStatus.success;
  bool get hasCandidates => status == MatchStatus.candidates;
  bool get isFailure => status == MatchStatus.failure;
}

/// Service for matching English exercise names to exercises in the database
class ExerciseMatcherService {
  final List<Exercise> _exercises;

  ExerciseMatcherService({required List<Exercise> exercises})
      : _exercises = exercises;

  /// Match an English exercise name to the exercise database
  Future<MatchResult> matchExercise(String englishName) async {
    if (englishName.trim().isEmpty) {
      return MatchResult.failure(error: 'Exercise name cannot be empty');
    }

    // Step 1: Exact match (case-insensitive)
    final exactMatches = _exercises
        .where((e) => e.nameEn.toLowerCase() == englishName.toLowerCase())
        .toList();

    if (exactMatches.length == 1) {
      return MatchResult.success(exercise: exactMatches.first);
    }

    // Step 2: Normalized match
    final normalizedInput = _normalize(englishName);
    final normalizedMatches = _exercises
        .where((e) => _normalize(e.nameEn) == normalizedInput)
        .toList();

    if (normalizedMatches.length == 1) {
      return MatchResult.success(exercise: normalizedMatches.first);
    }

    // Step 3: String similarity
    final similarityThreshold = 0.7;
    final candidatesWithScore = <MapEntry<Exercise, double>>[];

    for (final exercise in _exercises) {
      final similarity = englishName.similarityTo(exercise.nameEn);
      if (similarity > similarityThreshold) {
        candidatesWithScore.add(MapEntry(exercise, similarity));
      }
    }

    // Sort by similarity descending and take top 5
    candidatesWithScore.sort((a, b) => b.value.compareTo(a.value));
    final topCandidates =
        candidatesWithScore.take(5).map((e) => e.key).toList();

    if (topCandidates.isNotEmpty) {
      return MatchResult.candidates(candidates: topCandidates);
    }

    // Step 4: No matches found
    return MatchResult.failure(
        error: 'No matching exercise found for "$englishName"');
  }

  /// Batch match multiple exercise names in parallel
  Future<List<MatchResult>> matchAll(List<String> englishNames) async {
    return Future.wait(englishNames.map((name) => matchExercise(name)));
  }

  /// Normalize a string by removing hyphens, underscores, spaces, and lowercasing
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '').trim();
}
