import 'dart:async';
import 'fullscreen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../bloc/plan_provider.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        leading: GestureDetector(
          onTap: () {
            if (exercise.imageUrl != null) {
              FullscreenImageViewer.show(
                context,
                imageUrl: exercise.imageUrl!,
                title: exercise.name,
              );
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: exercise.imageUrl != null
                  ? Hero(
                      tag: exercise.imageUrl!,
                      child: CachedNetworkImage(
                        imageUrl: exercise.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.fitness_center,
                          color: isSelected ? Colors.white : theme.accentColor,
                          size: 22,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.fitness_center,
                          color: isSelected ? Colors.white : theme.accentColor,
                          size: 22,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      color: isSelected ? Colors.white : theme.accentColor,
                      size: 22,
                    ),
            ),
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
        onTap: onTap,
      ),
    );
  }
}

/// 动作详情弹窗（支持图片轮播和动作指导）
class ExerciseDetailSheet extends StatefulWidget {
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
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  static const _autoPlayDuration = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (widget.exercise.images.isNotEmpty) {
        setState(() {
          _currentPage = (_currentPage + 1) % widget.exercise.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final hasImages = widget.exercise.images.isNotEmpty;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 拖动条
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 动作名称
                      Text(
                        widget.exercise.name,
                        style: TextStyle(
                          fontFamily: '.SF Pro Display',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.nameEn,
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
                          _buildTag(widget.exercise.primaryMuscle.displayName, Icons.fitness_center, theme),
                          _buildTag(widget.exercise.equipmentDisplayName, Icons.sports_gymnastics, theme),
                          _buildTag(widget.exercise.levelDisplayName, Icons.signal_cellular_alt, theme),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 图片轮播
                      if (hasImages)
                        _buildImageCarousel(theme),
                      
                      // 动作指导
                      if (widget.exercise.instructions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInstructions(theme),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // 推荐配置
                      _buildRecommendation(theme),
                      
                      const SizedBox(height: 24),
                      
                      // 次要肌肉部位
                      if (widget.exercise.secondaryMuscles.isNotEmpty) ...[
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
                          children: widget.exercise.secondaryMuscles.map((muscle) {
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onToggle();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isSelected ? Colors.red : theme.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.isSelected ? '从计划中移除' : '添加到计划',
                            style: const TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 图片轮播组件（交叉渐隐自动轮播）
  Widget _buildImageCarousel(AppThemeData theme) {
    final images = widget.exercise.images;
    
    return Column(
      children: [
        // 轮播图片 - 使用 AnimatedSwitcher 实现交叉渐隐
        GestureDetector(
          onTap: () => _showFullscreenImage(_currentPage),
          child: SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: _fadeDuration,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Container(
                key: ValueKey<int>(_currentPage),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: 'exercise_image_$_currentPage',
                    child: CachedNetworkImage(
                      imageUrl: images[_currentPage],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        child: Icon(Icons.fitness_center, size: 48, color: theme.accentColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 页面指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return GestureDetector(
              onTap: () {
                setState(() => _currentPage = index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? theme.accentColor 
                      : theme.textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 8),
        
        // 图片说明
        Text(
          '第 ${_currentPage + 1} 步 / 共 ${images.length} 步',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  /// 动作指导组件
  Widget _buildInstructions(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, size: 20, color: theme.accentColor),
            const SizedBox(width: 8),
            Text(
              '动作指导',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.exercise.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 步骤编号
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 步骤内容
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        height: 1.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 推荐配置组件
  Widget _buildRecommendation(AppThemeData theme) {
    return Container(
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
                  '${widget.exercise.recommendation.recommendedSets} 组',
                  '推荐组数',
                  Icons.repeat,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  widget.exercise.recommendation.repsRangeText,
                  '次数范围',
                  Icons.filter_list,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  widget.exercise.recommendation.restText,
                  '组间休息',
                  Icons.timer,
                  theme,
                ),
              ),
            ],
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

  void _showFullscreenImage(int initialIndex) {
    // 使用全屏查看器显示所有图片
    showDialog(
      context: context,
      builder: (context) => _FullscreenImageGallery(
        images: widget.exercise.images,
        initialIndex: initialIndex,
        title: widget.exercise.name,
      ),
    );
  }
}

/// 全屏图片画廊查看器（自动轮播 + 交叉渐隐）
class _FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _FullscreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<_FullscreenImageGallery> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  Timer? _autoPlayTimer;
  static const _autoPlayDuration = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (widget.images.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 图片轮播 - 交叉渐隐
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: InteractiveViewer(
                  key: ValueKey<int>(_currentIndex),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.images[_currentIndex],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 顶部栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 底部指示器
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index 
                              ? Colors.white 
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
