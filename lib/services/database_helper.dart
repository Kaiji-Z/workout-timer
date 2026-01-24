import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout_session.dart';

class DatabaseHelper {
  static const _databaseName = 'workout_timer.db';
  static const _databaseVersion = 1;
  static const table = 'workout_sessions';

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
      // For web, use in-memory database
      return await openDatabase(
        inMemoryDatabasePath,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    } else {
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId TEXT PRIMARY KEY,
        $columnSets INTEGER NOT NULL,
        $columnRestTimeMs INTEGER NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(WorkoutSession session) async {
    Database db = await instance.database;
    return await db.insert(table, session.toMap());
  }

  Future<List<WorkoutSession>> queryAllRows() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: '$columnCreatedAt DESC');
    return List.generate(maps.length, (i) {
      return WorkoutSession.fromMap(maps[i]);
    });
  }

  Future<int> delete(String id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(WorkoutSession session) async {
    Database db = await instance.database;
    return await db.update(
      table,
      session.toMap(),
      where: '$columnId = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteAll() async {
    Database db = await instance.database;
    await db.delete(table);
  }
}