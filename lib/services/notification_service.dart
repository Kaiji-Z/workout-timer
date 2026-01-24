import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(settings);
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      rethrow; // This is critical for app startup
    }
  }

  Future<void> showNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      final customMessage = prefs.getString('custom_message') ?? '准备开始下一组！';

      // Sound notification
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: soundEnabled,
      );
      final NotificationDetails details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        0,
        '休息结束！',
        customMessage,
        details,
      );

      // Vibration
      if (vibrationEnabled) {
        try {
          final hasVibrator = await Vibration.hasVibrator() ?? false;
          if (hasVibrator) {
            await Vibration.vibrate(duration: 500);
          }
        } catch (e) {
          debugPrint('Vibration failed: $e');
          // Continue without vibration
        }
      }
    } catch (e) {
      debugPrint('Failed to show notification: $e');
      // Silently fail - don't crash the app
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      // Continue - permissions might still work
    }
  }
}