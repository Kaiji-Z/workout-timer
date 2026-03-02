import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';

/// 动作数据服务 - 从 free-exercise-db 加载数据
/// 
/// 数据来源: https://github.com/yuhonas/free-exercise-db (Public Domain)
/// 图片URL格式: https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{imagePath}
class ExerciseService {
  static const String _exerciseDbAsset = 'assets/data/exercises.json';
  
  static List<Exercise> _exercises = [];
  static bool _isLoaded = false;
  static String? _error;

  /// 获取所有动作
  static List<Exercise> get exercises => _exercises;
  
  /// 是否已加载
  static bool get isLoaded => _isLoaded;
  
  /// 获取错误信息
  static String? get error => _error;

  /// 获取指定动作
  static Exercise? getExercise(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取指定肌肉群的动作列表
  static List<Exercise> getExercisesByMuscle(PrimaryMuscleGroup muscle) {
    return _exercises.where((e) => e.primaryMuscle == muscle).toList();
  }

  /// 获取指定器械的动作列表
  static List<Exercise> getExercisesByEquipment(String equipment) {
    return _exercises.where((e) => e.equipment.toLowerCase() == equipment.toLowerCase()).toList();
  }

  /// 搜索动作（支持中英文名称）
  static List<Exercise> searchExercises(String query) {
    if (query.isEmpty) return _exercises;
    final lowerQuery = query.toLowerCase();
    return _exercises.where((e) {
      return e.name.toLowerCase().contains(lowerQuery) ||
          e.nameEn.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 从 assets 加载动作数据
  static Future<void> loadExercises() async {
    if (_isLoaded && _exercises.isNotEmpty) {
      return;
    }

    try {
      final String jsonString = await rootBundle.loadString(_exerciseDbAsset);
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      
      _exercises = data
          .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _isLoaded = true;
      _error = null;
      
      debugPrint('ExerciseService: Loaded ${_exercises.length} exercises from $_exerciseDbAsset');
    } catch (e, stackTrace) {
      _isLoaded = false;
      _error = e.toString();
      debugPrint('ExerciseService: Error loading exercises: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 获取所有器械类型
  static List<String> getAllEquipment() {
    final equipment = <String>{};
    for (final e in _exercises) {
      equipment.add(e.equipment);
    }
    return equipment.toList()..sort();
  }

  /// 按肌肉群分组获取动作数量
  static Map<PrimaryMuscleGroup, int> getExerciseCountByMuscle() {
    final count = <PrimaryMuscleGroup, int>{};
    for (final muscle in PrimaryMuscleGroup.values) {
      count[muscle] = _exercises.where((e) => e.primaryMuscle == muscle).length;
    }
    return count;
  }

  /// 清除缓存（用于重新加载）
  static void clearCache() {
    _exercises = [];
    _isLoaded = false;
    _error = null;
  }
}
