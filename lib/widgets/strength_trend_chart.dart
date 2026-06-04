import 'dart:math' as math;

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
  } catch (e) {
    debugPrint('ThemeProvider not available, using fallback: $e');
    return amberGoldTheme;
  }
}

/// Calculate a "nice" Y-axis interval that produces round numbers.
/// Returns a value like 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, etc.
double _niceInterval(double range, int targetTicks) {
  if (range <= 0) return 1.0;
  final roughStep = range / targetTicks;
  final magnitude =
      math.pow(10, (math.log(roughStep) / math.log(10)).floor()).toDouble();
  final residual = roughStep / magnitude;
  double niceStep;
  if (residual <= 1.5) {
    niceStep = magnitude;
  } else if (residual <= 3.5) {
    niceStep = 2 * magnitude;
  } else if (residual <= 7.5) {
    niceStep = 5 * magnitude;
  } else {
    niceStep = 10 * magnitude;
  }
  return niceStep;
}

/// Format a numeric value for Y-axis labels.
/// Shows integer when whole, otherwise one decimal place.
String _formatValue(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
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
    double minY, maxY;

    // Ensure non-degenerate Y-axis range
    if (padding == 0) {
      minY = 0;
      maxY = max1RM > 0 ? max1RM * 1.2 : 10.0;
    } else {
      minY = (min1RM - padding).clamp(0.0, double.infinity);
      maxY = max1RM + padding;
    }

    // Calculate nice Y-axis
    final interval = _niceInterval(maxY - minY, 4);
    maxY = (maxY / interval).ceilToDouble() * interval;
    minY = (minY / interval).floorToDouble() * interval;

    return LineChartData(
      minX: 0,
      maxX: (dataPoints.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final dateStr = index >= 0 && index < dataPoints.length
                  ? DateFormat.Md().format(dataPoints[index].date)
                  : '';
              return LineTooltipItem(
                '$dateStr\n${_formatValue(spot.y)} kg',
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
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
            interval: interval,
            getTitlesWidget: (value, meta) {
              if (value % interval != 0 && (value % interval).abs() > 0.01) {
                return const SizedBox.shrink();
              }
              return Text(
                _formatValue(value),
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
