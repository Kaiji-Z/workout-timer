import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/screens/ai_plan_wizard_screen.dart';
import 'package:workout_timer/screens/plan_form_screen.dart';
import 'package:workout_timer/screens/plan_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// 计划库为空时的引导：空卡片不应直接跳手动表单，应先弹 AI/手动二选一。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
  });

  Future<void> pumpPlanScreen(WidgetTester tester) async {
    // 日历占掉大半屏，加高视口让「添加今日计划」空卡片可点。
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
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
  }

  testWidgets('计划库为空时点空卡片弹二选一引导而非手动表单', (tester) async {
    await pumpPlanScreen(tester);

    await tester.tap(find.text('添加今日计划'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlanFormScreen), findsNothing);
    expect(find.text('还没有任何计划'), findsOneWidget);
    expect(find.text('用 AI 一分钟生成，或自己动手创建'), findsOneWidget);
    // AppBar 的 AI 入口 + 弹窗里的 AI 按钮各一个。
    expect(find.text('AI训练计划'), findsNWidgets(2));
    expect(find.text('创建新计划'), findsOneWidget);
  });

  testWidgets('二选一里选 AI 进入向导', (tester) async {
    await pumpPlanScreen(tester);

    await tester.tap(find.text('添加今日计划'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('AI训练计划').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(AIPlanWizardScreen), findsOneWidget);
    expect(find.byType(PlanFormScreen), findsNothing);
  });

  testWidgets('计划库按钮在空库时同样弹二选一引导', (tester) async {
    await pumpPlanScreen(tester);

    await tester.tap(find.text('📚 我的计划库'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlanFormScreen), findsNothing);
    expect(find.text('还没有任何计划'), findsOneWidget);
    expect(find.text('AI训练计划'), findsNWidgets(2));
  });
}
