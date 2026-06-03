import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/theme/theme_provider.dart';

/// Safe helper to get [AppThemeData] from context.
/// Falls back to default theme when no [ThemeProvider] is available (e.g. tests).
AppThemeData _getAppTheme(BuildContext context) {
  try {
    return Provider.of<ThemeProvider>(context, listen: true).currentTheme;
  } catch (_) {
    return amberGoldTheme;
  }
}

/// Strength trend line chart widget using fl_chart.
/// Displays estimated 1RM progression over time for a specific exercise.
class StrengthTrendChart extends StatelessWidget {
  final List<StrengthDataPoint> dataPoints;
  final String exerciseName;

  const StrengthTrendChart({
    super.key,
    required this.dataPoints,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getAppTheme(context);

    if (dataPoints.isEmpty) {
      return Center(
        child: Text(
          '暂无力量数据',
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.6,
          child: LineChart(_buildChartData(theme)),
        ),
      ],
    );
  }

  LineChartData _buildChartData(AppThemeData theme) {
    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.estimated1RM,
      );
    }).toList();

    final min1RM = dataPoints.map((e) => e.estimated1RM).reduce(
          (a, b) => a < b ? a : b,
        );
    final max1RM = dataPoints.map((e) => e.estimated1RM).reduce(
          (a, b) => a > b ? a : b,
        );
    final padding = (max1RM - min1RM) * 0.1;

    return LineChartData(
      minX: 0,
      maxX: (dataPoints.length - 1).toDouble(),
      minY: (min1RM - padding).clamp(0, double.infinity),
      maxY: max1RM + padding,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: dataPoints.length > 1
            ? ((max1RM - min1RM) / 4).clamp(1, double.infinity)
            : 10,
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.dividerColor,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= dataPoints.length) {
                return const SizedBox.shrink();
              }
              final date = dataPoints[index].date;
              final formatted = DateFormat.Md().format(date);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.secondaryTextColor,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.secondaryTextColor,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.accentColor,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: theme.accentColor,
                strokeWidth: 2,
                strokeColor: theme.surfaceColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: theme.accentColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
