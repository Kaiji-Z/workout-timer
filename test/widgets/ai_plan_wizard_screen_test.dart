import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/screens/ai_plan_wizard_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/bloc/plan_provider.dart';

void main() {
  group('AIPlanWizardScreen Stats Analysis Mode', () {
    testWidgets('starts from step 3 in stats analysis mode', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: const MaterialApp(
            home: const AIPlanWizardScreen(
              statsAnalysisMode: true,
              generatedPrompt: 'Test prompt for AI analysis',
            ),
          ),
        ),
      );

      await tester.pump();

      // In stats analysis mode, should skip to step 3 (paste JSON)
      // The step indicator should show step 3 as current
      expect(find.text('粘贴JSON'), findsOneWidget);
    });

    testWidgets('displays generated prompt in step 2', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      
      const testPrompt = 'Test prompt content for AI analysis';
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => PlanProvider()),
          ],
          child: MaterialApp(
            home: AIPlanWizardScreen(
              statsAnalysisMode: true,
              generatedPrompt: testPrompt,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Should display the generated prompt
      expect(find.text(testPrompt), findsOneWidget);
    });

    testWidgets('shows normal wizard mode without statsAnalysisMode', (tester) async {
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

      await tester.pump();

      // In normal mode, should start from step 1
      expect(find.text('个人资料'), findsOneWidget);
    });
  });
}
