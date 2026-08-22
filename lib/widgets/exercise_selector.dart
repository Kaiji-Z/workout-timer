import 'fullscreen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../providers/plan_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/build_context_text_styles.dart';

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
        Expanded(child: _buildExerciseList(planProvider, theme)),

        // 已选动作预览
        if (widget.selectedExercises.isNotEmpty) ...[
          const Divider(height: 32),
          _buildSelectedPreview(theme),
        ],
      ],
    );
  }

  Widget _buildSearchBar(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: l10n.widgetSearchExerciseHint,
          hintStyle: context.bodyLarge.copyWith(
            color: theme.secondaryTextColor,
          ),
          prefixIcon: Icon(Icons.search, color: theme.secondaryTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: l10n.widgetClearSearch,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: context.bodyLarge.copyWith(color: theme.textColor),
      ),
    );
  }

  Widget _buildMuscleFilterChips(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "全部" 选项
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterMuscle = null),
              borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _filterMuscle == null
                      ? theme.accentColor
                      : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                  border: Border.all(
                    color: _filterMuscle == null
                        ? theme.accentColor
                        : theme.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  l10n.widgetAll,
                  style: context.labelLarge.copyWith(
                    fontWeight: _filterMuscle == null
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _filterMuscle == null
                        ? theme.onAccentColor
                        : theme.textColor,
                  ),
                ),
              ),
            ),
          ),
          // 各肌肉部位
          ...widget.selectedMuscles.map((muscle) {
            final isSelected = _filterMuscle == muscle;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _filterMuscle = muscle),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accentColor : theme.surfaceColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusChip,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor
                          : theme.textColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    muscle.displayName,
                    style: context.labelLarge.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? theme.onAccentColor : theme.textColor,
                    ),
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    // 获取所有动作
    List<Exercise> exercises = planProvider.exercises;

    // 按肌肉部位筛选
    if (_filterMuscle != null) {
      exercises = exercises
          .where((e) => e.primaryMuscle == _filterMuscle)
          .toList();
    } else if (widget.selectedMuscles.isNotEmpty) {
      exercises = exercises
          .where((e) => widget.selectedMuscles.contains(e.primaryMuscle))
          .toList();
    }

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      exercises = exercises
          .where(
            (e) =>
                e.name.toLowerCase().contains(_searchQuery) ||
                e.nameEn.toLowerCase().contains(_searchQuery),
          )
          .toList();
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
              l10n.widgetNoExerciseFound,
              style: context.bodyLarge.copyWith(
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
        final isSelected = widget.selectedExercises.any(
          (e) => e.exerciseId == exercise.id,
        );
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 110),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.widgetSelectedCount(widget.selectedExercises.length),
                style: context.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              TextButton(
                onPressed: () => widget.onSelectionChanged([]),
                child: Text(
                  l10n.widgetClearAll,
                  style: context.labelLarge.copyWith(color: theme.accentColor),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXl,
                      ),
                      boxShadow: AppElevation.resting(theme.shadowColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          planExercise.name,
                          style: context.bodyMedium.copyWith(
                            fontSize: 13,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${l10n.widgetSetsSuffix(planExercise.targetSets)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _removeExerciseById(planExercise.exerciseId),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: theme.secondaryTextColor,
                            ),
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
    final existingIndex = newSelection.indexWhere(
      (e) => e.exerciseId == exercise.id,
    );

    if (existingIndex >= 0) {
      newSelection.removeAt(existingIndex);
    } else {
      newSelection.add(
        PlanExercise(
          exerciseId: exercise.id,
          exercise: exercise,
          targetSets: exercise.recommendation.recommendedSets,
          order: newSelection.length,
        ),
      );
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final imageUrl = exercise.imageUrl;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.accentColor.withValues(alpha: 0.1)
            : theme.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isSelected ? theme.accentColor : Colors.transparent,
          width: isSelected ? 1.5 : 0,
        ),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: ListTile(
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final imageUrl = exercise.imageUrl;
              if (imageUrl != null) {
                FullscreenImageViewer.show(
                  context,
                  imageUrl: imageUrl,
                  title: exercise.name,
                );
              }
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.accentColor
                    : theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: imageUrl != null
                    ? Hero(
                        tag: imageUrl,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.fitness_center,
                            color: isSelected
                                ? theme.onAccentColor
                                : theme.accentColor,
                            size: 22,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.fitness_center,
                            color: isSelected
                                ? theme.onAccentColor
                                : theme.accentColor,
                            size: 22,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        color: isSelected
                            ? theme.onAccentColor
                            : theme.accentColor,
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
        title: Text(
          exercise.name,
          style: context.titleLarge.copyWith(
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Text(
                exercise.primaryMuscle.displayName,
                style: context.bodySmall.copyWith(
                  fontSize: 11,
                  color: theme.accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              exercise.equipmentDisplayName(l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.accentColor, size: 24)
            : Icon(
                Icons.add_circle_outline,
                color: theme.secondaryTextColor,
                size: 24,
              ),
        onTap: onTap,
      ),
    );
  }
}

/// 动作详情弹窗（支持图片轮播和动作指导）
