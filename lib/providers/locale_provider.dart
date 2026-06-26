import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// User-facing language preference.
///
/// Three modes:
/// - `system` (default): follow the device locale, falling back to `zh`
///   when the device locale is not one of the supported locales (zh/en).
/// - `zh`: force Simplified Chinese.
/// - `en`: force English.
///
/// Mirrors [ThemeProvider]'s persistence pattern (ChangeNotifier +
/// SharedPreferences). Drives `MaterialApp.locale` via [effectiveLocale].
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  /// Supported language codes. Used only for `contains` membership checks
  /// and the unsupported-locale fallback; the canonical locale list lives in
  /// `AppLocalizations.supportedLocales` (which is `[en, zh]`).
  static const List<String> supportedCodes = ['zh', 'en'];

  String _localeCode = 'system';

  /// The stored preference: 'system', 'zh', or 'en'.
  String get localeCode => _localeCode;

  /// The [Locale] to actually apply to [MaterialApp].
  ///
  /// For 'system', resolves the device locale; if unsupported, falls back to
  /// Chinese (the app's primary audience).
  Locale get effectiveLocale {
    if (_localeCode == 'system') {
      // Read the device locale via the binding's dispatcher so tests can
      // override it via `TestWidgetsFlutterBinding.platformDispatcher.localeTestValue`.
      final device = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedCodes.contains(device.languageCode)) {
        return Locale(device.languageCode);
      }
      return const Locale('zh');
    }
    return Locale(_localeCode);
  }

  /// Load the persisted preference. Safe to call before [runApp].
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_localeKey);
      if (stored == 'system' || supportedCodes.contains(stored)) {
        _localeCode = stored!;
      }
    } catch (e) {
      debugPrint('Error loading locale preference: $e');
    }
    notifyListeners();
  }

  /// Persist and apply a new language code ('system' | 'zh' | 'en').
  Future<void> setLocaleCode(String code) async {
    if (code != 'system' && !supportedCodes.contains(code)) return;
    if (_localeCode == code) return;
    _localeCode = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, code);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
    notifyListeners();
  }
}
