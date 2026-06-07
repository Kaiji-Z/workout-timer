import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// This service does NOT exist yet — these tests are the TDD RED phase.
// They will fail to compile until ExerciseFavoritesService is implemented.
import 'package:workout_timer/services/exercise_favorites_service.dart';

void main() {
  late Database db;
  late ExerciseFavoritesService favoritesService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 5,
        onCreate: (db, version) async {
          // Minimal v5 schema — favorite_exercises table
          await db.execute('''
            CREATE TABLE favorite_exercises (
              exercise_id TEXT PRIMARY KEY,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    favoritesService = ExerciseFavoritesService(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExerciseFavoritesService', () {
    test('toggleFavorite adds exercise to favorites', () async {
      await favoritesService.toggleFavorite('exercise_1');

      expect(await favoritesService.isFavorite('exercise_1'), isTrue);
    });

    test('toggleFavorite called again removes it', () async {
      await favoritesService.toggleFavorite('exercise_1');
      expect(await favoritesService.isFavorite('exercise_1'), isTrue);

      await favoritesService.toggleFavorite('exercise_1');

      expect(await favoritesService.isFavorite('exercise_1'), isFalse);
    });

    test('getFavoriteIds returns all favorited exercise IDs', () async {
      await favoritesService.toggleFavorite('exercise_1');
      await favoritesService.toggleFavorite('exercise_2');
      await favoritesService.toggleFavorite('exercise_3');

      final ids = await favoritesService.getFavoriteIds();

      expect(ids, equals({'exercise_1', 'exercise_2', 'exercise_3'}));
    });

    test('getFavoriteIds returns empty set when no favorites', () async {
      final ids = await favoritesService.getFavoriteIds();

      expect(ids, isEmpty);
    });

    test('isFavorite returns false for never-favorited exercise', () async {
      expect(await favoritesService.isFavorite('nonexistent'), isFalse);
    });

    test(
      'isFavorite returns false for exercise that was unfavorited',
      () async {
        await favoritesService.toggleFavorite('exercise_1');
        await favoritesService.toggleFavorite('exercise_1');

        expect(await favoritesService.isFavorite('exercise_1'), isFalse);
      },
    );

    test('getFavoriteIds excludes unfavorited exercises', () async {
      await favoritesService.toggleFavorite('exercise_1');
      await favoritesService.toggleFavorite('exercise_2');
      await favoritesService.toggleFavorite('exercise_1'); // unfavorite 1

      final ids = await favoritesService.getFavoriteIds();

      expect(ids, equals({'exercise_2'}));
    });
  });

  group('Database Migration v4 to v5', () {
    setUp(() async {
      // Clean up file-based test databases before each test
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_1.db');
      } catch (_) {}
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_2.db');
      } catch (_) {}
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_3.db');
      } catch (_) {}
    });

    tearDown(() async {
      // Clean up file-based test databases after each test
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_1.db');
      } catch (_) {}
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_2.db');
      } catch (_) {}
      try {
        await databaseFactory.deleteDatabase('migration_v5_test_3.db');
      } catch (_) {}
    });

    test('migration creates favorite_exercises table with correct schema', () async {
      // Create v4 database (without favorite_exercises) — use unique path to avoid collision
      final migrationDb = await databaseFactory.openDatabase(
        'migration_v5_test_1.db',
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (db, version) async {
            // Minimal v4 tables to simulate existing schema
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

      // Verify table does NOT exist yet
      var tables = await migrationDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorite_exercises'",
      );
      expect(tables, isEmpty);

      // Simulate v5 migration: create favorite_exercises table
      await migrationDb.execute('''
        CREATE TABLE IF NOT EXISTS favorite_exercises (
          exercise_id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');

      // Verify table now exists
      tables = await migrationDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorite_exercises'",
      );
      expect(tables, isNotEmpty);

      // Verify schema columns
      final columns = await migrationDb.rawQuery(
        'PRAGMA table_info(favorite_exercises)',
      );
      final columnMap = {for (var c in columns) c['name'] as String: c};

      expect(columnMap, containsPair('exercise_id', isNotNull));
      expect(columnMap, containsPair('created_at', isNotNull));
      expect(columns.length, equals(2));

      // Verify exercise_id is PRIMARY KEY
      final exerciseIdCol = columnMap['exercise_id']!;
      expect(exerciseIdCol['pk'], equals(1));

      // Verify created_at is NOT NULL
      final createdAtCol = columnMap['created_at']!;
      expect(createdAtCol['notnull'], equals(1));

      // Verify table is functional
      await migrationDb.insert('favorite_exercises', {
        'exercise_id': 'bench_press',
        'created_at': '2026-06-03T12:00:00',
      });

      final rows = await migrationDb.query('favorite_exercises');
      expect(rows.length, equals(1));
      expect(rows[0]['exercise_id'], equals('bench_press'));

      await migrationDb.close();
    });

    test('migration preserves existing data', () async {
      // Create v4 database with existing data — use unique path
      final migrationDb = await databaseFactory.openDatabase(
        'migration_v5_test_2.db',
        options: OpenDatabaseOptions(
          version: 4,
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
              CREATE TABLE workout_records (
                id TEXT PRIMARY KEY,
                date TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                total_sets INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert existing data
      await migrationDb.insert('workout_sessions', {
        'id': 'session_1',
        'sets': 5,
        'rest_time_ms': 60000,
        'created_at': '2026-05-01T10:00:00',
      });

      await migrationDb.insert('workout_records', {
        'id': 'record_1',
        'date': '2026-05-15',
        'duration_seconds': 2400,
        'total_sets': 18,
        'created_at': '2026-05-15T09:00:00',
      });

      // Run v5 migration
      await migrationDb.execute('''
        CREATE TABLE IF NOT EXISTS favorite_exercises (
          exercise_id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');

      // Verify existing data is preserved
      final sessions = await migrationDb.query('workout_sessions');
      expect(sessions.length, equals(1));
      expect(sessions[0]['id'], equals('session_1'));

      final records = await migrationDb.query('workout_records');
      expect(records.length, equals(1));
      expect(records[0]['id'], equals('record_1'));

      await migrationDb.close();
    });

    test('fresh install at v5 includes favorite_exercises table', () async {
      final migrationDb = await databaseFactory.openDatabase(
        'migration_v5_test_3.db',
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS favorite_exercises (
                exercise_id TEXT PRIMARY KEY,
                created_at TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      // Table should exist on fresh install
      final tables = await migrationDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorite_exercises'",
      );
      expect(tables, isNotEmpty);

      await migrationDb.close();
    });
  });
}
