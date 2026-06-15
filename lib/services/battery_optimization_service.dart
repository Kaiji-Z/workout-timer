import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to check and request battery optimization whitelist on Android.
///
/// On Huawei/HarmonyOS and other aggressive OEMs, the system may suspend
/// foreground services when the app is backgrounded unless the user explicitly
/// allows background activity. This service provides:
/// - [isIgnoringBatteryOptimizations]: Check if app is whitelisted
/// - [requestIgnoreBatteryOptimizations]: Show system dialog to whitelist app
/// - [getOemManufacturer]: Detect Chinese OEM manufacturer (huawei/xiaomi/...)
/// - [isOemAutoStartAvailable]: Check if OEM-specific settings exist
/// - [requestOemAutoStart]: Open OEM-specific auto-start settings page
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

  /// Returns the OEM manufacturer name (e.g., "huawei", "xiaomi") or null for
  /// stock Android.
  ///
  /// Used to determine if OEM-specific battery settings are needed.
  static Future<String?> getOemManufacturer() async {
    if (kIsWeb || !defaultTargetPlatform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<String>('getOemManufacturer');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to get OEM manufacturer: $e');
      return null;
    }
  }

  /// Checks if OEM-specific auto-start/battery settings are available on this
  /// device.
  ///
  /// Returns true for Chinese OEMs (华为/小米/OPPO/vivo/魅族/三星/OnePlus).
  static Future<bool> isOemAutoStartAvailable() async {
    if (kIsWeb || !defaultTargetPlatform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('isOemAutoStartAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check OEM auto-start availability: $e');
      return false;
    }
  }

  /// Opens the OEM-specific auto-start/battery settings page.
  ///
  /// Returns true if the settings page was successfully opened.
  static Future<bool> requestOemAutoStart() async {
    if (kIsWeb || !defaultTargetPlatform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestOemAutoStart');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to request OEM auto-start: $e');
      return false;
    }
  }
}

/// Extension to check platform without importing dart:io.
extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
