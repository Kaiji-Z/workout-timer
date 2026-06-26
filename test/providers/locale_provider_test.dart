import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    // Ensure no per-test platformDispatcher locale mock leaks into the next.
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocaleTestValue();
  });

  group('LocaleProvider', () {
    test('defaults to system', () async {
      final p = LocaleProvider();
      await p.initialize();
      expect(p.localeCode, 'system');
    });

    test('explicit zh overrides system', () async {
      final p = LocaleProvider();
      await p.initialize();
      await p.setLocaleCode('zh');
      expect(p.localeCode, 'zh');
      expect(p.effectiveLocale, const Locale('zh'));
    });

    test('explicit en overrides system', () async {
      final p = LocaleProvider();
      await p.initialize();
      await p.setLocaleCode('en');
      expect(p.effectiveLocale, const Locale('en'));
    });

    test('persists localeCode across instances', () async {
      final p1 = LocaleProvider();
      await p1.initialize();
      await p1.setLocaleCode('en');
      final p2 = LocaleProvider();
      await p2.initialize();
      expect(p2.localeCode, 'en');
    });

    test('notifies listeners on change', () async {
      final p = LocaleProvider();
      await p.initialize();
      var notified = false;
      p.addListener(() => notified = true);
      await p.setLocaleCode('en');
      expect(notified, isTrue);
    });

    test('system is a valid option after explicit set', () async {
      final p = LocaleProvider();
      await p.initialize();
      await p.setLocaleCode('zh');
      await p.setLocaleCode('system');
      expect(p.localeCode, 'system');
    });

    test('system falls back to zh when device locale unsupported', () async {
      // Simulate an unsupported device locale (French).
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.localeTestValue = const Locale('fr');
      final p = LocaleProvider();
      await p.initialize();
      expect(p.effectiveLocale, const Locale('zh'));
    });

    test('system resolves to en when device locale is en', () async {
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.localeTestValue = const Locale('en');
      final p = LocaleProvider();
      await p.initialize();
      expect(p.effectiveLocale, const Locale('en'));
    });

    test('rejects unsupported locale codes', () async {
      final p = LocaleProvider();
      await p.initialize();
      await p.setLocaleCode('fr'); // ignored
      expect(p.localeCode, 'system');
    });
  });
}
