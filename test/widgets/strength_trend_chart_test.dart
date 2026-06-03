import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/widgets/strength_trend_chart.dart';

void main() {
  group('StrengthTrendChart', () {
    late List<StrengthDataPoint> sampleData;

    setUp(() {
      sampleData = [
        StrengthDataPoint(
          date: DateTime(2026, 5, 1),
          weight: 60,
          estimated1RM: 68,
        ),
        StrengthDataPoint(
          date: DateTime(2026, 5, 8),
          weight: 65,
          estimated1RM: 74,
        ),
        StrengthDataPoint(
          date: DateTime(2026, 5, 15),
          weight: 70,
          estimated1RM: 80,
        ),
        StrengthDataPoint(
          date: DateTime(2026, 5, 22),
          weight: 72.5,
          estimated1RM: 83,
        ),
      ];
    });

    Widget buildSubject({
      List<StrengthDataPoint>? dataPoints,
      String exerciseName = '杠铃深蹲',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StrengthTrendChart(
            dataPoints: dataPoints ?? sampleData,
            exerciseName: exerciseName,
          ),
        ),
      );
    }

    testWidgets('renders without error when given valid strength trend data',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Widget should render without throwing
      expect(find.byType(StrengthTrendChart), findsOneWidget);
    });

    testWidgets('displays exercise name', (tester) async {
      await tester.pumpWidget(buildSubject(exerciseName: '杠铃卧推'));

      expect(find.text('杠铃卧推'), findsOneWidget);
    });

    testWidgets('handles empty data gracefully - shows empty state message',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          dataPoints: [],
        ),
      );

      // Should show some indication that there's no data
      expect(find.byType(StrengthTrendChart), findsOneWidget);
      // Empty state message should be visible
      expect(find.textContaining('暂无'), findsOneWidget);
    });

    testWidgets('handles single data point without crashing', (tester) async {
      final singlePointData = [
        StrengthDataPoint(
          date: DateTime(2026, 5, 1),
          weight: 60,
          estimated1RM: 68,
        ),
      ];

      await tester.pumpWidget(
        buildSubject(dataPoints: singlePointData),
      );

      // Should render without crash
      expect(find.byType(StrengthTrendChart), findsOneWidget);
      // Chart should still be present even with one data point
      expect(find.text('杠铃深蹲'), findsOneWidget);
    });
  });
}
