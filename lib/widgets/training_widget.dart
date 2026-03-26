import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/training_provider.dart';
import '../bloc/plan_provider.dart';
import '../bloc/training_progress_provider.dart';
import '../bloc/record_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import '../models/workout_plan.dart';
import '../models/set_data.dart';

import 'duration_picker.dart';
import 'glass_widgets.dart';
import 'animated_timer_widget.dart';
import 'plan_card.dart';
import 'bulk_exercise_data_dialog.dart';
import 'set_record_dialog.dart';

/// 训练主界面 - 极简设计
///
/// 布局：一屏显示，无需滚动
/// - 顶部标题 + 计划图标入口
/// - 极简进度行（计划模式）
/// - 中央计时器
/// - 状态徽章
/// - 按钮区域（主按钮在右侧）
class TrainingWidget extends StatefulWidget {
  const TrainingWidget({super.key});

  @override
  State<TrainingWidget> createState() => _TrainingWidgetState();
}

class _TrainingWidgetState extends State<TrainingWidget>
    with WidgetsBindingObserver {
  bool _isPlanMode = false;
  WorkoutPlan? _selectedPlan;
  bool _detailedRecordingEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDetailedRecordingPref();
  }

  Future<void> _loadDetailedRecordingPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _detailedRecordingEnabled = prefs.getBool('detailed_recording') ?? false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final training = context.read<TrainingProvider>();
      if (training.isExercising || training.isResting) {
        training.refreshDuration();
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    final progressProvider = context.watch<TrainingProgressProvider>();

    return Consumer<TrainingProvider>(
      builder: (context, training, child) {
        // 同步计划模式状态
        _isPlanMode = progressProvider.isPlanMode;
        _selectedPlan = progressProvider.currentPlan;

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 顶部标题 + 计划图标
              _buildHeader(theme, planProvider, progressProvider),

              // 极简进度行（计划模式下显示）
              if (_isPlanMode && _selectedPlan != null)
                _buildCompactProgress(progressProvider, theme),

              // 计时器 - 占用剩余空间
              Expanded(child: _buildMainContent(training, theme)),

              // 状态徽章
              _buildStatusBadge(training, theme, progressProvider),

              // 按钮区域
              _buildButtonArea(context, training, theme, progressProvider),

              // 底部导航栏空间
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  /// 顶部标题 + 计划图标入口
  Widget _buildHeader(
    AppThemeData theme,
    PlanProvider planProvider,
    TrainingProgressProvider progressProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 16),
      child: Row(
        children: [
          // Left spacer to balance plan icon
          const SizedBox(width: 40),
          // Centered title
          Expanded(
            child: Text(
              'WORKOUT TIMER',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5, // Match other pages
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Plan icon button
          GestureDetector(
            onTap: () =>
                _showPlanSelector(theme, planProvider, progressProvider),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isPlanMode
                    ? theme.accentColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.playlist_add_check,
                size: 24,
                color: _isPlanMode
                    ? theme.accentColor
                    : theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 极简进度行
  Widget _buildCompactProgress(
    TrainingProgressProvider progressProvider,
    AppThemeData theme,
  ) {
    final currentExercise = progressProvider.currentExercise;
    if (currentExercise == null) return const SizedBox.shrink();

    // 计算下一个动作提示
    String? nextHint;
    if (_isPlanMode && progressProvider.currentPlan != null) {
      final nextExercise = progressProvider.getNextExercise();
      if (nextExercise != null) {
        nextHint = 'next: ${nextExercise.name}';
      } else {
        nextHint = 'next: 训练完成';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          PlanProgressCompact(
            exerciseName: currentExercise.name,
            currentSet: progressProvider.currentSetInExercise + 1,
            totalSets: currentExercise.effectiveSets,
            totalProgress: progressProvider.progressPercentage,
          ),
          if (nextHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                nextHint,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 主内容区域 - 计时器
  Widget _buildMainContent(TrainingProvider training, AppThemeData theme) {
    return Center(child: _buildTimerDisplay(training, theme));
  }

  /// 计时器显示
  Widget _buildTimerDisplay(TrainingProvider training, AppThemeData theme) {
    // 休息状态：显示总时长 + 倒计时
    if (training.isResting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 小秒表显示总时长
          AnimatedStopwatchDisplay(
            seconds: training.sessionDuration,
            theme: theme,
            size: 70,
          ),
          const SizedBox(height: 16),
          // 主倒计时
          AnimatedTimerDisplay(
            seconds: training.restRemaining,
            label: '休息倒计时',
            theme: theme,
            size: 240,
            isCountdown: true,
            progress: training.restDuration > 0
                ? training.restRemaining / training.restDuration
                : 0,
          ),
        ],
      );
    }

    // 运动中或暂停
    if (training.isExercising || training.isExercisePaused) {
      return AnimatedTimerDisplay(
        seconds: training.sessionDuration,
        label: '运动中',
        theme: theme,
        size: 280,
        isCountdown: false,
      );
    }

    // 完成状态
    if (training.isCompleted) {
      return _buildCompletedDisplay(training, theme);
    }

    // 空闲状态
    return AnimatedTimerDisplay(
      seconds: training.restDuration,
      label: '休息时长',
      theme: theme,
      size: 280,
      isCountdown: false,
    );
  }

  /// 完成状态显示
  Widget _buildCompletedDisplay(TrainingProvider training, AppThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 完成圆圈
        PulsingWidget(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: theme.progressRingColor,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(training.sessionDuration),
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: theme.textColor,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '总时长',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 13,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 统计徽章
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusBadge(
              text: '${training.currentSet} 组',
              color: theme.progressRingColor,
              icon: Icons.repeat,
            ),
            const SizedBox(width: 12),
            StatusBadge(
              text: _formatTime(training.totalExerciseTime),
              color: theme.progressRingColor,
              icon: Icons.timer,
            ),
          ],
        ),
      ],
    );
  }

  /// 状态徽章
  Widget _buildStatusBadge(
    TrainingProvider training,
    AppThemeData theme,
    TrainingProgressProvider progressProvider,
  ) {
    Color color;
    String text;
    IconData icon;

    if (training.isExercising) {
      color = theme.progressRingColor;
      if (_isPlanMode && progressProvider.currentExercise != null) {
        final exercise = progressProvider.currentExercise!;
        text =
            '${exercise.name} · 第${progressProvider.currentSetInExercise + 1}组 · 运动中';
      } else {
        text = '第 ${training.currentSet} 组 · 运动中';
      }
      icon = Icons.fitness_center;
    } else if (training.isResting) {
      color = theme.progressRingColor;
      if (_isPlanMode && progressProvider.currentExercise != null) {
        final exercise = progressProvider.currentExercise!;
        text =
            '${exercise.name} · 已完成${progressProvider.currentSetInExercise}组 · 休息中';
      } else {
        text = '第 ${training.currentSet} 组 · 休息中';
      }
      icon = Icons.self_improvement;
    } else if (training.isCompleted) {
      color = theme.progressRingColor;
      text = '训练完成';
      icon = Icons.emoji_events;
    } else if (training.isExercisePaused) {
      color = theme.progressRingColor;
      text = '第 ${training.currentSet} 组 · 已暂停';
      icon = Icons.pause_circle_outline;
    } else {
      color = theme.secondaryTextColor;
      if (_isPlanMode && _selectedPlan != null) {
        text = '${_selectedPlan!.name} · 准备开始';
      } else {
        text = '准备开始';
      }
      icon = Icons.play_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: StatusBadge(text: text, color: color, icon: icon),
    );
  }

  /// 按钮区域 - 主按钮在右侧
  Widget _buildButtonArea(
    BuildContext context,
    TrainingProvider training,
    AppThemeData theme,
    TrainingProgressProvider progressProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildButtonsForState(context, training, theme, progressProvider),
    );
  }

  /// 根据状态构建按钮
  Widget _buildButtonsForState(
    BuildContext context,
    TrainingProvider training,
    AppThemeData theme,
    TrainingProgressProvider progressProvider,
  ) {
    // 空闲状态：设置按钮 | 开始(主按钮)
    if (training.isIdle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularControlButton(
            icon: Icons.timer_outlined,
            onPressed: () => _showDurationPicker(context, training),
          ),
          const SizedBox(width: 16),
          PrimaryActionButton(
            label: '开始运动',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              training.startExercise();
              if (_isPlanMode &&
                  _selectedPlan != null &&
                  progressProvider.startTime == null) {
                progressProvider.startPlan(_selectedPlan!);
              }
            },
          ),
        ],
      );
    }

    // 运动中：暂停 + 结束 | 休息(主按钮)
    if (training.isExercising) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularControlButton(
            icon: Icons.pause,
            onPressed: training.pauseExercise,
          ),
          const SizedBox(width: 12),
          CircularControlButton(
            icon: Icons.stop,
            iconColor: Colors.red,
            onPressed: () {
              if (_isPlanMode && progressProvider.currentExercise != null) {
                final completedExercise = progressProvider.currentExercise!;
                final completedSetNumber =
                    progressProvider.currentSetInExercise + 1;
                progressProvider.completeSet();
                _showSetRecordDialogAndEndWorkout(
                  context,
                  training,
                  progressProvider,
                  completedExercise,
                  completedSetNumber,
                );
              } else {
                if (_isPlanMode) {
                  progressProvider.completeSet();
                }
                training.endWorkout();
              }
            },
          ),
          const SizedBox(width: 16),
          PrimaryActionButton(
            label: '休息',
            icon: Icons.self_improvement,
            onPressed: () {
              if (_isPlanMode) {
                // 在 completeSet 之前捕获当前动作和组号（刚完成的）
                final completedExercise = progressProvider.currentExercise;
                final completedSetNumber =
                    progressProvider.currentSetInExercise + 1;

                progressProvider.completeSet();

                if (progressProvider.isAllExercisesComplete) {
                  // 最后一组：弹出记录对话框后结束训练（不开始休息，保持 exercising 状态）
                  if (completedExercise != null) {
                    _showSetRecordDialogAndEndWorkout(
                      context,
                      training,
                      progressProvider,
                      completedExercise,
                      completedSetNumber,
                    );
                  } else {
                    training.endWorkout();
                  }
                  return;
                }
                training.startRest();
                // 计划模式：休息开始时弹出记录对话框（传入刚完成的动作信息）
                if (completedExercise != null) {
                  _showSetRecordDialog(
                    context,
                    training,
                    progressProvider,
                    completedExercise,
                    completedSetNumber,
                  );
                }
              } else {
                training.startRest();
              }
            },
          ),
        ],
      );
    }

    // 暂停：结束 | 继续(主按钮)
    if (training.isExercisePaused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularControlButton(
            icon: Icons.stop,
            iconColor: Colors.red,
            onPressed: () {
              if (_isPlanMode && progressProvider.currentExercise != null) {
                final completedExercise = progressProvider.currentExercise!;
                final completedSetNumber =
                    progressProvider.currentSetInExercise + 1;
                progressProvider.completeSet();
                _showSetRecordDialogAndEndWorkout(
                  context,
                  training,
                  progressProvider,
                  completedExercise,
                  completedSetNumber,
                );
              } else {
                if (_isPlanMode) {
                  progressProvider.completeSet();
                }
                training.endWorkout();
              }
            },
          ),
          const SizedBox(width: 16),
          PrimaryActionButton(
            label: '继续',
            icon: Icons.play_arrow,
            onPressed: training.resumeFromPause,
          ),
        ],
      );
    }

    // 休息中：跳过休息(主按钮，居中)
    if (training.isResting) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PrimaryActionButton(
          label: '跳过休息',
          icon: Icons.skip_next,
          onPressed: training.skipRest,
        ),
      );
    }

    // 完成状态：删除 + 继续 | 保存(主按钮)
    if (training.isCompleted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularControlButton(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            onPressed: () {
              training.resetWorkout();
              if (_isPlanMode) {
                progressProvider.endPlan();
              }
            },
          ),
          const SizedBox(width: 12),
          CircularControlButton(
            icon: Icons.play_arrow,
            onPressed: () {
              training.resumeExercise();
            },
          ),
          const SizedBox(width: 16),
          PrimaryActionButton(
            label: '保存',
            icon: Icons.save,
            onPressed: () =>
                _saveWorkout(context, training, theme, progressProvider),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// 显示计划选择器
  void _showPlanSelector(
    AppThemeData theme,
    PlanProvider planProvider,
    TrainingProgressProvider progressProvider,
  ) {
    final plans = planProvider.plans;

    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还没有计划，请先创建计划'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择训练计划',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                if (_isPlanMode)
                  TextButton(
                    onPressed: () {
                      progressProvider.endPlan();
                      Navigator.pop(context);
                    },
                    child: Text('取消计划', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = _selectedPlan?.id == plan.id;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.accentColor
                            : theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: isSelected ? Colors.white : theme.accentColor,
                      ),
                    ),
                    title: Text(plan.name),
                    subtitle: Text(plan.targetMusclesText),
                    trailing: Text(
                      '${plan.exerciseCount}动作 · ${plan.totalSets}组',
                    ),
                    selected: isSelected,
                    onTap: () {
                      progressProvider.startPlan(plan);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示单组数据记录对话框（休息开始时弹出，休息期间记录）
  Future<void> _showSetRecordDialog(
    BuildContext context,
    TrainingProvider training,
    TrainingProgressProvider progressProvider,
    PlanExercise completedExercise,
    int completedSetNumber,
  ) async {
    // 获取之前保存的数据（如果有）
    final existingData = progressProvider.getExerciseSetsData(
      completedExercise.exerciseId,
    );
    SetData? lastSetData;
    if (existingData.isNotEmpty) {
      lastSetData = existingData.last;
    }

    if (!context.mounted) return;

    final setData = await SetRecordDialog.show(
      context,
      exerciseName: completedExercise.name,
      setNumber: completedSetNumber,
      initialReps: lastSetData?.reps,
      initialWeight: lastSetData?.weight,
      exercise: completedExercise.exercise,
    );

    if (setData != null && context.mounted) {
      progressProvider.addSetData(completedExercise.exerciseId, setData);
    }
  }

  /// 显示最后一组的记录对话框，关闭后结束训练
  Future<void> _showSetRecordDialogAndEndWorkout(
    BuildContext context,
    TrainingProvider training,
    TrainingProgressProvider progressProvider,
    PlanExercise completedExercise,
    int completedSetNumber,
  ) async {
    final existingData = progressProvider.getExerciseSetsData(
      completedExercise.exerciseId,
    );
    SetData? lastSetData;
    if (existingData.isNotEmpty) {
      lastSetData = existingData.last;
    }

    if (!context.mounted) return;

    final setData = await SetRecordDialog.show(
      context,
      exerciseName: completedExercise.name,
      setNumber: completedSetNumber,
      initialReps: lastSetData?.reps,
      initialWeight: lastSetData?.weight,
      exercise: completedExercise.exercise,
    );

    if (setData != null && context.mounted) {
      progressProvider.addSetData(completedExercise.exerciseId, setData);
    }

    // 对话框关闭后结束训练
    if (context.mounted) {
      training.endWorkout();
    }
  }

  /// 显示时长选择器
  void _showDurationPicker(BuildContext context, TrainingProvider training) {
    DurationPicker.show(
      context,
      initialDurationSeconds: training.restDuration,
      onDurationSelected: (seconds) {
        training.setRestDuration(seconds);
      },
    );
  }

  /// 保存训练记录
  Future<void> _saveWorkout(
    BuildContext context,
    TrainingProvider training,
    AppThemeData theme,
    TrainingProgressProvider progressProvider,
  ) async {
    try {
      if (_isPlanMode && _selectedPlan != null) {
        // 计划模式：先显示批量数据输入对话框
        if (_detailedRecordingEnabled) {
          final exerciseData = await showDialog<Map<String, List<SetData>>?>(
            context: context,
            builder: (context) => BulkExerciseDataDialog(
              exercises: _selectedPlan!.exercises,
              completedSets: progressProvider.completedSets,
              prePopulatedData: progressProvider.exerciseSetsData.isNotEmpty
                  ? progressProvider.exerciseSetsData
                  : null,
            ),
          );

          // 如果用户输入了数据，替换 progressProvider 中的数据（而非追加，避免重复）
          if (exerciseData != null) {
            for (final entry in exerciseData.entries) {
              progressProvider.replaceSetsData(entry.key, entry.value);
            }
          }
        }

        // 保存带详细动作的记录
        final record = progressProvider.generateRecord();
        await context.read<RecordProvider>().saveRecord(record);

        training.resetWorkout();
        progressProvider.endPlan();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '训练已保存：${record.totalSets}组，总时长 ${record.durationText}',
              ),
              backgroundColor: theme.progressRingColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 自由模式：保存简单记录
        final repository = WorkoutRepository();
        final data = training.getWorkoutData();

        await repository.saveSession(
          data['totalSets'],
          data['sessionDurationMs'],
        );

        training.resetWorkout();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '训练已保存：完成${data['totalSets']}组，总时长 ${training.sessionDurationFormatted}',
              ),
              backgroundColor: theme.progressRingColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
