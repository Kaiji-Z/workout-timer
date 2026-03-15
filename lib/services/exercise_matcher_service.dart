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

  factory MatchResult.success({required Exercise exercise}) => MatchResult._(
        status: MatchStatus.success,
        exercise: exercise,
        candidates: const [],
      );

  factory MatchResult.candidates({required List<Exercise> candidates}) =>
      MatchResult._(
        status: MatchStatus.candidates,
        exercise: null,
        candidates: candidates,
      );

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

/// Service for matching exercise names (English or Chinese) to exercises in the database
class ExerciseMatcherService {
  final List<Exercise> _exercises;

  ExerciseMatcherService({required List<Exercise> exercises}) : _exercises = exercises;

  /// Match an exercise name (English or Chinese) to the exercise database
  Future<MatchResult> matchExercise(String inputName) async {
    if (inputName.trim().isEmpty) {
      return MatchResult.failure(error: 'Exercise name cannot be empty');
    }

    final normalizedInput = _normalize(inputName);

    // Step 1: Exact match on nameEn (case-insensitive)
    final exactMatchEn = _exercises
        .where((e) => e.nameEn.toLowerCase() == normalizedInput)
        .firstOrNull;

    if (exactMatchEn != null) {
      return MatchResult.success(exercise: exactMatchEn);
    }

    // Step 2: Exact match on nameZh (Chinese name, if available)
    final chineseMatch = _exercises
        .where((e) => e.nameZh?.toLowerCase() == normalizedInput)
        .firstOrNull;

    if (chineseMatch != null) {
      return MatchResult.success(exercise: chineseMatch);
    }

    // Step 3: Normalized match on nameEn
    final normalizedMatches = _exercises
        .where((e) => _normalize(e.nameEn) == normalizedInput)
        .toList();

    if (normalizedMatches.length == 1) {
      return MatchResult.success(exercise: normalizedMatches.first);
    }

    // Step 4: Normalized match on nameZh
    final normalizedZhMatches = _exercises
        .where((e) => e.nameZh != null && _normalize(e.nameZh!) == normalizedInput)
        .toList();

    if (normalizedZhMatches.length == 1) {
      return MatchResult.success(exercise: normalizedZhMatches.first);
    }

    // Step 5: Partial match (contains) - input words are contained in exercise name
    final inputWords = normalizedInput.split(' ');
    final partialMatches = <Exercise>[];
    for (final exercise in _exercises) {
      final normalizedName = _normalize(exercise.nameEn);
      // Check if all input words are in the exercise name
      final allWordsContained = inputWords.every(
        (word) => normalizedName.contains(_normalize(word)),
      );
      if (allWordsContained && inputWords.length >= 2) {
        partialMatches.add(exercise);
      }
    }

    if (partialMatches.isNotEmpty) {
      return MatchResult.candidates(candidates: partialMatches.take(5).toList());
    }

    // Step 6: String similarity (English names)
    final similarityThreshold = 0.6; // Lowered from 0.7
    final candidatesWithScore = <MapEntry<Exercise, double>>[];

    for (final exercise in _exercises) {
      final similarity = inputName.similarityTo(exercise.nameEn);
      if (similarity > similarityThreshold) {
        candidatesWithScore.add(MapEntry(exercise, similarity));
      }
    }

    // Sort by similarity descending
    candidatesWithScore.sort((a, b) => b.value.compareTo(a.value));

    // Collect top 5, deduplicating results
    final seenIds = <String>{};
    final topCandidates = <Exercise>[];
    for (final entry in candidatesWithScore) {
      if (!seenIds.contains(entry.key.id)) {
        seenIds.add(entry.key.id);
        topCandidates.add(entry.key);
        if (topCandidates.length >= 5) break;
      }
    }

    // If we have contains matches, add them to candidates (prioritized)
    if (partialMatches.isNotEmpty) {
      for (final exercise in partialMatches) {
        if (!seenIds.contains(exercise.id)) {
          seenIds.add(exercise.id);
          topCandidates.insert(0, exercise); // Prioritize contains matches
        }
      }
    }

    if (topCandidates.isNotEmpty) {
      return MatchResult.candidates(candidates: topCandidates.take(5).toList());
    }

    // Step 7: No matches found
    return MatchResult.failure(
        error: 'No matching exercise found for "$inputName"');
  }

  /// Batch match multiple exercise names in parallel
  Future<List<MatchResult>> matchAll(List<String> exerciseNames) async {
    return Future.wait(exerciseNames.map((name) => matchExercise(name)));
  }

  /// Normalize a string by removing hyphens, underscores, spaces, and lowercasing
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '').trim();
}
