import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/context_l10n.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../providers/plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/muscle_group.dart';

import '../widgets/muscle_selector.dart';
import '../widgets/plan_form_components.dart';
import '../theme/app_theme.dart';
import 'exercise_selection_screen.dart';
import '../theme/build_context_text_styles.dart';

/// 创建/编辑计划页面 - 3步流程
///
/// 第1步：选择训练部位
/// 第2步：选择训练动作
/// 第3步：确认组数和名称
class PlanFormScreen extends StatefulWidget {
  final WorkoutPlan? plan; // 编辑模式时传入

  const PlanFormScreen({super.key, this.plan});

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  late final PageController _pageController;
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0;
  List<PrimaryMuscleGroup> _selectedMuscles = [];
  List<PlanExercise> _selectedExercises = [];

  bool _isSaving = false;

  bool get isEditMode => widget.plan != null;

  @override
  void initState() {
    super.initState();

    // 编辑模式：初始化数据
    final editingPlan = widget.plan;
    if (isEditMode && editingPlan != null) {
      _selectedMuscles = List.from(editingPlan.targetMuscles);
      _selectedExercises = List.from(editingPlan.exercises);
      _nameController.text = editingPlan.name;
      // 编辑模式默认跳到第3步（确认/微调）
      _currentStep = 2;
    }
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _confirmClose();
        }
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: l10n.pfCloseTooltip,
            icon: Icon(Icons.close, color: theme.textColor),
            onPressed: _confirmClose,
          ),
          title: Text(
            isEditMode ? l10n.pfEditTitle : l10n.pfCreateTitle,
            style: context.headlineLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            // 步骤指示器
            buildPlanFormStepIndicator(
              context,
              currentStep: _currentStep,
              isEditMode: isEditMode,
              onJumpToStep: _jumpToStep,
              theme: theme,
            ),

            // 内容
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                ],
              ),
            ),

            // 底部按钮
            _buildBottomButton(theme),
          ],
        ),
      ),
    );
  }

  // ==================== 第1步：选择部位 ====================
  Widget _buildStep1(AppThemeData theme) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pfSelectMuscleHeading,
            style: context.headlineLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pfSelectMuscleSubheading,
            style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),
          MuscleSelector(
            selectedMuscles: _selectedMuscles,
            onSelectionChanged: (muscles) {
              setState(() {
                _selectedMuscles = muscles;
              });
            },
            showTitle: false,
          ),
          const SizedBox(height: 24),
          // 快速选择
          _buildQuickSelectButtons(theme),
        ],
      ),
    );
  }

  Widget _buildQuickSelectButtons(AppThemeData theme) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pfQuickSelect,
          style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton(l10n.pfQuickUpper, [
              PrimaryMuscleGroup.chest,
              PrimaryMuscleGroup.back,
              PrimaryMuscleGroup.shoulders,
              PrimaryMuscleGroup.arms,
            ], theme),
            _buildQuickButton(l10n.pfQuickLower, [
              PrimaryMuscleGroup.legs,
              PrimaryMuscleGroup.core,
            ], theme),
            _buildQuickButton(
              l10n.pfQuickFull,
              PrimaryMuscleGroup.values.toList(),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  // ==================== 第2步：选择动作 ====================
  Widget _buildStep2(AppThemeData theme) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pfSelectExerciseHeading,
            style: context.headlineLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pfSelectedMusclesLine(
              _selectedMuscles.isEmpty
                  ? l10n.pfNotSelected
                  : _selectedMuscles.map((m) => m.displayName).join(', '),
            ),
            style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),

          // 已选动作摘要卡片
          if (_selectedExercises.isNotEmpty) ...[
            _buildSelectedSummaryCard(theme),
            const SizedBox(height: 16),
          ],

          // 选择动作入口按钮
          _buildSelectExerciseButton(theme),
        ],
      ),
    );
  }

  /// 已选动作摘要卡片
  Widget _buildSelectedSummaryCard(AppThemeData theme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pfSelectedExercisesHeading,
                style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.pfClearSelectedTitle),
                      content: Text(l10n.pfClearSelectedBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.widgetCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            l10n.widgetClearAll,
                            style: TextStyle(color: theme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    setState(() => _selectedExercises.clear());
                  }
                },
                child: Text(
                  l10n.widgetClearAll,
                  style: context.labelLarge.copyWith(color: theme.accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedExercises.map((exercise) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedExercises.removeWhere(
                      (e) => e.exerciseId == exercise.exerciseId,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.hasDetails
                            ? exercise.name
                            : '${exercise.name} ${l10n.pfNoDetailsSuffix}',
                        style: context.bodyMedium.copyWith(
                          fontSize: 13,
                          color: exercise.hasDetails
                              ? theme.textColor
                              : theme.secondaryTextColor.withValues(alpha: 0.7),
                          fontStyle: exercise.hasDetails
                              ? null
                              : FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pfSetsSuffix(exercise.targetSets),
                        style: context.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.close,
                        size: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 选择动作入口按钮
  Widget _buildSelectExerciseButton(AppThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openExerciseSelection,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: theme.surfaceColorRaised,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: AppElevation.resting(theme.shadowColor),
          ),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: theme.accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedExercises.isEmpty
                    ? context.l10n.pfSelectExerciseHeading
                    : context.l10n.pfContinueAdding,
                style: context.titleLarge.copyWith(color: theme.accentColor),
              ),
              if (_selectedExercises.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.pfSelectedCountLine(_selectedExercises.length),
                  style: context.bodyMedium.copyWith(
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    String label,
    List<PrimaryMuscleGroup> muscles,
    AppThemeData theme,
  ) {
    final isSelected = muscles.every((m) => _selectedMuscles.contains(m));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final allSelected = muscles.every(
            (m) => _selectedMuscles.contains(m),
          );
          setState(() {
            if (allSelected) {
              // 全部已选 → 移除该组
              _selectedMuscles.removeWhere((m) => muscles.contains(m));
            } else {
              // 部分或未选 → 添加缺失的（合并，不替换）
              for (final m in muscles) {
                if (!_selectedMuscles.contains(m)) {
                  _selectedMuscles.add(m);
                }
              }
            }
          });
          if (mounted) {
            final l10n = context.l10n;
            final muscleNames = muscles.map((m) => m.displayName).join(', ');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  allSelected
                      ? l10n.pfQuickRemovedToast(muscleNames)
                      : l10n.pfQuickAddedToast(muscleNames),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
            border: Border.all(
              color: isSelected
                  ? theme.accentColor
                  : theme.accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: context.labelLarge.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? theme.onAccentColor : theme.accentColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 打开动作选择页面
  Future<void> _openExerciseSelection() async {
    final result = await ExerciseSelectionScreen.show(
      context,
      selectedMuscles: _selectedMuscles,
      initialExercises: _selectedExercises,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedExercises = result;
      });
    }
  }

  // ==================== 第3步：确认计划 ====================
  Widget _buildStep3(AppThemeData theme) {
    final l10n = context.l10n;
    // 计算预估时长（假设每组动作1.5分钟，休息1分钟）
    final estimatedDuration =
        (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5)
            .round();
    final totalSets = _selectedExercises.fold(
      0,
      (sum, e) => sum + e.effectiveSets,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pfConfirmHeading,
            style: context.headlineLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),

          // 计划名称输入
          Text(
            l10n.pfPlanNameLabel,
            style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.surfaceColorRaised,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: AppElevation.resting(theme.shadowColor),
            ),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.pfPlanNameHint,
                hintStyle: context.bodyLarge.copyWith(
                  color: theme.secondaryTextColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: context.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),

          // 计划摘要
          Container(
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            decoration: BoxDecoration(
              color: theme.surfaceColorRaised,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              boxShadow: AppElevation.resting(theme.shadowColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pfSummaryHeading,
                  style: context.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  l10n.pfSummaryMuscles,
                  _selectedMuscles.map((m) => m.displayName).join(', '),
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  l10n.pfSummaryExerciseCount,
                  l10n.pfExerciseCountValue(_selectedExercises.length),
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  l10n.pfSummaryTotalSets,
                  l10n.pfTotalSetsValue(totalSets),
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  l10n.pfSummaryDuration,
                  l10n.pfDurationValue(estimatedDuration),
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pfDurationFootnote,
            style: context.bodySmall.copyWith(
              fontSize: 12,
              color: theme.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          // 动作列表（可调整组数）
          Text(
            l10n.pfAdjustSetsHeading,
            style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _selectedExercises.length * 80.0,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _selectedExercises.length,
              // onReorderItem 的 newIndex 已按移除项调整过（等价于旧
              // onReorder 里手动的 if (newIndex > oldIndex) newIndex--）。
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _selectedExercises.removeAt(oldIndex);
                  _selectedExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return buildPlanFormExerciseSetItem(
                  context,
                  index: index,
                  planExercise: exercise,
                  theme: theme,
                  key: ValueKey(exercise.exerciseId),
                  onSetsChanged: (newSets) =>
                      _updateExerciseSets(index, newSets),
                  onRemove: () =>
                      setState(() => _selectedExercises.removeAt(index)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.bodyMedium.copyWith(color: theme.secondaryTextColor),
        ),
        Text(value, style: context.labelLarge),
      ],
    );
  }

  void _updateExerciseSets(int index, int newSets) {
    setState(() {
      final exercise = _selectedExercises[index];
      _selectedExercises[index] = exercise.copyWith(customSets: newSets);
    });
  }

  Widget _buildBottomButton(AppThemeData theme) {
    final l10n = context.l10n;
    String buttonText;
    bool isEnabled;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = l10n.pfNextSelectExercise;
        isEnabled = _selectedMuscles.isNotEmpty;
        onPressed = isEnabled ? _nextStep : null;
        break;
      case 1:
        buttonText = l10n.pfNextConfirm;
        isEnabled = _selectedExercises.isNotEmpty;
        onPressed = isEnabled ? _nextStep : null;
        break;
      case 2:
        buttonText = isEditMode ? l10n.pfSaveChanges : l10n.pfCreateTitle;
        isEnabled = _selectedExercises.isNotEmpty;
        onPressed = isEnabled ? _savePlan : null;
        break;
      default:
        buttonText = '';
        isEnabled = false;
        onPressed = null;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Row(
          children: [
            // 上一步按钮（左側，仅当不是第一步时显示）
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.accentColor,
                  side: BorderSide(
                    color: theme.accentColor.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: Text(
                  context.l10n.pfPreviousStep,
                  style: context.titleLarge.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // 下一步/保存按钮（右侧，占满剩余空间）
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? theme.accentColor
                      : theme.textColor.withValues(alpha: 0.1),
                  foregroundColor: theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.onAccentColor,
                          ),
                        ),
                      )
                    : Text(
                        buttonText,
                        style: context.titleLarge.copyWith(
                          color: isEnabled
                              ? theme.onAccentColor
                              : theme.secondaryTextColor,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _jumpToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _jumpToStep(_currentStep - 1);
    }
  }

  /// 跳转到指定步骤（用于步骤指示器点击和上一步）
  void _jumpToStep(int step) {
    if (step < 0 || step > 2 || step == _currentStep) return;
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _savePlan() async {
    final l10n = context.l10n;
    var name = _nameController.text.trim();
    // 如果未输入名称，自动按训练部位命名
    if (name.isEmpty) {
      name = _selectedMuscles.map((m) => m.displayName).join(' + ');
      if (name.isEmpty) name = l10n.pfDefaultPlanName;
    }

    final planProvider = context.read<PlanProvider>();

    // 计算预估时长
    final estimatedDuration =
        (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5)
            .round();

    setState(() => _isSaving = true);
    try {
      final editingPlan = widget.plan;
      if (isEditMode && editingPlan != null) {
        // 编辑模式
        final updatedPlan = editingPlan.copyWith(
          name: name,
          targetMuscles: _selectedMuscles,
          exercises: _selectedExercises,
          updatedAt: DateTime.now(),
          estimatedDuration: estimatedDuration,
        );
        await planProvider.updatePlan(updatedPlan);
      } else {
        // 创建模式
        final newPlan = WorkoutPlan(
          id: const Uuid().v4(),
          name: name,
          targetMuscles: _selectedMuscles,
          exercises: _selectedExercises,
          createdAt: DateTime.now(),
          estimatedDuration: estimatedDuration,
        );
        await planProvider.createPlan(newPlan);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final theme = context.read<ThemeProvider>().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pfSaveFailed(e.toString())),
            backgroundColor: theme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 检查是否有未保存的更改
  Future<bool> _hasUnsavedChanges() async {
    // 编辑模式：与原始计划比较
    final original = widget.plan;
    if (isEditMode && original != null) {
      final nameChanged = _nameController.text.trim() != original.name;
      final musclesChanged = !listEquals(
        _selectedMuscles,
        original.targetMuscles,
      );
      final exercisesChanged = !listEquals(
        _selectedExercises,
        original.exercises,
      );
      return nameChanged || musclesChanged || exercisesChanged;
    }
    // 创建模式：任何已输入数据都算未保存
    return _selectedMuscles.isNotEmpty ||
        _selectedExercises.isNotEmpty ||
        _nameController.text.trim().isNotEmpty;
  }

  /// 关闭前确认（有未保存更改时弹出对话框）
  Future<void> _confirmClose() async {
    if (!await _hasUnsavedChanges()) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted) return;
    final l10n = context.l10n;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pfDiscardTitle),
        content: Text(l10n.pfDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.pfKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pfDiscard),
          ),
        ],
      ),
    );
    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }
}
