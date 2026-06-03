import 'package:sqflite/sqflite.dart';

class ExerciseFavoritesService {
  final Database _database;

  ExerciseFavoritesService({required Database database}) : _database = database;

  /// Toggle favorite status. Adds if not favorited, removes if already favorited.
  Future<void> toggleFavorite(String exerciseId) async {
    final exists = await isFavorite(exerciseId);
    if (exists) {
      await _database.delete(
        'favorite_exercises',
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
      );
    } else {
      await _database.insert('favorite_exercises', {
        'exercise_id': exerciseId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  /// Check if an exercise is favorited.
  Future<bool> isFavorite(String exerciseId) async {
    final results = await _database.query(
      'favorite_exercises',
      columns: ['exercise_id'],
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    return results.isNotEmpty;
  }

  /// Get all favorited exercise IDs as a Set.
  Future<Set<String>> getFavoriteIds() async {
    final results = await _database.query(
      'favorite_exercises',
      columns: ['exercise_id'],
    );
    return results.map((row) => row['exercise_id'] as String).toSet();
  }
}
