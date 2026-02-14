import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workout_timer/main.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/screens/timer_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Timer Integration Tests', () {
    testWidgets('App launches and shows timer screen', (tester) async {
      // Launch the app
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      await tester.pumpWidget(MyApp(themeProvider: themeProvider));
      await tester.pumpAndSettle();

      // Verify initial state - timer screen shows
      expect(find.byType(TimerScreen), findsOneWidget);
      
      // Verify header is displayed
      expect(find.text('WORKOUT TIMER'), findsOneWidget);
    });

    testWidgets('Navigation to settings works', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      await tester.pumpWidget(MyApp(themeProvider: themeProvider));
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Should be on settings screen (check for switches)
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('Navigation to history works', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      await tester.pumpWidget(MyApp(themeProvider: themeProvider));
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history_outlined));
      await tester.pumpAndSettle();

      // Should be on history screen
      expect(find.text('WORKOUT HISTORY'), findsOneWidget);
    });
  });
}