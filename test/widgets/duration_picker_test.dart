import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/duration_picker.dart';

void main() {
  Widget wrap(Widget child) => ChangeNotifierProvider<ThemeProvider>(
    create: (_) => ThemeProvider(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('renders one-tap preset chips for 30/60/90/120 seconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        DurationPicker(
          initialDurationSeconds: 60,
          onDurationSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('duration-preset-30')), findsOneWidget);
    expect(find.byKey(const Key('duration-preset-60')), findsOneWidget);
    expect(find.byKey(const Key('duration-preset-90')), findsOneWidget);
    expect(find.byKey(const Key('duration-preset-120')), findsOneWidget);
  });

  testWidgets('tapping a preset sets the value and confirm reports it', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      wrap(
        DurationPicker(
          initialDurationSeconds: 60,
          onDurationSelected: (s) => selected = s,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('duration-preset-120')));
    await tester.pump();
    // 预览行同步到 120s（en: "2 min"）
    expect(find.textContaining('2 min'), findsWidgets);

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(selected, 120);
  });
}
