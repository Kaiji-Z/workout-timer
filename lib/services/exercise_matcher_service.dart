import 'package:fuzzy/fuzzy.dart';
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

  factory MatchResult.candidates({required List<Exercise> candidates}) => MatchResult._(
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
/// Uses fuzzy matching with typo tolerance for better user experience
class ExerciseMatcherService {
  final List<Exercise> _exercises;
  late final Map<String, Exercise> _nameEnMap;
  late final Map<String, Exercise> _nameZhMap;
  late final List<String> _searchableStrings;

  ExerciseMatcherService({required List<Exercise> exercises}) : _exercises = exercises {
    _buildIndex();
  }

  void _buildIndex() {
    _nameEnMap = {};
    _nameZhMap = {};
    _searchableStrings = [];
    
    for (final exercise in _exercises) {
      // Index by normalized nameEn
      final normalizedEn = _normalize(exercise.nameEn);
      _nameEnMap[normalizedEn] = exercise;
      
      // Index by nameZh if available
      if (exercise.nameZh != null && exercise.nameZh!.isNotEmpty) {
        final normalizedZh = _normalize(exercise.nameZh!);
        _nameZhMap[normalizedZh] = exercise;
      }
      
      // Build searchable string for fuzzy matching (combine en + zh)
      _searchableStrings.add('${exercise.nameEn}|${exercise.nameZh ?? ""}');
    }
  }

  /// Match an exercise name (English or Chinese) to the exercise database
  Future<MatchResult> matchExercise(String inputName) async {
    if (inputName.trim().isEmpty) {
      return MatchResult.failure(error: 'Exercise name cannot be empty');
    }

    final normalizedInput = _normalize(inputName);

    // Step 1: Exact match on nameEn
    if (_nameEnMap.containsKey(normalizedInput)) {
      return MatchResult.success(exercise: _nameEnMap[normalizedInput]!);
    }

    // Step 2: Exact match on nameZh
    if (_nameZhMap.containsKey(normalizedInput)) {
      return MatchResult.success(exercise: _nameZhMap[normalizedInput]!);
    }

    // Step 3: Fuzzy search using fuzzy package
    // This handles typos, partial matches, and word reordering
    final fuzzy = Fuzzy<Exercise>(
      _exercises,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'nameEn', getter: (e) => e.nameEn, weight: 1.0),
          WeightedKey(name: 'nameZh', getter: (e) => e.nameZh ?? '', weight: 0.8),
        ],
        threshold: 0.4, // Lower threshold = more permissive matching
        findAllMatches: true,
        isCaseSensitive: false,
        // Allow matching with typos and partial words
        tokenize: true,
        matchAllTokens: false,
      ),
    );

    final result = fuzzy.search(inputName);

    if (result.isNotEmpty) {
      // Take top 5 candidates sorted by match score
      final topCandidates = result.take(5).map((r) => r.item).toList();
      
      // If the top result has a very high score, return as success
      if (result.first.score > 0.8) {
        return MatchResult.success(exercise: result.first.item);
      }
      
      return MatchResult.candidates(candidates: topCandidates);
    }

    // Step 4: No matches found
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
