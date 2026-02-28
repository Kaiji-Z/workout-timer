/// 内置动作库数据
///
/// 数据来源：yuhonas/free-exercise-db (Public Domain)
library;

import 'dart:convert';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// 解析次要肌肉部位（从内置数据）
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

class ExerciseData {
  /// 内置动作列表（精选常见动作）
  static const List<Map<String, dynamic>> builtInExercises = [
    // ==================== 胸部动作 ====================
    {
      'id': 'barbell_bench_press',
      'name': '卧推（杠铃）',
      'nameEn': 'Barbell Bench Press',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt', 'triceps'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'incline_barbell_bench_press',
      'name': '上斜卧推（杠铃）',
      'nameEn': 'Incline Barbell Bench Press',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt', 'triceps'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'decline_barbell_bench_press',
      'name': '下斜卧推（杠铃）',
      'nameEn': 'Decline Barbell Bench Press',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['triceps'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'dumbbell_bench_press',
      'name': '卧推（哑铃）',
      'nameEn': 'Dumbbell Bench Press',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt', 'triceps'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'incline_dumbbell_press',
      'name': '上斜卧推（哑铃）',
      'nameEn': 'Incline Dumbbell Press',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt', 'triceps'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'dumbbell_flyes',
      'name': '哑铃飞鸟',
      'nameEn': 'Dumbbell Flyes',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'cable_crossover',
      'name': '龙门架夹胸',
      'nameEn': 'Cable Crossover',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt'],
      'equipment': 'cable',
      'level': 'intermediate',
    },
    {
      'id': 'push_ups',
      'name': '俯卧撑',
      'nameEn': 'Push-Ups',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt', 'triceps'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'chest_dips',
      'name': '双杠臂屈伸（练胸）',
      'nameEn': 'Chest Dips',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['triceps', 'frontDelt'],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 'pec_deck',
      'name': '蝴蝶机夹胸',
      'nameEn': 'Pec Deck',
      'primaryMuscle': 'chest',
      'secondaryMuscles': ['frontDelt'],
      'equipment': 'machine',
      'level': 'beginner',
    },

    // ==================== 背部动作 ====================
    {
      'id': 'deadlift',
      'name': '硬拉',
      'nameEn': 'Deadlift',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['glutes', 'hamstrings', 'lowerBack'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'barbell_row',
      'name': '杠铃划船',
      'nameEn': 'Barbell Row',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'dumbbell_row',
      'name': '单臂哑铃划船',
      'nameEn': 'One-Arm Dumbbell Row',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'lat_pulldown',
      'name': '高位下拉',
      'nameEn': 'Lat Pulldown',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'cable',
      'level': 'beginner',
    },
    {
      'id': 'seated_cable_row',
      'name': '坐姿绳索划船',
      'nameEn': 'Seated Cable Row',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'cable',
      'level': 'beginner',
    },
    {
      'id': 'pull_ups',
      'name': '引体向上',
      'nameEn': 'Pull-Ups',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 'chin_ups',
      'name': '反手引体向上',
      'nameEn': 'Chin-Ups',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps'],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 't_bar_row',
      'name': 'T杆划船',
      'nameEn': 'T-Bar Row',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['biceps', 'rearDelt'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'hyperextensions',
      'name': '山羊挺身',
      'nameEn': 'Hyperextensions',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'face_pulls',
      'name': '面拉',
      'nameEn': 'Face Pulls',
      'primaryMuscle': 'back',
      'secondaryMuscles': ['rearDelt', 'biceps'],
      'equipment': 'cable',
      'level': 'beginner',
    },

    // ==================== 肩部动作 ====================
    {
      'id': 'overhead_press',
      'name': '站姿推举（杠铃）',
      'nameEn': 'Overhead Press',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['triceps', 'upperBack'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'dumbbell_shoulder_press',
      'name': '哑铃推举',
      'nameEn': 'Dumbbell Shoulder Press',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['triceps'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'arnold_press',
      'name': '阿诺德推举',
      'nameEn': 'Arnold Press',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['triceps'],
      'equipment': 'dumbbell',
      'level': 'intermediate',
    },
    {
      'id': 'lateral_raises',
      'name': '侧平举',
      'nameEn': 'Lateral Raises',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': [],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'front_raises',
      'name': '前平举',
      'nameEn': 'Front Raises',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': [],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'rear_delt_flyes',
      'name': '俯身飞鸟',
      'nameEn': 'Rear Delt Flyes',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['upperBack'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'upright_row',
      'name': '直立划船',
      'nameEn': 'Upright Row',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['biceps', 'upperBack'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'shrugs',
      'name': '耸肩',
      'nameEn': 'Shrugs',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['upperBack'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'cable_lateral_raises',
      'name': '绳索单臂侧平举',
      'nameEn': 'Cable Lateral Raises',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': [],
      'equipment': 'cable',
      'level': 'beginner',
    },
    {
      'id': 'machine_shoulder_press',
      'name': '器械推肩',
      'nameEn': 'Machine Shoulder Press',
      'primaryMuscle': 'shoulders',
      'secondaryMuscles': ['triceps'],
      'equipment': 'machine',
      'level': 'beginner',
    },

    // ==================== 手臂动作 ====================
    {
      'id': 'barbell_curl',
      'name': '杠铃弯举',
      'nameEn': 'Barbell Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['forearms'],
      'equipment': 'barbell',
      'level': 'beginner',
    },
    {
      'id': 'dumbbell_curl',
      'name': '哑铃弯举',
      'nameEn': 'Dumbbell Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['forearms'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'hammer_curl',
      'name': '锤式弯举',
      'nameEn': 'Hammer Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['forearms'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'preacher_curl',
      'name': '牧师凳弯举',
      'nameEn': 'Preacher Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['forearms'],
      'equipment': 'barbell',
      'level': 'beginner',
    },
    {
      'id': 'concentration_curl',
      'name': '集中弯举',
      'nameEn': 'Concentration Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': [],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'incline_dumbbell_curl',
      'name': '上斜哑铃弯举',
      'nameEn': 'Incline Dumbbell Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['forearms'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'tricep_pushdown',
      'name': '绳索下压',
      'nameEn': 'Tricep Pushdown',
      'primaryMuscle': 'arms',
      'secondaryMuscles': [],
      'equipment': 'cable',
      'level': 'beginner',
    },
    {
      'id': 'skull_crushers',
      'name': '仰卧臂屈伸',
      'nameEn': 'Skull Crushers',
      'primaryMuscle': 'arms',
      'secondaryMuscles': [],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'close_grip_bench_press',
      'name': '窄握卧推',
      'nameEn': 'Close-Grip Bench Press',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['chest', 'frontDelt'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'tricep_dips',
      'name': '双杠臂屈伸（练三头）',
      'nameEn': 'Tricep Dips',
      'primaryMuscle': 'arms',
      'secondaryMuscles': ['chest', 'frontDelt'],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 'overhead_tricep_extension',
      'name': '过头臂屈伸',
      'nameEn': 'Overhead Tricep Extension',
      'primaryMuscle': 'arms',
      'secondaryMuscles': [],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'wrist_curl',
      'name': '腕弯举',
      'nameEn': 'Wrist Curl',
      'primaryMuscle': 'arms',
      'secondaryMuscles': [],
      'equipment': 'barbell',
      'level': 'beginner',
    },

    // ==================== 腿部动作 ====================
    {
      'id': 'barbell_squat',
      'name': '深蹲（杠铃）',
      'nameEn': 'Barbell Squat',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'front_squat',
      'name': '前蹲',
      'nameEn': 'Front Squat',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'leg_press',
      'name': '腿举',
      'nameEn': 'Leg Press',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'equipment': 'machine',
      'level': 'beginner',
    },
    {
      'id': 'leg_extension',
      'name': '腿屈伸',
      'nameEn': 'Leg Extension',
      'primaryMuscle': 'legs',
      'secondaryMuscles': [],
      'equipment': 'machine',
      'level': 'beginner',
    },
    {
      'id': 'romanian_deadlift',
      'name': '罗马尼亚硬拉',
      'nameEn': 'Romanian Deadlift',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes', 'lowerBack'],
      'equipment': 'barbell',
      'level': 'intermediate',
    },
    {
      'id': 'leg_curl',
      'name': '腿弯举',
      'nameEn': 'Leg Curl',
      'primaryMuscle': 'legs',
      'secondaryMuscles': [],
      'equipment': 'machine',
      'level': 'beginner',
    },
    {
      'id': 'lunges',
      'name': '弓步蹲',
      'nameEn': 'Lunges',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'bulgarian_split_squat',
      'name': '保加利亚分腿蹲',
      'nameEn': 'Bulgarian Split Squat',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes'],
      'equipment': 'dumbbell',
      'level': 'intermediate',
    },
    {
      'id': 'calf_raises',
      'name': '提踵',
      'nameEn': 'Calf Raises',
      'primaryMuscle': 'legs',
      'secondaryMuscles': [],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'hip_thrust',
      'name': '臀桥',
      'nameEn': 'Hip Thrust',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['hamstrings'],
      'equipment': 'barbell',
      'level': 'beginner',
    },
    {
      'id': 'goblet_squat',
      'name': '高脚杯深蹲',
      'nameEn': 'Goblet Squat',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes'],
      'equipment': 'dumbbell',
      'level': 'beginner',
    },
    {
      'id': 'hack_squat',
      'name': '哈克深蹲',
      'nameEn': 'Hack Squat',
      'primaryMuscle': 'legs',
      'secondaryMuscles': ['glutes'],
      'equipment': 'machine',
      'level': 'beginner',
    },

    // ==================== 核心动作 ====================
    {
      'id': 'plank',
      'name': '平板支撑',
      'nameEn': 'Plank',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['lowerBack'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'crunches',
      'name': '卷腹',
      'nameEn': 'Crunches',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'sit_ups',
      'name': '仰卧起坐',
      'nameEn': 'Sit-Ups',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'russian_twist',
      'name': '俄罗斯转体',
      'nameEn': 'Russian Twist',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['obliques'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'leg_raises',
      'name': '仰卧抬腿',
      'nameEn': 'Leg Raises',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'hanging_leg_raises',
      'name': '悬垂举腿',
      'nameEn': 'Hanging Leg Raises',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 'cable_crunch',
      'name': '绳索卷腹',
      'nameEn': 'Cable Crunch',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'cable',
      'level': 'beginner',
    },
    {
      'id': 'ab_wheel_rollout',
      'name': '健腹轮',
      'nameEn': 'Ab Wheel Rollout',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['lowerBack'],
      'equipment': 'body only',
      'level': 'intermediate',
    },
    {
      'id': 'side_plank',
      'name': '侧平板支撑',
      'nameEn': 'Side Plank',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['obliques'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'mountain_climbers',
      'name': '登山跑',
      'nameEn': 'Mountain Climbers',
      'primaryMuscle': 'core',
      'secondaryMuscles': [],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'dead_bug',
      'name': '死虫式',
      'nameEn': 'Dead Bug',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['lowerBack'],
      'equipment': 'body only',
      'level': 'beginner',
    },
    {
      'id': 'bicycle_crunches',
      'name': '自行车卷腹',
      'nameEn': 'Bicycle Crunches',
      'primaryMuscle': 'core',
      'secondaryMuscles': ['obliques'],
      'equipment': 'body only',
      'level': 'beginner',
    },
  ];

  /// 获取所有内置动作（转换为Exercise对象列表）
  static List<Exercise> getBuiltInExercises() {
    return builtInExercises.map((data) {
      // 解析主要肌肉部位
      final primaryMuscle = PrimaryMuscleGroupExtension.fromString(
        data['primaryMuscle'] as String,
      ) ?? PrimaryMuscleGroup.chest;

      // 解析次要肌肉部位
      final secondaryMusclesList = data['secondaryMuscles'] as List<dynamic>? ?? [];
      final secondaryMuscles = secondaryMusclesList
          .map((s) => _parseSecondaryMuscle(s as String))
          .whereType<SecondaryMuscleGroup>()
          .toList();

      // 根据难度设置推荐配置
      final level = data['level'] as String? ?? 'beginner';
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
        case 'advanced':
        case 'expert':
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

      return Exercise(
        id: data['id'] as String,
        name: data['name'] as String,
        nameEn: data['nameEn'] as String? ?? '',
        primaryMuscle: primaryMuscle,
        secondaryMuscles: secondaryMuscles,
        equipment: data['equipment'] as String? ?? '',
        level: level,
        recommendation: recommendation,
      );
    }).toList();
  }

  /// 将内置动作数据导入数据库
  static Future<void> importToDatabase(dynamic db) async {
    // 检查是否已导入
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );
    if (count != null && count > 0) {
      return; // 已有数据，跳过导入
    }

    // 批量插入
    Batch batch = db.batch();
    for (var exerciseData in builtInExercises) {
      // 解析主要肌肉部位
    final primaryMuscle = PrimaryMuscleGroupExtension.fromString(
      exerciseData['primaryMuscle'] as String,
    ) ?? PrimaryMuscleGroup.chest;

    // 根据难度设置推荐参数
    final level = exerciseData['level'] as String? ?? 'beginner';
    int recommendedSets = 3;
    int minReps = 10;
    int maxReps = 15;
    int restSeconds = 60;

    switch (level) {
      case 'beginner':
        recommendedSets = 3;
        minReps = 10;
        maxReps = 15;
        restSeconds = 60;
        break;
      case 'intermediate':
        recommendedSets = 4;
        minReps = 8;
        maxReps = 12;
        restSeconds = 90;
        break;
      case 'advanced':
      case 'expert':
        recommendedSets = 5;
        minReps = 6;
        maxReps = 10;
        restSeconds = 120;
        break;
    }

    batch.insert(
      DatabaseHelper.tableExercises,
      {
        'id': exerciseData['id'],
        'name': exerciseData['name'],
        'name_en': exerciseData['nameEn'],
        'primary_muscle': primaryMuscle.name,
        'secondary_muscles': jsonEncode(exerciseData['secondaryMuscles'] ?? []),
        'equipment': exerciseData['equipment'],
        'level': level,
        'recommended_sets': recommendedSets,
        'recommended_min_reps': minReps,
        'recommended_max_reps': maxReps,
        'rest_seconds': restSeconds,
      },
    );
  }
  await batch.commit(noResult: true);
  }

  /// 按肌肉部位筛选动作
  static List<Exercise> filterByMuscle(
    List<Exercise> exercises,
    PrimaryMuscleGroup muscle,
  ) {
    return exercises.where((e) => e.primaryMuscle == muscle).toList();
  }

  /// 搜索动作
  static List<Exercise> search(List<Exercise> exercises, String query) {
    final lowerQuery = query.toLowerCase();
    return exercises.where((e) {
      return e.name.toLowerCase().contains(lowerQuery) ||
          e.nameEn.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 按器械筛选
  static List<Exercise> filterByEquipment(
    List<Exercise> exercises,
    String equipment,
  ) {
    return exercises.where((e) => e.equipment == equipment).toList();
  }

  /// 按难度筛选
  static List<Exercise> filterByLevel(
    List<Exercise> exercises,
    String level,
  ) {
    return exercises.where((e) => e.level == level).toList();
  }
}
