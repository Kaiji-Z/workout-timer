import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/service_locator.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Resolve the current [AppLocalizations] for service-layer use (services
  /// have no BuildContext). Reads the root locale registered in
  /// [ServiceLocator]; falls back to Chinese if not yet registered.
  AppLocalizations _currentLocalizations() {
    try {
      final locale = ServiceLocator.get<ValueNotifier<Locale>>().value;
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('zh'));
    }
  }

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notifications.initialize(settings: settings);

      await _createNotificationChannel();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'timer_channel',
        'Timer Notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> showNotification() async {
    try {
      if (kIsWeb) return;

      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      final l10n = _currentLocalizations();
      final customMessage =
          prefs.getString('custom_message') ?? l10n.notifNextSet;

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'timer_channel',
            'Timer Notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: soundEnabled,
            enableVibration: vibrationEnabled,
            vibrationPattern: vibrationEnabled
                ? Int64List.fromList([0, 500, 200, 500])
                : null,
            icon: '@drawable/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@drawable/ic_launcher',
            ),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id: 0,
        title: l10n.notifRestDone,
        body: customMessage,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true);
      } else if (!kIsWeb && Platform.isAndroid) {
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
    }
  }
}
