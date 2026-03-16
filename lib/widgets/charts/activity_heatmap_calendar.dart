import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ActivityHeatmapCalendar extends StatelessWidget {
  final Map<DateTime, double> dailyData; // Date -> volume or count
  final AppThemeData theme;
  final int weeksToShow;
  
  const ActivityHeatmapCalendar({
    super.key,
    required this.dailyData,
    required this.theme,
    this.weeksToShow = 12,
  });
  
  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return _buildEmptyState();
    }
    
    final maxVolume = dailyData.values.isEmpty 
        ? 1.0 
        : dailyData.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month/Week labels
        _buildMonthLabels(),
        const SizedBox(height: 12),
        // Heatmap grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            _buildDayLabels(),
            const SizedBox(width: 12),
            // Heatmap cells
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildWeeks(maxVolume),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Legend
        _buildLegend(),
      ],
    );
  }
  
  Widget _buildMonthLabels() {
    final now = DateTime.now();
    final monthNames = <String>[];
    
    for (int i = 0; i < weeksToShow; i++) {
      final weekStart = now.subtract(Duration(days: (weeksToShow - i - 1) * 7));
      final month = weekStart.month;
      final monthName = _getMonthName(month);
      monthNames.add(monthName);
    }
    
    return Row(
      children: [
        Text(
          '训练热力图',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: monthNames.map((month) => 
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    month,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    return months[month - 1];
  }
  
  Widget _buildDayLabels() {
    const days = ['一', '三', '五'];
    return Column(
      children: days.map((day) => 
        SizedBox(
          height: 18,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.secondaryTextColor,
            ),
          ),
        ),
      ).toList(),
    );
  }
  
  List<Widget> _buildWeeks(double maxVolume) {
    final now = DateTime.now();
    final weeks = <Widget>[];
    
    for (int week = 0; week < weeksToShow; week++) {
      final weekStart = now.subtract(Duration(days: (weeksToShow - week - 1) * 7));
      final monday = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            children: List.generate(7, (dayIndex) {
              final date = monday.add(Duration(days: dayIndex));
              final volume = _getVolumeForDate(date);
              final intensity = maxVolume > 0 ? volume / maxVolume : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildCell(date, intensity, volume),
              );
            }),
          ),
        ),
      );
    }
    
    return weeks;
  }
  
  double _getVolumeForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyData[normalizedDate] ?? 0.0;
  }
  
  Widget _buildCell(DateTime date, double intensity, double volume) {
    final isToday = _isToday(date);
    final isFuture = date.isAfter(DateTime.now());
    
    Color cellColor;
    if (isFuture) {
      cellColor = Colors.transparent;
    } else if (intensity == 0) {
      cellColor = theme.textColor.withValues(alpha: 10);
    } else if (intensity < 0.33) {
      cellColor = theme.accentColor.withValues(alpha: 0.3);
    } else if (intensity < 0.66) {
      cellColor = theme.accentColor.withValues(alpha: 0.6);
    } else {
      cellColor = theme.accentColor;
    }
    
    return Tooltip(
      message: '${date.month}月${date.day}日: ${volume.toStringAsFixed(0)} kg',
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(2),
          border: isToday 
            ? Border.all(color: theme.accentColor, width: 1)
            : null,
        ),
      ),
    );
  }
  
  Color _getIntensityColor(double intensity) {
    // GitHub-style intensity scale
    if (intensity < 0.33) {
      return theme.accentColor.withValues(alpha: 0.3);
    } else if (intensity < 0.66) {
      return theme.accentColor.withValues(alpha: 0.6);
    } else {
      return theme.accentColor;
    }
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '少',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.secondaryTextColor),
        ),
        const SizedBox(width: 8),
        ...[0.0, 0.33, 0.66, 1.0].map((intensity) => 
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: intensity == 0 
                  ? theme.textColor.withValues(alpha: 10)
                  : _getIntensityColor(intensity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '多',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.secondaryTextColor),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: theme.secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            '暂无训练记录',
            style: TextStyle(color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}