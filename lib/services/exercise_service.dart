import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';

/// 动作数据服务 - 从 free-exercise-db 加载数据
///
/// 数据来源: https://gitee.com/kaiji1126/free-exercise-db (镜像)
/// 原始仓库: https://github.com/yuhonas/free-exercise-db (Public Domain)
/// 图片URL格式: https://gitee.com/kaiji1126/free-exercise-db/raw/main/exercises/{imagePath}
class ExerciseService {
  static const String _exerciseDbAsset = 'assets/data/exercises.json';
  static const String _translationsAsset =
      'assets/data/exercise_translations.json';

  static List<Exercise> _exercises = [];
  static Map<String, String> _translations = {}; // 英文名 -> 中文名
  static bool _isLoaded = false;
  static String? _error;

  /// 获取所有动作
  static List<Exercise> get exercises => _exercises;

  /// 是否已加载
  static bool get isLoaded => _isLoaded;

  /// 获取错误信息
  static String? get error => _error;

  /// 从 assets 加载动作数据
  static Future<void> loadExercises() async {
    if (_isLoaded && _exercises.isNotEmpty) {
      return;
    }

    try {
      // 加载中文翻译
      await _loadTranslations();

      // 加载动作数据
      final String jsonString = await rootBundle.loadString(_exerciseDbAsset);
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;

      _exercises = data.map((json) {
        final exerciseJson = json as Map<String, dynamic>;
        // 应用中文翻译
        final name = exerciseJson['name'] as String? ?? '';
        final nameZh = _translations[name];
        if (nameZh != null) {
          exerciseJson['nameZh'] = nameZh;
        }
        return Exercise.fromJson(exerciseJson);
      }).toList();

      _isLoaded = true;
      _error = null;

      debugPrint(
        'ExerciseService: Loaded ${_exercises.length} exercises with ${_translations.length} translations',
      );
    } catch (e, stackTrace) {
      _isLoaded = false;
      _error = e.toString();
      debugPrint('ExerciseService: Error loading exercises: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 加载中文翻译
  static Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString(_translationsAsset);
      final Map<String, dynamic> data =
          json.decode(jsonString) as Map<String, dynamic>;
      _translations = data.map((key, value) => MapEntry(key, value as String));
      debugPrint(
        'ExerciseService: Loaded ${_translations.length} translations',
      );
    } catch (e) {
      debugPrint(
        'ExerciseService: No translations file found, using English names',
      );
      _translations = {};
    }
  }
}
