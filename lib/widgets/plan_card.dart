import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import 'muscle_selector.dart';
import '../theme/app_theme.dart';

/// 计划卡片 - Flat Vitality 设计
/// 
/// 显示训练计划的摘要信息
class PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const PlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.onStart,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: theme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(
                                fontFamily: '.SF Pro Display',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            MuscleBadge(
                              muscles: plan.targetMuscles,
                              compact: true,
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (!isCompact) ...[
                    const SizedBox(height: 12),
                    // 统计信息
                    Row(
                      children: [
                        _buildStat(
                          '${plan.exerciseCount} 个动作',
                          Icons.list_alt,
                          theme,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          '${plan.totalSets} 组',
                          Icons.repeat,
                          theme,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          '~${plan.estimatedDuration} 分钟',
                          Icons.timer_outlined,
                          theme,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // 操作按钮
            if (showActions && !isCompact) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, size: 18, color: theme.secondaryTextColor),
                        label: Text(
                          '编辑',
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ),
                    if (onStart != null)
                      ElevatedButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('开始'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String text, IconData icon, AppThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.secondaryTextColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

/// 紧凑型计划卡片 - 用于列表项
class CompactPlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback? onTap;
  final bool isSelected;

  const CompactPlanCard({
    super.key,
    required this.plan,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.accentColor : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: isSelected ? Colors.white : theme.accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.targetMusclesText,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // 统计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${plan.exerciseCount}动作 · ${plan.totalSets}组',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 计划进度卡片 - 训练中显示
class PlanProgressCard extends StatefulWidget {
  final WorkoutPlan plan;
  final int currentExerciseIndex;
  final Map<String, int> completedSets;
  final VoidCallback? onToggle;
  final VoidCallback? onNextExercise;
  final bool isExpanded;
  final bool isResting; // 是否处于休息状态

  const PlanProgressCard({
    super.key,
    required this.plan,
    required this.currentExerciseIndex,
    required this.completedSets,
    this.onToggle,
    this.onNextExercise,
    this.isExpanded = false,
    this.isResting = false,
  });

  @override
  State<PlanProgressCard> createState() => _PlanProgressCardState();
}

class _PlanProgressCardState extends State<PlanProgressCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PlanProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final currentExercise = widget.plan.exercises.isNotEmpty &&
            widget.currentExerciseIndex < widget.plan.exercises.length
        ? widget.plan.exercises[widget.currentExerciseIndex]
        : null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏 - 始终显示
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_add_check,
                      color: theme.accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: currentExercise != null
                        ? Text(
                            '${widget.plan.name} · ${currentExercise.name} 第${_getCurrentSetNumber(currentExercise)}组',
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            widget.plan.name,
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                            ),
                          ),
                  ),
                  Icon(
                    widget.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
          
          // 展开内容
          SizeTransition(
            sizeFactor: _heightAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 当前动作进度
                      if (currentExercise != null) ...[
                        Text(
                          '当前：${currentExercise.name} 第${_getCurrentSetNumber(currentExercise)}/${currentExercise.effectiveSets}组',
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // 所有动作列表
                      ...widget.plan.exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        final completed = widget.completedSets[exercise.exerciseId] ?? 0;
                        final isCurrent = index == widget.currentExerciseIndex;
                        final isCompleted = completed >= exercise.effectiveSets;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : isCurrent
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                size: 20,
                                color: isCompleted
                                    ? theme.accentColor
                                    : isCurrent
                                        ? theme.accentColor
                                        : theme.secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: TextStyle(
                                    fontFamily: '.SF Pro Text',
                                    fontSize: 14,
                                    color: isCompleted || isCurrent
                                        ? theme.textColor
                                        : theme.secondaryTextColor,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              Text(
                                '$completed/${exercise.effectiveSets}',
                                style: TextStyle(
                                  fontFamily: '.SF Pro Text',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isCompleted
                                      ? theme.accentColor
                                      : theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      // 切换下一动作按钮 - 醒目样式
                      if (widget.onNextExercise != null &&
                          widget.currentExerciseIndex < widget.plan.exercises.length - 1) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.accentColor,
                                theme.accentColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onNextExercise,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '切换下一动作',
                                      style: TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentSetNumber(PlanExercise exercise) {
    final completed = widget.completedSets[exercise.exerciseId] ?? 0;
    // 休息状态：显示已完成的组数
    // 运动状态：显示当前进行中的组数（已完成 + 1）
    if (widget.isResting) {
      return completed > 0 ? completed : 1;
    }
    return completed + 1;
  }
}

/// 空计划占位卡片
class EmptyPlanCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String subtitle;

  const EmptyPlanCard({
    super.key,
    this.onTap,
    this.title = '还没有计划',
    this.subtitle = '点击创建你的第一个训练计划',
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: theme.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// 极简进度行 - 计划模式训练中显示
/// 单行：动作名 + 当前组/总组 + 整体进度条
class PlanProgressCompact extends StatelessWidget {
  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final double totalProgress; // 0.0 - 1.0

  const PlanProgressCompact({
    super.key,
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.totalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 动作名 + 进度
          Expanded(
            child: Text(
              '$exerciseName · $currentSet/$totalSets组',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // 进度条
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: totalProgress,
                backgroundColor: theme.accentColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}