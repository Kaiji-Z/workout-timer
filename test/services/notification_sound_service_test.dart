import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This import will fail because NotificationSoundService does not exist yet.
import 'package:workout_timer/services/notification_sound_service.dart';

void main() {
  late NotificationSoundService soundService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    soundService = NotificationSoundService();
    await soundService.init();
  });

  group('getAvailableSounds', () {
    test('returns a list of at least 3 sound names', () {
      final sounds = soundService.getAvailableSounds();

      expect(sounds, isA<List<String>>());
      expect(sounds.length, greaterThanOrEqualTo(3));
      expect(sounds, containsAll(['default', 'beep', 'chime']));
    });
  });

  group('getSelectedSound', () {
    test('returns "default" when no selection has been made', () {
      final selected = soundService.getSelectedSound();

      expect(selected, equals('default'));
    });
  });

  group('setSelectedSound', () {
    test('persists the selection', () async {
      await soundService.setSelectedSound('beep');

      // Verify persistence by reading back from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_notification_sound'), equals('beep'));
    });

    test('getSelectedSound returns "beep" after selection', () async {
      await soundService.setSelectedSound('beep');

      expect(soundService.getSelectedSound(), equals('beep'));
    });
  });

  group('setSelectedSound validation', () {
    test('throws ArgumentError for unknown sound name', () async {
      expect(
        () => soundService.setSelectedSound('invalid'),
        throwsArgumentError,
      );
    });
  });

  group('getSoundDisplayName', () {
    test('returns human-readable name for "default"', () {
      final displayName = soundService.getSoundDisplayName('default');

      expect(displayName, equals('默认'));
    });
  });
}
