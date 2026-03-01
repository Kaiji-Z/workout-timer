import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../bloc/plan_provider.dart';
import '../theme/app_theme.dart';

/// 动作选择器 - Flat Vitality 设计
/// 
/// 按肌肉部位筛选，支持多选，可查看详情
class ExerciseSelector extends StatefulWidget {
  /// 已选中的肌肉部位（用于筛选）
  final List<PrimaryMuscleGroup> selectedMuscles;
  
  /// 已选中的动作（含组数）
  final List<PlanExercise> selectedExercises;
  
  /// 选择变化回调
  final ValueChanged<List<PlanExercise>> onSelectionChanged;
  
  const ExerciseSelector({
    super.key,
    required this.selectedMuscles,
    required this.selectedExercises,
    required this.onSelectionChanged,
  });

  @override
  State<ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<ExerciseSelector> {
  PrimaryMuscleGroup? _filterMuscle;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 默认筛选第一个选中的肌肉部位
    if (widget.selectedMuscles.isNotEmpty) {
      _filterMuscle = widget.selectedMuscles.first;
    }
  }

  @override
  void didUpdateWidget(ExerciseSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的肌肉部位变化时，更新筛选
    if (widget.selectedMuscles.isNotEmpty && 
        !widget.selectedMuscles.contains(_filterMuscle)) {
      _filterMuscle = widget.selectedMuscles.first;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索框
        _buildSearchBar(theme),
        const SizedBox(height: 12),
        
        // 肌肉部位筛选标签
        if (widget.selectedMuscles.isNotEmpty) ...[
          _buildMuscleFilterChips(theme),
          const SizedBox(height: 12),
        ],
        
        // 动作列表
        Expanded(
          child: _buildExerciseList(planProvider, theme),
        ),
        
        // 已选动作预览
        if (widget.selectedExercises.isNotEmpty) ...[
          const Divider(height: 32),
          _buildSelectedPreview(theme),
        ],
      ],
    );
  }

  Widget _buildSearchBar(AppThemeData theme) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: '搜索动作...',
          hintStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: theme.secondaryTextColor,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.secondaryTextColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.secondaryTextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          color: theme.textColor,
        ),
      ),
    );
  }

  Widget _buildMuscleFilterChips(AppThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "全部" 选项
          GestureDetector(
            onTap: () => setState(() => _filterMuscle = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _filterMuscle == null ? theme.accentColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filterMuscle == null 
                      ? theme.accentColor 
                      : theme.textColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '全部',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: _filterMuscle == null ? FontWeight.w600 : FontWeight.w500,
                  color: _filterMuscle == null ? Colors.white : theme.textColor,
                ),
              ),
            ),
          ),
          // 各肌肉部位
          ...widget.selectedMuscles.map((muscle) {
            final isSelected = _filterMuscle == muscle;
            return GestureDetector(
              onTap: () => setState(() => _filterMuscle = muscle),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.accentColor : theme.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  muscle.displayName,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.textColor,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExerciseList(PlanProvider planProvider, AppThemeData theme) {
    // 获取所有动作
    List<Exercise> exercises = planProvider.exercises;
    
    // 按肌肉部位筛选
    if (_filterMuscle != null) {
      exercises = exercises.where((e) => e.primaryMuscle == _filterMuscle).toList();
    } else if (widget.selectedMuscles.isNotEmpty) {
      exercises = exercises.where((e) => widget.selectedMuscles.contains(e.primaryMuscle)).toList();
    }
    
    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      exercises = exercises.where((e) =>
          e.name.toLowerCase().contains(_searchQuery) ||
          e.nameEn.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到动作',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = widget.selectedExercises.any((e) => e.exerciseId == exercise.id);
        return _ExerciseListItem(
          exercise: exercise,
          isSelected: isSelected,
          onTap: () => _toggleExercise(exercise),
          theme: theme,
        );
      },
    );
  }

  Widget _buildSelectedPreview(AppThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 110),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已选 ${widget.selectedExercises.length} 个动作',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              TextButton(
                onPressed: () => widget.onSelectionChanged([]),
                child: Text(
                  '清空',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    color: theme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedExercises.map((planExercise) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          planExercise.name,
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${planExercise.targetSets}组)',
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeExerciseById(planExercise.exerciseId),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExercise(Exercise exercise) {
    final newSelection = List<PlanExercise>.from(widget.selectedExercises);
    final existingIndex = newSelection.indexWhere((e) => e.exerciseId == exercise.id);
    
    if (existingIndex >= 0) {
      newSelection.removeAt(existingIndex);
    } else {
      newSelection.add(PlanExercise(
        exerciseId: exercise.id,
        exercise: exercise,
        targetSets: exercise.recommendation.recommendedSets,
        order: newSelection.length,
      ));
    }
    
    widget.onSelectionChanged(newSelection);
  }

  void _removeExerciseById(String exerciseId) {
    final newSelection = List<PlanExercise>.from(widget.selectedExercises);
    newSelection.removeWhere((e) => e.exerciseId == exerciseId);
    widget.onSelectionChanged(newSelection);
  }
}


/// 动作列表项
class _ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _ExerciseListItem({
    required this.exercise,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.accentColor.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.accentColor : Colors.transparent,
          width: isSelected ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.fitness_center,
            color: isSelected ? Colors.white : theme.accentColor,
            size: 22,
          ),
        ),
        title: Text(
          exercise.name,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: theme.textColor,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exercise.primaryMuscle.displayName,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 11,
                  color: theme.accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              exercise.equipmentDisplayName,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.accentColor, size: 24)
            : Icon(Icons.add_circle_outline, color: theme.secondaryTextColor, size: 24),
      ),
    );
  }
}

/// 动作详情弹窗
class ExerciseDetailSheet extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onToggle;
  final Function(int)? onSetsChanged;

  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onToggle,
    this.onSetsChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    bool isSelected = false,
    required VoidCallback onToggle,
    Function(int)? onSetsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(
        exercise: exercise,
        isSelected: isSelected,
        onToggle: onToggle,
        onSetsChanged: onSetsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 动作名称
          Text(
            exercise.name,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.nameEn,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // 标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(exercise.primaryMuscle.displayName, Icons.fitness_center, theme),
              _buildTag(exercise.equipmentDisplayName, Icons.sports_gymnastics, theme),
              _buildTag(exercise.levelDisplayName, Icons.signal_cellular_alt, theme),
            ],
          ),
          const SizedBox(height: 24),
          
          // 推荐配置
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '推荐配置',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '${exercise.recommendation.recommendedSets} 组',
                        '推荐组数',
                        Icons.repeat,
                        theme,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        exercise.recommendation.repsRangeText,
                        '次数范围',
                        Icons.filter_list,
                        theme,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        exercise.recommendation.restText,
                        '组间休息',
                        Icons.timer,
                        theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 次要肌肉部位
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            Text(
              '涉及部位',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.secondaryMuscles.map((muscle) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    muscle.displayName,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 13,
                      color: theme.textColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // 操作按钮
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onToggle();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.red : theme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSelected ? '从计划中移除' : '添加到计划',
                  style: const TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, AppThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.accentColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
