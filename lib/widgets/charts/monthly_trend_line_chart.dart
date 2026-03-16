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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with unit
        Text(
          '日训练容量 (kg)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.textColor.withValues(alpha: 0.08),
                  strokeWidth: 1,
                  dashArray: [3, 3],
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: theme.textColor.withValues(alpha: 0.08),
                  strokeWidth: 1,
                  dashArray: [3, 3],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: 1,
                    getTitlesWidget: _getBottomTitles,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 20,
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
                    color: theme.accentColor.withValues(alpha: 0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => theme.accentColor,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final sortedEntries = dailyData.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                      
                      if (index >= 0 && index < sortedEntries.length) {
                        final date = sortedEntries[index].key;
                        final volume = sortedEntries[index].value;
                        return LineTooltipItem(
                          '${date.month}/${date.day}\n${volume.toStringAsFixed(0)} kg',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }
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
        ),
      ],
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
    final day = date.day;
    
    // Show key dates: 1, 5, 10, 15, 20, 25, and月末
    if (day == 1 || day == 5 || day == 10 || day == 15 || day == 20 || day == 25) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 10,
            color: theme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (day == sortedEntries.last.key.day) {
      // Show "月末" for the last day
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '月末',
          style: TextStyle(
            fontSize: 10,
            color: theme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return const SizedBox();
  }
  
  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      '${value.toInt()} kg',
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