import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../providers/record_provider.dart';
import '../models/workout_record.dart';
import '../models/set_data.dart';
import '../models/muscle_group.dart';

import '../theme/app_theme.dart';
import '../utils/dimensions.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.recDetailBackTooltip,
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => _onBackPressed(),
        ),
        title: Text(
          l10n.recDetailTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                l10n.recSave,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
              Text(l10n.recDetailExercisesSection,
                  style: Theme.of(context).textTheme.titleLarge!),
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
      width: 60, // Narrow width
      child: CupertinoPicker(
        itemExtent: 32,
        scrollController: FixedExtentScrollController(
          initialItem: currentReps - 1,
        ),
        onSelectedItemChanged: (index) => onChanged(index + 1),
        children: List.generate(
          30,
          (index) => Center(
            child: Text(
              '${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
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
      final updatedSetsData = exercise.setsData!
          .where((s) => s.setNumber != setNumber)
          .toList();

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
          : currentSets
                    .map((s) => s.setNumber)
                    .reduce((a, b) => a > b ? a : b) +
                1;

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
      _weightControllers[exerciseIndex]![newSetNumber] =
          TextEditingController();
    });
  }

  Widget _buildSummaryCard(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.resting(theme.shadowColor),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.record.fullDateText,
                        style: Theme.of(context).textTheme.headlineMedium!,
                      ),
                    ),
                    if (widget.record.isPlanMode) ...[
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.playlist_add_check,
                              size: 14,
                              color: theme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.record.planName ?? l10n.historyPlanMode,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
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
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.record.durationText,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
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
                  l10n.recDetailStatTotalSets,
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
                  l10n.recDetailStatExerciseCount,
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
                      ? l10n.recDetailNone
                      : widget.record.trainedMuscles
                            .map((m) => m.displayName)
                            .join('/'),
                  l10n.recDetailStatMuscles,
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

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    AppThemeData theme,
  ) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall!),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(
    int index,
    RecordedExercise exercise,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hasSetData =
        exercise.setsData != null && exercise.setsData!.isNotEmpty;
    final exerciseControllers = _weightControllers[index] ?? {};

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行: 序号-动作名称/训练部位
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _getExerciseDisplayName(index, exercise),
              style: Theme.of(context).textTheme.titleLarge!,
            ),
          ),

          const SizedBox(height: 12),

          // 详情行: 每组数据
          if (hasSetData) ...[
            // 显示组数据
            ...exercise.setsData!.map(
              (setData) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // 组数标签
                    SizedBox(
                      width: 40,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.dialogSetTitle(setData.setNumber),
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: theme.secondaryTextColor),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 次数选择器
                    SizedBox(
                      width: 60,
                      child: _buildRepsSelector(
                        currentReps: setData.reps ?? 12,
                        onChanged: (reps) =>
                            _updateReps(index, setData.setNumber, reps),
                        theme: theme,
                      ),
                    ),

                    const SizedBox(width: 4),

                    // 乘号
                    Text('×', style: Theme.of(context).textTheme.titleLarge!),

                    const SizedBox(width: 4),

                    // 重量输入
                    Expanded(
                      child: TextField(
                        controller: exerciseControllers[setData.setNumber],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: theme.secondaryTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            borderSide: BorderSide(color: theme.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            borderSide: BorderSide(
                              color: theme.accentColor,
                              width: 2,
                            ),
                          ),
                          suffixText: 'kg',
                          suffixStyle: Theme.of(context).textTheme.bodySmall!,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium!,
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          _updateWeight(index, setData.setNumber, weight);
                        },
                      ),
                    ),

                    const SizedBox(width: 4),

                    // 删除按钮 (紧凑)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _deleteSet(index, setData.setNumber),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.textColor.withValues(alpha: 0.5),
                          ),
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
                    l10n.recDetailAddSet,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: theme.accentColor),
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.recDetailTotalVolume,
                      style: Theme.of(context).textTheme.bodySmall!),
                  Text(
                    '${exercise.totalVolume.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 无数据：显示提示
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addSet(index, exercise),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Text(
                    l10n.recDetailAddDataPrompt,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: theme.accentColor),
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
    final l10n = AppLocalizations.of(context)!;
    final updatedRecord = widget.record.copyWith(exercises: _exercises);

    try {
      await context.read<RecordProvider>().updateRecord(updatedRecord);
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recDetailSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final theme = context.read<ThemeProvider>().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recDetailSaveFailed(e.toString())),
            backgroundColor: theme.errorColor,
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

    final l10n = AppLocalizations.of(context)!;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recDetailUnsavedTitle),
        content: Text(l10n.recDetailUnsavedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.recDetailDontSave),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recSave),
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

  String _getExerciseDisplayName(int index, RecordedExercise exercise) {
    final l10n = AppLocalizations.of(context)!;
    if (exercise.exercise != null) {
      return '${index + 1}-${exercise.name}/${_getMuscleGroupName(exercise)}';
    }
    // 旧记录可能没有关联的动作数据，显示未知动作
    return '${index + 1}-${l10n.recDetailUnknownExercise}';
  }

  String _getMuscleGroupName(RecordedExercise exercise) {
    final l10n = AppLocalizations.of(context)!;
    final muscle = exercise.exercise?.primaryMuscle;
    return muscle?.displayName ?? l10n.recDetailUnspecifiedMuscle;
  }

  /// Calculate max weight from sets data
  double? _calculateMaxWeight(List<SetData> setsData) {
    if (setsData.isEmpty) return null;
    final weights = setsData
        .where((s) => s.weight != null)
        .map((s) => s.weight!)
        .toList();
    if (weights.isEmpty) return null;
    return weights.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildDeleteButton(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(),
        icon: Icon(Icons.delete_outline, color: theme.errorColor),
        label: Text(
          l10n.recDetailDeleteButton,
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(color: theme.errorColor),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: theme.errorColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recDetailDeleteTitle),
        content: Text(l10n.recDetailDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.widgetCancel),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              try {
                await context.read<RecordProvider>().deleteRecord(
                  widget.record.id,
                );
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.recDetailDeleted),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.recDetailDeleteFailed(e.toString())),
                      backgroundColor: theme.errorColor,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.recDetailDeleteAction,
                style: TextStyle(color: theme.errorColor)),
          ),
        ],
      ),
    );
  }
}
