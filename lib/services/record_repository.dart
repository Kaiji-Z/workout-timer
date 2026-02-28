import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_record.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import 'database_helper.dart';

/// 训练记录数据仓库
class RecordRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// Check if database is available (web has limited support)
  bool get _isDatabaseAvailable => !kIsWeb;

  /// 保存训练记录
  Future<String> saveRecord(WorkoutRecord record) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - saveRecord skipped');
      return record.id;
    }
    final database = await _db.database;

    await database.transaction((txn) async {
      // 插入记录主表
      await txn.insert(
        DatabaseHelper.tableWorkoutRecords,
        record.toMap(),
      );

      // 插入记录动作详情
      for (var exercise in record.exercises) {
        await txn.insert(
          DatabaseHelper.tableRecordExercises,
          {
            'id': _uuid.v4(),
            ...exercise.toMap(record.id),
          },
        );
      }
    });

    debugPrint('Saved record: ${record.dateText}, ${record.totalSets} sets');
    return record.id;
  }

  /// 更新训练记录
  Future<void> updateRecord(WorkoutRecord record) async {
    final database = await _db.database;

    await database.transaction((txn) async {
      // 更新记录主表
      await txn.update(
        DatabaseHelper.tableWorkoutRecords,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );

      // 删除旧的记录动作
      await txn.delete(
        DatabaseHelper.tableRecordExercises,
        where: 'record_id = ?',
        whereArgs: [record.id],
      );

      // 插入新的记录动作
      for (var exercise in record.exercises) {
        await txn.insert(
          DatabaseHelper.tableRecordExercises,
          {
            'id': _uuid.v4(),
            ...exercise.toMap(record.id),
          },
        );
      }
    });

    debugPrint('Updated record: ${record.id}');
  }

  /// 删除训练记录
  Future<void> deleteRecord(String recordId) async {
    final database = await _db.database;

    // 由于有外键级联删除，删除记录会自动删除关联动作
    await database.delete(
      DatabaseHelper.tableWorkoutRecords,
      where: 'id = ?',
      whereArgs: [recordId],
    );

    debugPrint('Deleted record: $recordId');
  }

  /// 根据ID获取记录
  Future<WorkoutRecord?> getRecordById(String id, {List<Exercise>? exercises}) async {
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableWorkoutRecords,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    // 加载记录动作
    final recordExercises = await _loadRecordExercises(database, id, exercises);

    return WorkoutRecord.fromMap(maps.first, exercises: recordExercises);
  }

  /// 获取所有记录
  Future<List<WorkoutRecord>> getAllRecords({
    int? limit,
    int? offset,
    List<Exercise>? exercises,
  }) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - returning empty records list');
      return [];
    }
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableWorkoutRecords,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    final records = <WorkoutRecord>[];
    for (var map in maps) {
      final recordExercises = await _loadRecordExercises(
        database,
        map['id'] as String,
        exercises,
      );
      records.add(WorkoutRecord.fromMap(map, exercises: recordExercises));
    }

    return records;
  }

  /// 加载记录动作列表
  Future<List<RecordedExercise>> _loadRecordExercises(
    Database database,
    String recordId,
    List<Exercise>? exercises,
  ) async {
    final maps = await database.query(
      DatabaseHelper.tableRecordExercises,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    return maps.map((map) {
      final exerciseId = map['exercise_id'] as String;
      final exercise = exercises?.where((e) => e.id == exerciseId).firstOrNull;
      return RecordedExercise.fromMap(map, exercise: exercise);
    }).toList();
  }

  /// 按日期范围获取记录
  Future<List<WorkoutRecord>> getRecordsByDateRange(
    DateTime from,
    DateTime to, {
    List<Exercise>? exercises,
  }) async {
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableWorkoutRecords,
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date DESC',
    );

    final records = <WorkoutRecord>[];
    for (var map in maps) {
      final recordExercises = await _loadRecordExercises(
        database,
        map['id'] as String,
        exercises,
      );
      records.add(WorkoutRecord.fromMap(map, exercises: recordExercises));
    }

    return records;
  }

  // ========== 统计功能 ==========

  /// 获取周统计
  Future<Map<String, dynamic>> getWeeklyStats(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final records = await getRecordsByDateRange(weekStart, weekEnd);

    return _calculateStats(records, '本周');
  }

  /// 获取月统计
  Future<Map<String, dynamic>> getMonthlyStats(DateTime monthStart) async {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final records = await getRecordsByDateRange(monthStart, monthEnd);

    return _calculateStats(records, '本月');
  }

  /// 计算统计数据
  Map<String, dynamic> _calculateStats(List<WorkoutRecord> records, String period) {
    if (records.isEmpty) {
      return {
        'period': period,
        'totalSessions': 0,
        'totalDuration': 0,
        'totalSets': 0,
        'totalExercises': 0,
      };
    }

    int totalDuration = 0;
    int totalSets = 0;
    int totalExercises = 0;

    for (var record in records) {
      totalDuration += record.durationSeconds;
      totalSets += record.totalSets;
      totalExercises += record.exerciseCount;
    }

    return {
      'period': period,
      'totalSessions': records.length,
      'totalDuration': totalDuration,
      'totalDurationMinutes': totalDuration ~/ 60,
      'totalSets': totalSets,
      'totalExercises': totalExercises,
      'avgDuration': totalDuration ~/ records.length,
      'avgSets': totalSets ~/ records.length,
    };
  }

  /// 获取肌肉部位训练分布
  Future<Map<PrimaryMuscleGroup, int>> getMuscleDistribution(
    DateTime from,
    DateTime to,
  ) async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT trained_muscles FROM ${DatabaseHelper.tableWorkoutRecords}
      WHERE date >= ? AND date <= ? AND trained_muscles IS NOT NULL
    ''', [from.toIso8601String(), to.toIso8601String()]);

    final Map<PrimaryMuscleGroup, int> distribution = {};

    for (var row in results) {
      final musclesJson = row['trained_muscles'] as String?;
      if (musclesJson == null || musclesJson.isEmpty) continue;

      try {
        // 解析JSON数组
        final musclesList = musclesJson
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',');

        for (var muscleName in musclesList) {
          final trimmed = muscleName.trim();
          if (trimmed.isEmpty) continue;

          final muscle = PrimaryMuscleGroupExtension.fromString(trimmed);
          if (muscle != null) {
            distribution[muscle] = (distribution[muscle] ?? 0) + 1;
          }
        }
      } catch (e) {
        debugPrint('Error parsing muscles: $e');
      }
    }

    return distribution;
  }

  /// 获取最近使用的计划
  Future<List<Map<String, dynamic>>> getRecentPlans({int? limit}) async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT plan_id, plan_name, COUNT(*) as use_count
      FROM ${DatabaseHelper.tableWorkoutRecords}
      WHERE plan_id IS NOT NULL AND plan_name IS NOT NULL
      GROUP BY plan_id, plan_name
      ORDER BY MAX(date) DESC
      LIMIT ?
    ''', [limit ?? 5]);

    return results.map((row) {
      return <String, dynamic>{
        'planId': row['plan_id'],
        'planName': row['plan_name'],
        'useCount': row['use_count'],
      };
    }).toList();
  }

  /// 获取记录总数
  Future<int> getRecordCount() async {
    if (!_isDatabaseAvailable) {
      return 0;
    }
    final database = await _db.database;

    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ${DatabaseHelper.tableWorkoutRecords}'),
    );

    return count ?? 0;
  }
}
