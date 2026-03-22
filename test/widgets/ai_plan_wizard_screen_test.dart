import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/screens/ai_plan_wizard_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/bloc/plan_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'pref_goal': 'muscle_building',
      'pref_experience': 'intermediate',
      'pref_equipment': 'gym',
      'pref_frequency': 4,
      'pref_focus_areas': '',
    });
  });

  group('AIPlanWizardScreen', () {
    testWidgets('starts from step 1 (个人资料) in default mode', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: const MaterialApp(
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In default mode, should start from step 1
      expect(find.text('个人资料'), findsOneWidget);
    });

    testWidgets('shows 新建计划 and 导入分析 tabs', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: const MaterialApp(
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show both tab options
      expect(find.text('新建计划'), findsOneWidget);
      expect(find.text('导入分析'), findsOneWidget);
    });

    testWidgets('switches to 导入分析 tab on tap', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: const MaterialApp(
            home: const AIPlanWizardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the 导入分析 tab
      await tester.tap(find.text('导入分析'));
      await tester.pumpAndSettle();

      // Should show import form
      expect(find.text('导入AI分析计划'), findsOneWidget);
    });
  });
}
