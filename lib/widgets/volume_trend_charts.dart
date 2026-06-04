import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

/// Daily volume line chart widget using fl_chart.
/// Displays volume progression day by day.
class DailyVolumeChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const DailyVolumeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getAppTheme(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无每日训练量数据',
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    final sortedKeys = data.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        data[sortedKeys[entry.key]]!,
      );
    }).toList();

    final values = data.values.toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;
    double minY, maxY;

    // Ensure non-degenerate Y-axis range
    if (padding == 0) {
      minY = 0;
      maxY = maxValue > 0 ? maxValue * 1.2 : 10.0;
    } else {
      minY = (minValue - padding).clamp(0.0, double.infinity);
      maxY = maxValue + padding;
    }

    // Calculate nice Y-axis
    final interval = _niceInterval(maxY - minY, 4);
    maxY = (maxY / interval).ceilToDouble() * interval;
    minY = (minY / interval).floorToDouble() * interval;

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sortedKeys.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final dateStr = index >= 0 && index < sortedKeys.length
                      ? DateFormat.Md().format(sortedKeys[index])
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
                  if (index < 0 || index >= sortedKeys.length) {
                    return const SizedBox.shrink();
                  }
                  final formatted = DateFormat.Md().format(sortedKeys[index]);
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
        ),
      ),
    );
  }
}
