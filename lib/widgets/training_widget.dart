import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/training_provider.dart';
import '../utils/dimensions.dart';
import '../providers/plan_provider.dart';
import '../providers/training_progress_provider.dart';
import '../providers/record_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import '../models/workout_plan.dart';
import '../models/set_data.dart';

import 'duration_picker.dart';
import 'glass_widgets.dart';
import 'animated_timer_widget.dart';
import 'completed_medal_display.dart';
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
              Expanded(
                child: _buildMainContent(training, theme, progressProvider),
              ),

              // 状态徽章
              _buildStatusBadge(training, theme, progressProvider),

              // 按钮区域
              _buildButtonArea(context, training, theme, progressProvider),

              // 底部导航栏空间
              SizedBox(height: AppDimensions.navBarTotalHeight),
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
              AppLocalizations.of(context)!.navTimer,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5, // Match other pages
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Plan icon button
          Tooltip(
            message: AppLocalizations.of(context)!.trainingSelectPlan,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    _showPlanSelector(theme, planProvider, progressProvider),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isPlanMode
                        ? theme.accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
        nextHint =
            AppLocalizations.of(context)!.trainingNextExercise(nextExercise.name);
      } else {
        nextHint = AppLocalizations.of(context)!.trainingNextDone;
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
                style: Theme.of(context).textTheme.bodySmall!,
              ),
            ),
        ],
      ),
    );
  }

  /// 主内容区域 - 计时器
  Widget _buildMainContent(
    TrainingProvider training,
    AppThemeData theme,
    TrainingProgressProvider progressProvider,
  ) {
    return Center(child: _buildTimerDisplay(training, theme));
  }

  /// 计时器显示 — 完成状态使用奖牌动画
  Widget _buildTimerDisplay(TrainingProvider training, AppThemeData theme) {
    // 完成状态： 奖牌变形动画
    // 奖牌圆盘直径 = timerSize（与计时器圆环等大），
    // SVG 的缎带/花环会溢出 SizedBox 但通过 Clip.none 显示。
    if (training.isCompleted) {
      return Center(
        child: CompletedMedalDisplay(
          sessionDuration: training.sessionDuration,
          theme: theme,
          size: AppDimensions.timerSize(context),
        ),
      );
    }

    // 休息状态：外环正计时 + 内环虚线倒计时
    if (training.isResting) {
      return Center(
        child: AnimatedTimerDisplay(
          seconds: training.restRemaining,
          label: AppLocalizations.of(context)!.trainingRestCountdown,
          theme: theme,
          size: AppDimensions.timerSize(context),
          sessionDuration: training.sessionDuration,
          countdownProgress: training.restDuration > 0
              ? training.restRemaining / training.restDuration
              : 0,
        ),
      );
    }

    // 运动中或暂停：外环正计时 + 内环满段
    if (training.isExercising || training.isExercisePaused) {
      return Center(
        child: AnimatedTimerDisplay(
          seconds: training.sessionDuration,
          label: AppLocalizations.of(context)!.trainingExercising,
          theme: theme,
          size: AppDimensions.timerSize(context),
          sessionDuration: training.sessionDuration,
          countdownProgress: 1.0,
        ),
      );
    }

    // 空闲状态：空外环 + 内环满段
    return Center(
      child: AnimatedTimerDisplay(
        seconds: training.restDuration,
        label: AppLocalizations.of(context)!.trainingRestDuration,
        theme: theme,
        size: AppDimensions.timerSize(context),
        sessionDuration: 0,
        countdownProgress: 1.0,
      ),
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
        text = AppLocalizations.of(context)!.trainingExerciseProgress(
          exercise.name,
          progressProvider.currentSetInExercise + 1,
        );
      } else {
        text = AppLocalizations.of(context)!
            .trainingSetExercising(training.currentSet);
      }
      icon = Icons.fitness_center;
    } else if (training.isResting) {
      color = theme.progressRingColor;
      if (_isPlanMode && progressProvider.currentExercise != null) {
        final exercise = progressProvider.currentExercise!;
        text = AppLocalizations.of(context)!.trainingExerciseRest(
          exercise.name,
          progressProvider.currentSetInExercise,
        );
      } else {
        text =
            AppLocalizations.of(context)!.trainingSetRest(training.currentSet);
      }
      icon = Icons.self_improvement;
    } else if (training.isCompleted) {
      color = theme.progressRingColor;
      text = AppLocalizations.of(context)!.trainingCompleted;
      icon = Icons.emoji_events;
    } else if (training.isExercisePaused) {
      color = theme.progressRingColor;
      text =
          AppLocalizations.of(context)!.trainingSetPaused(training.currentSet);
      icon = Icons.pause_circle_outline;
    } else {
      color = theme.secondaryTextColor;
      if (_isPlanMode && _selectedPlan != null) {
        text = AppLocalizations.of(context)!
            .trainingPlanReady(_selectedPlan!.name);
      } else {
        text = AppLocalizations.of(context)!.trainingReady;
      }
      icon = Icons.play_circle_outline;
    }

    // 完成状态：训练完成 + 组数 + 总时长 三徽章一行
    if (training.isCompleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusBadge(
              text: AppLocalizations.of(context)!.trainingCompleted,
              color: theme.progressRingColor,
              icon: Icons.emoji_events,
            ),
            const SizedBox(width: 10),
            StatusBadge(
              text: AppLocalizations.of(context)!
                  .trainingSetCount(training.currentSet),
              color: theme.progressRingColor,
              icon: Icons.fitness_center,
            ),
            const SizedBox(width: 10),
            StatusBadge(
              text: _formatTime(training.sessionDuration),
              color: theme.progressRingColor,
              icon: Icons.timer_outlined,
            ),
          ],
        ),
      );
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
            label: AppLocalizations.of(context)!.trainingStartExercise,
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
            iconColor: theme.errorColor,
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
            label: AppLocalizations.of(context)!.trainingRest,
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
            iconColor: theme.errorColor,
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
            label: AppLocalizations.of(context)!.trainingContinue,
            icon: Icons.play_arrow,
            onPressed: training.resumeFromPause,
          ),
        ],
      );
    }

    // 休息中：跳过休息(主按钮，居中)
    if (training.isResting) {
      return PrimaryActionButton(
        label: AppLocalizations.of(context)!.trainingSkipRest,
        icon: Icons.skip_next,
        onPressed: training.skipRest,
      );
    }

    // 完成状态：删除 + 继续 | 保存(主按钮)
    if (training.isCompleted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularControlButton(
            icon: Icons.delete_outline,
            iconColor: theme.errorColor,
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
            label: AppLocalizations.of(context)!.trainingSave,
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.trainingNoPlan),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
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
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.trainingSelectPlan,
                  style: Theme.of(context).textTheme.headlineMedium!,
                ),
                if (_isPlanMode)
                  TextButton(
                    onPressed: () {
                      progressProvider.endPlan();
                      Navigator.pop(context);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.trainingCancelPlan,
                      style: TextStyle(color: theme.errorColor),
                    ),
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: isSelected
                            ? theme.onAccentColor
                            : theme.accentColor,
                      ),
                    ),
                    title: Text(plan.name),
                    subtitle: Text(plan.targetMusclesText),
                    trailing: Text(
                      AppLocalizations.of(context)!
                          .trainingPlanSummary(plan.exerciseCount, plan.totalSets),
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

    if (training.isResting) {
      training.pauseRest();
    }

    final setData = await SetRecordDialog.show(
      context,
      exerciseName: completedExercise.name,
      setNumber: completedSetNumber,
      initialReps: lastSetData?.reps,
      initialWeight: lastSetData?.weight,
      exercise: completedExercise.exercise,
    );

    if (training.isRestPaused) {
      training.resumeRest();
    }

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
      // 方案 B：时长异常时先弹修正对话框（忘记停止导致计时器空转）
      if (training.hasAbnormalDuration) {
        final corrected = await _showDurationCorrectionDialog(
          context,
          training,
          theme,
        );
        if (corrected == null) return; // 用户关闭对话框，取消保存
        if (corrected > 0) {
          training.correctSessionDuration(corrected);
        }
        if (!context.mounted) return;
      }

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
        if (!context.mounted) return;
        final recordProvider = context.read<RecordProvider>();
        final record = progressProvider.generateRecord();
        await recordProvider.saveRecord(record);

        training.resetWorkout();
        progressProvider.endPlan();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.trainingSavedDetail(
                  record.totalSets,
                  record.durationText,
                ),
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
                AppLocalizations.of(context)!.trainingSavedCompleted(
                  data['totalSets'] as int,
                  training.sessionDurationFormatted,
                ),
              ),
              backgroundColor: theme.progressRingColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Training save failed: $e\n$st');
      if (context.mounted) {
        // Translate common failure modes to user-facing copy; the raw
        // exception string stays in the dev log, not on the user's screen.
        final l10n = AppLocalizations.of(context)!;
        final userMessage = _translateSaveError(e, l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: theme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 时长修正对话框（方案 B）。
  ///
  /// 返回值：
  /// - null：对话框被销毁（如页面退出），取消保存
  /// - 0：保持原时长
  /// - >0：用户修正后的时长（秒）
  Future<int?> _showDurationCorrectionDialog(
    BuildContext context,
    TrainingProvider training,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // 估算分钟数（预填值）
    final estimateMinutes = training.estimatedSessionDuration ~/ 60;
    final controller = TextEditingController(text: '$estimateMinutes');

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          l10n.trainingDurationCorrectionTitle,
          style: TextStyle(color: theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trainingDurationCorrectionMessage(
                _formatHoursMinutes(training.sessionDuration),
                training.currentSet,
              ),
              style: TextStyle(color: theme.textColor.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.accentColor.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.accentColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(0),
            child: Text(
              l10n.trainingDurationCorrectionKeep,
              style: TextStyle(color: theme.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.of(dialogContext).pop(
                minutes > 0 ? minutes * 60 : 0,
              );
            },
            child: Text(
              l10n.trainingDurationCorrectionApply,
              style: TextStyle(
                color: theme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// 把秒数格式化为 "X 小时 Y 分" 或 "Y 分钟"（修正对话框用）
  String _formatHoursMinutes(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours h $mins min' : '$hours h';
    }
    return '$minutes min';
  }

  /// Map a save-workout exception to a short user-facing message.
  ///
  /// The raw exception + stack trace are logged via [debugPrint] by the
  /// caller; this method only decides what the user sees. Unknown failures
  /// fall back to a generic retry prompt instead of leaking `error.toString()`.
  String _translateSaveError(Object e, AppLocalizations l10n) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('database') ||
        raw.contains('sqlite') ||
        raw.contains('sqflite')) {
      return l10n.trainingSaveFailedDb;
    }
    if (raw.contains('filesystem') ||
        raw.contains('no space') ||
        raw.contains('disk') ||
        raw.contains('storage')) {
      return l10n.trainingSaveFailedStorage;
    }
    return l10n.trainingSaveFailedGeneric;
  }
}
