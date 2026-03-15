import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// 训练计划数据仓库
class PlanRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// Check if database is available (web has limited support)
  bool get _isDatabaseAvailable => !kIsWeb;

  /// 创建计划
  Future<String> createPlan(WorkoutPlan plan) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - createPlan skipped');
      return plan.id;
    }
    final database = await _db.database;

    await database.transaction((txn) async {
      // 插入计划主表
      await txn.insert(
        DatabaseHelper.tableWorkoutPlans,
        plan.toMap(),
      );

      // 插入计划动作关联表
      for (var exercise in plan.exercises) {
        await txn.insert(
          DatabaseHelper.tablePlanExercises,
          {
            'id': _uuid.v4(),
            ...exercise.toMap(plan.id),
          },
        );
      }
    });

    debugPrint('Created plan: ${plan.name} with ${plan.exercises.length} exercises');
    return plan.id;
  }

  /// 更新计划
  Future<void> updatePlan(WorkoutPlan plan) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - updatePlan skipped');
      return;
    }
    final database = await _db.database;

    await database.transaction((txn) async {
      // 更新计划主表
      await txn.update(
        DatabaseHelper.tableWorkoutPlans,
        {
          ...plan.toMap(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [plan.id],
      );

      // 删除旧的关联动作
      await txn.delete(
        DatabaseHelper.tablePlanExercises,
        where: 'plan_id = ?',
        whereArgs: [plan.id],
      );

      // 插入新的关联动作
      for (var exercise in plan.exercises) {
        await txn.insert(
          DatabaseHelper.tablePlanExercises,
          {
            'id': _uuid.v4(),
            ...exercise.toMap(plan.id),
          },
        );
      }
    });

    debugPrint('Updated plan: ${plan.name}');
  }

  /// 删除计划
  Future<void> deletePlan(String planId) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - deletePlan skipped');
      return;
    }
    final database = await _db.database;

    // 由于有外键级联删除，删除计划会自动删除关联数据
    await database.delete(
      DatabaseHelper.tableWorkoutPlans,
      where: 'id = ?',
      whereArgs: [planId],
    );

    debugPrint('Deleted plan: $planId');
  }

  /// 根据ID获取计划
  Future<WorkoutPlan?> getPlanById(String id, {List<Exercise>? exercises}) async {
    if (!_isDatabaseAvailable) {
      return null;
    }
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableWorkoutPlans,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    // 加载计划动作
    final planExercises = await _loadPlanExercises(database, id, exercises);

    return WorkoutPlan.fromMap(maps.first, exercises: planExercises);
  }

  /// 获取所有计划
  Future<List<WorkoutPlan>> getAllPlans({List<Exercise>? exercises}) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - returning empty plans list');
      return [];
    }
    final database = await _db.database;

    final maps = await database.query(
      DatabaseHelper.tableWorkoutPlans,
      orderBy: 'created_at DESC',
    );

    final plans = <WorkoutPlan>[];
    for (var map in maps) {
      final planExercises = await _loadPlanExercises(
        database,
        map['id'] as String,
        exercises,
      );
      plans.add(WorkoutPlan.fromMap(map, exercises: planExercises));
    }

    return plans;
  }

  /// 加载计划动作列表
  Future<List<PlanExercise>> _loadPlanExercises(
    Database database,
    String planId,
    List<Exercise>? exercises,
  ) async {
    final maps = await database.query(
      DatabaseHelper.tablePlanExercises,
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'exercise_order ASC',
    );

    return maps.map((map) {
      final exerciseId = map['exercise_id'] as String;
      final exercise = exercises?.where((e) => e.id == exerciseId).firstOrNull;
      return PlanExercise.fromMap(map, exercise: exercise);
    }).toList();
  }

  // ========== 日历操作 ==========

  /// 安排计划到日期
  Future<void> assignPlanToDate(String planId, DateTime date) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - assignPlanToDate skipped');
      return;
    }
    final database = await _db.database;

    final dateStr = date.toIso8601String();

    // 检查是否已存在
    final existing = await database.query(
      DatabaseHelper.tableCalendarPlans,
      where: 'date = ? AND plan_id = ?',
      whereArgs: [dateStr, planId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await database.insert(
        DatabaseHelper.tableCalendarPlans,
        {
          'id': _uuid.v4(),
          'date': dateStr,
          'plan_id': planId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Assigned plan $planId to ${date.toIso8601String()}');
    }
  }

  /// 批量创建计划并分配到日历（用于AI周计划导入）
  /// 返回创建的计划ID列表
  Future<List<String>> batchCreatePlansWithCalendar(
    List<WorkoutPlan> plans,
    List<DateTime> dates,
  ) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - batchCreatePlansWithCalendar skipped');
      return [];
    }

    if (plans.length != dates.length) {
      throw ArgumentError('Plans and dates lists must have equal length');
    }

    if (plans.isEmpty) {
      return [];
    }

    final database = await _db.database;
    final List<String> createdIds = [];

    await database.transaction((txn) async {
      for (int i = 0; i < plans.length; i++) {
        final plan = plans[i];
        final date = dates[i];

        // 插入计划
        await txn.insert(
          DatabaseHelper.tableWorkoutPlans,
          plan.toMap(),
        );

        // 插入计划动作
        for (var exercise in plan.exercises) {
          await txn.insert(
            DatabaseHelper.tablePlanExercises,
            {
              'id': _uuid.v4(),
              ...exercise.toMap(plan.id),
            },
          );
        }

        // 分配到日历
        await txn.insert(
          DatabaseHelper.tableCalendarPlans,
          {
            'id': _uuid.v4(),
            'date': date.toIso8601String(),
            'plan_id': plan.id,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        createdIds.add(plan.id);
      }
    });

    debugPrint('Batch created ${createdIds.length} plans with calendar assignments');
    return createdIds;
  }

  /// 从日期移除计划
  Future<void> removePlanFromDate(String planId, DateTime date) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - removePlanFromDate skipped');
      return;
    }
    final database = await _db.database;

    await database.delete(
      DatabaseHelper.tableCalendarPlans,
      where: 'date = ? AND plan_id = ?',
      whereArgs: [date.toIso8601String(), planId],
    );

    debugPrint('Removed plan $planId from ${date.toIso8601String()}');
  }

  /// 获取某日期的计划列表
  Future<List<WorkoutPlan>> getPlansForDate(DateTime date, {List<Exercise>? exercises}) async {
    if (!_isDatabaseAvailable) {
      return [];
    }
    final database = await _db.database;

    final dateStr = date.toIso8601String();

    final results = await database.rawQuery('''
      SELECT p.* FROM ${DatabaseHelper.tableWorkoutPlans} p
      INNER JOIN ${DatabaseHelper.tableCalendarPlans} c ON p.id = c.plan_id
      WHERE c.date = ?
      ORDER BY c.created_at ASC
    ''', [dateStr]);

    final plans = <WorkoutPlan>[];
    for (var map in results) {
      final planExercises = await _loadPlanExercises(
        database,
        map['id'] as String,
        exercises,
      );
      plans.add(WorkoutPlan.fromMap(map, exercises: planExercises));
    }

    return plans;
  }

  /// 获取某月的计划（返回日期->计划ID列表的映射）
  Future<Map<DateTime, List<String>>> getPlansForMonth(DateTime month) async {
    if (!_isDatabaseAvailable) {
      return {};
    }
    final database = await _db.database;

    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final results = await database.query(
      DatabaseHelper.tableCalendarPlans,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final Map<DateTime, List<String>> planMap = {};
    for (var row in results) {
      final date = DateTime.parse(row['date'] as String);
      final planId = row['plan_id'] as String;

      // 标准化日期（去掉时间部分）
      final normalizedDate = DateTime(date.year, date.month, date.day);
      planMap.putIfAbsent(normalizedDate, () => []).add(planId);
    }

    return planMap;
  }

  /// 获取有计划的日期列表
  Future<Set<DateTime>> getDatesWithPlans(DateTime from, DateTime to) async {
    if (!_isDatabaseAvailable) {
      return {};
    }
    final database = await _db.database;

    final results = await database.query(
      DatabaseHelper.tableCalendarPlans,
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      columns: ['date'],
      distinct: true,
    );

    return results.map((row) {
      final date = DateTime.parse(row['date'] as String);
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  }
}
