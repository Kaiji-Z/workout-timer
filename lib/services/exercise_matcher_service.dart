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
  late final Map<String, Exercise> _normalizedIndex;

  /// Synonym mappings for common exercise name variations
  /// Key: normalized input, Value: normalized canonical name
  static const Map<String, String> _synonyms = {
    // Overhead Press variations
    'overheaddumbbellpress': 'dumbbellshoulderpress',
    'overheadpress': 'shoulderpress',
    'overheaddumbbell': 'dumbbellshoulderpress',
    'militarypress': 'barbellshoulderpress',
    'militarydumbbellpress': 'dumbbellshoulderpress',
    // Lateral raise variations
    'dumbbelllateralraise': 'sidelateralraise',
    'lateralraise': 'sidelateralraise',
    'sidelateralraises': 'sidelateralraise',
    'dumbbellside raise': 'sidelateralraise',
    // Row variations
    'bentoverdumbbellrow': 'bentovertwodumbbellrow',
    'bentoverrow': 'bentoverbarbellrow',
    'dumbbellrow': 'bentovertwodumbbellrow',
    // Tricep variations
    'tricepdumbbellextension': 'dumbbellonearmtricepsextension',
    'tricepsextension': 'dumbbellonearmtricepsextension',
    'tricepsdumbbellextension': 'dumbbellonearmtricepsextension',
    'overheadtricepsextension': 'standingoverheadbarbelltricepsextension',
    // Bicep variations
    'dumbbellbicepcurls': 'dumbbellbicepcurl',
    'bicepcurl': 'dumbbellbicepcurl',
    'bicepcurls': 'dumbbellbicepcurl',
    // Romanian deadlift variations
    'dumbbellromaniandeadlift': 'romaniandeadlift',
    'rdl': 'romaniandeadlift',
    'dumbbellrdl': 'romaniandeadlift',
    // Squat variations
    'gobletdumbbellsquat': 'gobletsquat',
    'dumbbellgobletsquat': 'gobletsquat',
    // Calf raise variations
    'standingdumbbellcalfraise': 'standingdumbbellcalfraise',
    'dumbbellcalfraise': 'calfraiseonadumbbell',
    // Russian twist variations
    'russiandumbbelltwist': 'russiantwist',
    'dumbbellrussiantwist': 'russiantwist',
    // Plank variations
    'sideplank': 'plank',
    'dumbbellsideplank': 'plank',
    // Lunge variations
    'dumbbellwalkinglunge': 'dumbbellrearlunge',
    'walkinglunge': 'barbellwalkinglunge',
    'dumbbelllunge': 'dumbbellrearlunge',
    // Pullover variations
    'dumbbellpullover': 'bentarmdumbbellpullover',
    'dumbbellpullovers': 'bentarmdumbbellpullover',
    // Incline Press variations (词序差异)
    'dumbbellinclinepress': 'incline dumbbellpress',
  };

  ExerciseMatcherService({required List<Exercise> exercises}) : _exercises = exercises {
    _buildIndex();
  }

  void _buildIndex() {
    _nameEnMap = {};
    _nameZhMap = {};
    _normalizedIndex = {};
    
    for (final exercise in _exercises) {
      // Index by normalized nameEn
      final normalizedEn = _normalize(exercise.nameEn);
      _nameEnMap[normalizedEn] = exercise;
      _normalizedIndex[normalizedEn] = exercise;
      
      // Also index by sorted words (handles word order differences)
      final sortedWords = _normalizeAndSort(exercise.nameEn);
      if (sortedWords != normalizedEn) {
        _normalizedIndex[sortedWords] = exercise;
      }
      
      // Index by nameZh if available
      if (exercise.nameZh != null && exercise.nameZh!.isNotEmpty) {
        final normalizedZh = _normalize(exercise.nameZh!);
        _nameZhMap[normalizedZh] = exercise;
      }
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

    // Step 3: Check synonym mapping
    final synonymMatch = _checkSynonyms(normalizedInput);
    if (synonymMatch != null && _nameEnMap.containsKey(synonymMatch)) {
      return MatchResult.success(exercise: _nameEnMap[synonymMatch]!);
    }

    // Step 4: Check sorted word order match (handles "Dumbbell Incline Press" vs "Incline Dumbbell Press")
    final sortedInput = _normalizeAndSort(inputName);
    if (_normalizedIndex.containsKey(sortedInput)) {
      return MatchResult.success(exercise: _normalizedIndex[sortedInput]!);
    }

    // Step 5: Fuzzy search using fuzzy package
    final fuzzy = Fuzzy<Exercise>(
      _exercises,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'nameEn', getter: (e) => e.nameEn, weight: 1.0),
          WeightedKey(name: 'nameZh', getter: (e) => e.nameZh ?? '', weight: 0.8),
        ],
        threshold: 0.4,
        findAllMatches: true,
        isCaseSensitive: false,
        tokenize: true,
        matchAllTokens: false,
      ),
    );

    final result = fuzzy.search(inputName);

    if (result.isNotEmpty) {
      final topCandidates = result.take(5).map((r) => r.item).toList();
      
      // FIXED: fuzzy score is a DISTANCE score (lower = better match)
      // score < 0.15 = high confidence match (almost exact)
      // score < 0.4 = reasonable match
      // score > 0.4 = poor match, likely unrelated
      if (result.first.score < 0.15) {
        return MatchResult.success(exercise: result.first.item);
      }
      
      return MatchResult.candidates(candidates: topCandidates);
    }

    // Step 6: No matches found
    return MatchResult.failure(
        error: 'No matching exercise found for "$inputName"');
  }

  /// Check if normalized input matches any synonym
  String? _checkSynonyms(String normalizedInput) {
    // Direct synonym match
    if (_synonyms.containsKey(normalizedInput)) {
      return _synonyms[normalizedInput];
    }
    
    // Try removing common prefixes/suffixes for partial matches
    // e.g., "standingdumbbellcalfraise" -> check "dumbbellcalfraise"
    final variations = _generateInputVariations(normalizedInput);
    for (final variation in variations) {
      if (_synonyms.containsKey(variation)) {
        return _synonyms[variation];
      }
    }
    
    return null;
  }

  /// Generate variations of input for more flexible matching
  List<String> _generateInputVariations(String input) {
    final variations = <String>[];
    
    // Remove common prefixes
    const prefixes = ['standing', 'seated', 'lying', 'onearm', 'twoarm', 'alternating'];
    for (final prefix in prefixes) {
      if (input.startsWith(prefix)) {
        variations.add(input.substring(prefix.length));
      }
    }
    
    // Also try the input as-is with common suffixes removed
    const suffixes = ['s', 'es'];
    for (final suffix in suffixes) {
      if (input.endsWith(suffix) && input.length > 3) {
        variations.add(input.substring(0, input.length - suffix.length));
      }
    }
    
    return variations;
  }

  /// Normalize and sort words for word-order-insensitive matching
  String _normalizeAndSort(String s) {
    final words = s
        .toLowerCase()
        .replaceAll(RegExp(r'[-_/\(\)]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList()
      ..sort();
    return words.join('');
  }

  /// Normalize a string by removing hyphens, underscores, spaces, and lowercasing
  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[-_/\s]'), '').trim();

  /// Batch match multiple exercise names in parallel
  Future<List<MatchResult>> matchAll(List<String> exerciseNames) async {
    return Future.wait(exerciseNames.map((name) => matchExercise(name)));
  }
}
