import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workout_timer/models/muscle_group.dart';
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

/// Pie chart colors for secondary muscle group distribution.
const _kPieChartColors = [
  Color(0xFF1A237E), // deep indigo
  Color(0xFF3949AB), // indigo 600
  Color(0xFF5C6BC0), // indigo 400
  Color(0xFF7986CB), // indigo 300
  Color(0xFF9FA8DA), // indigo 200
  Color(0xFFC5CAE9), // indigo 100
  Color(0xFFFF8A65), // coral orange
  Color(0xFFFFB74D), // amber
  Color(0xFF81C784), // mint green
  Color(0xFFF48FB1), // rose pink
  Color(0xFF64B5F6), // sky blue
  Color(0xFFCE93D8), // purple 200
  Color(0xFF80CBC4), // teal 200
  Color(0xFFFFCC80), // orange 200
  Color(0xFFEF9A9A), // red 200
  Color(0xFFA5D6A7), // green 200
  Color(0xFF90CAF9), // blue 200
  Color(0xFFBCAAA4), // brown 200
  Color(0xFFB0BEC5), // blue grey 200
  Color(0xFFFFE082), // yellow 200
];

/// Weekly volume bar chart widget using fl_chart.
/// Displays total volume per week as bars.
class WeeklyVolumeChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const WeeklyVolumeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getAppTheme(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无每周训练量数据',
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    final sortedKeys = data.keys.toList()..sort();
    final maxVolume = data.values.reduce((a, b) => a > b ? a : b);

    // Calculate nice Y-axis
    final rawMaxY = maxVolume > 0 ? maxVolume * 1.1 : 10.0;
    final interval = _niceInterval(rawMaxY, 4);
    final maxY = (rawMaxY / interval).ceilToDouble() * interval;

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: 0,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = sortedKeys[group.x];
                final dateStr = DateFormat.Md().format(date);
                return BarTooltipItem(
                  '$dateStr\n${_formatValue(rod.toY)} kg',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
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
                  // Skip labels that aren't multiples of interval
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
          barGroups: List.generate(sortedKeys.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[sortedKeys[index]]!,
                  color: theme.accentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  width: 20,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
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

/// Secondary muscle group volume distribution pie chart widget using fl_chart.
/// Displays volume proportion per secondary muscle group.
class SecondaryMuscleVolumeChart extends StatelessWidget {
  final Map<SecondaryMuscleGroup, double> data;

  const SecondaryMuscleVolumeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getAppTheme(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无肌群训练量分布数据',
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    final totalVolume = data.values.fold(0.0, (sum, v) => sum + v);
    final entries = data.entries.toList();

    return AspectRatio(
      aspectRatio: 1.2,
      child: PieChart(
        PieChartData(
          sections: List.generate(entries.length, (index) {
            final muscle = entries[index].key;
            final volume = entries[index].value;
            final percentage = totalVolume > 0 ? volume / totalVolume : 0;
            return PieChartSectionData(
              value: volume,
              title: '${muscle.displayName}\n${(percentage * 100).toStringAsFixed(0)}%',
              titleStyle: TextStyle(
                fontSize: 10,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              color: _kPieChartColors[index % _kPieChartColors.length],
              radius: 80,
              titlePositionPercentageOffset: 0.55,
            );
          }),
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
