import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/providers/timer_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/widgets/training_widget.dart';

void main() {
  setUpAll(() {
    // ServiceLocator must be initialized before Providers that resolve
    // dependencies via the registry (TimerProvider, PlanProvider, ...).
    ServiceLocator.setup();
  });

  testWidgets('TrainingWidget shows training screen', (
    WidgetTester tester,
  ) async {
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
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale("zh"),
          home: const TrainingWidget(),
        ),
      ),
    );

    // Allow widget to build
    await tester.pump(const Duration(seconds: 1));

    // Verify that the timer screen shows the start button
    expect(find.text('开始运动'), findsOneWidget);
  });
}
