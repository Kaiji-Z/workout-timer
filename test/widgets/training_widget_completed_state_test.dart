import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_plan.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/providers/timer_provider.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/plan_card.dart';
import 'package:workout_timer/widgets/training_widget.dart';

import '../helpers/test_fixtures.dart';

/// 回归：计划模式训练完成后，顶部计划进行栏应消失（奖牌收尾，不再压住进度行）。
void main() {
  const timerChannel = MethodChannel('com.kaiji.workouttimer/timer_service');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
    // TrainingProvider.startExercise 会触发前台服务 MethodChannel，测试里 mock 掉。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timerChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timerChannel, null);
  });

  WorkoutPlan planWithOneExercise() {
    final exercise = sampleExercises.first;
    return WorkoutPlan(
      id: 'plan-test',
      name: '测试计划',
      targetMuscles: [PrimaryMuscleGroup.chest],
      createdAt: DateTime(2026, 1, 1),
      exercises: [
        PlanExercise(
          exerciseId: exercise.id,
          exercise: exercise,
          targetSets: 4,
          order: 0,
        ),
      ],
    );
  }

  // TrainingWidget 内环是常驻动画，pumpAndSettle 永不收敛，固定 pump。
  // TrainingProvider 用 create 注册：树销毁时 dispose 会取消秒表计时器，
  // 否则测试结束残留 pending Timer（.value 不负责 dispose）。
  Future<TrainingProvider> pumpPlanTraining(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final progress = TrainingProgressProvider();
    progress.startPlan(planWithOneExercise());

    late final TrainingProvider training;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) {
            training = TrainingProvider();
            return training;
          }),
          ChangeNotifierProvider.value(value: progress),
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

    training.startExercise();
    await tester.pump(const Duration(milliseconds: 100));
    return training;
  }

  testWidgets('计划模式运动中显示计划进行栏', (tester) async {
    final training = await pumpPlanTraining(tester);

    expect(find.byType(PlanProgressCompact), findsOneWidget);

    // endWorkout 取消秒表计时器，避免测试结束残留 pending Timer。
    training.endWorkout();
    // 奖牌入场动画链（Future.delayed 序列）每步需要一帧推进，多次小步 pump 冲干净。
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });

  testWidgets('训练完成后计划进行栏消失', (tester) async {
    final training = await pumpPlanTraining(tester);
    expect(find.byType(PlanProgressCompact), findsOneWidget);

    training.endWorkout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(training.isCompleted, isTrue);

    // 回归点：完成态由奖牌收尾，顶部计划进行栏退场
    expect(find.byType(PlanProgressCompact), findsNothing);

    // 冲洗奖牌入场动画链，避免测试结束残留 pending Timer。
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  });
}
