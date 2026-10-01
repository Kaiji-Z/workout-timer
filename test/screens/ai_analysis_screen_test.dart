import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/screens/ai_analysis_screen.dart';
import 'package:workout_timer/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AI 分析页打开后自动生成提示词，不停留在"正在生成"占位',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AIAnalysisScreen(
              startDate: DateTime(2026, 9, 2),
              endDate: DateTime(2026, 10, 1),
              records: const [],
              previousRecords: const [],
              allRecords: const [],
            ),
          ),
        ),
      );

      // 首帧（initState）→ 偏好加载微任务 → 提示词生成后的重建
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining('Generating prompt'),
        findsNothing,
        reason: '提示词不应停留在"正在生成"占位状态',
      );
      expect(
        find.textContaining('You are a professional fitness coach'),
        findsOneWidget,
      );
    },
  );

  testWidgets('range tabs re-window records and regenerate the prompt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AIAnalysisScreen(
            startDate: DateTime(2026, 9, 2),
            endDate: DateTime(2026, 10, 1),
            records: const [],
            previousRecords: const [],
            allRecords: const [],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 初始 30 天窗口的周期行
    expect(find.textContaining('Last 30 days ('), findsOneWidget);

    // 切到 7 天标签页 → 报告与提示词都换成 7 天窗口
    await tester.tap(find.text('Last 7 days'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Last 7 days ('), findsOneWidget);
    expect(find.textContaining('Last 30 days ('), findsNothing);
  });
}
