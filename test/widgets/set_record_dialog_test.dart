import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/set_record_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Regression guard for the Save button contrast bug:
  /// The global `elevatedButtonTheme` sets `foregroundColor: accentColor` (deep
  /// indigo) for white circular icon buttons. Any ElevatedButton that fills
  /// with `accentColor` inherited that indigo TEXT — indigo text on an indigo
  /// fill = invisible (pixel-confirmed: zero white pixels in the button area).
  /// The Save button now uses FilledButton, whose foreground is white on the
  /// indigo fill. This test locks that in.
  testWidgets(
    'Save button renders white text on indigo background (contrast fixed)',
    (tester) async {
      final themeProvider = ThemeProvider();
      final accent = themeProvider.currentTheme.accentColor;
      final onAccent = themeProvider.currentTheme.onAccentColor;

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: themeProvider)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => SetRecordDialog.show(
                    context,
                    exerciseName: 'Bench Press',
                    setNumber: 1,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the dialog.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The Save button is now a FilledButton (not ElevatedButton).
      final saveFinder = find.byWidgetPredicate(
        (w) => w is FilledButton,
      );
      expect(saveFinder, findsOneWidget, reason: 'Save must be a FilledButton');

      // Its style resolves to the indigo accent fill + white foreground so the
      // label is readable (this is exactly what was broken before).
      final button = tester.widget<FilledButton>(saveFinder);
      final style = button.style ?? const ButtonStyle();
      final ctx = tester.element(saveFinder);
      final bg = style.backgroundColor?.resolve({}) ?? Colors.transparent;
      final fg = style.foregroundColor?.resolve({}) ?? Colors.transparent;

      expect(bg, accent, reason: 'Save background should be the indigo accent');
      expect(
        fg,
        onAccent,
        reason: 'Save text color must be white (onAccent), not indigo',
      );
    },
  );
}
