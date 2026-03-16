import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/set_data.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

/// 批量训练数据记录对话框 - Flat Vitality 设计风格
/// 
/// 特点:
/// - 白色背景对话框
/// - 深色文字和图标
/// - 圆形按钮
/// - 简洁阴影
/// - 滚动列表显示所有动作
class BulkExerciseDataDialog extends StatefulWidget {
  final List<PlanExercise> exercises;
  final Map<String, int> completedSets;
  
  const BulkExerciseDataDialog({
    super.key,
    required this.exercises,
    required this.completedSets,
  });
  
  @override
  State<BulkExerciseDataDialog> createState() => _BulkExerciseDataDialogState();
}

class _BulkExerciseDataDialogState extends State<BulkExerciseDataDialog> {
  final Map<String, List<SetData>> _exerciseData = {};
  final Map<String, List<TextEditingController>> _weightControllers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  void _initializeData() {
    for (final exercise in widget.exercises) {
      final exerciseId = exercise.exerciseId;
      final sets = widget.completedSets[exerciseId] ?? exercise.effectiveSets;
      
      _exerciseData[exerciseId] = [];
      _weightControllers[exerciseId] = [];
      
      for (int i = 1; i <= sets; i++) {
        _exerciseData[exerciseId]!.add(SetData(
          setNumber: i,
          reps: 12, // 默认12次
          weight: null,
        ));
        _weightControllers[exerciseId]!.add(TextEditingController());
      }
    }
  }
  
  @override
  void dispose() {
    for (final controllers in _weightControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }
  
  void _updateReps(String exerciseId, int setNumber, int reps) {
    final index = setNumber - 1;
    if (_exerciseData[exerciseId] != null && index < _exerciseData[exerciseId]!.length) {
      setState(() {
        _exerciseData[exerciseId]![index] = _exerciseData[exerciseId]![index].copyWith(reps: reps);
      });
    }
  }
  
  void _updateWeight(String exerciseId, int setNumber, double? weight) {
    final index = setNumber - 1;
    if (_exerciseData[exerciseId] != null && index < _exerciseData[exerciseId]!.length) {
      setState(() {
        _exerciseData[exerciseId]![index] = _exerciseData[exerciseId]![index].copyWith(weight: weight);
      });
    }
  }
  
  Map<String, List<SetData>>? _getData() {
    final result = <String, List<SetData>>{};
    
    for (final entry in _exerciseData.entries) {
      final exerciseId = entry.key;
      final sets = entry.value.where((set) => set.reps != null || set.weight != null).toList();
      
      if (sets.isNotEmpty) {
        result[exerciseId] = sets;
      }
    }
    
    return result.isEmpty ? null : result;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              '记录训练数据',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            // 副标题
            Text(
              '滚动选择次数，输入重量',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // 滚动列表
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.exercises.map((exercise) {
                    final exerciseId = exercise.exerciseId;
                    final sets = _exerciseData[exerciseId] ?? [];
                    
                    return _buildExerciseCard(
                      exercise: exercise,
                      sets: sets,
                      theme: theme,
                      exerciseId: exerciseId,
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 跳过按钮
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
const SizedBox(width: 8),
                // 保存按钮
                ElevatedButton(
                  onPressed: () {
                    final data = _getData();
                    Navigator.of(context).pop(data);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseCard({
    required PlanExercise exercise,
    required List<SetData> sets,
    required AppThemeData theme,
    required String exerciseId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 动作名称
            Text(
              exercise.name,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            
            // 组数列表
            Column(
              children: sets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                final setNumber = index + 1;
                final weightController = _weightControllers[exerciseId]?[index];
                
                return _buildSetRow(
                  setNumber: setNumber,
                  set: set,
                  theme: theme,
                  exerciseId: exerciseId,
                  weightController: weightController,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSetRow({
    required int setNumber,
    required SetData set,
    required AppThemeData theme,
    required String exerciseId,
    required TextEditingController? weightController,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主行：组数 + reps × weight
          Row(
            children: [
              // 组数标签
              SizedBox(
                width: 40,
                child: Text(
                  '第$setNumber组',
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
                  currentReps: set.reps ?? 12,
                  onChanged: (reps) => _updateReps(exerciseId, setNumber, reps),
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
              SizedBox(
                width: 90,
                child: TextField(
                  controller: weightController,
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
                  ),
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value);
                    _updateWeight(exerciseId, setNumber, weight);
                  },
                 ),
              ),
              
              const SizedBox(width: 8),
              
              // 重量输入
              SizedBox(
                width: 90,
                child: TextField(
                  controller: weightController,
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
                  ),
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value);
                    _updateWeight(exerciseId, setNumber, weight);
                  },
                 ),
               )
             ],
           ),
         ],
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
}