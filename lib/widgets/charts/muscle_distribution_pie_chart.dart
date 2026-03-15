import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/muscle_group.dart';

class MuscleDistributionPieChart extends StatelessWidget {
  final Map<PrimaryMuscleGroup, double> muscleData;
  final AppThemeData theme;
  
  const MuscleDistributionPieChart({
    super.key,
    required this.muscleData,
    required this.theme,
  });
  
  // Muscle group colors - using theme accent colors and complementary colors
  static const Map<PrimaryMuscleGroup, Color> _muscleColors = {
    PrimaryMuscleGroup.chest: Color(0xFFE53935),      // Red
    PrimaryMuscleGroup.back: Color(0xFF43A047),      // Green
    PrimaryMuscleGroup.shoulders: Color(0xFF1E88E5),  // Blue
    PrimaryMuscleGroup.arms: Color(0xFFFB8C00),      // Orange
    PrimaryMuscleGroup.legs: Color(0xFF8E24AA),      // Purple
    PrimaryMuscleGroup.core: Color(0xFF00ACC1),      // Cyan
  };
  
  static const Map<PrimaryMuscleGroup, String> _muscleLabels = {
    PrimaryMuscleGroup.chest: '胸',
    PrimaryMuscleGroup.back: '背',
    PrimaryMuscleGroup.shoulders: '肩',
    PrimaryMuscleGroup.arms: '手臂',
    PrimaryMuscleGroup.legs: '腿',
    PrimaryMuscleGroup.core: '核心',
  };
  
  @override
  Widget build(BuildContext context) {
    if (muscleData.isEmpty) {
      return _buildEmptyState();
    }
    
    final total = muscleData.values.fold(0.0, (a, b) => a + b);
    
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildSections(total),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  // Handle touch if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }
  
  List<PieChartSectionData> _buildSections(double total) {
    return muscleData.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _muscleColors[entry.key] ?? theme.accentColor;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: '.SF Pro Text',
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }
  
  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: muscleData.entries.map((entry) {
        final color = _muscleColors[entry.key] ?? theme.accentColor;
        final label = _muscleLabels[entry.key] ?? entry.key.name;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textColor,
                fontFamily: '.SF Pro Text',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: theme.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无部位分布数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}