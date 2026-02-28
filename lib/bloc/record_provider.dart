import 'package:flutter/foundation.dart';
import '../models/workout_record.dart';

import '../models/muscle_group.dart';
import '../services/record_repository.dart';
import '../services/exercise_repository.dart';

/// 训练记录状态管理
class RecordProvider extends ChangeNotifier {
  final RecordRepository _repository = RecordRepository();
  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  List<WorkoutRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WorkoutRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get recordCount => _records.length;

  /// 加载所有记录
  Future<void> loadRecords({int? limit}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 先加载所有动作
      final exercises = await _exerciseRepository.getAllExercises();

      // 加载记录
      _records = await _repository.getAllRecords(
        limit: limit,
        exercises: exercises,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading records: $e');
      notifyListeners();
    }
  }

  /// 保存记录
  Future<void> saveRecord(WorkoutRecord record) async {
    try {
      await _repository.saveRecord(record);
      _records.insert(0, record);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving record: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 更新记录
  Future<void> updateRecord(WorkoutRecord record) async {
    try {
      await _repository.updateRecord(record);

      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating record: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    try {
      await _repository.deleteRecord(recordId);
      _records.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting record: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// 根据ID获取记录
  WorkoutRecord? getRecordById(String id) {
    return _records.where((r) => r.id == id).firstOrNull;
  }

  /// 获取周统计
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return await _repository.getWeeklyStats(weekStart);
  }

  /// 获取月统计
  Future<Map<String, dynamic>> getMonthlyStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return await _repository.getMonthlyStats(monthStart);
  }

  /// 获取肌肉部位训练分布
  Future<Map<PrimaryMuscleGroup, int>> getMuscleDistribution() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    return await _repository.getMuscleDistribution(monthStart, monthEnd);
  }

  /// 获取最近使用的计划
  Future<List<Map<String, dynamic>>> getRecentPlans({int? limit}) async {
    return await _repository.getRecentPlans(limit: limit);
  }

  /// 按日期范围筛选记录
  List<WorkoutRecord> getRecordsByDateRange(DateTime from, DateTime to) {
    return _records.where((r) {
      final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
      final fromDate = DateTime(from.year, from.month, from.day);
      final toDate = DateTime(to.year, to.month, to.day);
      return (recordDate.isAfter(fromDate) || recordDate.isAtSameMomentAs(fromDate)) &&
          (recordDate.isBefore(toDate) || recordDate.isAtSameMomentAs(toDate));
    }).toList();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _records.clear();
    super.dispose();
  }
}
