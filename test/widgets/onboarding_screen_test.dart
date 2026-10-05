import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/main.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/providers/record_provider.dart';
import 'package:workout_timer/providers/timer_provider.dart';
import 'package:workout_timer/providers/training_progress_provider.dart';
import 'package:workout_timer/providers/training_provider.dart';
import 'package:workout_timer/screens/onboarding_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// 首次启动三页轮播引导：未完成时首启显示；跳过或完成都要置位标记。
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

  /// MainNavigation 完整 harness——引导从主框架之上弹出。
  /// 注意：不要在这里调 loadPlans/loadRecords——它们会触发
  /// ExerciseService 资产加载，在 flutter_tester 中会挂死；
  /// 引导流程不依赖计划/记录数据。
  Future<void> pumpApp(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final localeProvider = LocaleProvider();
    await localeProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProvider()),
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => RecordProvider()),
          ChangeNotifierProvider(create: (_) => TrainingProgressProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainNavigation(),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// 直接泵引导页（验证页内内容与翻页）。
  Future<void> pumpOnboarding(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('首启未完成引导时自动弹出引导页', (tester) async {
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('已完成引导后不再弹出', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await pumpApp(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('三页内容可翻到最后一页并出现 CTA', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text('组间休息，交给倒计时'), findsOneWidget);

    // tap 手势在下一次 pump 才派发，先 pump() 启动翻页动画再跑完。
    await tester.tap(find.text('下一步'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('按计划训练，不乱练'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('每组都算数'), findsOneWidget);
    expect(find.text('去创建第一个计划'), findsOneWidget);
  });

  testWidgets('跳过后标记完成并关闭引导', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('跳过'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingScreen), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isTrue);
  });
}
