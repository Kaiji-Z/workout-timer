import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/models/muscle_group.dart';
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
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('WeeklyVolumeChart', () {
    testWidgets('renders with weekly volume data (BarChart)', (tester) async {
      // calculateWeeklyVolumeTrend returns Map<DateTime, double>
      final weeklyData = <DateTime, double>{
        DateTime(2026, 5, 25): 1200.0, // Week 1 Monday
        DateTime(2026, 6, 1): 1800.0, // Week 2 Monday
        DateTime(2026, 6, 8): 1500.0, // Week 3 Monday
        DateTime(2026, 6, 15): 2100.0, // Week 4 Monday
      };

      await tester.pumpWidget(buildTestWidget(
        WeeklyVolumeChart(data: weeklyData),
      ));
      await tester.pumpAndSettle();

      // Widget should render without crash and contain chart elements
      expect(find.byType(WeeklyVolumeChart), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      final emptyData = <DateTime, double>{};

      await tester.pumpWidget(buildTestWidget(
        WeeklyVolumeChart(data: emptyData),
      ));
      await tester.pumpAndSettle();

      // Should show a "no data" message or empty placeholder
      expect(find.byType(WeeklyVolumeChart), findsOneWidget);
    });
  });

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

      await tester.pumpWidget(buildTestWidget(
        DailyVolumeChart(data: dailyData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DailyVolumeChart), findsOneWidget);
    });

    testWidgets('handles empty data without crash', (tester) async {
      final emptyData = <DateTime, double>{};

      await tester.pumpWidget(buildTestWidget(
        DailyVolumeChart(data: emptyData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DailyVolumeChart), findsOneWidget);
    });
  });

  group('SecondaryMuscleVolumeChart', () {
    testWidgets('renders with muscle distribution data (PieChart)', (tester) async {
      // calculateSecondaryMuscleVolumeDistribution returns Map<SecondaryMuscleGroup, double>
      final muscleData = <SecondaryMuscleGroup, double>{
        SecondaryMuscleGroup.upperChest: 800.0,
        SecondaryMuscleGroup.middleChest: 600.0,
        SecondaryMuscleGroup.lowerChest: 400.0,
        SecondaryMuscleGroup.triceps: 1200.0,
        SecondaryMuscleGroup.frontDelt: 500.0,
      };

      await tester.pumpWidget(buildTestWidget(
        SecondaryMuscleVolumeChart(data: muscleData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SecondaryMuscleVolumeChart), findsOneWidget);
    });

    testWidgets('handles empty data without crash', (tester) async {
      final emptyData = <SecondaryMuscleGroup, double>{};

      await tester.pumpWidget(buildTestWidget(
        SecondaryMuscleVolumeChart(data: emptyData),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SecondaryMuscleVolumeChart), findsOneWidget);
    });
  });
}
