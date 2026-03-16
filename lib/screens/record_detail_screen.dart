import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // 自动迁移旧版记录到每组格式
    _exercises = widget.record.exercises.map((e) => 
      e.needsMigration ? e.migrateToSetData() : e
    ).toList();
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
                Column(
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
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        Text(
          '${index + 1}-${exercise.name}/${_getMuscleGroupName(exercise)}',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        
        const SizedBox(height: 12),
        
        // 详情行: 每组数据
        if (hasSetData) ...[
          // 显示组数据
          ...exercise.setsData!.map((setData) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => _showSetEditor(index, setData, exercise, theme),
                child: Text(
                  '第${setData.setNumber}组-${setData.reps ?? 0}×${(setData.weight ?? 0).toStringAsFixed(1)}kg',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
              ),
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
            onTap: () => _showSetEditor(index, null, exercise, theme),
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
                _hasChanges = true;
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

  void _showSetEditor(int exerciseIndex, SetData? setData, RecordedExercise exercise, AppThemeData theme) {
    // Create controllers with initial values
    final repsController = TextEditingController(
      text: setData?.reps?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: setData?.weight?.toString() ?? '',
    );
    
    final isNewSet = setData == null;
    final title = isNewSet 
        ? '添加组数据 - ${exercise.name}'
        : '编辑第${setData.setNumber}组 - ${exercise.name}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '次数',
                hintText: '输入次数',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: repsController,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '重量 (kg)',
                hintText: '输入重量',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: weightController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              repsController.dispose();
              weightController.dispose();
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final repsValue = int.tryParse(repsController.text);
              final weightValue = double.tryParse(weightController.text);
              
              // Validate input
              if (repsValue == null && weightValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请填写次数或重量'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              
              setState(() {
                List<SetData> updatedSetsData;
                
                if (isNewSet) {
                  // Adding a new set
                  final currentSets = exercise.setsData ?? [];
                  final newSetNumber = currentSets.isEmpty 
                      ? 1 
                      : currentSets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1;
                  
                  final newSet = SetData(
                    setNumber: newSetNumber,
                    reps: repsValue,
                    weight: weightValue,
                  );
                  
                  updatedSetsData = [...currentSets, newSet];
                } else {
                  // Editing existing set
                  updatedSetsData = exercise.setsData!.map((s) {
                    if (s.setNumber == setData.setNumber) {
                      return s.copyWith(
                        reps: repsValue,
                        weight: weightValue,
                      );
                    }
                    return s;
                  }).toList();
                }
                
                // Update the exercise in _exercises list
                final updatedExercise = exercise.copyWith(
                  setsData: updatedSetsData,
                  maxWeight: _calculateMaxWeight(updatedSetsData),
                  completedSets: updatedSetsData.length,
                );
                
                _exercises[exerciseIndex] = updatedExercise;
                _hasChanges = true;
              });
              
              repsController.dispose();
              weightController.dispose();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
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
