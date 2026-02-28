import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/bloc/timer_provider.dart';
import 'package:workout_timer/bloc/training_provider.dart';
import 'package:workout_timer/bloc/plan_provider.dart';
import 'package:workout_timer/bloc/training_progress_provider.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/training_widget.dart';

void main() {
  testWidgets('TrainingWidget shows training screen', (WidgetTester tester) async {
    // Create providers
    final themeProvider = ThemeProvider();
    final planProvider = PlanProvider();
    final trainingProvider = TrainingProvider();
    final progressProvider = TrainingProgressProvider();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: planProvider),
          ChangeNotifierProvider.value(value: trainingProvider),
          ChangeNotifierProvider.value(value: progressProvider),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
        ],
        child: const MaterialApp(home: TrainingWidget()),
      ),
    );

    // Allow widget to build
    await tester.pump(const Duration(seconds: 1));

    // Verify that the timer screen shows the start button
    expect(find.text('开始运动'), findsOneWidget);
  });
}
