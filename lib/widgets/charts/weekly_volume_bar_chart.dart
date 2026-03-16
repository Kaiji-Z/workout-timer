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
  final DateTime? today;
  
  const WeeklyVolumeBarChart({
    super.key,
    required this.weeklyData,
    required this.theme,
    this.today,
  });
  
  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '本周训练容量',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              fontFamily: '.SF Pro Display',
            ),
          ),
        ),
        // Unit label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '单位: kg (组数 × 重量)',
            style: TextStyle(
              fontSize: 12,
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.surfaceColor,
                    getTooltipItem: (group, index, rod, rodIndex) {
                      final dayIndex = group.x;
                      final sortedEntries = weeklyData.entries.toList()
                        ..sort((a, b) => a.key.compareTo(b.key));
                      final date = sortedEntries[dayIndex].key;
                      final weekday = ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1];
                      final volume = rod.toY;
                      
                      return BarTooltipItem(
                        '周$weekday: ${volume.toStringAsFixed(0)} kg',
                        TextStyle(
                          color: theme.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: '.SF Pro Text',
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getBottomTitles,
                      reservedSize: 38,
                    ),
                    axisNameWidget: Text(
                      '星期',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _getLeftTitles,
                      reservedSize: 40,
                      interval: _calculateGridInterval(),
                    ),
                    axisNameWidget: Text(
                      '容量 (kg)',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: theme.accentColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateGridInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.textColor.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: theme.textColor.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  List<BarChartGroupData> _buildBarGroups() {
    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final date = entry.value.key;
      final isToday = today != null && date.year == today!.year && 
                     date.month == today!.month && date.day == today!.day;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value,
            color: isToday ? theme.accentColor.withValues(alpha: 0.8) : theme.accentColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: isToday ? BackgroundBarChartRodData(
              toY: data.value,
              color: theme.accentColor.withValues(alpha: 0.15),
            ) : null,
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
          Icon(
            Icons.bar_chart,
            size: 64,
            color: theme.accentColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: '.SF Pro Text',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始训练后数据将自动显示',
            style: TextStyle(
              color: theme.secondaryTextColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }
}