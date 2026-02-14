import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';

/// 训练状态枚举
enum TrainingState {
  idle,           // 空闲，未开始
  exercising,     // 运动中（正向计时）
  exercisePaused, // 运动暂停
  resting,        // 休息中（倒计时）
  completed,      // 训练完成
}

/// 训练状态管理 Provider
class TrainingProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  // 状态
  TrainingState _state = TrainingState.idle;
  int _currentSet = 0;           // 当前组数
  int _restDuration = 60;        // 休息时长（秒）
  int _restRemaining = 0;        // 休息剩余时间（秒）
  int _exerciseTime = 0;         // 运动时长（秒）
  int _totalExerciseTime = 0;    // 总运动时长（秒）
  int _totalRestTime = 0;        // 总休息时长（秒）
  bool _isPaused = false;

  // 计时器
  Timer? _timer;
  Stopwatch? _stopwatch;

  // Getters
  TrainingState get state => _state;
  int get currentSet => _currentSet;
  int get restDuration => _restDuration;
  int get restRemaining => _restRemaining;
  int get exerciseTime => _exerciseTime;
  int get totalExerciseTime => _totalExerciseTime;
  int get totalRestTime => _totalRestTime;
  bool get isPaused => _isPaused;
  
  bool get isIdle => _state == TrainingState.idle;
  bool get isExercising => _state == TrainingState.exercising;
  bool get isExercisePaused => _state == TrainingState.exercisePaused;
  bool get isResting => _state == TrainingState.resting;
  bool get isCompleted => _state == TrainingState.completed;

  /// 状态显示文本
  String get statusText {
    switch (_state) {
      case TrainingState.idle:
        return '准备开始';
      case TrainingState.exercising:
        return '正在进行第$_currentSet组';
      case TrainingState.exercisePaused:
        return '第$_currentSet组 已暂停';
      case TrainingState.resting:
        return '已完成$_currentSet组，准备进行第${_currentSet + 1}组';
      case TrainingState.completed:
        return '本次训练已完成$_currentSet组';
    }
  }

  /// 设置休息时长
  void setRestDuration(int seconds) {
    if (_state != TrainingState.idle) return;
    _restDuration = seconds;
    notifyListeners();
  }

  /// 开始运动
  void startExercise() {
    if (_state != TrainingState.idle && _state != TrainingState.completed) return;

    _state = TrainingState.exercising;
    _currentSet = 1;
    _exerciseTime = 0;
    _totalExerciseTime = 0;
    _totalRestTime = 0;
    _isPaused = false;

    _stopwatch = Stopwatch()..start();
    _startExerciseTimer();

    if (!kIsWeb) {
      TimerService.startService();
      _updateServiceNotification();
    }

    notifyListeners();
  }

  /// 继续运动（从完成状态恢复）
  void resumeExercise() {
    if (_state != TrainingState.completed) return;

    _state = TrainingState.exercising;
    _isPaused = false;

    _stopwatch = Stopwatch()..start();
    _startExerciseTimer();

    if (!kIsWeb) {
      TimerService.startService();
      _updateServiceNotification();
    }

    notifyListeners();
  }

  /// 暂停运动
  void pauseExercise() {
    if (_state != TrainingState.exercising) return;

    _state = TrainingState.exercisePaused;
    _isPaused = true;
    _stopwatch?.stop();
    _timer?.cancel();
    _timer = null;

    if (!kIsWeb) {
      TimerService.stopService();
    }

    notifyListeners();
  }

  /// 继续运动（从暂停恢复）
  void resumeFromPause() {
    if (_state != TrainingState.exercisePaused) return;

    _state = TrainingState.exercising;
    _isPaused = false;
    _stopwatch?.start();
    _startExerciseTimer();

    if (!kIsWeb) {
      TimerService.startService();
      _updateServiceNotification();
    }

    notifyListeners();
  }

  /// 开始休息
  void startRest() {
    if (_state != TrainingState.exercising) return;

    // 保存当前运动时间
    _totalExerciseTime += _exerciseTime;

    _state = TrainingState.resting;
    _restRemaining = _restDuration;
    _stopwatch?.stop();
    _timer?.cancel();
    _timer = null;

    _startRestTimer();

    notifyListeners();
  }

  /// 跳过休息
  void skipRest() {
    if (_state != TrainingState.resting) return;

    _timer?.cancel();
    _timer = null;

    // 保存已休息的时间
    final restedTime = _restDuration - _restRemaining;
    _totalRestTime += restedTime;

    _transitionToNextSet();
  }

  /// 结束训练
  void endWorkout() {
    if (_state != TrainingState.exercising && 
        _state != TrainingState.exercisePaused) {
      return;
    }

    // 保存当前运动时间
    if (_state == TrainingState.exercising) {
      _totalExerciseTime += _exerciseTime;
    }

    _stopwatch?.stop();
    _stopwatch = null;
    _timer?.cancel();
    _timer = null;

    _state = TrainingState.completed;
    _isPaused = false;

    if (!kIsWeb) {
      TimerService.stopService();
    }

    notifyListeners();
  }

  /// 重置训练
  void resetWorkout() {
    _stopwatch?.stop();
    _stopwatch = null;
    _timer?.cancel();
    _timer = null;

    _state = TrainingState.idle;
    _currentSet = 0;
    _exerciseTime = 0;
    _restRemaining = 0;
    _totalExerciseTime = 0;
    _totalRestTime = 0;
    _isPaused = false;

    if (!kIsWeb) {
      TimerService.stopService();
    }

    notifyListeners();
  }

  /// 获取训练数据
  Map<String, dynamic> getWorkoutData() {
    return {
      'totalSets': _currentSet,
      'totalExerciseTimeMs': _totalExerciseTime * 1000,
      'totalRestTimeMs': _totalRestTime * 1000,
    };
  }

  // Private methods

  void _startExerciseTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch != null) {
        _exerciseTime = _stopwatch!.elapsed.inSeconds;
        _updateServiceNotification();
        notifyListeners();
      }
    });
  }

  void _startRestTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining > 0) {
        _restRemaining--;
        _updateServiceNotification();
        notifyListeners();
      } else {
        // 休息结束，自动切换到下一组
        _totalRestTime += _restDuration;
        _transitionToNextSet();
      }
    });
  }

  void _transitionToNextSet() {
    _currentSet++;
    _state = TrainingState.exercising;
    _exerciseTime = 0;
    _isPaused = false;

    _stopwatch = Stopwatch()..start();
    _startExerciseTimer();

    // 发送通知提醒用户开始下一组
    if (!kIsWeb) {
      _notificationService.showNotification().catchError(
        (e) => debugPrint('Notification error: $e'),
      );
    }

    notifyListeners();
  }

  void _updateServiceNotification() {
    if (!kIsWeb) {
      String timeStr;
      if (_state == TrainingState.exercising || _state == TrainingState.exercisePaused) {
        final minutes = _exerciseTime ~/ 60;
        final seconds = _exerciseTime % 60;
        timeStr = '运动 ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        final minutes = _restRemaining ~/ 60;
        final seconds = _restRemaining % 60;
        timeStr = '休息 ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      TimerService.updateNotification(timeStr);
    }
  }

  @override
  void dispose() {
    _stopwatch?.stop();
    _timer?.cancel();
    super.dispose();
  }
}
