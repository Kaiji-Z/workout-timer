import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../bloc/record_provider.dart';
import '../models/workout_record.dart';
import '../models/set_data.dart';
import '../models/muscle_group.dart';
import '../widgets/muscle_selector.dart';
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
  late List<PrimaryMuscleGroup> _trainedMuscles;
  late List<RecordedExercise> _exercises;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _trainedMuscles = List.from(widget.record.trainedMuscles);
    _exercises = widget.record.exercises.map((e) => 
      RecordedExercise(
        exerciseId: e.exerciseId,
        exercise: e.exercise,
        completedSets: e.completedSets,
        maxWeight: e.maxWeight,
      )
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
            
            // 训练部位（可编辑）
            _buildMuscleSection(theme),
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
                  _trainedMuscles.isEmpty ? '无' : '${_trainedMuscles.length}',
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

  Widget _buildMuscleSection(AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '训练部位',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            if (_trainedMuscles.isNotEmpty)
              TextButton(
                onPressed: () => _showMuscleSelector(theme),
                child: Text(
                  '编辑',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.accentColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_trainedMuscles.isEmpty)
          GestureDetector(
            onTap: () => _showMuscleSelector(theme),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    '添加训练部位',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      color: theme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          MuscleBadge(muscles: _trainedMuscles),
      ],
    );
  }

Widget _buildExerciseItem(int index, RecordedExercise exercise, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exercise number badge + name + muscle group
          Row(
            children: [
              // Exercise number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Exercise name and muscle group
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontFamily: '.SF Pro Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (exercise.exercise?.primaryMuscle != null)
                      Text(
                        exercise.exercise!.primaryMuscle.displayName,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Body: Set rows with editable fields
          if (exercise.setsData != null && exercise.setsData!.isNotEmpty) ...[
            Column(
              children: [
                ...exercise.setsData!.map((setData) => 
                  _buildSetRow(setData, theme)
                ),
                const SizedBox(height: 12),
                // Total volume footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '总容量',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        '${exercise.totalVolume.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Legacy display with editable weight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${exercise.completedSets}组',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showWeightEditor(index, exercise, theme),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.textColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  exercise.weightText,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(SetData setData, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          // Set number label
          SizedBox(
            width: 60,
            child: Text(
              '第${setData.setNumber}组',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ),
          
          // Reps selector chips
          Expanded(
            child: _buildRepsSelector(setData.reps ?? 8, theme),
          ),
          
          // Weight input
          SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: (setData.weight ?? 0).toStringAsFixed(1)),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'kg',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.accentColor),
                ),
              ),
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepsSelector(int currentReps, AppThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(20, (index) {
          final reps = index + 1;
          final isSelected = reps == currentReps;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                reps.toString(),
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {},
              backgroundColor: theme.surfaceColor,
              selectedColor: theme.accentColor,
              elevation: 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
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

  void _showMuscleSelector(AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
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
                MuscleSelector(
                  selectedMuscles: _trainedMuscles,
                  onSelectionChanged: (muscles) {
                    setModalState(() {
                      _trainedMuscles = muscles;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasChanges = true;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWeightEditor(int index, RecordedExercise exercise, AppThemeData theme) {
    final controller = TextEditingController(
      text: exercise.maxWeight?.toStringAsFixed(1) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置最大重量 - ${exercise.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '重量 (kg)',
            hintText: '例如：60',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              setState(() {
                _exercises[index] = exercise.copyWith(maxWeight: weight);
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final updatedRecord = widget.record.copyWith(
      trainedMuscles: _trainedMuscles,
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
