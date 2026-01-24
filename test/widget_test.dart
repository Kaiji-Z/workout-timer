// Basic Flutter widget test for Workout Timer app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/bloc/timer_provider.dart';
import 'package:workout_timer/screens/timer_screen.dart';

void main() {
  testWidgets('App loads and shows timer screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TimerProvider()),
        ],
        child: const MaterialApp(
          home: TimerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the timer screen is shown
    expect(find.text('健身计时器'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget); // Default 60 seconds
  });

  testWidgets('Timer buttons work', (WidgetTester tester) async {
    final timerProvider = TimerProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => timerProvider),
        ],
        child: const MaterialApp(
          home: TimerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap start button
    await tester.tap(find.text('开始'));
    await tester.pump();

    expect(timerProvider.isRunning, true);

    // Tap pause
    await tester.tap(find.text('暂停'));
    await tester.pump();

    expect(timerProvider.isRunning, false);
  });
}
