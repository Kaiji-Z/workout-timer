import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/services/database_helper.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration v2 to v3', () {
    test('fresh install creates v3 schema with per_set_data column', () async {
      // Open in-memory database at version 3
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            // Create all tables (simulating _onCreate in database_helper.dart)
            await db.execute('''
              CREATE TABLE workout_sessions (
                id TEXT PRIMARY KEY,
                sets INTEGER NOT NULL,
                rest_time_ms INTEGER NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE exercises (
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
            await db.execute('''
              CREATE TABLE workout_plans (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                target_muscles TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 30,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE plan_exercises (
                id TEXT PRIMARY KEY,
                plan_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                target_sets INTEGER NOT NULL DEFAULT 3,
                custom_sets INTEGER,
                exercise_order INTEGER NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE calendar_plans (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                plan_id TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
                UNIQUE(date, plan_id)
              )
            ''');
            await db.execute('''
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                trained_muscles TEXT,
                plan_id TEXT,
                plan_name TEXT,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE record_exercises (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                completed_sets INTEGER NOT NULL,
                max_weight REAL,
                per_set_data TEXT,
                FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Verify per_set_data column exists
      final columns = await db.rawQuery("PRAGMA table_info(record_exercises)");
      final columnNames = columns.map((c) => c['name'] as String).toList();

      expect(columnNames, contains('per_set_data'));

      await db.close();
    });

    test('migration v2 to v3 preserves existing data', () async {
      // Simulate v2 database creation
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            // Create v2 schema (without per_set_data)
            await db.execute('''
              CREATE TABLE workout_sessions (
                id TEXT PRIMARY KEY,
                sets INTEGER NOT NULL,
                rest_time_ms INTEGER NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE exercises (
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
            await db.execute('''
              CREATE TABLE workout_plans (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                target_muscles TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 30,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE plan_exercises (
                id TEXT PRIMARY KEY,
                plan_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                target_sets INTEGER NOT NULL DEFAULT 3,
                custom_sets INTEGER,
                exercise_order INTEGER NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE calendar_plans (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                plan_id TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
                UNIQUE(date, plan_id)
              )
            ''');
            await db.execute('''
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                trained_muscles TEXT,
                plan_id TEXT,
                plan_name TEXT,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE record_exercises (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                completed_sets INTEGER NOT NULL,
                max_weight REAL,
                FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Insert test data (simulating existing records)
      await db.insert('workout_records', {
        'id': 'record_1',
        'date': '2026-03-15',
        'duration_seconds': 1800,
        'trained_muscles': 'chest,triceps',
        'total_sets': 15,
        'created_at': '2026-03-15T10:00:00',
      });

      await db.insert('record_exercises', {
        'id': 're_1',
        'record_id': 'record_1',
        'exercise_id': 'bench_press',
        'completed_sets': 5,
        'max_weight': 100.0,
      });

      // Verify column does NOT exist yet
      var columns = await db.rawQuery("PRAGMA table_info(record_exercises)");
      var columnNames = columns.map((c) => c['name'] as String).toList();
      expect(columnNames, isNot(contains('per_set_data')));

      // Simulate migration to v3
      await db.execute(
        'ALTER TABLE record_exercises ADD COLUMN per_set_data TEXT',
      );

      // Verify per_set_data column now exists
      columns = await db.rawQuery("PRAGMA table_info(record_exercises)");
      columnNames = columns.map((c) => c['name'] as String).toList();
      expect(columnNames, contains('per_set_data'));

      // Verify existing data is preserved
      final exercises = await db.query('record_exercises');
      expect(exercises.length, equals(1));
      expect(exercises[0]['id'], equals('re_1'));
      expect(exercises[0]['record_id'], equals('record_1'));
      expect(exercises[0]['exercise_id'], equals('bench_press'));
      expect(exercises[0]['completed_sets'], equals(5));
      expect(exercises[0]['max_weight'], equals(100.0));

      await db.close();
    });

    test('old records have null per_set_data after migration', () async {
      // Create v2 database
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE workout_plans (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                target_muscles TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 30,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                trained_muscles TEXT,
                plan_id TEXT,
                plan_name TEXT,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE record_exercises (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                completed_sets INTEGER NOT NULL,
                max_weight REAL,
                FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Insert old record (without per_set_data)
      await db.insert('workout_records', {
        'id': 'record_old',
        'date': '2026-03-10',
        'duration_seconds': 1200,
        'total_sets': 10,
        'created_at': '2026-03-10T08:00:00',
      });

      await db.insert('record_exercises', {
        'id': 're_old',
        'record_id': 'record_old',
        'exercise_id': 'squat',
        'completed_sets': 3,
        'max_weight': 80.0,
      });

      // Run migration
      await db.execute(
        'ALTER TABLE record_exercises ADD COLUMN per_set_data TEXT',
      );

      // Verify old record has null per_set_data
      final exercises = await db.query('record_exercises');
      expect(exercises.length, equals(1));
      expect(exercises[0]['per_set_data'], isNull);

      await db.close();
    });

    test('new records can store per_set_data', () async {
      // Create v3 database directly
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE workout_plans (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                target_muscles TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 30,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                trained_muscles TEXT,
                plan_id TEXT,
                plan_name TEXT,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE record_exercises (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                completed_sets INTEGER NOT NULL,
                max_weight REAL,
                per_set_data TEXT,
                FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );

      // Insert new record with per_set_data
      await db.insert('workout_records', {
        'id': 'record_new',
        'date': '2026-03-15',
        'duration_seconds': 1800,
        'total_sets': 12,
        'created_at': '2026-03-15T10:00:00',
      });

      const perSetData = '[{"weight":100,"reps":10},{"weight":105,"reps":8}]';
      await db.insert('record_exercises', {
        'id': 're_new',
        'record_id': 'record_new',
        'exercise_id': 'deadlift',
        'completed_sets': 2,
        'max_weight': 105.0,
        'per_set_data': perSetData,
      });

      // Verify per_set_data is stored and retrieved correctly
      final exercises = await db.query('record_exercises');
      expect(exercises.length, equals(1));
      expect(exercises[0]['per_set_data'], equals(perSetData));

      await db.close();
    });
  });

  group('Database Migration real-path regression (v1/v2 → v5)', () {
    /// 历史 v1 真实形态：只有 workout_sessions 一张表。
    Future<String> seedV1Database(String path) async {
      final db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE workout_sessions (
                id TEXT PRIMARY KEY,
                sets INTEGER NOT NULL,
                rest_time_ms INTEGER NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      await db.insert('workout_sessions', {
        'id': 'legacy_session',
        'sets': 5,
        'rest_time_ms': 60000,
        'created_at': '2026-01-01T10:00:00.000',
      });
      await db.close();
      return path;
    }

    /// 用真实 _onUpgrade 把 path 处的旧库升到 v5。
    Future<Database> upgradeToV5(String path) {
      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            fail('onCreate must not run when upgrading an existing database');
          },
          onUpgrade: (db, oldVersion, newVersion) =>
              DatabaseHelper.instance.debugOnUpgrade(db, oldVersion, newVersion),
        ),
      );
    }

    Future<List<String>> columnNames(Database db, String table) async {
      final cols = await db.rawQuery('PRAGMA table_info($table)');
      return cols.map((c) => c['name'] as String).toList();
    }

    test(
        'v1 legacy install upgrades straight to v5 (no duplicate column)',
        () async {
      final dir = await Directory.systemTemp.createTemp('wt_migration');
      final path = await seedV1Database('${dir.path}/v1_to_v5.db');

      // 关键回归：修复前 <2 块的 CREATE 已含 per_set_data，
      // <3 块的 ALTER 再加一次 → duplicate column name 异常。
      final db = await upgradeToV5(path);

      // 老数据保留
      final sessions = await db.query('workout_sessions');
      expect(sessions, hasLength(1));
      expect(sessions.first['id'], 'legacy_session');

      // v3 列经 ALTER 补上
      expect(await columnNames(db, 'record_exercises'),
          contains('per_set_data'));
      // v4 列经 ALTER 补上
      expect(await columnNames(db, 'plan_exercises'),
          contains('unmatched_name'));
      // v5 新表存在
      expect(await db.query('favorite_exercises'), isEmpty);

      await db.close();
      await dir.delete(recursive: true);
    });

    test('v2 install upgrades to v5 via real _onUpgrade', () async {
      final dir = await Directory.systemTemp.createTemp('wt_migration');
      final path = '${dir.path}/v2_to_v5.db';

      // 历史 v2 只能手工复刻：当年 v1→v2 的 _onUpgrade 只有 <2 块，
      // 今天代码里的 _onUpgrade 以 oldVersion=1 调用会四个块全跑，
      // 得到的是 v5 形态，复现不了真实 v2 老安装。
      final v2 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE workout_sessions (
                id TEXT PRIMARY KEY,
                sets INTEGER NOT NULL,
                rest_time_ms INTEGER NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE exercises (
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
            await db.execute('''
              CREATE TABLE workout_plans (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                target_muscles TEXT NOT NULL,
                estimated_duration INTEGER DEFAULT 30,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE plan_exercises (
                id TEXT PRIMARY KEY,
                plan_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                target_sets INTEGER NOT NULL DEFAULT 3,
                custom_sets INTEGER,
                exercise_order INTEGER NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE calendar_plans (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                plan_id TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
                UNIQUE(date, plan_id)
              )
            ''');
            await db.execute('''
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                trained_muscles TEXT,
                plan_id TEXT,
                plan_name TEXT,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE record_exercises (
                id TEXT PRIMARY KEY,
                record_id TEXT NOT NULL,
                exercise_id TEXT NOT NULL,
                completed_sets INTEGER NOT NULL,
                max_weight REAL,
                FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );
      await v2.insert('workout_sessions', {
        'id': 'v2_session',
        'sets': 3,
        'rest_time_ms': 90000,
        'created_at': '2026-02-01T09:00:00.000',
      });
      final v2Columns = await columnNames(v2, 'record_exercises');
      expect(v2Columns, isNot(contains('per_set_data')));
      await v2.close();

      final db = await upgradeToV5(path);
      expect(await columnNames(db, 'record_exercises'),
          contains('per_set_data'));
      expect(await columnNames(db, 'plan_exercises'),
          contains('unmatched_name'));
      expect(await db.query('workout_sessions'), hasLength(1));

      await db.close();
      await dir.delete(recursive: true);
    });
  });
}
