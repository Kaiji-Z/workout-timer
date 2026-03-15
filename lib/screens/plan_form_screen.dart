import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/theme_provider.dart';
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
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  
  int _currentStep = 0;
  List<PrimaryMuscleGroup> _selectedMuscles = [];
  List<PlanExercise> _selectedExercises = [];
  
  bool get isEditMode => widget.plan != null;
  
  @override
  void initState() {
    super.initState();
    
    // 编辑模式：初始化数据
    if (isEditMode) {
      _selectedMuscles = List.from(widget.plan!.targetMuscles);
      _selectedExercises = List.from(widget.plan!.exercises);
      _nameController.text = widget.plan!.name;
    }
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
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? '编辑计划' : '创建计划',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                '上一步',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.accentColor,
                ),
              ),
            ),
        ],
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

  Widget _buildStepItem(int number, String label, bool isActive, AppThemeData theme) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > number - 1
                ? Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : theme.secondaryTextColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: isActive ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, AppThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
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
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择你今天想要训练的肌肉部位（可多选）',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
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
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('上肢', [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.back, PrimaryMuscleGroup.shoulders, PrimaryMuscleGroup.arms], theme),
            _buildQuickButton('下肢', [PrimaryMuscleGroup.legs, PrimaryMuscleGroup.core], theme),
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
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已选部位：${_selectedMuscles.isEmpty ? "未选择" : _selectedMuscles.map((m) => m.displayName).join("、")}',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // 已选动作摘要卡片
          if (_selectedExercises.isNotEmpty) ...[
            _buildSelectedSummaryCard(theme),
            const SizedBox(height: 16),
          ],
          
          // 选择动作入口按钮
          _buildSelectExerciseButton(theme),
          const SizedBox(height: 32),
          
          // 快速推荐（可选）
          _buildQuickRecommendations(theme),
        ],
      ),
    );
  }
  
  /// 已选动作摘要卡片
  Widget _buildSelectedSummaryCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已选动作',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedExercises.clear()),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedExercises.map((exercise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.hasDetails ? exercise.name : '${exercise.name} (无详情)',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 13,
                        color: exercise.hasDetails
                            ? theme.textColor
                            : theme.secondaryTextColor.withValues(alpha: 0.7),
                        fontStyle: exercise.hasDetails ? null : FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${exercise.targetSets}组)',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
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
    return GestureDetector(
      onTap: _openExerciseSelection,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  ? '选择训练动作' 
                  : '继续添加动作',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            if (_selectedExercises.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '已选 ${_selectedExercises.length} 个动作',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 快速推荐
  Widget _buildQuickRecommendations(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '或从推荐计划开始',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('上肢推', [PrimaryMuscleGroup.chest, PrimaryMuscleGroup.shoulders, PrimaryMuscleGroup.arms], theme),
            _buildQuickButton('上肢拉', [PrimaryMuscleGroup.back, PrimaryMuscleGroup.arms], theme),
            _buildQuickButton('下肢', [PrimaryMuscleGroup.legs, PrimaryMuscleGroup.core], theme),
            _buildQuickButton('全身', PrimaryMuscleGroup.values.toList(), theme),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickButton(String label, List<PrimaryMuscleGroup> muscles, AppThemeData theme) {
    final isSelected = _selectedMuscles.length == muscles.length && 
        _selectedMuscles.every((m) => muscles.contains(m));
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMuscles = muscles;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.accentColor 
              : theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? theme.accentColor 
                : theme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : theme.accentColor,
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
    final estimatedDuration = (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5).round();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '确认计划',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // 计划名称输入
          Text(
            '计划名称',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '例如：上肢训练日',
                hintStyle: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.secondaryTextColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 计划摘要
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '计划摘要',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('训练部位', _selectedMuscles.map((m) => m.displayName).join('、'), theme),
                const Divider(height: 24),
                _buildSummaryRow('动作数量', '${_selectedExercises.length} 个', theme),
                const Divider(height: 24),
                _buildSummaryRow('总组数', '${_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets)} 组', theme),
                const Divider(height: 24),
                _buildSummaryRow('预估时长', '~$estimatedDuration 分钟', theme),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 动作列表（可调整组数）
          Text(
            '调整组数（可选）',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedExercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _buildExerciseSetItem(index, exercise, theme);
          }),
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
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            color: theme.secondaryTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSetItem(int index, PlanExercise planExercise, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
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
                  planExercise.hasDetails ? planExercise.name : '${planExercise.name} (无详情)',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: planExercise.hasDetails
                        ? theme.textColor
                        : theme.secondaryTextColor.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  planExercise.exercise?.primaryMuscle.displayName ?? '',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          // 组数调整
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: planExercise.effectiveSets > 1
                    ? () => _updateExerciseSets(index, planExercise.effectiveSets - 1)
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
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: planExercise.effectiveSets < 10
                    ? () => _updateExerciseSets(index, planExercise.effectiveSets + 1)
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
            ],
          ),
        ],
      ),
    );
  }

  void _updateExerciseSets(int index, int newSets) {
    setState(() {
      final exercise = _selectedExercises[index];
      _selectedExercises[index] = exercise.copyWith(
        customSets: newSets,
      );
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    final estimatedDuration = (_selectedExercises.fold(0, (sum, e) => sum + e.effectiveSets) * 2.5).round();
    
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
