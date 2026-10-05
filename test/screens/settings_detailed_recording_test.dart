import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/locale_provider.dart';
import 'package:workout_timer/screens/settings_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// 「详细记录模式」开关必须带说明文案——它决定保存计划训练时是否弹
/// 批量录入对话框，没有副标题用户无法预知行为。
void main() {
  setUp(() {
    ServiceLocator.setup();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('详细记录模式开关显示行为说明副标题', (tester) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('详细记录模式'), findsOneWidget);
    expect(
      find.text('保存计划训练时，弹窗批量核对每组的次数与重量'),
      findsOneWidget,
    );
  });
}
