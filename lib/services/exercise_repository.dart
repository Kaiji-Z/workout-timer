import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// 动作数据仓库
class ExerciseRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isImported = false;

  /// 确保动作数据已导入
  Future<void> ensureExercisesImported() async {
    if (_isImported) return;

    final database = await _db.database;
    await _importExercisesIfNeeded(database);
    _isImported = true;
  }

  /// 检查并导入动作数据
  Future<void> _importExercisesIfNeeded(Database database) async {
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );

    if (count == null || count == 0) {
      // 导入内置动作数据
      // 由于这里没有直接访问ExerciseData，我们在首次查询时触发导入
      // 实际导入由ExerciseData.importToDatabase完成
      debugPrint('Exercise database is empty, will import on first use');
    }
  }

  /// 获取所有动作
  Future<List<Exercise>> getAllExercises() async {
    final database = await _db.database;

    // 检查是否需要导入
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );

    if (count == null || count == 0) {
      // 导入内置数据
      await _importBuiltInExercises(database);
    }

    final maps = await database.query(
      DatabaseHelper.tableExercises,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// 导入内置动作数据
  Future<void> _importBuiltInExercises(Database database) async {
    // 内置动作数据（与ExerciseData.builtInExercises相同）
    const builtInExercises = _builtInExercisesData;

    final batch = database.batch();
    for (var data in builtInExercises) {
      batch.insert(
        DatabaseHelper.tableExercises,
        data,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('Imported ${builtInExercises.length} exercises to database');
  }

  /// 根据ID获取动作
  Future<Exercise?> getExerciseById(String id) async {
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableExercises,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  /// 根据主要肌肉部位获取动作
  Future<List<Exercise>> getExercisesByPrimaryMuscle(PrimaryMuscleGroup muscle) async {
    final database = await _db.database;

    // 确保数据已导入
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );
    if (count == null || count == 0) {
      await _importBuiltInExercises(database);
    }

    final maps = await database.query(
      DatabaseHelper.tableExercises,
      where: 'primary_muscle = ?',
      whereArgs: [muscle.name],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// 搜索动作（按名称）
  Future<List<Exercise>> searchExercises(String query) async {
    final database = await _db.database;

    // 确保数据已导入
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );
    if (count == null || count == 0) {
      await _importBuiltInExercises(database);
    }

    final maps = await database.query(
      DatabaseHelper.tableExercises,
      where: 'name LIKE ? OR name_en LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// 获取动作数量
  Future<int> getExerciseCount() async {
    final database = await _db.database;

    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableExercises}'),
    );

    return count ?? 0;
  }

  /// 按多个ID获取动作
  Future<List<Exercise>> getExercisesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final database = await _db.database;

    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await database.query(
      DatabaseHelper.tableExercises,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return maps.map((map) => Exercise.fromMap(map)).toList();
  }
}

/// 内置动作数据（数据库格式）
const _builtInExercisesData = [
  // 胸部动作
  {'id': 'barbell_bench_press', 'name': '卧推（杠铃）', 'name_en': 'Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt","triceps"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'incline_barbell_bench_press', 'name': '上斜卧推（杠铃）', 'name_en': 'Incline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt","triceps"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'decline_barbell_bench_press', 'name': '下斜卧推（杠铃）', 'name_en': 'Decline Barbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': '["triceps"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'dumbbell_bench_press', 'name': '卧推（哑铃）', 'name_en': 'Dumbbell Bench Press', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt","triceps"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'incline_dumbbell_press', 'name': '上斜卧推（哑铃）', 'name_en': 'Incline Dumbbell Press', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt","triceps"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'dumbbell_flyes', 'name': '哑铃飞鸟', 'name_en': 'Dumbbell Flyes', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'cable_crossover', 'name': '龙门架夹胸', 'name_en': 'Cable Crossover', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt"]', 'equipment': 'cable', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'push_ups', 'name': '俯卧撑', 'name_en': 'Push-Ups', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt","triceps"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'chest_dips', 'name': '双杠臂屈伸（练胸）', 'name_en': 'Chest Dips', 'primary_muscle': 'chest', 'secondary_muscles': '["triceps","frontDelt"]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'pec_deck', 'name': '蝴蝶机夹胸', 'name_en': 'Pec Deck', 'primary_muscle': 'chest', 'secondary_muscles': '["frontDelt"]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  // 背部动作
  {'id': 'deadlift', 'name': '硬拉', 'name_en': 'Deadlift', 'primary_muscle': 'back', 'secondary_muscles': '["glutes","hamstrings","lowerBack"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'barbell_row', 'name': '杠铃划船', 'name_en': 'Barbell Row', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'dumbbell_row', 'name': '单臂哑铃划船', 'name_en': 'One-Arm Dumbbell Row', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'lat_pulldown', 'name': '高位下拉', 'name_en': 'Lat Pulldown', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'seated_cable_row', 'name': '坐姿绳索划船', 'name_en': 'Seated Cable Row', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'pull_ups', 'name': '引体向上', 'name_en': 'Pull-Ups', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'chin_ups', 'name': '反手引体向上', 'name_en': 'Chin-Ups', 'primary_muscle': 'back', 'secondary_muscles': '["biceps"]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 't_bar_row', 'name': 'T杆划船', 'name_en': 'T-Bar Row', 'primary_muscle': 'back', 'secondary_muscles': '["biceps","rearDelt"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'hyperextensions', 'name': '山羊挺身', 'name_en': 'Hyperextensions', 'primary_muscle': 'back', 'secondary_muscles': '["glutes","hamstrings"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'face_pulls', 'name': '面拉', 'name_en': 'Face Pulls', 'primary_muscle': 'back', 'secondary_muscles': '["rearDelt","biceps"]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  // 肩部动作
  {'id': 'overhead_press', 'name': '站姿推举（杠铃）', 'name_en': 'Overhead Press', 'primary_muscle': 'shoulders', 'secondary_muscles': '["triceps","upperBack"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'dumbbell_shoulder_press', 'name': '哑铃推举', 'name_en': 'Dumbbell Shoulder Press', 'primary_muscle': 'shoulders', 'secondary_muscles': '["triceps"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'arnold_press', 'name': '阿诺德推举', 'name_en': 'Arnold Press', 'primary_muscle': 'shoulders', 'secondary_muscles': '["triceps"]', 'equipment': 'dumbbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'lateral_raises', 'name': '侧平举', 'name_en': 'Lateral Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '[]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'front_raises', 'name': '前平举', 'name_en': 'Front Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '[]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'rear_delt_flyes', 'name': '俯身飞鸟', 'name_en': 'Rear Delt Flyes', 'primary_muscle': 'shoulders', 'secondary_muscles': '["upperBack"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'upright_row', 'name': '直立划船', 'name_en': 'Upright Row', 'primary_muscle': 'shoulders', 'secondary_muscles': '["biceps","upperBack"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'shrugs', 'name': '耸肩', 'name_en': 'Shrugs', 'primary_muscle': 'shoulders', 'secondary_muscles': '["upperBack"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'cable_lateral_raises', 'name': '绳索单臂侧平举', 'name_en': 'Cable Lateral Raises', 'primary_muscle': 'shoulders', 'secondary_muscles': '[]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'machine_shoulder_press', 'name': '器械推肩', 'name_en': 'Machine Shoulder Press', 'primary_muscle': 'shoulders', 'secondary_muscles': '["triceps"]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  // 手臂动作
  {'id': 'barbell_curl', 'name': '杠铃弯举', 'name_en': 'Barbell Curl', 'primary_muscle': 'arms', 'secondary_muscles': '["forearms"]', 'equipment': 'barbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'dumbbell_curl', 'name': '哑铃弯举', 'name_en': 'Dumbbell Curl', 'primary_muscle': 'arms', 'secondary_muscles': '["forearms"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'hammer_curl', 'name': '锤式弯举', 'name_en': 'Hammer Curl', 'primary_muscle': 'arms', 'secondary_muscles': '["forearms"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'preacher_curl', 'name': '牧师凳弯举', 'name_en': 'Preacher Curl', 'primary_muscle': 'arms', 'secondary_muscles': '["forearms"]', 'equipment': 'barbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'concentration_curl', 'name': '集中弯举', 'name_en': 'Concentration Curl', 'primary_muscle': 'arms', 'secondary_muscles': '[]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'incline_dumbbell_curl', 'name': '上斜哑铃弯举', 'name_en': 'Incline Dumbbell Curl', 'primary_muscle': 'arms', 'secondary_muscles': '["forearms"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'tricep_pushdown', 'name': '绳索下压', 'name_en': 'Tricep Pushdown', 'primary_muscle': 'arms', 'secondary_muscles': '[]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'skull_crushers', 'name': '仰卧臂屈伸', 'name_en': 'Skull Crushers', 'primary_muscle': 'arms', 'secondary_muscles': '[]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'close_grip_bench_press', 'name': '窄握卧推', 'name_en': 'Close-Grip Bench Press', 'primary_muscle': 'arms', 'secondary_muscles': '["chest","frontDelt"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'tricep_dips', 'name': '双杠臂屈伸（练三头）', 'name_en': 'Tricep Dips', 'primary_muscle': 'arms', 'secondary_muscles': '["chest","frontDelt"]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'overhead_tricep_extension', 'name': '过头臂屈伸', 'name_en': 'Overhead Tricep Extension', 'primary_muscle': 'arms', 'secondary_muscles': '[]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'wrist_curl', 'name': '腕弯举', 'name_en': 'Wrist Curl', 'primary_muscle': 'arms', 'secondary_muscles': '[]', 'equipment': 'barbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  // 腿部动作
  {'id': 'barbell_squat', 'name': '深蹲（杠铃）', 'name_en': 'Barbell Squat', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes","hamstrings"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'front_squat', 'name': '前蹲', 'name_en': 'Front Squat', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'leg_press', 'name': '腿举', 'name_en': 'Leg Press', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes","hamstrings"]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'leg_extension', 'name': '腿屈伸', 'name_en': 'Leg Extension', 'primary_muscle': 'legs', 'secondary_muscles': '[]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'romanian_deadlift', 'name': '罗马尼亚硬拉', 'name_en': 'Romanian Deadlift', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes","lowerBack"]', 'equipment': 'barbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'leg_curl', 'name': '腿弯举', 'name_en': 'Leg Curl', 'primary_muscle': 'legs', 'secondary_muscles': '[]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'lunges', 'name': '弓步蹲', 'name_en': 'Lunges', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes","hamstrings"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'bulgarian_split_squat', 'name': '保加利亚分腿蹲', 'name_en': 'Bulgarian Split Squat', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes"]', 'equipment': 'dumbbell', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'calf_raises', 'name': '提踵', 'name_en': 'Calf Raises', 'primary_muscle': 'legs', 'secondary_muscles': '[]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'hip_thrust', 'name': '臀桥', 'name_en': 'Hip Thrust', 'primary_muscle': 'legs', 'secondary_muscles': '["hamstrings"]', 'equipment': 'barbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'goblet_squat', 'name': '高脚杯深蹲', 'name_en': 'Goblet Squat', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes"]', 'equipment': 'dumbbell', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'hack_squat', 'name': '哈克深蹲', 'name_en': 'Hack Squat', 'primary_muscle': 'legs', 'secondary_muscles': '["glutes"]', 'equipment': 'machine', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  // 核心动作
  {'id': 'plank', 'name': '平板支撑', 'name_en': 'Plank', 'primary_muscle': 'core', 'secondary_muscles': '["lowerBack"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'crunches', 'name': '卷腹', 'name_en': 'Crunches', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'sit_ups', 'name': '仰卧起坐', 'name_en': 'Sit-Ups', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'russian_twist', 'name': '俄罗斯转体', 'name_en': 'Russian Twist', 'primary_muscle': 'core', 'secondary_muscles': '["obliques"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'leg_raises', 'name': '仰卧抬腿', 'name_en': 'Leg Raises', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'hanging_leg_raises', 'name': '悬垂举腿', 'name_en': 'Hanging Leg Raises', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'cable_crunch', 'name': '绳索卷腹', 'name_en': 'Cable Crunch', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'cable', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'ab_wheel_rollout', 'name': '健腹轮', 'name_en': 'Ab Wheel Rollout', 'primary_muscle': 'core', 'secondary_muscles': '["lowerBack"]', 'equipment': 'body only', 'level': 'intermediate', 'recommended_sets': 4, 'recommended_min_reps': 8, 'recommended_max_reps': 12, 'rest_seconds': 90},
  {'id': 'side_plank', 'name': '侧平板支撑', 'name_en': 'Side Plank', 'primary_muscle': 'core', 'secondary_muscles': '["obliques"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'mountain_climbers', 'name': '登山跑', 'name_en': 'Mountain Climbers', 'primary_muscle': 'core', 'secondary_muscles': '[]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'dead_bug', 'name': '死虫式', 'name_en': 'Dead Bug', 'primary_muscle': 'core', 'secondary_muscles': '["lowerBack"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
  {'id': 'bicycle_crunches', 'name': '自行车卷腹', 'name_en': 'Bicycle Crunches', 'primary_muscle': 'core', 'secondary_muscles': '["obliques"]', 'equipment': 'body only', 'level': 'beginner', 'recommended_sets': 3, 'recommended_min_reps': 10, 'recommended_max_reps': 15, 'rest_seconds': 60},
];
