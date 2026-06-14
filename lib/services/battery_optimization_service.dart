import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to check and request battery optimization whitelist on Android.
///
/// On Huawei/HarmonyOS and other aggressive OEMs, the system may suspend
/// foreground services when the app is backgrounded unless the user explicitly
/// allows background activity. This service provides:
/// - [isIgnoringBatteryOptimizations]: Check if app is whitelisted
/// - [requestIgnoreBatteryOptimizations]: Show system dialog to whitelist app
class BatteryOptimizationService {
  static const _channel = MethodChannel('com.kaiji.workouttimer/timer_service');

  /// Returns true if the app is already whitelisted from battery optimization.
  /// Returns false on web or non-Android platforms.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !defaultTargetPlatform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check battery optimization: $e');
      return false;
    }
  }

  /// Opens the system dialog asking user to whitelist the app.
  /// Returns true if the intent was successfully launched.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !defaultTargetPlatform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to request battery optimization: $e');
      return false;
    }
  }
}

/// Extension to check platform without importing dart:io.
extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
