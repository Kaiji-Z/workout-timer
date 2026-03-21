import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../bloc/record_provider.dart';
import '../models/workout_record.dart';
import '../models/set_data.dart';
import '../models/muscle_group.dart';

import '../theme/app_theme.dart';

/// 训练记录详情页面 - Flat Vitality 设计
/// 
/// 显示训练记录的详细信息，支持编辑
class RecordDetailScreen extends StatefulWidget {
  final WorkoutRecord record;
  
  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late List<RecordedExercise> _exercises;
  bool _hasChanges = false;
  final Map<int, Map<int, TextEditingController>> _weightControllers = {};

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.record.exercises);
    
    // 初始化重量控制器
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      if (exercise.setsData != null) {
        _weightControllers[i] = {};
        for (final setData in exercise.setsData!) {
          _weightControllers[i]![setData.setNumber] = TextEditingController(
            text: setData.weight?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // 释放所有重量控制器
    for (final exerciseControllers in _weightControllers.values) {
      for (final controller in exerciseControllers.values) {
        controller.dispose();
      }
    }
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
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => _onBackPressed(),
        ),
        title: Text(
          '训练详情',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                '保存',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 训练摘要卡片
            _buildSummaryCard(theme),
            const SizedBox(height: 24),
            
            // 动作详情
            if (_exercises.isNotEmpty) ...[
              Text(
                '动作详情',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ..._exercises.asMap().entries.map((entry) {
                return _buildExerciseItem(entry.key, entry.value, theme);
              }),
              const SizedBox(height: 24),
            ],
            
            // 删除按钮
            _buildDeleteButton(theme),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRepsSelector({
    required int currentReps,
    required Function(int) onChanged,
    required AppThemeData theme,
  }) {
    return SizedBox(
      height: 80, // Show 3-4 items
      width: 60,  // Narrow width
      child: CupertinoPicker(
        itemExtent: 32,
        scrollController: FixedExtentScrollController(initialItem: currentReps - 1),
        onSelectedItemChanged: (index) => onChanged(index + 1),
        children: List.generate(30, (index) => 
          Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ),
      ),
    );
  }

  void _updateReps(int exerciseIndex, int setNumber, int reps) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final setsData = exercise.setsData ?? [];
      if (setsData.isEmpty) return;
      
      final updatedSetsData = setsData.map((s) {
        if (s.setNumber == setNumber) {
          return s.copyWith(reps: reps);
        }
        return s;
      }).toList();
      
      final updatedExercise = exercise.copyWith(
        setsData: updatedSetsData,
        maxWeight: _calculateMaxWeight(updatedSetsData),
        completedSets: updatedSetsData.length,
      );
      
      _exercises[exerciseIndex] = updatedExercise;
      _hasChanges = true;
    });
  }

 void _updateWeight(int exerciseIndex, int setNumber, double? weight) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final setsData = exercise.setsData ?? [];
      final updatedSetsData = setsData.map((s) {
        if (s.setNumber == setNumber) {
          return s.copyWith(weight: weight);
        }
        return s;
      }).toList();
      
      final updatedExercise = exercise.copyWith(
        setsData: updatedSetsData,
        maxWeight: _calculateMaxWeight(updatedSetsData),
        completedSets: updatedSetsData.length,
      );
      
      _exercises[exerciseIndex] = updatedExercise;
      _hasChanges = true;
    });
  }

  void _deleteSet(int exerciseIndex, int setNumber) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final updatedSetsData = exercise.setsData!.where((s) => s.setNumber != setNumber).toList();
      
      // 重新编号
      final renumberedSets = updatedSetsData.asMap().entries.map((entry) {
        final newIndex = entry.key + 1;
        return entry.value.copyWith(setNumber: newIndex);
      }).toList();
      
      final updatedExercise = exercise.copyWith(
        setsData: renumberedSets,
        maxWeight: _calculateMaxWeight(renumberedSets),
        completedSets: renumberedSets.length,
      );
      
      _exercises[exerciseIndex] = updatedExercise;
      _hasChanges = true;
      
      // 释放被删除的控制器
      _weightControllers[exerciseIndex]?.remove(setNumber)?.dispose();
    });
  }

  void _addSet(int exerciseIndex, RecordedExercise exercise) {
    setState(() {
      final currentSets = exercise.setsData ?? [];
      final newSetNumber = currentSets.isEmpty 
          ? 1 
          : currentSets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1;
      
      final newSet = SetData(
        setNumber: newSetNumber,
        reps: 12, // 默认12次
        weight: null,
      );
      
      final updatedSetsData = [...currentSets, newSet];
      final updatedExercise = exercise.copyWith(
        setsData: updatedSetsData,
        maxWeight: _calculateMaxWeight(updatedSetsData),
        completedSets: updatedSetsData.length,
      );
      
      _exercises[exerciseIndex] = updatedExercise;
      _hasChanges = true;
      
      // 添加新的控制器
      _weightControllers[exerciseIndex] ??= {};
      _weightControllers[exerciseIndex]![newSetNumber] = TextEditingController();
    });
  }

  Widget _buildSummaryCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// 日期和计划名称
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.fullDateText,
                        style: TextStyle(
                          fontFamily: '.SF Pro Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      if (widget.record.isPlanMode) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.playlist_add_check, size: 14, color: theme.accentColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.record.planName ?? '计划模式',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: '.SF Pro Text',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.accentColor,
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
                // 训练时长
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: theme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        widget.record.durationText,
                        style: TextStyle(
                          fontFamily: '.SF Pro Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          
          // 统计数据
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '${widget.record.totalSets}',
                  '总组数',
                  Icons.repeat,
                  theme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.textColor.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  '${widget.record.exerciseCount}',
                  '动作数',
                  Icons.fitness_center,
                  theme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.textColor.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildStatItem(
                  widget.record.trainedMuscles.isEmpty 
                      ? '无' 
                      : widget.record.trainedMuscles.map((m) => m.displayName).join('/'),
                  '训练部位',
                  Icons.accessibility_new,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }



Widget _buildExerciseItem(int index, RecordedExercise exercise, AppThemeData theme) {
  final hasSetData = exercise.setsData != null && exercise.setsData!.isNotEmpty;
  final exerciseControllers = _weightControllers[index] ?? {};
  
  return Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
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
         // 标题行: 序号-动作名称/训练部位
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${index + 1}-${exercise.name}/${_getMuscleGroupName(exercise)}',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 详情行: 每组数据
        if (hasSetData) ...[
          // 显示组数据
          ...exercise.setsData!.map((setData) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // 组数标签
                  SizedBox(
                    width: 40,
                    child: Text(
                      '第${setData.setNumber}组',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 次数选择器
                  SizedBox(
                    width: 60,
                    child: _buildRepsSelector(
                      currentReps: setData.reps ?? 12,
                      onChanged: (reps) => _updateReps(index, setData.setNumber, reps),
                      theme: theme,
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // 乘号
                  Text(
                    '×',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // 重量输入
                  Expanded(
                    child: TextField(
                      controller: exerciseControllers[setData.setNumber],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          color: theme.secondaryTextColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.accentColor,
                            width: 2,
                          ),
                        ),
                        suffixText: 'kg',
                        suffixStyle: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                      onChanged: (value) {
                        final weight = double.tryParse(value);
                        _updateWeight(index, setData.setNumber, weight);
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // 删除按钮 (紧凑)
                  GestureDetector(
                    onTap: () => _deleteSet(index, setData.setNumber),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 添加组按钮
          TextButton(
            onPressed: () => _addSet(index, exercise),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  '添加组',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 总容量（仅当有 setsData 时显示）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '总容量',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  '${exercise.totalVolume.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 无数据：显示提示
          GestureDetector(
            onTap: () => _addSet(index, exercise),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '点击添加训练数据',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  color: theme.accentColor,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  Future<void> _saveChanges() async {
    final updatedRecord = widget.record.copyWith(
      exercises: _exercises,
    );
    
    try {
      await context.read<RecordProvider>().updateRecord(updatedRecord);
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已保存'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  Future<void> _onBackPressed() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存更改？'),
        content: const Text('你有未保存的更改，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (shouldSave == true) {
      await _saveChanges();
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _getMuscleGroupName(RecordedExercise exercise) {
    final muscle = exercise.exercise?.primaryMuscle;
    return muscle?.displayName ?? '未指定';
  }

  
  
  /// Calculate max weight from sets data
  double? _calculateMaxWeight(List<SetData> setsData) {
    if (setsData.isEmpty) return null;
    final weights = setsData.where((s) => s.weight != null).map((s) => s.weight!).toList();
    if (weights.isEmpty) return null;
    return weights.reduce((a, b) => a > b ? a : b);
  }

  

  Widget _buildDeleteButton(AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text(
          '删除此记录',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条训练记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              try {
                await context.read<RecordProvider>().deleteRecord(widget.record.id);
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('已删除'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('删除失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
