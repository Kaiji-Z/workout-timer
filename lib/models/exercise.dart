import 'dart:convert';
import 'muscle_group.dart';

/// 动作推荐配置
class ExerciseRecommendation {
  final int recommendedSets;
  final int minReps;
  final int maxReps;
  final int restSeconds;

  const ExerciseRecommendation({
    required this.recommendedSets,
    required this.minReps,
    required this.maxReps,
    required this.restSeconds,
  });

  factory ExerciseRecommendation.fromMap(Map<String, dynamic> map) {
    return ExerciseRecommendation(
      recommendedSets: map['recommended_sets'] as int? ?? 3,
      minReps: map['recommended_min_reps'] as int? ?? 8,
      maxReps: map['recommended_max_reps'] as int? ?? 12,
      restSeconds: map['rest_seconds'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommended_sets': recommendedSets,
      'recommended_min_reps': minReps,
      'recommended_max_reps': maxReps,
      'rest_seconds': restSeconds,
    };
  }

  /// 格式化的推荐次数范围
  String get repsRangeText => '$minReps-$maxReps次';

  /// 格式化的休息时间
  String get restText {
    if (restSeconds >= 60) {
      final minutes = restSeconds ~/ 60;
      final seconds = restSeconds % 60;
      if (seconds == 0) {
        return '$minutes分钟';
      }
      return '$minutes分$seconds秒';
    }
    return '$restSeconds秒';
  }

  @override
  String toString() => 'ExerciseRecommendation(sets: $recommendedSets, reps: $minReps-$maxReps, rest: ${restSeconds}s)';
}

/// 动作模型
class Exercise {
  final String id;
  final String name;
  final String nameEn;
  final PrimaryMuscleGroup primaryMuscle;
  final List<SecondaryMuscleGroup> secondaryMuscles;
  final String equipment;
  final String level;
  final String? imageUrl;
  final String? muscleImageUrl;
  final ExerciseRecommendation recommendation;

  const Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.equipment,
    required this.level,
    this.imageUrl,
    this.muscleImageUrl,
    required this.recommendation,
  });

  /// 从JSON解析（用于导入yuhonas/free-exercise-db数据）
  factory Exercise.fromJson(Map<String, dynamic> json) {
    // 解析主要肌肉部位
    final primaryMusclesList = json['primaryMuscles'] as List<dynamic>?;
    PrimaryMuscleGroup primaryMuscle = PrimaryMuscleGroup.chest;
    if (primaryMusclesList != null && primaryMusclesList.isNotEmpty) {
      final parsed = PrimaryMuscleGroupExtension.fromString(primaryMusclesList[0] as String);
      if (parsed != null) {
        primaryMuscle = parsed;
      }
    }

    // 解析次要肌肉部位
    final secondaryMusclesList = json['secondaryMuscles'] as List<dynamic>? ?? [];
    final secondaryMuscles = secondaryMusclesList
        .map((s) => _parseSecondaryMuscle(s as String))
        .whereType<SecondaryMuscleGroup>()
        .toList();

    // 解析推荐配置
    final level = json['level'] as String? ?? 'beginner';
    ExerciseRecommendation recommendation;
    switch (level) {
      case 'beginner':
        recommendation = const ExerciseRecommendation(
          recommendedSets: 3,
          minReps: 10,
          maxReps: 15,
          restSeconds: 60,
        );
        break;
      case 'intermediate':
        recommendation = const ExerciseRecommendation(
          recommendedSets: 4,
          minReps: 8,
          maxReps: 12,
          restSeconds: 90,
        );
        break;
      case 'expert':
      case 'advanced':
        recommendation = const ExerciseRecommendation(
          recommendedSets: 5,
          minReps: 6,
          maxReps: 10,
          restSeconds: 120,
        );
        break;
      default:
        recommendation = const ExerciseRecommendation(
          recommendedSets: 3,
          minReps: 8,
          maxReps: 12,
          restSeconds: 60,
        );
    }

    // 解析图片URL
    final imagesList = json['images'] as List<dynamic>?;
    String? imageUrl;
    if (imagesList != null && imagesList.isNotEmpty) {
      final imagePath = imagesList[0] as String;
      imageUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/$imagePath';
    }

    // 解析器械名称
    final equipmentRaw = json['equipment'] as String?;
    final equipment = _normalizeEquipment(equipmentRaw);

    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name'] as String? ?? '',
      primaryMuscle: primaryMuscle,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      level: level,
      imageUrl: imageUrl,
      muscleImageUrl: json['muscleImageUrl'] as String?,
      recommendation: recommendation,
    );
  }

  /// 标准化器械名称
  static String _normalizeEquipment(String? equipment) {
    if (equipment == null) return 'body only';
    switch (equipment.toLowerCase()) {
      case 'barbell':
      case 'ez-barbell':
        return 'barbell';
      case 'dumbbell':
      case 'dumbbells':
        return 'dumbbell';
      case 'cable':
      case 'cables':
        return 'cable';
      case 'machine':
      case 'leverage machine':
        return 'machine';
      case 'body only':
      case 'bodyweight':
        return 'body only';
      case 'kettlebells':
      case 'kettlebell':
        return 'kettlebells';
      case 'bands':
      case 'band':
        return 'bands';
      case 'medicine ball':
        return 'medicine ball';
      case 'exercise ball':
        return 'exercise ball';
      case 'foam roll':
        return 'foam roll';
      case 'other':
        return 'other';
      default:
        return equipment.toLowerCase();
    }
  }

  /// 从数据库Map解析
  factory Exercise.fromMap(Map<String, dynamic> map) {
    // 解析次要肌肉部位
    List<SecondaryMuscleGroup> secondaryMuscles = [];
    if (map['secondary_muscles'] != null) {
      final decoded = jsonDecode(map['secondary_muscles'] as String);
      if (decoded is List) {
        secondaryMuscles = decoded
            .map((s) => _parseSecondaryMuscleFromDb(s as String))
            .whereType<SecondaryMuscleGroup>()
            .toList();
      }
    }

    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['name_en'] as String? ?? '',
      primaryMuscle: PrimaryMuscleGroupExtension.fromString(map['primary_muscle'] as String) ?? PrimaryMuscleGroup.chest,
      secondaryMuscles: secondaryMuscles,
      equipment: map['equipment'] as String? ?? '',
      level: map['level'] as String? ?? 'beginner',
      imageUrl: map['image_url'] as String?,
      muscleImageUrl: map['muscle_image_url'] as String?,
      recommendation: ExerciseRecommendation.fromMap(map),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'primary_muscle': primaryMuscle.name,
      'secondary_muscles': jsonEncode(secondaryMuscles.map((e) => e.name).toList()),
      'equipment': equipment,
      'level': level,
      'image_url': imageUrl,
      'muscle_image_url': muscleImageUrl,
      'recommended_sets': recommendation.recommendedSets,
      'recommended_min_reps': recommendation.minReps,
      'recommended_max_reps': recommendation.maxReps,
      'rest_seconds': recommendation.restSeconds,
    };
  }

  /// 难度显示名称
  String get levelDisplayName {
    switch (level) {
      case 'beginner':
        return '初级';
      case 'intermediate':
        return '中级';
      case 'expert':
      case 'advanced':
        return '高级';
      default:
        return '中级';
    }
  }

  /// 器械显示名称
  String get equipmentDisplayName {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return '杠铃';
      case 'dumbbell':
      case 'dumbbells':
        return '哑铃';
      case 'body only':
      case 'bodyweight':
      case 'none':
        return '自重';
      case 'cable':
        return '绳索';
      case 'machine':
      case 'leverage machine':
        return '器械';
      case 'kettlebells':
        return '壶铃';
      case 'bands':
        return '弹力带';
      case 'medicine ball':
        return '药球';
      case 'ez-barbell':
        return '曲杆杠铃';
      case 'smith machine':
        return '史密斯机';
      default:
        return equipment;
    }
  }

  /// 复制并修改
  Exercise copyWith({
    String? id,
    String? name,
    String? nameEn,
    PrimaryMuscleGroup? primaryMuscle,
    List<SecondaryMuscleGroup>? secondaryMuscles,
    String? equipment,
    String? level,
    String? imageUrl,
    String? muscleImageUrl,
    ExerciseRecommendation? recommendation,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      level: level ?? this.level,
      imageUrl: imageUrl ?? this.imageUrl,
      muscleImageUrl: muscleImageUrl ?? this.muscleImageUrl,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Exercise(id: $id, name: $name, muscle: ${primaryMuscle.displayName})';
}

/// 解析次要肌肉部位（从外部数据源）
SecondaryMuscleGroup? _parseSecondaryMuscle(String value) {
  final lower = value.toLowerCase();
  switch (lower) {
    // 胸部
    case 'upper chest':
    case 'clavicular head':
      return SecondaryMuscleGroup.upperChest;
    case 'middle chest':
    case 'sternal head':
      return SecondaryMuscleGroup.middleChest;
    case 'lower chest':
    case 'abdominal head':
      return SecondaryMuscleGroup.lowerChest;
    // 背部
    case 'lats':
    case 'latissimus dorsi':
      return SecondaryMuscleGroup.lats;
    case 'upper back':
    case 'traps':
    case 'trapezius':
      return SecondaryMuscleGroup.upperBack;
    case 'rhomboids':
      return SecondaryMuscleGroup.rhomboids;
    case 'lower back':
    case 'erector spinae':
      return SecondaryMuscleGroup.lowerBack;
    // 肩部
    case 'front delt':
    case 'anterior deltoid':
    case 'front delts':
      return SecondaryMuscleGroup.frontDelt;
    case 'side delt':
    case 'lateral deltoid':
    case 'side delts':
      return SecondaryMuscleGroup.sideDelt;
    case 'rear delt':
    case 'posterior deltoid':
    case 'rear delts':
      return SecondaryMuscleGroup.rearDelt;
    // 手臂
    case 'biceps':
    case 'bicep':
      return SecondaryMuscleGroup.biceps;
    case 'triceps':
    case 'tricep':
      return SecondaryMuscleGroup.triceps;
    case 'forearms':
    case 'forearm':
      return SecondaryMuscleGroup.forearms;
    // 腿部
    case 'quads':
    case 'quadriceps':
      return SecondaryMuscleGroup.quads;
    case 'hamstrings':
    case 'hamstring':
      return SecondaryMuscleGroup.hamstrings;
    case 'glutes':
    case 'gluteus':
    case 'glute':
      return SecondaryMuscleGroup.glutes;
    case 'calves':
    case 'calf':
    case 'gastrocnemius':
      return SecondaryMuscleGroup.calves;
    // 核心
    case 'abs':
    case 'abdominals':
    case 'rectus abdominis':
      return SecondaryMuscleGroup.abs;
    case 'obliques':
    case 'oblique':
      return SecondaryMuscleGroup.obliques;
    default:
      return null;
  }
}

/// 从数据库枚举名称解析次要肌肉部位
SecondaryMuscleGroup? _parseSecondaryMuscleFromDb(String value) {
  return SecondaryMuscleGroup.values.where((e) => e.name == value).firstOrNull;
}
