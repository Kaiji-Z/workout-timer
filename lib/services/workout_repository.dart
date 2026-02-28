import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_session.dart';
import 'database_helper.dart';

class WorkoutRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// Check if database is available (web has limited support)
  bool get _isDatabaseAvailable => !kIsWeb;

  Future<void> saveSession(int totalSets, int totalRestTimeMs) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - saveSession skipped');
      return;
    }
    try {
      final session = WorkoutSession(
        id: _uuid.v4(),
        totalSets: totalSets,
        totalRestTimeMs: totalRestTimeMs,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _dbHelper.insert(session);
    } catch (e) {
      debugPrint('Error saving session: $e');
      rethrow;
    }
  }

  Future<List<WorkoutSession>> getAllSessions() async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - returning empty sessions list');
      return [];
    }
    try {
      return await _dbHelper.queryAllRows();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  Future<void> deleteSession(String id) async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - deleteSession skipped');
      return;
    }
    try {
      await _dbHelper.delete(id);
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  Future<void> clearAllSessions() async {
    if (!_isDatabaseAvailable) {
      debugPrint('Database not available on web - clearAllSessions skipped');
      return;
    }
    try {
      await _dbHelper.deleteAll();
    } catch (e) {
      debugPrint('Error clearing sessions: $e');
      rethrow;
    }
  }

  // Optional: Get total stats
  Future<Map<String, int>> getTotalStats() async {
    final sessions = await getAllSessions();
    final totalSets = sessions.fold<int>(0, (sum, session) => sum + session.totalSets);
    final totalTimeMs = sessions.fold<int>(0, (sum, session) => sum + session.totalRestTimeMs);
    return {
      'totalSets': totalSets,
      'totalTimeMs': totalTimeMs,
    };
  }
}
