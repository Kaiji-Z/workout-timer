import 'package:flutter/foundation.dart';
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

    if (maps.isEmpty) return [];

    // 一次性批量加载全部关联动作再内存分组（替代逐条 N+1 查询；
    // 该方法是启动加载与历史页的主路径）。rowid 排序保持插入序，
    // 与旧的逐条查询语义一致；分片防御 SQLite 变量数上限。
    final ids = maps.map((m) => m['id'] as String).toList();
    final exerciseRows = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 500) {
      final chunkEnd = i + 500 > ids.length ? ids.length : i + 500;
      final chunk = ids.sublist(i, chunkEnd);
      final placeholders = List.filled(chunk.length, '?').join(',');
      exerciseRows.addAll(
        await database.query(
          DatabaseHelper.tableRecordExercises,
          where: 'record_id IN ($placeholders)',
          whereArgs: chunk,
          orderBy: 'rowid ASC',
        ),
      );
    }

    final byRecord = <String, List<Map<String, dynamic>>>{};
    for (final row in exerciseRows) {
      byRecord.putIfAbsent(row['record_id'] as String, () => []).add(row);
    }

    final records = <WorkoutRecord>[];
    for (var map in maps) {
      final rows = byRecord[map['id'] as String] ?? const [];
      final recordExercises = rows.map((row) {
        final exerciseId = row['exercise_id'] as String;
        final exercise = exercises?.where(
          (e) => e.id == exerciseId,
        ).firstOrNull;
        return RecordedExercise.fromMap(row, exercise: exercise);
      }).toList();
      records.add(WorkoutRecord.fromMap(map, exercises: recordExercises));
    }

    return records;
  }
}
