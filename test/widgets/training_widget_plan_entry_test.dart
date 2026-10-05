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

  // TrainingWidget 内环是常驻动画，pumpAndSettle 永不收敛，固定 pump。
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
          // 生产环境 TimerScreen 用 Scaffold 包裹 TrainingWidget，
          // Snackbar 依赖它，测试保持一致。
          home: const Scaffold(body: TrainingWidget()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  /// Badge 组件始终存在，按「圆点是否可见」断言。
  Finder visiblePlanBadge() =>
      find.byWidgetPredicate((w) => w is Badge && w.isLabelVisible);

  testWidgets('从未打开计划选择器时入口显示角标', (tester) async {
    await pumpTraining(tester);

    expect(visiblePlanBadge(), findsOneWidget);
  });

  testWidgets('已打开过计划选择器时角标不再显示', (tester) async {
    // setMockInitialValues 只影响新实例；此文件前面测试已创建缓存实例，
    // 直接写入同一实例确保生效。
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('plan_selector_opened', true);
    await pumpTraining(tester);

    expect(visiblePlanBadge(), findsNothing);
  });

  testWidgets('空计划库点入口弹出带去创建动作的提示', (tester) async {
    await pumpTraining(tester);

    await tester.tap(find.byIcon(Icons.playlist_add_check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('去创建'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsOneWidget);

    // 等 Snackbar 自动消失，避免测试结束时残留悬挂 Timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('触发过一次选择器后角标消失', (tester) async {
    await pumpTraining(tester);
    expect(visiblePlanBadge(), findsOneWidget);

    await tester.tap(find.byIcon(Icons.playlist_add_check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(visiblePlanBadge(), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  });
}
