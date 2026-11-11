import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_record.dart';
import '../models/exercise.dart';
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
      await txn.insert(DatabaseHelper.tableWorkoutRecords, record.toMap());

      // 插入记录动作详情
      for (var exercise in record.exercises) {
        await txn.insert(DatabaseHelper.tableRecordExercises, {
          'id': _uuid.v4(),
          ...exercise.toMap(record.id),
        });
      }
    });

    debugPrint('Saved record: ${record.date.toIso8601String()}, ${record.totalSets} sets');
    return record.id;
  }

  /// 更新训练记录
  Future<void> updateRecord(WorkoutRecord record) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - updateRecord skipped');
      return;
    }
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
        await txn.insert(DatabaseHelper.tableRecordExercises, {
          'id': _uuid.v4(),
          ...exercise.toMap(record.id),
        });
      }
    });

    debugPrint('Updated record: ${record.id}');
  }

  /// 删除训练记录
  Future<void> deleteRecord(String recordId) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - deleteRecord skipped');
      return;
    }
    final database = await _db.database;

    // 由于有外键级联删除，删除记录会自动删除关联动作
    await database.delete(
      DatabaseHelper.tableWorkoutRecords,
      where: 'id = ?',
      whereArgs: [recordId],
    );

    debugPrint('Deleted record: $recordId');
  }

  /// 获取所有记录
  Future<List<WorkoutRecord>> getAllRecords({
    int? limit,
    int? offset,
    List<Exercise>? exercises,
  }) async {
    if (!_isDatabaseAvailable) {
      debugPrint(
        'Database not available on web - returning empty records list',
      );
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
}
