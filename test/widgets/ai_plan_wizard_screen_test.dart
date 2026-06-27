import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/screens/ai_plan_wizard_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/providers/plan_provider.dart';

void main() {
  setUp(() {
    // ServiceLocator must be initialized because PlanProvider resolves its
    // PlanRepository dependency from the registry.
    ServiceLocator.setup();
    SharedPreferences.setMockInitialValues({
      'pref_goal': 'muscle_building',
      'pref_experience': 'intermediate',
      'pref_equipment': 'gym',
      'pref_frequency': 4,
      'pref_focus_areas': '',
    });
  });

  group('AIPlanWizardScreen', () {
    testWidgets('starts from step 1 (Profile) in default mode', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In default mode, should start from step 1
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows New plan and Import analysis tabs', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show both tab options
      expect(find.text('New plan'), findsOneWidget);
      expect(find.text('Import analysis'), findsOneWidget);
    });

    testWidgets('switches to Import analysis tab on tap', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Import analysis tab
      await tester.tap(find.text('Import analysis'));
      await tester.pumpAndSettle();

      // Should show import form
      expect(find.text('Import AI-analyzed plan'), findsOneWidget);
    });
  });
}
