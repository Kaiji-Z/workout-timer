import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(settings);

      await _createNotificationChannel();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification() async {
    try {
      if (kIsWeb) return;

      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      final customMessage = prefs.getString('custom_message') ?? '准备开始下一组！';

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        vibrationPattern: vibrationEnabled ? Int64List.fromList([0, 500, 200, 500]) : null,
      );
      final NotificationDetails details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        0,
        '休息结束！',
        customMessage,
        details,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
    }
  }
}