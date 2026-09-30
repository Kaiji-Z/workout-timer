import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/widgets/stats_today_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    double? loadRatio,
    Map<PrimaryMuscleGroup, int> recency = const {},
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatsTodayCard(
            loadRatio: loadRatio,
            recency: recency,
            theme: amberGoldTheme,
          ),
        ),
      ),
    );
  }

  group('StatsTodayCard', () {
    testWidgets('shows ratio value, band label and per-muscle chips', (
      tester,
    ) async {
      await pumpCard(
        tester,
        loadRatio: 1.05,
        recency: const {
          PrimaryMuscleGroup.chest: 0,
          PrimaryMuscleGroup.back: 3,
          PrimaryMuscleGroup.legs: 10,
        },
      );

      expect(find.text('1.05'), findsOneWidget);
      expect(find.text('Normal range'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      // 恢复 chips：练过的三个 + 未练过的三个显示无数据
      expect(find.text('Chest · Today'), findsOneWidget);
      expect(find.text('Back · 3d ago'), findsOneWidget);
      expect(find.text('Legs · 10d ago'), findsOneWidget);
      // 未练过的三个肌群 chip 显示无数据
      expect(find.textContaining('No data'), findsNWidgets(3));
      // 护栏免责声明必须在场（ACWR 只作参考）
      expect(find.text('Guardrail reference, not injury prediction'),
          findsOneWidget);
    });

    testWidgets('shows no-baseline hint when ratio is null', (tester) async {
      await pumpCard(tester, loadRatio: null, recency: const {});
      expect(
        find.text('Not enough baseline beyond this week yet'),
        findsOneWidget,
      );
    });

    testWidgets('classifies high and low ratio bands', (tester) async {
      await pumpCard(tester, loadRatio: 1.5, recency: const {});
      expect(find.text('High · sustained spike'), findsOneWidget);

      await pumpCard(tester, loadRatio: 0.5, recency: const {});
      expect(find.text('Low · reduced load or returning'), findsOneWidget);
    });
  });
}
