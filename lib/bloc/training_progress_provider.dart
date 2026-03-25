import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/set_data.dart';
import '../models/workout_plan.dart';
import '../models/workout_record.dart';



/// 训练进度状态管理
/// 用于跟踪按计划训练时的进度
class TrainingProgressProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  WorkoutPlan? _currentPlan;
  int _currentExerciseIndex = 0;
  int _currentSetInExercise = 0;
  Map<String, int> _completedSets = {}; // exerciseId -> count
  Map<String, double?> _exerciseWeights = {}; // exerciseId -> max weight
  final Map<String, List<SetData>> _exerciseSetsData = {}; // exerciseId -> per-set data
  bool _isExpanded = false; // UI expansion state
  DateTime? _startTime;

  // Getters
  WorkoutPlan? get currentPlan => _currentPlan;
  int get currentExerciseIndex => _currentExerciseIndex;
  bool get isExpanded => _isExpanded;
  bool get isPlanMode => _currentPlan != null;
  DateTime? get startTime => _startTime;

  /// 获取当前动作
  PlanExercise? get currentExercise {
    if (_currentPlan == null || _currentPlan!.exercises.isEmpty) return null;
    if (_currentExerciseIndex >= _currentPlan!.exercises.length) return null;
    return _currentPlan!.exercises[_currentExerciseIndex];
  }

  /// 获取下一个动作
  PlanExercise? getNextExercise() {
    if (_currentPlan == null || _currentPlan!.exercises.isEmpty) return null;
    if (_currentExerciseIndex >= _currentPlan!.exercises.length - 1) return null;
    return _currentPlan!.exercises[_currentExerciseIndex + 1];
  }

  /// 获取当前动作在当前练习中的组数
  int get currentSetInExercise => _currentSetInExercise;

  /// 获取总完成组数
  int get totalCompletedSets {
    return _completedSets.values.fold(0, (sum, count) => sum + count);
  }
  
  /// 获取所有动作的完成组数映射
  Map<String, int> get completedSets => Map.unmodifiable(_completedSets);

  /// 获取总目标组数
  int get totalTargetSets {
    if (_currentPlan == null) return 0;
    return _currentPlan!.exercises.fold(0, (sum, e) => sum + e.effectiveSets);
  }

  /// 获取进度百分比 (0.0 - 1.0)
  double get progressPercentage {
    if (totalTargetSets == 0) return 0.0;
    return totalCompletedSets / totalTargetSets;
  }

  /// 当前动作是否完成
  bool get isCurrentExerciseComplete {
    final exercise = currentExercise;
    if (exercise == null) return false;
    final completed = _completedSets[exercise.exerciseId] ?? 0;
    return completed >= exercise.effectiveSets;
  }

  /// 所有动作是否完成
  bool get isAllExercisesComplete {
    if (_currentPlan == null || _currentPlan!.exercises.isEmpty) return false;
    for (var exercise in _currentPlan!.exercises) {
      final completed = _completedSets[exercise.exerciseId] ?? 0;
      if (completed < exercise.effectiveSets) return false;
    }
    return true;
  }

  /// 获取某个动作的完成组数
  int getCompletedSets(String exerciseId) {
    return _completedSets[exerciseId] ?? 0;
  }

  /// 获取某个动作的最大重量
  double? getExerciseWeight(String exerciseId) {
    return _exerciseWeights[exerciseId];
  }

  /// 获取某个动作的每组数据
  Map<String, List<SetData>> get exerciseSetsData => _exerciseSetsData;

  /// 获取某个动作的每组数据
  List<SetData> getExerciseSetsData(String exerciseId) {
    return _exerciseSetsData[exerciseId] ?? [];
  }

  /// 记录一组的数据
  void addSetData(String exerciseId, SetData setData) {
    if (!_exerciseSetsData.containsKey(exerciseId)) {
      _exerciseSetsData[exerciseId] = [];
    }
    _exerciseSetsData[exerciseId]!.add(setData);
    notifyListeners();
  }

  /// 替换某个动作的所有组数据（用于最终保存时覆盖休息时记录的数据）
  void replaceSetsData(String exerciseId, List<SetData> setsData) {
    _exerciseSetsData[exerciseId] = setsData;
    notifyListeners();
  }

  /// 获取某个动作的最大重量（从setsData计算）
  double? getMaxWeight(String exerciseId) {
    final sets = _exerciseSetsData[exerciseId];
    if (sets == null || sets.isEmpty) return null;
    return sets.map((s) => s.weight ?? 0).reduce((a, b) => a > b ? a : b);
  }

  /// 清除每组数据
  void clearSetsData() {
    _exerciseSetsData.clear();
    notifyListeners();
  }

  /// 开始计划训练
  void startPlan(WorkoutPlan plan) {
    _currentPlan = plan;
    _currentExerciseIndex = 0;
    _currentSetInExercise = 0;
    _completedSets = {};
    _exerciseWeights = {};
    _exerciseSetsData.clear();
    _isExpanded = false;
    _startTime = DateTime.now();

    // 初始化所有动作的完成组数为0
    for (var exercise in plan.exercises) {
      _completedSets[exercise.exerciseId] = 0;
    }

    notifyListeners();
  }

  /// 完成一组
  void completeSet() {
    final exercise = currentExercise;
    if (exercise == null) return;

    _currentSetInExercise++;
    _completedSets[exercise.exerciseId] = _currentSetInExercise;

    // 检查是否完成当前动作的所有组，自动切换到下一个动作
    if (_currentSetInExercise >= exercise.effectiveSets) {
      // 当前动作完成，自动切换到下一个动作
      if (_currentExerciseIndex < _currentPlan!.exercises.length - 1) {
        _currentExerciseIndex++;
        _currentSetInExercise = 0;
        // 初始化下一个动作的完成组数（如果尚未初始化）
        final nextExercise = currentExercise;
        if (nextExercise != null && !_completedSets.containsKey(nextExercise.exerciseId)) {
          _completedSets[nextExercise.exerciseId] = 0;
        }
      }
    }

    notifyListeners();
  }

  /// 切换到下一个动作
  void nextExercise() {
    if (_currentPlan == null) return;
    if (_currentExerciseIndex >= _currentPlan!.exercises.length - 1) return;

    _currentExerciseIndex++;
    _currentSetInExercise = _completedSets[currentExercise!.exerciseId] ?? 0;

    notifyListeners();
  }

  /// 切换到指定动作
  void goToExercise(int index) {
    if (_currentPlan == null) return;
    if (index < 0 || index >= _currentPlan!.exercises.length) return;

    _currentExerciseIndex = index;
    _currentSetInExercise = _completedSets[currentExercise!.exerciseId] ?? 0;

    notifyListeners();
  }

  /// 设置动作的重量
  void setWeight(String exerciseId, double weight) {
    _exerciseWeights[exerciseId] = weight;
    notifyListeners();
  }

  /// 切换展开状态
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// 结束计划训练
  void endPlan() {
    _currentPlan = null;
    _currentExerciseIndex = 0;
    _currentSetInExercise = 0;
    _completedSets = {};
    _exerciseWeights = {};
    _exerciseSetsData.clear();
    _isExpanded = false;
    _startTime = null;
    notifyListeners();
  }

  /// 生成训练记录
  WorkoutRecord generateRecord() {
    final now = DateTime.now();
    final durationSeconds = _startTime != null
        ? now.difference(_startTime!).inSeconds
        : 0;

    // 构建记录中的动作列表
    final recordedExercises = <RecordedExercise>[];
    for (var planExercise in _currentPlan!.exercises) {
      final completedSets = _completedSets[planExercise.exerciseId] ?? 0;
      if (completedSets > 0) {
        final setsData = _exerciseSetsData[planExercise.exerciseId];
        final maxWeight = setsData != null && setsData.isNotEmpty
            ? getMaxWeight(planExercise.exerciseId)
            : _exerciseWeights[planExercise.exerciseId];
        recordedExercises.add(RecordedExercise(
          exerciseId: planExercise.exerciseId,
          exercise: planExercise.exercise,
          completedSets: completedSets,
          maxWeight: maxWeight,
          setsData: setsData,
        ));
      }
    }

    return WorkoutRecord(
      id: _uuid.v4(),
      date: now,
      durationSeconds: durationSeconds,
      trainedMuscles: _currentPlan!.targetMuscles,
      exercises: recordedExercises,
      planId: _currentPlan!.id,
      planName: _currentPlan!.name,
      totalSets: totalCompletedSets,
      createdAt: now,
    );
  }

  /// 获取训练时长（秒）
  int get trainingDurationSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  /// 获取格式化的训练时长
  String get trainingDurationText {
    final seconds = trainingDurationSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '$remainingSeconds秒';
    } else if (remainingSeconds == 0) {
      return '$minutes分钟';
    } else {
      return '$minutes分$remainingSeconds秒';
    }
  }

  @override
  void dispose() {
    _currentPlan = null;
    _completedSets.clear();
    _exerciseWeights.clear();
    _exerciseSetsData.clear();
    super.dispose();
  }
}
