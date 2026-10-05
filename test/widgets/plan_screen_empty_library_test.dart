import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/plan_provider.dart';
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
  });
}
