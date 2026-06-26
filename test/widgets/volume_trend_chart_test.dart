import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/volume_trend_charts.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to build a test widget with ThemeProvider and chart content
  Widget buildTestWidget(Widget child) {
    final themeProvider = ThemeProvider();
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: themeProvider)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('DailyVolumeChart', () {
    testWidgets('renders with daily volume data (LineChart)', (tester) async {
      // calculateDailyVolumeTrend returns Map<DateTime, double>
      final dailyData = <DateTime, double>{
        DateTime(2026, 6, 1): 500.0,
        DateTime(2026, 6, 2): 0.0,
        DateTime(2026, 6, 3): 700.0,
        DateTime(2026, 6, 4): 300.0,
        DateTime(2026, 6, 5): 900.0,
        DateTime(2026, 6, 6): 0.0,
        DateTime(2026, 6, 7): 600.0,
      };

      await tester.pumpWidget(
        buildTestWidget(DailyVolumeChart(data: dailyData)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyVolumeChart), findsOneWidget);
    });

    testWidgets('handles empty data without crash', (tester) async {
      final emptyData = <DateTime, double>{};

      await tester.pumpWidget(
        buildTestWidget(DailyVolumeChart(data: emptyData)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DailyVolumeChart), findsOneWidget);
    });
  });
}
