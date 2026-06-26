import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/service_locator.dart';
import '../l10n/app_localizations.dart';

/// Manages notification sound selection and persistence.
class NotificationSoundService {
  static const String _prefsKey = 'selected_notification_sound';

  static const List<String> _availableSounds = [
    'default',
    'beep',
    'chime',
    'bell',
    'whistle',
  ];

  late SharedPreferences _prefs;

  /// Initializes the service by loading SharedPreferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Returns the list of available notification sound identifiers.
  List<String> getAvailableSounds() => List.unmodifiable(_availableSounds);

  /// Returns the currently selected sound name.
  /// Defaults to 'default' if no selection has been made.
  String getSelectedSound() {
    return _prefs.getString(_prefsKey) ?? 'default';
  }

  /// Persists the selected sound name.
  /// Throws [ArgumentError] if [name] is not in [getAvailableSounds].
  Future<void> setSelectedSound(String name) async {
    if (!_availableSounds.contains(name)) {
      throw ArgumentError('Unknown notification sound: $name');
    }
    await _prefs.setString(_prefsKey, name);
  }

  /// Resolve the current [AppLocalizations] for service-layer use (no
  /// BuildContext available). Falls back to Chinese if not registered yet.
  AppLocalizations _currentLocalizations() {
    try {
      final locale = ServiceLocator.get<ValueNotifier<Locale>>().value;
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('zh'));
    }
  }

  /// Returns a human-readable, locale-aware display name for the given sound
  /// identifier.
  ///
  /// Note: the internal sound ids predate localization and don't line up 1:1
  /// with the ARB key suffixes — `chime` renders as the "ring" label and
  /// `bell` as the "chime" label, matching the original Chinese semantics.
  String getSoundDisplayName(String name) {
    final l10n = _currentLocalizations();
    switch (name) {
      case 'default':
        return l10n.soundDefault;
      case 'beep':
        return l10n.soundBeep;
      case 'chime':
        return l10n.soundRing;
      case 'bell':
        return l10n.soundChime;
      case 'whistle':
        return l10n.soundWhistle;
      default:
        return name;
    }
  }
}

