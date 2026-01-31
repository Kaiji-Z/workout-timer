import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class TimerService {
  static const _channel = MethodChannel('com.example.workout_timer/timer_service');

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (e) {
      debugPrint('Failed to start service: $e');
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop service: $e');
    }
  }

  static Future<void> updateNotification(String time) async {
    try {
      await _channel.invokeMethod('updateNotification', {'time': time});
    } on PlatformException catch (e) {
      debugPrint('Failed to update notification: $e');
    }
  }
}
