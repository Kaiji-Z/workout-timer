import 'package:flutter/material.dart';
import '../models/muscle_group.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

/// 肌肉部位选择器 - Flat Vitality 设计
/// 
/// 支持多选6个主要肌肉部位
class MuscleSelector extends StatelessWidget {
  /// 当前选中的肌肉部位
  final List<PrimaryMuscleGroup> selectedMuscles;
  
  /// 选择变化回调
  final ValueChanged<List<PrimaryMuscleGroup>> onSelectionChanged;
  
  /// 是否显示标题
  final bool showTitle;
  
  const MuscleSelector({
    super.key,
    required this.selectedMuscles,
    required this.onSelectionChanged,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            '选择训练部位',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PrimaryMuscleGroup.values.map((muscle) {
            final isSelected = selectedMuscles.contains(muscle);
            return _MuscleChip(
              muscle: muscle,
              isSelected: isSelected,
              onTap: () => _toggleMuscle(muscle),
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggleMuscle(PrimaryMuscleGroup muscle) {
    final newSelection = List<PrimaryMuscleGroup>.from(selectedMuscles);
    if (newSelection.contains(muscle)) {
      newSelection.remove(muscle);
    } else {
      newSelection.add(muscle);
    }
    onSelectionChanged(newSelection);
  }
}

/// 肌肉部位选择芯片
class _MuscleChip extends StatelessWidget {
  final PrimaryMuscleGroup muscle;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _MuscleChip({
    required this.muscle,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? theme.accentColor : theme.textColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMuscle(muscle),
              size: 20,
              color: isSelected ? Colors.white : theme.textColor,
            ),
            const SizedBox(width: 8),
            Text(
              muscle.displayName,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMuscle(PrimaryMuscleGroup muscle) {
    switch (muscle) {
      case PrimaryMuscleGroup.chest:
        return Icons.fitness_center_rounded;
      case PrimaryMuscleGroup.back:
        return Icons.accessibility_new_rounded;
      case PrimaryMuscleGroup.shoulders:
        return Icons.arrow_upward_rounded;
      case PrimaryMuscleGroup.arms:
        return Icons.back_hand_rounded;
      case PrimaryMuscleGroup.legs:
        return Icons.directions_walk_rounded;
      case PrimaryMuscleGroup.core:
        return Icons.circle_rounded;
    }
  }
}

/// 紧凑型肌肉选择器 - 用于显示已选部位
class CompactMuscleSelector extends StatelessWidget {
  final List<PrimaryMuscleGroup> selectedMuscles;
  final ValueChanged<List<PrimaryMuscleGroup>> onSelectionChanged;
  final int maxChips;

  const CompactMuscleSelector({
    super.key,
    required this.selectedMuscles,
    required this.onSelectionChanged,
    this.maxChips = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PrimaryMuscleGroup.values.take(maxChips).map((muscle) {
        final isSelected = selectedMuscles.contains(muscle);
        return GestureDetector(
          onTap: () => _toggleMuscle(muscle),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? theme.accentColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.accentColor : theme.textColor.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              muscle.displayName,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : theme.textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleMuscle(PrimaryMuscleGroup muscle) {
    final newSelection = List<PrimaryMuscleGroup>.from(selectedMuscles);
    if (newSelection.contains(muscle)) {
      newSelection.remove(muscle);
    } else {
      newSelection.add(muscle);
    }
    onSelectionChanged(newSelection);
  }
}

/// 肌肉部位显示徽章 - 只读显示
class MuscleBadge extends StatelessWidget {
  final List<PrimaryMuscleGroup> muscles;
  final double fontSize;
  final bool compact;

  const MuscleBadge({
    super.key,
    required this.muscles,
    this.fontSize = 12,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    if (muscles.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      // 紧凑模式：用逗号分隔
      return Text(
        muscles.map((m) => m.displayName).join('、'),
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: fontSize,
          color: theme.secondaryTextColor,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: muscles.map((muscle) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: fontSize + 2, vertical: fontSize / 2),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(fontSize),
          ),
          child: Text(
            muscle.displayName,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: theme.accentColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}
