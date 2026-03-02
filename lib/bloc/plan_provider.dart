import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';

import '../services/plan_repository.dart';

import '../data/exercise_data.dart';


/// 训练计划状态管理
class PlanProvider extends ChangeNotifier {
  final PlanRepository _repository = PlanRepository();


  List<WorkoutPlan> _plans = [];
  final Map<String, List<WorkoutPlan>> _calendarPlans = {}; // Key: 'yyyy-MM-dd'
  WorkoutPlan? _selectedPlan;
  bool _isLoading = false;
  String? _error;

  List<Exercise> _exercises = [];

  // Getters
  List<WorkoutPlan> get plans => _plans;
  List<Exercise> get exercises => _exercises;
  Set<DateTime> get datesWithPlans => getDatesWithPlans();
  WorkoutPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get planCount => _plans.length;

  /// 加载所有计划
  Future<void> loadPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 加载完整动作列表（优先使用ExerciseService的数据）
      _exercises = ExerciseData.getFullExerciseList();

      // 加载计划
      _plans = await _repository.getAllPlans(exercises: _exercises);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('Error loading plans: $e');
      notifyListeners();
    }
  }

  /// 加载某月的计划
  Future<void> loadMonthPlans(DateTime month) async {
    try {
      final planMap = await _repository.getPlansForMonth(month);

      // 更新日历计划映射
      planMap.forEach((date, planIds) {
        final key = _dateToKey(date);
        // 只存储planId列表，实际计划数据从_plans中获取
        _calendarPlans[key] = _plans.where((p) => planIds.contains(p.id)).toList();
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading month plans: $e');
    }
  }

  /// 创建计划
  Future<void> createPlan(WorkoutPlan plan) async {
    try {
    await _repository.createPlan(plan);
    _plans.insert(0, plan);
    notifyListeners();
    } catch (e) {
    _error = e.toString();
    debugPrint('Error creating plan: $e');
    notifyListeners();
    rethrow;
    }
  }

  /// 更新计划
  Future<void> updatePlan(WorkoutPlan plan) async {
    try {
    await _repository.updatePlan(plan);

    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
    }

    notifyListeners();
    } catch (e) {
    _error = e.toString();
    debugPrint('Error updating plan: $e');
    notifyListeners();
    rethrow;
    }
  }

  /// 删除计划
  Future<void> deletePlan(String planId) async {
    try {
    await _repository.deletePlan(planId);
    _plans.removeWhere((p) => p.id == planId);

    // 从日历中移除
    _calendarPlans.forEach((key, plans) {
      plans.removeWhere((p) => p.id == planId);
    });

    if (_selectedPlan?.id == planId) {
        _selectedPlan = null;
      }

    notifyListeners();
    } catch (e) {
    _error = e.toString();
    debugPrint('Error deleting plan: $e');
    notifyListeners();
    rethrow;
    }
  }

  /// 获取某日期的计划列表
  List<WorkoutPlan> getPlansForDate(DateTime date) {
    final key = _dateToKey(date);
    return _calendarPlans[key] ?? [];
  }

  /// 安排计划到日期
  Future<void> assignPlanToDate(String planId, DateTime date) async {
    try {
    await _repository.assignPlanToDate(planId, date);

    final plan = _plans.where((p) => p.id == planId).firstOrNull;
    if (plan != null) {
      final key = _dateToKey(date);
      _calendarPlans.putIfAbsent(key, () => []).add(plan);
      notifyListeners();
    }
    } catch (e) {
    debugPrint('Error assigning plan to date: $e');
    rethrow;
    }
  }

  /// 从日期移除计划
  Future<void> removePlanFromDate(String planId, DateTime date) async {
    try {
    await _repository.removePlanFromDate(planId, date);

    final key = _dateToKey(date);
    _calendarPlans[key]?.removeWhere((p) => p.id == planId);

    notifyListeners();
    } catch (e) {
    debugPrint('Error removing plan from date: $e');
    rethrow;
    }
  }

  /// 选择计划（用于训练）
  void selectPlan(WorkoutPlan? plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// 根据ID获取计划
  WorkoutPlan? getPlanById(String id) {
    return _plans.where((p) => p.id == id).firstOrNull;
  }

  /// 获取有计划的日期集合
  Set<DateTime> getDatesWithPlans() {
    return _calendarPlans.keys.map((key) => _keyToDate(key)).toSet();
  }

  /// 日期转换为key
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// key转换为日期
  DateTime _keyToDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _plans.clear();
    _calendarPlans.clear();
    _selectedPlan = null;
    super.dispose();
  }
}
