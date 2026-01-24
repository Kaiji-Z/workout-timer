import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/workout_repository.dart';

class TimerProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final WorkoutRepository _repository = WorkoutRepository();

  // Timer state
  Timer? _timer;
  int _remainingSeconds = 60; // Default 1 min
  bool _isRunning = false;
  int _totalSets = 0;
  int _currentSessionRestTime = 0;

  // Preset times in seconds
  final List<int> presetTimes = [30, 60, 90, 120];

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  int get totalSets => _totalSets;
  double get progress => _remainingSeconds / _initialSeconds;
  int get _initialSeconds => presetTimes.contains(_remainingSeconds) ? _remainingSeconds : 60;

  void selectPreset(int seconds) {
    if (_isRunning) return;
    _remainingSeconds = seconds;
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning || _timer != null) return;

    try {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting timer: $e');
      _isRunning = false;
      _timer = null;
      notifyListeners();
    }
  }

  void pauseTimer() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _remainingSeconds = _initialSeconds;
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (!_isRunning) return; // Safety check

    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      _currentSessionRestTime++;
      notifyListeners();
    } else {
      _onTimerEnd();
    }
  }

  void _onTimerEnd() {
    pauseTimer();
    _totalSets++;
    _notificationService.showNotification().catchError((e) => debugPrint('Error showing notification: $e'));
    _saveSession().catchError((e) => debugPrint('Error saving session: $e'));
    // Reset for next set
    _remainingSeconds = _initialSeconds;
    notifyListeners();
  }

  Future<void> _saveSession() async {
    await _repository.saveSession(_totalSets, _currentSessionRestTime * 1000);
    _currentSessionRestTime = 0;
  }

  void skipToNextSet() {
    _onTimerEnd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}