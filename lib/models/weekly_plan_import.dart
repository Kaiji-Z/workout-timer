/// 导入校验警告类型（AI 返回的 JSON 不合规时收集，向导预览展示）
enum PlanImportWarningType { outOfRangeDay, duplicateDay }

/// 单条导入警告
class PlanImportWarning {
  final PlanImportWarningType type;

  /// 越界的原始 dayOfWeek 值，或重复的 dayOfWeek
  final int day;

  const PlanImportWarning(this.type, this.day);

  @override
  String toString() => 'PlanImportWarning(${type.name}, day:$day)';
}

/// Import model for weekly workout plans from JSON
class WeeklyPlanImport {
  final String name;
  final List<DailyPlanImport> days;

  /// 解析期收集的合规警告（越界天被丢弃、重复天被保留但标记）。
  /// 空列表 = AI 输出完全合规。
  final List<PlanImportWarning> warnings;

  const WeeklyPlanImport({
    required this.name,
    required this.days,
    this.warnings = const [],
  });

  /// Parse from JSON with graceful handling of missing fields
  factory WeeklyPlanImport.fromJson(Map<String, dynamic> json) {
    // Parse days array
    List<DailyPlanImport> days = [];
    final warnings = <PlanImportWarning>[];
    if (json['days'] != null && json['days'] is List) {
      final daysList = json['days'] as List<dynamic>;
      final seenDays = <int>{};
      for (final d in daysList) {
        if (d is! Map<String, dynamic>) continue;

        // 越界天丢弃并计数——绝不静默 clamp。AI 把"月计划"输出成
        // dayOfWeek 8-28 时，clamp 会把它们全部塌缩到周日，一天堆 N 个
        // 计划（.goal/SPEC.md §3.4 导入防御）。
        final raw = d['dayOfWeek'];
        if (raw is int && (raw < 1 || raw > 7)) {
          warnings.add(
            PlanImportWarning(PlanImportWarningType.outOfRangeDay, raw),
          );
          continue;
        }

        final day = DailyPlanImport.fromJson(d);
        if (seenDays.contains(day.dayOfWeek)) {
          warnings.add(
            PlanImportWarning(PlanImportWarningType.duplicateDay, day.dayOfWeek),
          );
        }
        seenDays.add(day.dayOfWeek);
        days.add(day);
      }
    }

    return WeeklyPlanImport(
      name: json['name'] as String? ?? '',
      days: days,
      warnings: warnings,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'days': days.map((d) => d.toJson()).toList()};
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

  const ExerciseEntryImport({required this.exerciseName, this.targetSets = 3});

  /// Parse from JSON with graceful handling of missing fields
  factory ExerciseEntryImport.fromJson(Map<String, dynamic> json) {
    return ExerciseEntryImport(
      exerciseName: json['exerciseName'] as String? ?? '',
      targetSets: json['targetSets'] as int? ?? 3,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'exerciseName': exerciseName, 'targetSets': targetSets};
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
