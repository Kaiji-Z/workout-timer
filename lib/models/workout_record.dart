import 'dart:convert';
import 'exercise.dart';
import 'muscle_group.dart';

/// 记录中的动作详情
class RecordedExercise {
  final String exerciseId;
  final Exercise? exercise; // 加载时填充
  final int completedSets;
  final double? maxWeight;

  const RecordedExercise({
    required this.exerciseId,
    this.exercise,
    required this.completedSets,
    this.maxWeight,
  });

  /// 获取动作名称
  String get name => exercise?.name ?? '';

  /// 获取动作英文名
  String get nameEn => exercise?.nameEn ?? '';

  /// 格式化的重量文本
  String get weightText {
    if (maxWeight == null || maxWeight == 0) {
      return '';
    }
    return '${maxWeight!.toStringAsFixed(1)}kg';
  }

  /// 从JSON解析
  factory RecordedExercise.fromJson(Map<String, dynamic> json) {
    return RecordedExercise(
      exerciseId: json['exerciseId'] as String? ?? json['exercise_id'] as String? ?? '',
      completedSets: json['completedSets'] as int? ?? json['completed_sets'] as int? ?? 0,
      maxWeight: json['maxWeight'] as double? ?? json['max_weight'] as double?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'completedSets': completedSets,
      'maxWeight': maxWeight,
    };
  }

  /// 从数据库Map解析
  factory RecordedExercise.fromMap(Map<String, dynamic> map, {Exercise? exercise}) {
    return RecordedExercise(
      exerciseId: map['exercise_id'] as String,
      exercise: exercise,
      completedSets: map['completed_sets'] as int? ?? 0,
      maxWeight: map['max_weight'] as double?,
    );
  }

  /// 转换为数据库Map（用于record_exercises表）
  Map<String, dynamic> toMap(String recordId) {
    return {
      'record_id': recordId,
      'exercise_id': exerciseId,
      'completed_sets': completedSets,
      'max_weight': maxWeight,
    };
  }

  /// 复制并修改
  RecordedExercise copyWith({
    String? exerciseId,
    Exercise? exercise,
    int? completedSets,
    double? maxWeight,
  }) {
    return RecordedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
      completedSets: completedSets ?? this.completedSets,
      maxWeight: maxWeight ?? this.maxWeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordedExercise && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => exerciseId.hashCode;

  @override
  String toString() => 'RecordedExercise(exerciseId: $exerciseId, sets: $completedSets, weight: $maxWeight)';
}

/// 训练记录
class WorkoutRecord {
  final String id;
  final DateTime date;
  final int durationSeconds;
  final List<PrimaryMuscleGroup> trainedMuscles;
  final List<RecordedExercise> exercises;
  final String? planId;
  final String? planName;
  final int totalSets;
  final DateTime createdAt;

  const WorkoutRecord({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.trainedMuscles,
    required this.exercises,
    this.planId,
    this.planName,
    required this.totalSets,
    required this.createdAt,
  });

  /// 是否是计划模式的记录
  bool get isPlanMode => planId != null;

  /// 获取训练部位的显示文本
  String get trainedMusclesText {
    if (trainedMuscles.isEmpty) {
      return '自由训练';
    }
    return trainedMuscles.map((m) => m.displayName).join('、');
  }

  /// 获取格式化的训练时长
  String get durationText {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes == 0) {
      return '$seconds秒';
    } else if (seconds == 0) {
      return '$minutes分钟';
    }
    return '$minutes分$seconds秒';
  }

  /// 获取格式化的日期
  String get dateText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return '今天';
    } else if (recordDate == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  /// 获取完整日期文本
  String get fullDateText {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  /// 获取动作数量
  int get exerciseCount => exercises.length;

  /// 从JSON解析
  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    // 解析训练部位
    List<PrimaryMuscleGroup> trainedMuscles = [];
    if (json['trainedMuscles'] != null) {
      final musclesList = json['trainedMuscles'] as List<dynamic>;
      trainedMuscles = musclesList
          .map((m) => PrimaryMuscleGroupExtension.fromString(m as String))
          .whereType<PrimaryMuscleGroup>()
          .toList();
    }

    // 解析动作列表
    List<RecordedExercise> exercises = [];
    if (json['exercises'] != null) {
      final exercisesList = json['exercises'] as List<dynamic>;
      exercises = exercisesList
          .map((e) => RecordedExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return WorkoutRecord(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? json['duration_seconds'] as int? ?? 0,
      trainedMuscles: trainedMuscles,
      exercises: exercises,
      planId: json['planId'] as String? ?? json['plan_id'] as String?,
      planName: json['planName'] as String? ?? json['plan_name'] as String?,
      totalSets: json['totalSets'] as int? ?? json['total_sets'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'trainedMuscles': trainedMuscles.map((m) => m.name).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'planId': planId,
      'planName': planName,
      'totalSets': totalSets,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 从数据库Map解析
  factory WorkoutRecord.fromMap(Map<String, dynamic> map, {List<RecordedExercise>? exercises}) {
    // 解析训练部位
    List<PrimaryMuscleGroup> trainedMuscles = [];
    if (map['trained_muscles'] != null) {
      final decoded = jsonDecode(map['trained_muscles'] as String);
      if (decoded is List) {
        trainedMuscles = decoded
            .map((m) => PrimaryMuscleGroupExtension.fromString(m as String))
            .whereType<PrimaryMuscleGroup>()
            .toList();
      }
    }

    return WorkoutRecord(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      trainedMuscles: trainedMuscles,
      exercises: exercises ?? [],
      planId: map['plan_id'] as String?,
      planName: map['plan_name'] as String?,
      totalSets: map['total_sets'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map（用于workout_records表）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'duration_seconds': durationSeconds,
      'trained_muscles': trainedMuscles.isEmpty ? null : jsonEncode(trainedMuscles.map((m) => m.name).toList()),
      'plan_id': planId,
      'plan_name': planName,
      'total_sets': totalSets,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  WorkoutRecord copyWith({
    String? id,
    DateTime? date,
    int? durationSeconds,
    List<PrimaryMuscleGroup>? trainedMuscles,
    List<RecordedExercise>? exercises,
    String? planId,
    String? planName,
    int? totalSets,
    DateTime? createdAt,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      trainedMuscles: trainedMuscles ?? this.trainedMuscles,
      exercises: exercises ?? this.exercises,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      totalSets: totalSets ?? this.totalSets,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WorkoutRecord(id: $id, date: $dateText, duration: $durationText, sets: $totalSets)';
}
