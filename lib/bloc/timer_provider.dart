import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  int _currentSessionRestTime = 0;
  int _selectedPresetIndex = 1;

  final List<int> presetTimes = [30, 60, 90, 120];

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  int get totalSets => _totalSets;
  double get progress => _remainingSeconds / _initialSeconds;
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
      final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      TimerService.updateNotification('剩余 $timeStr');
    }
  }

  void _onTimerEnd() {
    pauseTimer();
    _totalSets++;
    if (!kIsWeb) {
      _notificationService.showNotification().catchError((e) => debugPrint('Notification error: $e'));
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
