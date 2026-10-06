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
import 'package:workout_timer/screens/plan_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/plan_detail_sheet.dart';

/// 计划页核心联动（验收标准 2/5 + 反向标准 1 的 UI 层守卫）：
/// 当日列表渲染 → 详情弹窗 → 添加到日历 → 列表联动 → 移除联动。
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
    // 每个测试独立内存库，避免跨测试主键冲突。
    await DatabaseHelper.resetForTesting();
  });

  WorkoutPlan planFixture({String id = 'plan-ui-1', String name = '推举日'}) {
    return WorkoutPlan(
      id: id,
      name: name,
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [PlanExercise(exerciseId: 'e1', targetSets: 3, order: 0)],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// 泵已排期的计划页。返回 provider 供断言。
  Future<PlanProvider> pumpSeededPlanScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final planProvider = PlanProvider();
    final plan = planFixture();
    await planProvider.createPlan(plan);
    final now = DateTime.now();
    await planProvider.assignPlanToDate(
      plan.id,
      DateTime(now.year, now.month, now.day),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: planProvider),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return planProvider;
  }

  testWidgets('当天已排期的计划在列表中渲染', (tester) async {
    await pumpSeededPlanScreen(tester);

    expect(find.text('推举日'), findsOneWidget);
    // 空态卡片不应同时出现
    expect(find.text('添加今日计划'), findsNothing);
  });

  testWidgets('详情弹窗添加到日历后关闭且列表仍只有一条', (tester) async {
    await pumpSeededPlanScreen(tester);

    // 打开详情
    await tester.tap(find.text('推举日'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailSheet), findsOneWidget);

    // 添加到日历（该计划已在今天，重复添加走去重路径）
    await tester.tap(find.text('添加到日历'));
    await tester.pumpAndSettle();

    // 弹窗已关闭，toast 已出现，列表仍恰好一条（无 Duplicate keys 崩溃）
    expect(find.byType(PlanDetailSheet), findsNothing);
    expect(find.textContaining('添加到'), findsOneWidget);
    expect(find.text('推举日'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('滑动移除排期后当日回到空态', (tester) async {
    await pumpSeededPlanScreen(tester);

    // Dismissible endToStart 滑动触发移除确认
    await tester.drag(find.text('推举日'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // 确认对话框
    expect(find.text('移除计划'), findsOneWidget);
    await tester.tap(find.text('移除'));
    await tester.pumpAndSettle();

    // 列表清空，空态卡片回归
    expect(find.text('推举日'), findsNothing);
    expect(find.text('添加今日计划'), findsOneWidget);
  });
}
