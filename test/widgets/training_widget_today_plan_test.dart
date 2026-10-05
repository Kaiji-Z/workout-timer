import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_plan.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/providers/timer_provider.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/training_widget.dart';

/// 今日排期感知：日历排了计划的当天，计时页空闲态应能看到并一键载入。
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.resetForTesting();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
  });

  WorkoutPlan planFixture({required String id, required String name}) {
    return WorkoutPlan(
      id: id,
      name: name,
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [
        PlanExercise(exerciseId: 'e1', targetSets: 3, order: 0),
      ],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Future<PlanProvider> pumpTraining(WidgetTester tester,
      {required WorkoutPlan plan, required DateTime scheduledDate}) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final planProvider = PlanProvider();
    await planProvider.createPlan(plan);
    await planProvider.assignPlanToDate(plan.id, scheduledDate);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: planProvider),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProgressProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: TrainingWidget()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    return planProvider;
  }

  testWidgets('今日有排期时空闲态显示今日计划 chip', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await pumpTraining(
      tester,
      plan: planFixture(id: 'plan-chip-1', name: '推举日'),
      scheduledDate: today,
    );

    expect(find.textContaining('今日计划'), findsOneWidget);
  });

  testWidgets('点今日计划 chip 一键进入该计划模式', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await pumpTraining(
      tester,
      plan: planFixture(id: 'plan-chip-2', name: '拉背日'),
      scheduledDate: today,
    );

    await tester.tap(find.textContaining('今日计划'));
    await tester.pump();

    final progress = tester.element(
      find.byType(TrainingWidget),
    ).read<TrainingProgressProvider>();
    expect(progress.currentPlan?.name, '拉背日');
  });

  testWidgets('非今日排期不显示 chip', (tester) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    await pumpTraining(
      tester,
      plan: planFixture(id: 'plan-chip-3', name: '腿日'),
      scheduledDate: tomorrow,
    );

    expect(find.textContaining('今日计划'), findsNothing);
  });
}
