import 'package:flutter/foundation.dart';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/workout_session.dart';

class DatabaseHelper {
  static const _databaseName = 'workout_timer.db';
  static const _databaseVersion = 4; // 升级到v4

  // 表名常量
  static const tableWorkoutSessions = 'workout_sessions';
  static const tableExercises = 'exercises';
  static const tableWorkoutPlans = 'workout_plans';
  static const tablePlanExercises = 'plan_exercises';
  static const tableCalendarPlans = 'calendar_plans';
  static const tableWorkoutRecords = 'workout_records';
  static const tableRecordExercises = 'record_exercises';

  // workout_sessions 表列名（保持兼容）
  static const columnId = 'id';
  static const columnSets = 'sets';
  static const columnRestTimeMs = 'rest_time_ms';
  static const columnCreatedAt = 'created_at';

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // For web, initialize sqflite ffi and use in-memory database
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      return await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  /// 创建所有表（新安装时调用）
  Future _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // 创建原有的 workout_sessions 表
      await txn.execute('''
        CREATE TABLE $tableWorkoutSessions (
          $columnId TEXT PRIMARY KEY,
          $columnSets INTEGER NOT NULL,
          $columnRestTimeMs INTEGER NOT NULL,
          $columnCreatedAt TEXT NOT NULL
        )
      ''');

      // 创建新的 exercises 表
      await txn.execute('''
        CREATE TABLE $tableExercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          name_en TEXT,
          primary_muscle TEXT NOT NULL,
          secondary_muscles TEXT,
          equipment TEXT,
          level TEXT,
          image_url TEXT,
          muscle_image_url TEXT,
          recommended_sets INTEGER DEFAULT 3,
          recommended_min_reps INTEGER DEFAULT 8,
          recommended_max_reps INTEGER DEFAULT 12,
          rest_seconds INTEGER DEFAULT 60
        )
      ''');

      // 创建 workout_plans 表
      await txn.execute('''
        CREATE TABLE $tableWorkoutPlans (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          target_muscles TEXT NOT NULL,
          estimated_duration INTEGER DEFAULT 30,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 创建 plan_exercises 表
      await txn.execute('''
        CREATE TABLE $tablePlanExercises (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          target_sets INTEGER NOT NULL DEFAULT 3,
          custom_sets INTEGER,
          exercise_order INTEGER NOT NULL,
          unmatched_name TEXT,
          FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE CASCADE
        )
      ''');

      // 创建 calendar_plans 表
      await txn.execute('''
        CREATE TABLE $tableCalendarPlans (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          plan_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE CASCADE,
          UNIQUE(date, plan_id)
        )
      ''');

      // 创建 workout_records 表
      await txn.execute('''
        CREATE TABLE $tableWorkoutRecords (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          trained_muscles TEXT,
          plan_id TEXT,
          plan_name TEXT,
          total_sets INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE SET NULL
        )
      ''');

      // 创建 record_exercises 表
      await txn.execute('''
        CREATE TABLE $tableRecordExercises (
          id TEXT PRIMARY KEY,
          record_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          completed_sets INTEGER NOT NULL,
          max_weight REAL,
          per_set_data TEXT,
          FOREIGN KEY (record_id) REFERENCES $tableWorkoutRecords(id) ON DELETE CASCADE
        )
      ''');

      // 创建索引以提高查询性能
      await txn.execute('CREATE INDEX idx_exercises_primary_muscle ON $tableExercises(primary_muscle)');
      await txn.execute('CREATE INDEX idx_plan_exercises_plan_id ON $tablePlanExercises(plan_id)');
      await txn.execute('CREATE INDEX idx_calendar_plans_date ON $tableCalendarPlans(date)');
      await txn.execute('CREATE INDEX idx_workout_records_date ON $tableWorkoutRecords(date)');
      await txn.execute('CREATE INDEX idx_record_exercises_record_id ON $tableRecordExercises(record_id)');
    });
  }

  /// 数据库升级（从旧版本迁移时调用）
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从v1升级到v2：添加新表
      await db.transaction((txn) async {
        // 创建新的 exercises 表
        await txn.execute('''
          CREATE TABLE $tableExercises (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            name_en TEXT,
            primary_muscle TEXT NOT NULL,
            secondary_muscles TEXT,
            equipment TEXT,
            level TEXT,
            image_url TEXT,
            muscle_image_url TEXT,
            recommended_sets INTEGER DEFAULT 3,
            recommended_min_reps INTEGER DEFAULT 8,
            recommended_max_reps INTEGER DEFAULT 12,
            rest_seconds INTEGER DEFAULT 60
          )
        ''');

        // 创建 workout_plans 表
        await txn.execute('''
          CREATE TABLE $tableWorkoutPlans (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            target_muscles TEXT NOT NULL,
            estimated_duration INTEGER DEFAULT 30,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        // 创建 plan_exercises 表
        await txn.execute('''
          CREATE TABLE $tablePlanExercises (
            id TEXT PRIMARY KEY,
            plan_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            target_sets INTEGER NOT NULL DEFAULT 3,
            custom_sets INTEGER,
            exercise_order INTEGER NOT NULL,
            FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE CASCADE
          )
        ''');

        // 创建 calendar_plans 表
        await txn.execute('''
          CREATE TABLE $tableCalendarPlans (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            plan_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE CASCADE,
            UNIQUE(date, plan_id)
          )
        ''');

        // 创建 workout_records 表
        await txn.execute('''
          CREATE TABLE $tableWorkoutRecords (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            trained_muscles TEXT,
            plan_id TEXT,
            plan_name TEXT,
            total_sets INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (plan_id) REFERENCES $tableWorkoutPlans(id) ON DELETE SET NULL
          )
        ''');

        // 创建 record_exercises 表
        await txn.execute('''
          CREATE TABLE $tableRecordExercises (
            id TEXT PRIMARY KEY,
            record_id TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            completed_sets INTEGER NOT NULL,
            max_weight REAL,
            per_set_data TEXT,
            FOREIGN KEY (record_id) REFERENCES $tableWorkoutRecords(id) ON DELETE CASCADE
          )
        ''');

        // 创建索引
        await txn.execute('CREATE INDEX idx_exercises_primary_muscle ON $tableExercises(primary_muscle)');
        await txn.execute('CREATE INDEX idx_plan_exercises_plan_id ON $tablePlanExercises(plan_id)');
        await txn.execute('CREATE INDEX idx_calendar_plans_date ON $tableCalendarPlans(date)');
        await txn.execute('CREATE INDEX idx_workout_records_date ON $tableWorkoutRecords(date)');
        await txn.execute('CREATE INDEX idx_record_exercises_record_id ON $tableRecordExercises(record_id)');

        // 注意：原有的 workout_sessions 表保持不变，用户数据不会丢失
      });
    }

    if (oldVersion < 3) {
      // 从v2升级到v3：添加per_set_data列用于详细记录
      await db.execute('ALTER TABLE $tableRecordExercises ADD COLUMN per_set_data TEXT');
    }

    if (oldVersion < 4) {
      // 从v3升级到v4：添加unmatched_name列用于未匹配的自定义动作
      await db.execute('ALTER TABLE $tablePlanExercises ADD COLUMN unmatched_name TEXT');
    }
  }

  // ========== 保留原有的 workout_sessions 操作方法 ==========

  Future<int> insert(WorkoutSession session) async {
    Database db = await instance.database;
    return await db.insert(tableWorkoutSessions, session.toMap());
  }

  Future<List<WorkoutSession>> queryAllRows() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableWorkoutSessions,
      orderBy: '$columnCreatedAt DESC',
    );
    return List.generate(maps.length, (i) {
      return WorkoutSession.fromMap(maps[i]);
    });
  }

  Future<int> delete(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableWorkoutSessions,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(WorkoutSession session) async {
    Database db = await instance.database;
    return await db.update(
      tableWorkoutSessions,
      session.toMap(),
      where: '$columnId = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteAll() async {
    Database db = await instance.database;
    await db.delete(tableWorkoutSessions);
  }

  // ========== 通用数据库操作方法 ==========

  /// 通用插入方法
  Future<int> insertToTable(String table, Map<String, dynamic> values) async {
    Database db = await instance.database;
    return await db.insert(table, values);
  }

  /// 通用查询方法
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    Database db = await instance.database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 通用更新方法
  Future<int> updateTable(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    Database db = await instance.database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// 通用删除方法
  Future<int> deleteFromTable(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    Database db = await instance.database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// 执行原始SQL查询
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    Database db = await instance.database;
    return await db.rawQuery(sql, arguments);
  }

  /// 执行事务
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    Database db = await instance.database;
    return await db.transaction(action);
  }

  /// 批量插入
  Future<void> batchInsert(String table, List<Map<String, dynamic>> values) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var value in values) {
      batch.insert(table, value);
    }
    await batch.commit(noResult: true);
  }
}
