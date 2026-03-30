import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class TimerService {
  static const _channel = MethodChannel(
    'com.example.workout_timer/timer_service',
  );

  /// Callback for native timer tick events (called from Kotlin side)
  static void Function(Map<String, dynamic>)? onNativeTick;

  /// Initialize the MethodChannel to receive native → Flutter events.
  /// Call once at app startup (e.g., in main.dart).
  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTimerTick':
          if (call.arguments is Map) {
            final data = Map<String, dynamic>.from(call.arguments as Map);
            onNativeTick?.call(data);
          }
      }
    });
  }

  /// Start the foreground service notification only (no countdown).
  static Future<void> startService() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      debugPrint('Failed to start service: $e');
    }
  }

  /// Stop the foreground service.
  static Future<void> stopService() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop service: $e');
    }
  }

  /// Update the foreground service notification text.
  static Future<void> updateNotification(String time) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('updateNotification', {'time': time});
    } on PlatformException catch (e) {
      debugPrint('Failed to update notification: $e');
    }
  }

  /// Start native countdown timer with given duration and mode.
  /// [duration] in seconds. [mode] is "simple" or "rest".
  static Future<void> startCountdown({
    required int duration,
    String mode = 'simple',
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('startCountdown', {
        'duration': duration,
        'mode': mode,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to start countdown: $e');
    }
  }

  /// Stop the native countdown timer (service continues for notification).
  static Future<void> stopCountdown() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('stopCountdown');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop countdown: $e');
    }
  }

  /// Poll native timer state. Returns {remaining: int, completed: bool, mode: String}.
  static Future<Map<String, dynamic>> getRemainingTime() async {
    if (kIsWeb) return {'remaining': 0, 'completed': false, 'mode': 'none'};
    try {
      final result = await _channel.invokeMethod('getRemainingTime');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'remaining': 0, 'completed': false, 'mode': 'none'};
    } on PlatformException catch (e) {
      debugPrint('Failed to get remaining time: $e');
      return {'remaining': 0, 'completed': false, 'mode': 'none'};
    }
  }
}
