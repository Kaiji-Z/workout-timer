import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

// Import necessary types for tooltip
typedef GetBarTooltipItem = BarTooltipItem Function(
  BarChartGroupData group,
  int groupIndex,
  BarChartRodData rod,
);

class WeeklyVolumeBarChart extends StatelessWidget {
  final Map<DateTime, double> weeklyData;
  final AppThemeData theme;
  
  const WeeklyVolumeBarChart({
    super.key,
    required this.weeklyData,
    required this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return _buildEmptyState();
    }
    
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          barTouchData: BarTouchData(
            enabled: true,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getBottomTitles,
                reservedSize: 38,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getLeftTitles,
                reservedSize: 40,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateGridInterval(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.textColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }
  
  List<BarChartGroupData> _buildBarGroups() {
    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value,
            color: theme.accentColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }
  
  double _calculateMaxY() {
    if (weeklyData.isEmpty) return 100;
    final maxVolume = weeklyData.values.reduce((a, b) => a > b ? a : b);
    return maxVolume * 1.2; // 20% padding
  }
  
  double _calculateGridInterval() {
    final maxY = _calculateMaxY();
    return maxY / 4;
  }
  
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (value.toInt() >= sortedEntries.length) {
      return const SizedBox();
    }
    
    final date = sortedEntries[value.toInt()].key;
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1];
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '周$weekday',
        style: TextStyle(
          color: theme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      '${value.toInt()}',
      style: TextStyle(
        color: theme.secondaryTextColor,
        fontSize: 11,
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: theme.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            '暂无训练容量数据',
            style: TextStyle(color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}