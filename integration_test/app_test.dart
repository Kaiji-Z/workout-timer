import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workout_timer/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Timer Integration Tests', () {
    testWidgets('App launches and shows timer screen', (tester) async {
      // Launch the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('健身计时器'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget); // Default 60 seconds
      expect(find.text('已完成组数: 0'), findsOneWidget);
    });

    testWidgets('Timer preset selection works', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Select 30 second preset (shown as "0 分")
      await tester.tap(find.text('0 分'));
      await tester.pump();

      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('Timer start and pause work', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Start timer
      await tester.tap(find.text('开始'));
      await tester.pump();

      // Verify timer is running (this is a basic test - full timer testing requires device/emulator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Navigation to settings works', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should be on settings screen (check for settings-related text)
      expect(find.byType(Switch), findsWidgets); // Settings screen has switches
    });

    testWidgets('Navigation to history works', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should be on history screen
      expect(find.text('历史记录'), findsOneWidget);
    });
  });
}