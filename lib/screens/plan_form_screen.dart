import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../bloc/plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/muscle_group.dart';

import '../widgets/muscle_selector.dart';
import '../theme/app_theme.dart';
import 'exercise_selection_screen.dart';

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
    if (isEditMode) {
      _selectedMuscles = List.from(widget.plan!.targetMuscles);
      _selectedExercises = List.from(widget.plan!.exercises);
      _nameController.text = widget.plan!.name;
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
            tooltip: '关闭',
            icon: Icon(Icons.close, color: theme.textColor),
            onPressed: _confirmClose,
          ),
          title: Text(
            isEditMode ? '编辑计划' : '创建计划',
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Column(
          children: [
            // 步骤指示器
            _buildStepIndicator(theme),

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

  Widget _buildStepIndicator(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepItem(1, '选择部位', _currentStep >= 0, theme),
          _buildStepLine(_currentStep >= 1, theme),
          _buildStepItem(2, '选择动作', _currentStep >= 1, theme),
          _buildStepLine(_currentStep >= 2, theme),
          _buildStepItem(3, '确认计划', _currentStep >= 2, theme),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    int number,
    String label,
    bool isActive,
    AppThemeData theme,
  ) {
    // 步骤索引 = number - 1
    final stepIndex = number - 1;
    // 判断是否可点击：编辑模式全部可点击；创建模式只能回到已完成步骤
    final canTap = isEditMode || stepIndex < _currentStep;

    return GestureDetector(
      onTap: canTap ? () => _jumpToStep(stepIndex) : null,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.accentColor
                  : theme.textColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && _currentStep > number - 1
                  ? Icon(Icons.check, color: theme.onAccentColor, size: 18)
                  : Text(
                      '$number',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? theme.onAccentColor
                            : theme.secondaryTextColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: isActive ? theme.textColor : theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive, AppThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? theme.accentColor
            : theme.textColor.withValues(alpha: 0.1),
      ),
    );
  }

  // ==================== 第1步：选择部位 ====================
  Widget _buildStep1(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择训练部位',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '选择计划要覆盖的肌肉部位（可多选）',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速选择',
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('上肢', [
              PrimaryMuscleGroup.chest,
              PrimaryMuscleGroup.back,
              PrimaryMuscleGroup.shoulders,
              PrimaryMuscleGroup.arms,
            ], theme),
            _buildQuickButton('下肢', [
              PrimaryMuscleGroup.legs,
              PrimaryMuscleGroup.core,
            ], theme),
            _buildQuickButton('全身', PrimaryMuscleGroup.values.toList(), theme),
          ],
        ),
      ],
    );
  }

  // ==================== 第2步：选择动作 ====================
  Widget _buildStep2(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择训练动作',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '已选部位：${_selectedMuscles.isEmpty ? "未选择" : _selectedMuscles.map((m) => m.displayName).join("、")}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
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
                '已选动作',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('清空已选动作？'),
                      content: const Text('确定要清空所有已选动作吗？此操作无法撤销。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            '清空',
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
                  '清空',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(color: theme.accentColor),
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
                            : '${exercise.name} (无详情)',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                        '(${exercise.targetSets}组)',
                        style: Theme.of(context).textTheme.bodySmall!,
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
                _selectedExercises.isEmpty ? '选择训练动作' : '继续添加动作',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: theme.accentColor),
              ),
              if (_selectedExercises.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '已选 ${_selectedExercises.length} 个动作',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          final allSelected = muscles.every((m) => _selectedMuscles.contains(m));
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  allSelected
                      ? '已移除：${muscles.map((m) => m.displayName).join("、")}'
                      : '已添加：${muscles.map((m) => m.displayName).join("、")}',
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
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
    // 计算预估时长（假设每组动作1.5分钟，休息1分钟）
    final estimatedDuration =
        (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5)
            .round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '确认计划',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),

          // 计划名称输入
          Text(
            '计划名称',
            style: Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
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
                hintText: '例如：上肢训练日',
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: theme.secondaryTextColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge!,
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
                  '计划摘要',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  '训练部位',
                  _selectedMuscles.map((m) => m.displayName).join('、'),
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  '动作数量',
                  '${_selectedExercises.length} 个',
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  '总组数',
                  '${_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets)} 组',
                  theme,
                ),
                const Divider(height: 24),
                _buildSummaryRow('预估时长', '~$estimatedDuration 分钟', theme),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 预估时长 = 总组数 × 2.5分钟（含休息）',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 12,
              color: theme.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          // 动作列表（可调整组数）
          Text(
            '调整组数（可拖拽排序）',
            style: Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _selectedExercises.length * 80.0,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _selectedExercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _selectedExercises.removeAt(oldIndex);
                  _selectedExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final exercise = _selectedExercises[index];
                return _buildExerciseSetItem(
                  index,
                  exercise,
                  theme,
                  key: ValueKey(exercise.exerciseId),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
        ),
        Text(value, style: Theme.of(context).textTheme.labelLarge!),
      ],
    );
  }

  Widget _buildExerciseSetItem(
    int index,
    PlanExercise planExercise,
    AppThemeData theme, {
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: Row(
        children: [
          // 拖拽手柄
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.drag_indicator,
                color: theme.secondaryTextColor,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planExercise.hasDetails
                      ? planExercise.name
                      : '${planExercise.name} (无详情)',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: planExercise.hasDetails
                        ? theme.textColor
                        : theme.secondaryTextColor.withValues(alpha: 0.7),
                    fontStyle: planExercise.hasDetails
                        ? null
                        : FontStyle.italic,
                  ),
                ),
                Text(
                  planExercise.exercise?.primaryMuscle.displayName ?? '',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
              ],
            ),
          ),
          // 组数调整
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '减少组数',
                onPressed: planExercise.effectiveSets > 1
                    ? () => _updateExerciseSets(
                        index,
                        planExercise.effectiveSets - 1,
                      )
                    : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: planExercise.effectiveSets > 1
                      ? theme.accentColor
                      : theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '${planExercise.effectiveSets}',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge!.copyWith(fontSize: 18),
                ),
              ),
              IconButton(
                tooltip: '增加组数',
                onPressed: planExercise.effectiveSets < 10
                    ? () => _updateExerciseSets(
                        index,
                        planExercise.effectiveSets + 1,
                      )
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: planExercise.effectiveSets < 10
                      ? theme.accentColor
                      : theme.secondaryTextColor.withValues(alpha: 0.3),
                ),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // 删除动作按钮
              IconButton(
                tooltip: '删除动作',
                onPressed: () {
                  setState(() {
                    _selectedExercises.removeAt(index);
                  });
                },
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.errorColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateExerciseSets(int index, int newSets) {
    setState(() {
      final exercise = _selectedExercises[index];
      _selectedExercises[index] = exercise.copyWith(customSets: newSets);
    });
  }

  Widget _buildBottomButton(AppThemeData theme) {
    String buttonText;
    bool isEnabled;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = '下一步：选择动作';
        isEnabled = _selectedMuscles.isNotEmpty;
        onPressed = isEnabled ? _nextStep : null;
        break;
      case 1:
        buttonText = '下一步：确认计划';
        isEnabled = _selectedExercises.isNotEmpty;
        onPressed = isEnabled ? _nextStep : null;
        break;
      case 2:
        buttonText = isEditMode ? '保存修改' : '创建计划';
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
                  '上一步',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 15,
                  ),
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
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
    var name = _nameController.text.trim();
    // 如果未输入名称，自动按训练部位命名
    if (name.isEmpty) {
      name = _selectedMuscles.map((m) => m.displayName).join(' + ');
      if (name.isEmpty) name = '训练计划';
    }

    final planProvider = context.read<PlanProvider>();

    // 计算预估时长
    final estimatedDuration =
        (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5)
            .round();

    setState(() => _isSaving = true);
    try {
      if (isEditMode) {
        // 编辑模式
        final updatedPlan = widget.plan!.copyWith(
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
            content: Text('保存失败: $e'),
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

  /// 比较两个列表是否相等（按顺序逐元素比较）
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 检查是否有未保存的更改
  Future<bool> _hasUnsavedChanges() async {
    // 编辑模式：与原始计划比较
    if (isEditMode) {
      final original = widget.plan!;
      final nameChanged = _nameController.text.trim() != original.name;
      final musclesChanged = !_listEquals(
        _selectedMuscles,
        original.targetMuscles,
      );
      final exercisesChanged = !_listEquals(
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
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃编辑？'),
        content: const Text('您有未保存的更改，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }
}
