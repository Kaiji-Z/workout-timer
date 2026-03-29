import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../services/workout_repository.dart';

class TimerProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final WorkoutRepository _repository = WorkoutRepository();

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isRunning = false;
  int _totalSets = 0;
  final int _totalPlannedSets = 5;
  int _currentSessionRestTime = 0;
  int _selectedPresetIndex = 1;
  DateTime? _sessionStartTime; // For accurate time tracking in background

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

  void selectPreset(int index) {
    if (_isRunning) return;
    _selectedPresetIndex = index;
    _remainingSeconds = presetTimes[index];
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _sessionStartTime =
        DateTime.now(); // Record start time for accurate tracking
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);

    if (!kIsWeb) {
      TimerService.startService();
      _updateServiceNotification();
    }
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    if (!kIsWeb) {
      TimerService.stopService();
    }
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _remainingSeconds = _initialSeconds;
    notifyListeners();
  }

  void newTimer() {
    pauseTimer();
    _remainingSeconds = _initialSeconds;
    _totalSets = 0;
    notifyListeners();
  }

  /// 刷新会话时长（从后台恢复时调用）
  void refreshDuration() {
    if (_isRunning && _sessionStartTime != null) {
      // Recalculate rest time from DateTime for accuracy
      _currentSessionRestTime = DateTime.now()
          .difference(_sessionStartTime!)
          .inSeconds;
      notifyListeners();
    }
  }

  void finishWorkout() async {
    if (_totalSets > 0) {
      try {
        await _repository.saveSession(_totalSets, _currentSessionRestTime);
      } catch (e) {
        debugPrint('Error saving session: $e');
      }
    }
    pauseTimer();
    _remainingSeconds = _initialSeconds;
    _totalSets = 0;
    _currentSessionRestTime = 0;
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (!_isRunning) return;

    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      _currentSessionRestTime++;
      _updateServiceNotification();
      notifyListeners();
    } else {
      _onTimerEnd();
    }
  }

  void _updateServiceNotification() {
    if (!kIsWeb) {
      final minutes = (_remainingSeconds / 60).floor();
      final seconds = _remainingSeconds % 60;
      final timeStr =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      TimerService.updateNotification('剩余 $timeStr');
    }
  }

  void _onTimerEnd() {
    pauseTimer();
    _totalSets++;
    if (!kIsWeb) {
      _notificationService.showNotification().catchError(
        (e) => debugPrint('Notification error: $e'),
      );
    }
    _remainingSeconds = _initialSeconds;
    notifyListeners();
  }

  void skipSet() {
    _onTimerEnd();
    if (_isRunning) startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
