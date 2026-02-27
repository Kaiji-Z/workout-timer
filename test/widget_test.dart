import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/bloc/timer_provider.dart';
import 'package:workout_timer/bloc/training_provider.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/screens/timer_screen.dart';

void main() {
  testWidgets('App loads and shows training screen', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProvider()),
        ],
        child: const MaterialApp(
          home: TimerScreen(),
        ),
      ),
    );
    // Use pump with duration instead of pumpAndSettle for continuous animations
    await tester.pump(const Duration(seconds: 1));

    // Verify that the timer screen shows the header
    expect(find.text('WORKOUT TIMER'), findsOneWidget);
    // Verify the rest duration is displayed (default 60 seconds)
    // There are multiple "01:00" displays in iOS 26 design
    expect(find.text('01:00'), findsWidgets);
    
    // Verify the start button exists
    expect(find.text('开始运动'), findsOneWidget);
  });
}
