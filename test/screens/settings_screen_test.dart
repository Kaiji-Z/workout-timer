import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/screens/settings_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// Regression tests for the language selector on the Settings screen.
///
/// Context: the selector was migrated from per-tile `RadioListTile` with
/// `groupValue` / `onChanged` (deprecated in Flutter 3.32+) to a single
/// `RadioGroup<String>` ancestor that owns the group state. The migration
/// changed where the tap callback lives, so a regression here would silently
/// break language switching — the user taps an option and nothing happens.
///
/// These tests pin the contract: tapping each option must call
/// `LocaleProvider.setLocaleCode` with the right value.
void main() {
  setUp(() {
    ServiceLocator.setup();
    // ThemeProvider.initialize + LocaleProvider.initialize both hit
    // SharedPreferences; mock it so the test doesn't hang on the platform
    // channel.
    SharedPreferences.setMockInitialValues({});
  });

  /// Pump the SettingsScreen with the providers it expects.
  Future<void> pumpSettings(
    WidgetTester tester, {
    required LocaleProvider localeProvider,
  }) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: localeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );

    // Settings screen loads preferences asynchronously in initState via
    // _loadSettings(): SharedPreferences + PackageInfo.fromPlatform() +
    // NotificationSoundService.init(). Pump long enough for all of those
    // microtasks to complete and trigger the final setState. Use a sequence
    // of pumps rather than pumpAndSettle to avoid getting stuck on any
    // ongoing animation.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Scroll the Language section into view (the settings list is long).
    final languageHeader = find.text('Language');
    if (languageHeader.evaluate().isNotEmpty) {
      await tester.ensureVisible(languageHeader);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('SettingsScreen language selector (RadioGroup regression)', () {
    testWidgets('renders all three language options', (tester) async {
      final lp = LocaleProvider();
      await lp.initialize();

      await pumpSettings(tester, localeProvider: lp);

      // The three option titles come from l10n keys
      // settingsLanguageSystem / settingsLanguageZh / settingsLanguageEn.
      expect(find.text('Follow system'), findsOneWidget);
      expect(find.text('简体中文'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('tapping "简体中文" updates LocaleProvider.localeCode', (tester) async {
      final lp = LocaleProvider();
      await lp.initialize();
      expect(lp.localeCode, 'system'); // sanity: starts at system

      await pumpSettings(tester, localeProvider: lp);

      // Tap the Chinese option. Use find.text on the title since multiple
      // RadioListTiles share the same type and value-type.
      await tester.tap(find.text('简体中文'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(lp.localeCode, 'zh',
          reason: 'tapping the Chinese option must switch localeCode to "zh"');
    });

    testWidgets('tapping "English" updates LocaleProvider.localeCode', (tester) async {
      final lp = LocaleProvider();
      await lp.initialize();

      await pumpSettings(tester, localeProvider: lp);

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(lp.localeCode, 'en');
    });

    testWidgets('tapping "Follow System" restores localeCode to system', (tester) async {
      final lp = LocaleProvider();
      await lp.initialize();

      // Start from a non-default state to make the regression visible.
      await lp.setLocaleCode('en');
      expect(lp.localeCode, 'en');

      await pumpSettings(tester, localeProvider: lp);

      await tester.tap(find.text('Follow system'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(lp.localeCode, 'system');
    });

    testWidgets('a previously-selected option persists across rebuilds', (tester) async {
      // Guards against a RadioGroup regression where the groupValue wiring
      // is wrong: in that case, no tile would render as "selected" and a
      // second tap on the same option would fire onChanged spuriously (or
      // never fire at all). The behavioral contract is what we care about.
      final lp = LocaleProvider();
      await lp.setLocaleCode('en');

      await pumpSettings(tester, localeProvider: lp);
      expect(lp.localeCode, 'en');

      // Tap a different option, then tap back. Both transitions must succeed.
      await tester.tap(find.text('简体中文'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lp.localeCode, 'zh');

      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lp.localeCode, 'en');
    });
  });
}
