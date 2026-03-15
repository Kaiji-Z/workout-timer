import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class MonthlyTrendLineChart extends StatelessWidget {
  final Map<DateTime, double> dailyData; // Date -> volume
  final AppThemeData theme;
  
  const MonthlyTrendLineChart({
    super.key,
    required this.dailyData,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return _buildEmptyState();
    }
    
    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.textColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 7, // Show every 7 days
                getTitlesWidget: _getBottomTitles,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: _getLeftTitles,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: _getMaxX(),
          minY: 0,
          maxY: _calculateMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(),
              isCurved: true,
              color: theme.accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => 
                  FlDotCirclePainter(
                    radius: 4,
                    color: theme.accentColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.accentColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)} kg',
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
  
List<FlSpot> _buildSpots() {
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      spots.add(FlSpot(i.toDouble(), entry.value));
    }
    return spots;
  }
  
  double _getMaxX() {
    return (dailyData.length - 1).toDouble().clamp(0, double.infinity);
  }
  
  double _calculateMaxY() {
    if (dailyData.isEmpty) return 100;
    final maxVolume = dailyData.values.reduce((a, b) => a > b ? a : b);
    return maxVolume * 1.2;
  }
  
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final index = value.toInt();
    if (index < 0 || index >= sortedEntries.length) {
      return const SizedBox();
    }
    
    final date = sortedEntries[index].key;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 10,
          color: theme.secondaryTextColor,
        ),
      ),
    );
  }
  
  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      '${value.toInt()}',
      style: TextStyle(
        fontSize: 10,
        color: theme.secondaryTextColor,
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: theme.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            '暂无月度趋势数据',
            style: TextStyle(color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}