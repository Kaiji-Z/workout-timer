import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/screens/ai_plan_wizard_screen.dart';
import 'package:workout_timer/screens/user_preferences_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// AI 向导第一步应说明选项来源：偏好已定制显示「已预填」，仍为默认则引导去完善。
void main() {
  setUp(() {
    ServiceLocator.setup();
  });

  Future<void> pumpWizard(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AIPlanWizardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('偏好仍为默认值时提示先完善训练偏好', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpWizard(tester);

    expect(find.text('想让 AI 更懂你？先完善训练偏好'), findsOneWidget);
    expect(find.text('去设置'), findsOneWidget);
  });

  testWidgets('偏好已定制时显示已预填说明', (tester) async {
    SharedPreferences.setMockInitialValues({
      'pref_goal': 'fat_loss',
      'pref_experience': 'advanced',
      'pref_equipment': 'bodyweight',
      'pref_frequency': 5,
      'pref_focus_areas': 'core',
    });
    await pumpWizard(tester);

    expect(find.text('已从你的训练偏好预填'), findsOneWidget);
    expect(find.text('去设置'), findsNothing);
  });

  testWidgets('去设置跳转训练偏好页', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpWizard(tester);

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();

    expect(find.byType(UserPreferencesScreen), findsOneWidget);
  });
}
