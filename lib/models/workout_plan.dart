import 'dart:convert';
import 'exercise.dart';
import 'muscle_group.dart';

/// 计划中的动作配置
class PlanExercise {
  final String exerciseId;
  final Exercise? exercise; // 加载时填充
  final int targetSets;
  final int? customSets;
  final int order;
  final String? unmatchedName; // AI导入时未匹配到的动作名称

  const PlanExercise({
    required this.exerciseId,
    this.exercise,
    required this.targetSets,
    this.customSets,
    required this.order,
    this.unmatchedName,
  });

  /// 实际使用的组数（优先使用自定义值）
  int get effectiveSets => customSets ?? targetSets;

  /// 获取动作名称
  String get name => exercise?.name ?? unmatchedName ?? '';

  /// 是否有详细动作信息
  bool get hasDetails => exercise != null;

  /// 获取动作英文名
  String get nameEn => exercise?.nameEn ?? '';

  /// 从JSON解析
  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] as String? ?? json['exercise_id'] as String? ?? '',
      targetSets: json['targetSets'] as int? ?? json['target_sets'] as int? ?? 3,
      customSets: json['customSets'] as int? ?? json['custom_sets'] as int?,
      order: json['order'] as int? ?? json['exercise_order'] as int? ?? 0,
      unmatchedName: json['unmatchedName'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'targetSets': targetSets,
      'customSets': customSets,
      'order': order,
      'unmatchedName': unmatchedName,
    };
  }

  /// 从数据库Map解析
  factory PlanExercise.fromMap(Map<String, dynamic> map, {Exercise? exercise}) {
    return PlanExercise(
      exerciseId: map['exercise_id'] as String,
      exercise: exercise,
      targetSets: map['target_sets'] as int? ?? 3,
      customSets: map['custom_sets'] as int?,
      order: map['exercise_order'] as int? ?? 0,
      unmatchedName: map['unmatched_name'] as String?,
    );
  }

  /// 转换为数据库Map（用于plan_exercises表）
  Map<String, dynamic> toMap(String planId) {
    return {
      'plan_id': planId,
      'exercise_id': exerciseId,
      'target_sets': targetSets,
      'custom_sets': customSets,
      'exercise_order': order,
      'unmatched_name': unmatchedName,
    };
  }

  /// 复制并修改
  PlanExercise copyWith({
    String? exerciseId,
    Exercise? exercise,
    int? targetSets,
    int? customSets,
    int? order,
    String? unmatchedName,
  }) {
    return PlanExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
      targetSets: targetSets ?? this.targetSets,
      customSets: customSets ?? this.customSets,
      order: order ?? this.order,
      unmatchedName: unmatchedName ?? this.unmatchedName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanExercise && other.exerciseId == exerciseId && other.order == order;
  }

  @override
  int get hashCode => Object.hash(exerciseId, order);

  @override
  String toString() => 'PlanExercise(exerciseId: $exerciseId, sets: $effectiveSets, order: $order)';
}

/// 训练计划
class WorkoutPlan {
  final String id;
  final String name;
  final List<PrimaryMuscleGroup> targetMuscles;
  final List<PlanExercise> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int estimatedDuration; // 分钟

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDuration = 30,
  });

  /// 获取总组数
  int get totalSets {
    return exercises.fold(0, (sum, e) => sum + e.effectiveSets);
  }

  /// 获取动作数量
  int get exerciseCount => exercises.length;

  /// 获取目标部位的显示文本
  String get targetMusclesText {
    return targetMuscles.map((m) => m.displayName).join('、');
  }

  /// 从JSON解析
  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    // 解析目标肌肉部位
    List<PrimaryMuscleGroup> targetMuscles = [];
    if (json['targetMuscles'] != null) {
      final musclesList = json['targetMuscles'] as List<dynamic>;
      targetMuscles = musclesList
          .map((m) => PrimaryMuscleGroupExtension.fromString(m as String))
          .whereType<PrimaryMuscleGroup>()
          .toList();
    }

    // 解析动作列表
    List<PlanExercise> exercises = [];
    if (json['exercises'] != null) {
      final exercisesList = json['exercises'] as List<dynamic>;
      exercises = exercisesList
          .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return WorkoutPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      targetMuscles: targetMuscles,
      exercises: exercises,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      estimatedDuration: json['estimatedDuration'] as int? ?? 30,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscles': targetMuscles.map((m) => m.name).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'estimatedDuration': estimatedDuration,
    };
  }

  /// 从数据库Map解析
  factory WorkoutPlan.fromMap(Map<String, dynamic> map, {List<PlanExercise>? exercises}) {
    // 解析目标肌肉部位
    List<PrimaryMuscleGroup> targetMuscles = [];
    if (map['target_muscles'] != null) {
      final decoded = jsonDecode(map['target_muscles'] as String);
      if (decoded is List) {
        targetMuscles = decoded
            .map((m) => PrimaryMuscleGroupExtension.fromString(m as String))
            .whereType<PrimaryMuscleGroup>()
            .toList();
      }
    }

    return WorkoutPlan(
      id: map['id'] as String,
      name: map['name'] as String,
      targetMuscles: targetMuscles,
      exercises: exercises ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      estimatedDuration: map['estimated_duration'] as int? ?? 30,
    );
  }

  /// 转换为数据库Map（用于workout_plans表）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_muscles': jsonEncode(targetMuscles.map((m) => m.name).toList()),
      'estimated_duration': estimatedDuration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 复制并修改
  WorkoutPlan copyWith({
    String? id,
    String? name,
    List<PrimaryMuscleGroup>? targetMuscles,
    List<PlanExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? estimatedDuration,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorkoutPlan(id: $id, name: $name, exercises: ${exercises.length}, totalSets: $totalSets)';
}
