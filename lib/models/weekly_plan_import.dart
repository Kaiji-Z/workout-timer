/// Import model for weekly workout plans from JSON
class WeeklyPlanImport {
  final String name;
  final List<DailyPlanImport> days;

  const WeeklyPlanImport({
    required this.name,
    required this.days,
  });

  /// Parse from JSON with graceful handling of missing fields
  factory WeeklyPlanImport.fromJson(Map<String, dynamic> json) {
    // Parse days array
    List<DailyPlanImport> days = [];
    if (json['days'] != null && json['days'] is List) {
      final daysList = json['days'] as List<dynamic>;
      days = daysList
          .whereType<Map<String, dynamic>>()
          .map((d) => DailyPlanImport.fromJson(d))
          .toList();
    }

    return WeeklyPlanImport(
      name: json['name'] as String? ?? '',
      days: days,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyPlanImport && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'WeeklyPlanImport(name: $name, days: ${days.length})';
}

/// Import model for daily workout plan
class DailyPlanImport {
  final int dayOfWeek; // 1-7 (Mon-Sun)
  final List<String> targetMuscles;
  final List<ExerciseEntryImport> exercises;

  DailyPlanImport({
    required this.dayOfWeek,
    required this.targetMuscles,
    required this.exercises,
  });

  /// Parse from JSON with graceful handling of missing fields
  factory DailyPlanImport.fromJson(Map<String, dynamic> json) {
    // Parse target muscles
    List<String> targetMuscles = [];
    if (json['targetMuscles'] != null && json['targetMuscles'] is List) {
      final musclesList = json['targetMuscles'] as List<dynamic>;
      targetMuscles = musclesList.whereType<String>().toList();
    }

    // Parse exercises
    List<ExerciseEntryImport> exercises = [];
    if (json['exercises'] != null && json['exercises'] is List) {
      final exercisesList = json['exercises'] as List<dynamic>;
      exercises = exercisesList
          .whereType<Map<String, dynamic>>()
          .map((e) => ExerciseEntryImport.fromJson(e))
          .toList();
    }

    // Clamp dayOfWeek to 1-7 range
    int dayOfWeek = (json['dayOfWeek'] as int?) ?? 1;
    dayOfWeek = dayOfWeek.clamp(1, 7);

    return DailyPlanImport(
      dayOfWeek: dayOfWeek,
      targetMuscles: targetMuscles,
      exercises: exercises,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'targetMuscles': targetMuscles,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyPlanImport && other.dayOfWeek == dayOfWeek;
  }

  @override
  int get hashCode => dayOfWeek.hashCode;

  @override
  String toString() =>
      'DailyPlanImport(dayOfWeek: $dayOfWeek, muscles: $targetMuscles, exercises: ${exercises.length})';
}

/// Import model for exercise entry in a daily plan
class ExerciseEntryImport {
  final String exerciseName; // English name for matching
  final int targetSets;

  const ExerciseEntryImport({
    required this.exerciseName,
    this.targetSets = 3,
  });

  /// Parse from JSON with graceful handling of missing fields
  factory ExerciseEntryImport.fromJson(Map<String, dynamic> json) {
    return ExerciseEntryImport(
      exerciseName: json['exerciseName'] as String? ?? '',
      targetSets: json['targetSets'] as int? ?? 3,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'targetSets': targetSets,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseEntryImport &&
        other.exerciseName == exerciseName &&
        other.targetSets == targetSets;
  }

  @override
  int get hashCode => Object.hash(exerciseName, targetSets);

  @override
  String toString() =>
      'ExerciseEntryImport(exerciseName: $exerciseName, targetSets: $targetSets)';
}
