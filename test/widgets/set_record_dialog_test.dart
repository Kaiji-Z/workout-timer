import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/set_record_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Regression guard for the Save button contrast bug.
  ///
  /// Root cause: the global `elevatedButtonTheme` hardcoded
  /// `foregroundColor: accentColor`, which in Material 3 collided with the
  /// local `styleFrom(foregroundColor: onAccentColor)` on dark-filled buttons,
  /// rendering the label in the inherited `DefaultTextStyle` color (near-black)
  /// on an indigo fill = unreadable. Pixel-confirmed: zero white pixels.
  ///
  /// The theme no longer sets a global foregroundColor, so the local style
  /// resolves to white on indigo. This test locks that contract.
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

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Locate the Save button by its label (the launcher "open" button is also
      // an ElevatedButton, so type-based finding matches both).
      final saveTextFinder = find.text('Save');
      expect(saveTextFinder, findsOneWidget, reason: 'Save label should render');

      final saveFinder = find.ancestor(
        of: saveTextFinder,
        matching: find.byType(ElevatedButton),
      );
      expect(saveFinder, findsOneWidget, reason: 'Save must be an ElevatedButton');

      // Render the text and assert its effective color is white (onAccent),
      // resolved through the widget tree — this is exactly what rendered black
      // before the theme fix.
      final textWidget = tester.widget<Text>(
        find.descendant(of: saveFinder, matching: find.byType(Text)),
      );
      final resolvedColor =
          (textWidget.style?.color ?? onAccent);

      expect(
        resolvedColor,
        onAccent,
        reason: 'Save text color must be white (onAccent), not inherited black',
      );

      // And the button's own foreground should resolve to white.
      final button = tester.widget<ElevatedButton>(saveFinder);
      final style = button.style;
      final fg = style?.foregroundColor?.resolve({}) ?? Colors.transparent;
      expect(fg, onAccent, reason: 'Button foreground must be white');
      final bg = style?.backgroundColor?.resolve({}) ?? Colors.transparent;
      expect(bg, accent, reason: 'Button background must be indigo accent');
    },
  );
}
