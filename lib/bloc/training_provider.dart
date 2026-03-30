import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import '../services/timer_service.dart';

/// 训练状态枚举
enum TrainingState {
  idle, // 空闲，未开始
  exercising, // 运动中（正向计时）
  exercisePaused, // 运动暂停
  resting, // 休息中（倒计时）
  completed, // 训练完成
}

/// 训练状态管理 Provider
class TrainingProvider extends ChangeNotifier {
  // 状态
  TrainingState _state = TrainingState.idle;
  int _currentSet = 0; // 当前组数
  int _restDuration = 60; // 休息时长（秒）
  int _restRemaining = 0; // 休息剩余时间（秒）
  int _exerciseTime = 0; // 运动时长（秒）
  int _totalExerciseTime = 0; // 总运动时长（秒）
  int _totalRestTime = 0; // 总休息时长（秒）
  bool _isPaused = false;

  // 计时器
  Timer? _timer;
  Timer? _sessionTimer; // Session timer for UI updates
  Stopwatch? _stopwatch;
  Stopwatch? _sessionStopwatch; // Runs continuously from start to end
  int _sessionDuration = 0; // Total session duration in seconds
  DateTime?
  _sessionStartTime; // When session started (for accurate time tracking)
  DateTime? _pauseStartTime; // When session was paused (to exclude paused time)
  DateTime? _restStartTime; // When rest period started (for accurate countdown)

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

  /// 总时长（秒）
  int get sessionDuration => _sessionDuration;

  /// 格式化的总时长 MM:SS
  String get sessionDurationFormatted {
    final minutes = _sessionDuration ~/ 60;
    final seconds = _sessionDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
    if (_state != TrainingState.idle && _state != TrainingState.completed)
      return;

    _state = TrainingState.exercising;
    _currentSet = 1;
    _exerciseTime = 0;
    _totalExerciseTime = 0;
    _totalRestTime = 0;
    _sessionDuration = 0;
    _isPaused = false;

    // Start session stopwatch (runs continuously)
    _sessionStopwatch = Stopwatch()..start();
    _sessionStartTime =
        DateTime.now(); // Record actual start time for accurate tracking
    _pauseStartTime = null;
    _startSessionTimer();

    // Start exercise stopwatch
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

    // Resume session stopwatch
    _sessionStopwatch?.start();
    _startSessionTimer();

    // Start new exercise stopwatch
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
    // 暂停session timer
    _sessionTimer?.cancel();
    _sessionTimer = null;
    // Fix: Also stop session stopwatch to prevent time accumulation during pause
    _sessionStopwatch?.stop();
    _pauseStartTime =
        DateTime.now(); // Record pause time to exclude from duration

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
    // Fix: Resume session stopwatch too, not just exercise stopwatch
    _pauseStartTime = null; // Clear pause time
    _sessionStopwatch?.start();
    _stopwatch = Stopwatch()..start();
    _startExerciseTimer();
    // 重新启动session timer
    _startSessionTimer();

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
    _restStartTime = DateTime.now(); // 记录休息开始时间，用于后台恢复
    _stopwatch?.stop();
    _timer?.cancel();
    _timer = null;
    // Note: Session stopwatch continues running

    _startRestTimer();

    if (!kIsWeb) {
      TimerService.startCountdown(duration: _restDuration, mode: 'rest');
    }

    notifyListeners();
  }

  /// 跳过休息
  void skipRest() {
    if (_state != TrainingState.resting) return;

    _timer?.cancel();
    _timer = null;

    if (!kIsWeb) {
      TimerService.stopCountdown();
    }

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

    // Stop session stopwatch
    _sessionStopwatch?.stop();
    // Calculate final duration using DateTime for accuracy (works after background)
    if (_sessionStartTime != null) {
      _sessionDuration = DateTime.now()
          .difference(_sessionStartTime!)
          .inSeconds;
    }
    _sessionTimer?.cancel();
    _sessionTimer = null;

    _state = TrainingState.completed;
    _isPaused = false;

    if (!kIsWeb) {
      TimerService.stopService();
      TimerService.stopCountdown();
    }

    notifyListeners();
  }

  /// 重置训练
  void resetWorkout() {
    _stopwatch?.stop();
    _stopwatch = null;
    _timer?.cancel();
    _timer = null;

    _sessionStopwatch?.stop();
    _sessionStopwatch = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    _state = TrainingState.idle;
    _currentSet = 0;
    _exerciseTime = 0;
    _restRemaining = 0;
    _totalExerciseTime = 0;
    _totalRestTime = 0;
    _sessionDuration = 0;
    _isPaused = false;

    if (!kIsWeb) {
      TimerService.stopService();
      TimerService.stopCountdown();
    }

    notifyListeners();
  }

  /// 获取训练数据
  Map<String, dynamic> getWorkoutData() {
    return {
      'totalSets': _currentSet,
      'totalExerciseTimeMs': _totalExerciseTime * 1000,
      'totalRestTimeMs': _totalRestTime * 1000,
      'sessionDurationMs': _sessionDuration * 1000,
    };
  }

  /// 刷新会话时长和休息倒计时（从后台恢复时调用）
  void refreshDuration() {
    if (_sessionStartTime != null && _pauseStartTime == null) {
      _sessionDuration = DateTime.now()
          .difference(_sessionStartTime!)
          .inSeconds;
    }

    // 修复休息倒计时：同步轮询 Kotlin 获取权威时间
    if (_state == TrainingState.resting && _restStartTime != null) {
      // Poll native timer synchronously-style (fire-and-forget async)
      if (!kIsWeb) {
        TimerService.getRemainingTime()
            .then((nativeState) {
              // State guard: only act if still resting (prevent double transition)
              if (_state != TrainingState.resting) return;

              if (nativeState['completed'] == true) {
                _timer?.cancel();
                _timer = null;
                _restRemaining = 0;
                _totalRestTime += _restDuration;
                _restStartTime = null;
                _transitionToNextSet();
              } else {
                final nativeRemaining = nativeState['remaining'] as int? ?? 0;
                if (nativeRemaining > 0) {
                  _restRemaining = nativeRemaining;
                  notifyListeners();
                }
              }
            })
            .catchError((e) {
              debugPrint('Native timer poll error on resume: $e');
            });
      }

      // Rebuild timer (Flutter #94094: Timer.periodic may be unresponsive after background)
      _timer?.cancel();
      _timer = null;
      _startRestTimer();

      // Don't check _restRemaining <= 0 here — let the async poll or
      // the rebuilt _startRestTimer handle it to avoid double transition
    }

    notifyListeners();
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

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Calculate duration from DateTime for accuracy (works in background)
      if (_sessionStartTime != null && _pauseStartTime == null) {
        _sessionDuration = DateTime.now()
            .difference(_sessionStartTime!)
            .inSeconds;
        _updateServiceNotification();
        notifyListeners();
      }
    });
  }

  void _startRestTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Poll native timer — single source of truth for rest countdown
      if (!kIsWeb) {
        try {
          final nativeState = await TimerService.getRemainingTime();
          _restRemaining = nativeState['remaining'] as int? ?? 0;

          // Native timer completed — transition with state guard
          if (nativeState['completed'] == true &&
              _state == TrainingState.resting) {
            _timer?.cancel();
            _timer = null;
            _restRemaining = 0;
            _totalRestTime += _restDuration;
            _restStartTime = null;
            _transitionToNextSet();
            return;
          }
        } catch (e) {
          debugPrint('Native timer poll error: $e');
        }
      } else {
        // Web fallback: use DateTime
        if (_restStartTime != null) {
          final elapsed = DateTime.now().difference(_restStartTime!).inSeconds;
          _restRemaining = (_restDuration - elapsed).clamp(0, _restDuration);
        }
      }

      if (_restRemaining > 0) {
        // Only update UI — Kotlin handles notification during rest
        notifyListeners();
      } else if (_state == TrainingState.resting) {
        // Fallback: Dart-detected completion (shouldn't happen if Kotlin is running)
        _timer?.cancel();
        _timer = null;
        _restRemaining = 0;
        _totalRestTime += _restDuration;
        _restStartTime = null;
        _transitionToNextSet();
      }
    });
  }

  void _transitionToNextSet() {
    _currentSet++;
    _state = TrainingState.exercising;
    _exerciseTime = 0;
    _isPaused = false;
    // Note: Session stopwatch continues running

    _stopwatch = Stopwatch()..start();
    _startExerciseTimer();

    // Resume exercise notification (Dart manages during exercise, Kotlin during rest)
    if (!kIsWeb) {
      _updateServiceNotification();
    }

    notifyListeners();
  }

  void _updateServiceNotification() {
    if (!kIsWeb && _state != TrainingState.resting) {
      // Only update during exercise — Kotlin handles rest notifications
      final timeStr = '运动 $sessionDurationFormatted';
      TimerService.updateNotification(timeStr);
    }
  }

  @override
  void dispose() {
    _stopwatch?.stop();
    _sessionStopwatch?.stop();
    _timer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}
