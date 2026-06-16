import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/service_locator.dart';
import '../services/error_reporter_service.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../services/workout_repository.dart';

class TimerProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  final WorkoutRepository _repository;
  final ErrorReporter _errorReporter;

  /// Dependencies default to the [ServiceLocator] registry for production use;
  /// tests pass mocks via this constructor.
  TimerProvider({
    NotificationService? notificationService,
    WorkoutRepository? repository,
    ErrorReporter? errorReporter,
  }) : _notificationService =
           notificationService ?? ServiceLocator.get<NotificationService>(),
       _repository = repository ?? ServiceLocator.get<WorkoutRepository>(),
       _errorReporter = errorReporter ?? ServiceLocator.get<ErrorReporter>();

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isRunning = false;
  int _totalSets = 0;
  final int _totalPlannedSets = 5;
  int _currentSessionRestTime = 0;
  int _selectedPresetIndex = 1;
  DateTime?
  _countdownStartTime; // When current countdown started (web fallback)
  int _countdownDuration =
      60; // Full duration of current countdown (web fallback)

  final List<int> presetTimes = [30, 60, 90, 120];

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  int get totalSets => _totalSets;
  int get totalPlannedSets => _totalPlannedSets;
  double get progress => _remainingSeconds / _initialSeconds;
  double get completedSetsRatio {
    if (_totalPlannedSets <= 0) return 0.0;
    return (_totalSets / _totalPlannedSets).clamp(0.0, 1.0);
  }

  int get _initialSeconds => presetTimes[_selectedPresetIndex];
  int get selectedPresetIndex => _selectedPresetIndex;

  /// Whether platform services (TimerService) are available.
  /// Returns false on web or when ServicesBinding is not initialized (e.g., unit tests).
  static bool get _canUsePlatformServices {
    if (kIsWeb) return false;
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  void selectPreset(int index) {
    if (_isRunning) return;
    _selectedPresetIndex = index;
    _remainingSeconds = presetTimes[index];
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _countdownStartTime = DateTime.now();
    _countdownDuration = _initialSeconds;
    _remainingSeconds = _initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);

    if (_canUsePlatformServices) {
      TimerService.startCountdown(duration: _initialSeconds, mode: 'simple');
    }
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    if (_canUsePlatformServices) {
      TimerService.stopCountdown();
    }
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _remainingSeconds = _initialSeconds;

    if (_canUsePlatformServices) {
      TimerService.stopService();
    }
    notifyListeners();
  }

  void newTimer() {
    pauseTimer();
    _remainingSeconds = _initialSeconds;
    _totalSets = 0;

    if (_canUsePlatformServices) {
      TimerService.stopService();
    }
    notifyListeners();
  }

  /// 刷新倒计时（从后台恢复时调用）
  /// 轮询 Kotlin 获取权威剩余时间，修复 Timer.periodic 后台冻结问题
  void refreshDuration() {
    if (!_isRunning) return;

    // Flutter #94094: Timer.periodic may be unresponsive after background
    _timer?.cancel();
    _timer = null;

    if (_canUsePlatformServices && _countdownStartTime != null) {
      TimerService.getRemainingTime()
          .then((nativeState) {
            // State guard: only act if still running (prevent double transition)
            if (!_isRunning) return;

            if (nativeState['completed'] == true) {
              _onTimerEnd();
              return;
            }

            final nativeRemaining = nativeState['remaining'] as int? ?? 0;
            if (nativeRemaining > 0) {
              _remainingSeconds = nativeRemaining;
              _currentSessionRestTime = _countdownDuration - nativeRemaining;
              // Restart polling timer
              _timer = Timer.periodic(const Duration(seconds: 1), _tick);
              notifyListeners();
            }
          })
          .catchError((e) {
            debugPrint('Native timer poll error on resume: $e');
            // Fallback: restart polling timer anyway
            _timer = Timer.periodic(const Duration(seconds: 1), _tick);
          });
    } else {
      // Web fallback: recalculate from DateTime
      if (_countdownStartTime != null) {
        final elapsed = DateTime.now()
            .difference(_countdownStartTime!)
            .inSeconds;
        _remainingSeconds = (_countdownDuration - elapsed).clamp(
          0,
          _countdownDuration,
        );
        _currentSessionRestTime = elapsed.clamp(0, _countdownDuration);
      }
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      notifyListeners();
    }
  }

  void finishWorkout() async {
    if (_totalSets > 0) {
      try {
        await _repository.saveSession(_totalSets, _currentSessionRestTime);
      } catch (e, st) {
        // Data-loss path: the user's completed workout may not be saved.
        // Surface a warning instead of failing silently.
        _errorReporter.report(
          e,
          severity: ErrorSeverity.userWarning,
          stackTrace: st,
          message: '训练记录保存失败，请检查后重试',
        );
      }
    }
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = _initialSeconds;
    _totalSets = 0;
    _currentSessionRestTime = 0;
    _countdownStartTime = null;

    if (_canUsePlatformServices) {
      TimerService.stopCountdown();
      TimerService.stopService();
    }
    notifyListeners();
  }

  void _tick(Timer timer) async {
    if (!_isRunning) return;

    if (_canUsePlatformServices) {
      // Poll native timer — single source of truth for countdown
      try {
        final nativeState = await TimerService.getRemainingTime();
        _remainingSeconds = nativeState['remaining'] as int? ?? 0;

        // Native timer completed
        if (nativeState['completed'] == true && _isRunning) {
          _onTimerEnd();
          return;
        }
      } catch (e) {
        debugPrint('Native timer poll error: $e');
      }
    } else {
      // Web fallback: DateTime-based calculation
      if (_countdownStartTime != null) {
        final elapsed = DateTime.now()
            .difference(_countdownStartTime!)
            .inSeconds;
        _remainingSeconds = (_countdownDuration - elapsed).clamp(
          0,
          _countdownDuration,
        );
      }
    }

    _currentSessionRestTime++;

    if (_remainingSeconds <= 0 && _isRunning) {
      _onTimerEnd();
    } else {
      notifyListeners();
    }
  }

  void _onTimerEnd() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _totalSets++;
    _countdownStartTime = null;

    if (_canUsePlatformServices) {
      TimerService.stopCountdown();
      TimerService.stopService();
      _notificationService.showNotification().catchError(
        (e) => debugPrint('Notification error: $e'),
      );
    }
    _remainingSeconds = _initialSeconds;
    notifyListeners();
  }

  void skipSet() {
    _onTimerEnd();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_canUsePlatformServices) {
      TimerService.stopCountdown();
      TimerService.stopService();
    }
    super.dispose();
  }
}
