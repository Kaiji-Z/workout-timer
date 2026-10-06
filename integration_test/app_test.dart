import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/main.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/screens/history_screen.dart';
import 'package:workout_timer/screens/settings_screen.dart';
import 'package:workout_timer/screens/timer_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// 启动冒烟：真实 MyApp 能启动、底部导航可切换。
/// 运行方式（模拟器/真机）：
///   `flutter test integration_test/app_test.dart -d <device>`
///
/// 注意：计时环是常驻动画，全程定长 pump，禁止 pumpAndSettle。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 测试不经过生产 main()，DI 注册表必须手动装配。
    ServiceLocator.setup();
  });

  setUp(() async {
    // 独立内存库 + 跳过首启引导，保证冒烟确定性。
    await DatabaseHelper.resetForTesting();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('plan_selector_opened', true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
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
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpFrames(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('App launches and shows timer screen', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TimerScreen), findsOneWidget);
  });

  testWidgets('Navigation to settings works', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await pumpFrames(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Navigation to history works', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.history_outlined));
    await pumpFrames(tester);

    expect(find.byType(HistoryScreen), findsOneWidget);
  });
}
