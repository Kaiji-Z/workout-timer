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
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/plan_detail_sheet.dart';

/// 构建单动作测试计划（无 Exercise 细节，详情表走序号占位渲染）。
WorkoutPlan planFixture({String id = 'plan-1', String name = '推举日'}) {
  return WorkoutPlan(
    id: id,
    name: name,
    targetMuscles: const [PrimaryMuscleGroup.chest],
    exercises: [
      PlanExercise(exerciseId: 'e1', targetSets: 3, order: 0),
      PlanExercise(exerciseId: 'e2', targetSets: 3, order: 1),
    ],
    createdAt: DateTime(2026, 1, 1),
  );
}

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

  Future<BuildContext> pumpSheetHarness(
    WidgetTester tester,
    WorkoutPlan plan,
  ) async {
    // 计划详情表在测试视口里整体偏低，surface 加高并预留底部余量保证按钮可点。
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProgressProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) =>
                          PlanDetailSheet(plan: plan, onAddToDate: () {}),
                    ),
                    child: const Text('open-sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return capturedContext;
  }

  testWidgets('开始训练激活计划模式', (tester) async {
    final plan = planFixture();
    final sheetContext = await pumpSheetHarness(tester, plan);
    final progress = sheetContext.read<TrainingProgressProvider>();

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(progress.currentPlan?.id, plan.id);
  });

  /// 打开详情表并点「开始训练」。tap 的手势在下一次 pump 才派发，
  /// 所以先 pump() 启动动画，再 pump(时长) 跑完。
  Future<void> openSheetAndTapStart(WidgetTester tester) async {
    await tester.tap(find.text('open-sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('开始训练'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('运动中开始训练先弹确认对话框', (tester) async {
    final plan = planFixture();
    final sheetContext = await pumpSheetHarness(tester, plan);
    final training = sheetContext.read<TrainingProvider>();
    final progress = sheetContext.read<TrainingProgressProvider>();

    training.startExercise();
    await tester.pump();

    await openSheetAndTapStart(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(progress.currentPlan, isNull);
  });

  testWidgets('运动中确认后丢弃进度并激活新计划', (tester) async {
    final plan = planFixture();
    final sheetContext = await pumpSheetHarness(tester, plan);
    final training = sheetContext.read<TrainingProvider>();
    final progress = sheetContext.read<TrainingProgressProvider>();

    training.startExercise();
    await tester.pump();

    await openSheetAndTapStart(tester);

    await tester.tap(find.text('结束并开始新计划'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.currentPlan?.id, plan.id);
    expect(training.isIdle, isTrue);
  });

  testWidgets('运动中取消则保持现状', (tester) async {
    final plan = planFixture();
    final sheetContext = await pumpSheetHarness(tester, plan);
    final training = sheetContext.read<TrainingProvider>();
    final progress = sheetContext.read<TrainingProgressProvider>();

    training.startExercise();
    await tester.pump();

    await openSheetAndTapStart(tester);

    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress.currentPlan, isNull);
    expect(find.byType(PlanDetailSheet), findsOneWidget);
  });
}
