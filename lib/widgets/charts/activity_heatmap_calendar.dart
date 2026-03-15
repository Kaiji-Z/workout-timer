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
    this.weeksToShow = 4,
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
        const SizedBox(height: 8),
        // Heatmap grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            _buildDayLabels(),
            const SizedBox(width: 8),
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
        const SizedBox(height: 16),
        // Legend
        _buildLegend(),
      ],
    );
  }
  
  Widget _buildMonthLabels() {
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
      ],
    );
  }
  
  Widget _buildDayLabels() {
    const days = ['一', '', '三', '', '五', '', '日'];
    return Column(
      children: days.map((day) => 
        SizedBox(
          height: 14,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 10,
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
          padding: const EdgeInsets.only(right: 2),
          child: Column(
            children: List.generate(7, (dayIndex) {
              final date = monday.add(Duration(days: dayIndex));
              final volume = _getVolumeForDate(date);
              final intensity = maxVolume > 0 ? volume / maxVolume : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
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
      cellColor = theme.textColor.withValues(alpha: 0.05);
    } else {
      cellColor = _getIntensityColor(intensity);
    }
    
    return Tooltip(
      message: '${date.month}/${date.day}: ${volume.toStringAsFixed(0)} kg',
      child: Container(
        width: 14,
        height: 14,
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
    // Use theme colors for intensity scale
    if (intensity < 0.25) {
      return theme.accentColor.withValues(alpha: 0.3);
    } else if (intensity < 0.5) {
      return theme.accentColor.withValues(alpha: 0.5);
    } else if (intensity < 0.75) {
      return theme.accentColor.withValues(alpha: 0.7);
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '少',
          style: TextStyle(fontSize: 10, color: theme.secondaryTextColor),
        ),
        const SizedBox(width: 4),
        ...[0.0, 0.25, 0.5, 0.75, 1.0].map((intensity) => 
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: intensity == 0 
                  ? theme.textColor.withValues(alpha: 0.05)
                  : _getIntensityColor(intensity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '多',
          style: TextStyle(fontSize: 10, color: theme.secondaryTextColor),
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