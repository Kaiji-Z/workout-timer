import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/main.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_plan.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/screens/plan_screen.dart';
import 'package:workout_timer/screens/timer_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/plan_detail_sheet.dart';
import 'package:workout_timer/widgets/set_record_dialog.dart';

/// 端到端验收（VERIFICATION.md §8.5）：
/// 1. 自由训练全流程：开始 → 结束 → 保存 → 历史可见（验收 4 / 反向 4）
/// 2. 计划训练全流程：今日 chip 一键载入（验收 1）→ 计划模式（验收 2）→
///    组记录对话框（验收 3）→ 保存 → 历史可见（验收 4）
/// 3. 计划详情「开始训练」进入计划模式（验收 2）
///
/// 运行方式（模拟器/真机）：
///   `flutter test integration_test/training_flow_e2e_test.dart -d <device>`
///
/// 注意：计时环是常驻动画，本文件全程用定长 pump，禁止 pumpAndSettle。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 测试不经过生产 main()，DI 注册表必须手动装配。
    ServiceLocator.setup();
  });

  /// 每个用例独立内存库 + 固定偏好，保证确定性。
  Future<void> pumpApp(WidgetTester tester) async {
    await DatabaseHelper.resetForTesting();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('plan_selector_opened', true);
    await prefs.setBool('detailed_recording', false);

    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final localeProvider = LocaleProvider();
    await localeProvider.initialize();

    await tester.pumpWidget(
      MyApp(
        themeProvider: themeProvider,
        localeProvider: localeProvider,
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      ),
    );
    // 多段短 pump：跳过启动帧与 l10n/DB 异步加载，避开常驻动画。
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  WorkoutPlan planFixture({String id = 'e2e-plan', String name = '推举日'}) {
    return WorkoutPlan(
      id: id,
      name: name,
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [
        PlanExercise(
          exerciseId: 'e1',
          targetSets: 1,
          order: 0,
          unmatchedName: '深蹲',
        ),
      ],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  testWidgets('自由训练：开始→结束→保存→历史可见', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TimerScreen), findsOneWidget);

    await tester.tap(find.text('开始运动'));
    await tester.pump(const Duration(milliseconds: 500));

    // 结束训练（红色 stop 圆钮）
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump(const Duration(milliseconds: 500));

    // 完成态 → 保存
    await tester.tap(find.text('保存'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('训练已保存'), findsOneWidget);

    // 历史页可检索到记录
    await tester.tap(find.text('历史记录'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('暂无记录'), findsNothing);
  });

  testWidgets('计划训练：今日chip→计划模式→组记录→保存→历史可见', (tester) async {
    await pumpApp(tester);

    // 通过应用自身的 PlanProvider 播种今天排期
    final planProvider = tester
        .element(find.byType(TimerScreen))
        .read<PlanProvider>();
    await planProvider.createPlan(planFixture());
    final now = DateTime.now();
    await planProvider.assignPlanToDate(
      'e2e-plan',
      DateTime(now.year, now.month, now.day),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 验收 1：今日计划 chip 一键载入
    await tester.tap(find.textContaining('今日计划'));
    await tester.pump(const Duration(milliseconds: 500));

    // 验收 2：进入计划模式（状态徽章带计划名）
    expect(find.textContaining('推举日'), findsWidgets);

    await tester.tap(find.text('开始运动'));
    await tester.pump(const Duration(milliseconds: 500));

    // 验收 3：休息触发该组记录对话框
    await tester.tap(find.text('休息'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SetRecordDialog), findsOneWidget);

    // 跳过录入 → 全部组完成 → 结束 → 完成态
    await tester.tap(find.text('跳过'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('保存'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('训练已保存'), findsOneWidget);

    // 验收 4：历史页可见记录
    await tester.tap(find.text('历史记录'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('暂无记录'), findsNothing);
  });

  testWidgets('计划详情开始训练进入计划模式', (tester) async {
    await pumpApp(tester);

    final planProvider = tester
        .element(find.byType(TimerScreen))
        .read<PlanProvider>();
    await planProvider.createPlan(planFixture());
    final now = DateTime.now();
    await planProvider.assignPlanToDate(
      'e2e-plan',
      DateTime(now.year, now.month, now.day),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 切到计划页，打开详情
    await tester.tap(find.text('训练计划'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PlanScreen), findsOneWidget);
    await tester.tap(find.text('推举日'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PlanDetailSheet), findsOneWidget);

    // 开始训练 → 回到计时页且处于计划模式
    await tester.tap(find.text('开始训练'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(TimerScreen), findsOneWidget);
    expect(find.textContaining('推举日'), findsWidgets);

    // 计划模式下开始运动后出现动作进度（紧凑进度行 + 动作名徽章）
    await tester.tap(find.text('开始运动'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('深蹲'), findsWidgets);

    // 收尾：结束并保存，避免悬挂会话
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('跳过'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('保存'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
