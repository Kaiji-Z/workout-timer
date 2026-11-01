import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/screens/user_preferences_screen.dart';
import 'package:workout_timer/services/user_preferences_service.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// 训练偏好页交互契约（一般 App 习惯）：
/// 1. 点选选项即时生效并静默保存——不逐次弹「偏好已保存」提示；
/// 2. 体重输入过程中不弹提示、不落盘，提交（失焦/键盘完成）后才保存；
/// 3. 保存必须真实落盘：service 层回读得到刚选的值（「弹了提示但没保存」回归守卫）；
/// 4. 重进页面恢复上次保存的值。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    final localeProvider = LocaleProvider();
    await localeProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: localeProvider),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const UserPreferencesScreen(),
        ),
      ),
    );
    // 页面异步 loadPreferences 完成并首帧渲染
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('点选训练目标：即时保存且不弹「偏好已保存」提示', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('减脂').first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 静默保存：逐次提示属于打扰，不允许出现
    expect(find.text('偏好已保存'), findsNothing);
    // 保存必须真实发生（端到端：UI 操作 → SharedPreferences 落盘）
    final prefs = await UserPreferencesService().loadPreferences();
    expect(prefs.goal, 'fat_loss');
  });

  testWidgets('体重输入：打字过程不弹提示，键盘完成后持久化', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '72.5');
    await tester.pump();
    // 输入中间态不弹保存提示、不落盘
    expect(find.text('偏好已保存'), findsNothing);
    expect((await UserPreferencesService().loadPreferences()).bodyWeight, 0.0);

    // 键盘「完成」提交
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('偏好已保存'), findsNothing);

    final prefs = await UserPreferencesService().loadPreferences();
    expect(prefs.bodyWeight, 72.5);
  });

  testWidgets('体重输入后直接点选其它项：体重随本次点选一并持久化', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '72.5');
    await tester.pump();

    // 不按键盘完成、体重框不失焦，直接点选训练目标（真实用户常见路径）
    await tester.tap(find.text('增肌').first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('偏好已保存'), findsNothing);

    final prefs = await UserPreferencesService().loadPreferences();
    expect(prefs.bodyWeight, 72.5);
    expect(prefs.goal, 'muscle_building');
  });

  testWidgets('重进页面恢复上次保存的偏好与体重', (tester) async {
    SharedPreferences.setMockInitialValues({
      'pref_goal': 'fat_loss',
      'pref_body_weight': 70.0,
    });
    await pumpScreen(tester);

    // 体重框回填已存值；goal chip 按已存值渲染（loadPreferences 路径）
    expect(find.text('70.0'), findsOneWidget);
    expect(find.text('减脂'), findsOneWidget);
  });
}
