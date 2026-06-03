import 'package:shared_preferences/shared_preferences.dart';

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

  static const Map<String, String> _displayNames = {
    'default': '默认',
    'beep': '哔声',
    'chime': '铃声',
    'bell': '钟声',
    'whistle': '哨声',
  };

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

  /// Returns a human-readable display name for the given sound identifier.
  String getSoundDisplayName(String name) {
    return _displayNames[name] ?? name;
  }
}
