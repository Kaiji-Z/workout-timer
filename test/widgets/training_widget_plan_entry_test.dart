import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/providers/timer_provider.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/training_widget.dart';

/// 计划入口引导：一次性角标 + 空计划库的「去创建」SnackBar。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
  });

  Future<void> pumpTraining(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProgressProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrainingWidget(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('从未打开计划选择器时入口显示角标', (tester) async {
    await pumpTraining(tester);

    expect(find.byType(Badge), findsOneWidget);
  });

  testWidgets('已打开过计划选择器时角标不再显示', (tester) async {
    SharedPreferences.setMockInitialValues({'plan_selector_opened': true});
    await pumpTraining(tester);

    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('空计划库点入口弹出带去创建动作的提示', (tester) async {
    await pumpTraining(tester);

    await tester.tap(find.byIcon(Icons.playlist_add_check));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(SnackBarAction), findsOneWidget);
  });
}
