import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/training_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import 'duration_picker.dart';
import 'glass_widgets.dart';
import 'animated_timer_widget.dart';

class TrainingWidget extends StatelessWidget {
  const TrainingWidget({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Consumer<TrainingProvider>(
      builder: (context, training, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.backgroundColor.withOpacity(0.95),
                theme.surfaceColor,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(theme),
                  const SizedBox(height: 32),
                  _buildMainDisplay(training, theme),
                  const SizedBox(height: 24),
                  _buildStatusBadge(training, theme),
                  const SizedBox(height: 32),
                  _buildButtons(context, training, theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Column(
      children: [
        Text(
          'WORKOUT',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: theme.timerGradientColors,
          ).createShader(bounds),
          child: Text(
            'TIMER',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainDisplay(TrainingProvider training, AppThemeData theme) {
    // During rest: show both small stopwatch and large rest timer
    if (training.isResting) {
      return Column(
        children: [
          AnimatedStopwatchDisplay(
            seconds: training.sessionDuration,
            theme: theme,
            size: 90,
          ),
          const SizedBox(height: 24),
          AnimatedTimerDisplay(
            seconds: training.restRemaining,
            label: '休息倒计时',
            theme: theme,
            size: 220,
            isCountdown: true,
            progress: training.restDuration > 0 
                ? training.restRemaining / training.restDuration 
                : 0,
          ),
        ],
      );
    }

    // During exercise
    if (training.isExercising || training.isExercisePaused) {
      return Column(
        children: [
          AnimatedTimerDisplay(
            seconds: training.sessionDuration,
            label: '运动中',
            theme: theme,
            size: 260,
            isCountdown: false,
          ),
          const SizedBox(height: 20),
          GlassBadge(
            text: '第 ${training.currentSet} 组',
            color: theme.primaryColor,
            icon: Icons.fitness_center,
          ),
        ],
      );
    }

    // Completed state
    if (training.isCompleted) {
      return Column(
        children: [
          PulsingWidget(
            child: LiquidGlassContainer(
              borderRadius: 100,
              blur: 25,
              opacity: 0.15,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: theme.successColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTime(training.sessionDuration),
                      style: TextStyle(
                        fontFamily: '.SF Pro Display',
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总时长',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassBadge(
                text: '${training.currentSet} 组',
                color: theme.successColor,
                icon: Icons.repeat,
              ),
              const SizedBox(width: 12),
              GlassBadge(
                text: _formatTime(training.totalExerciseTime),
                color: theme.primaryColor,
                icon: Icons.timer,
              ),
            ],
          ),
        ],
      );
    }

    // Idle state: show rest duration setting preview
    return Column(
      children: [
        AnimatedTimerDisplay(
          seconds: training.restDuration,
          label: '休息时长',
          theme: theme,
          size: 220,
          isCountdown: false,
        ),
        const SizedBox(height: 8),
        Text(
          '点击下方按钮设置休息时长',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TrainingProvider training, AppThemeData theme) {
    Color color;
    String text;
    IconData icon;

    if (training.isExercising) {
      color = theme.primaryColor;
      text = training.statusText;
      icon = Icons.directions_run;
    } else if (training.isResting) {
      color = theme.successColor;
      text = training.statusText;
      icon = Icons.self_improvement;
    } else if (training.isCompleted) {
      color = theme.successColor;
      text = '训练完成';
      icon = Icons.emoji_events;
    } else if (training.isExercisePaused) {
      color = theme.warningColor;
      text = training.statusText;
      icon = Icons.pause_circle_outline;
    } else {
      color = theme.secondaryTextColor;
      text = '准备开始';
      icon = Icons.play_circle_outline;
    }

    return GlassBadge(
      text: text,
      color: color,
      icon: icon,
    );
  }

  Widget _buildButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
    if (training.isIdle) {
      return _buildIdleButtons(context, training, theme);
    } else if (training.isExercising || training.isExercisePaused) {
      // 运动中和暂停状态使用相同的按钮布局
      return _buildExercisingButtons(training, theme);
    } else if (training.isResting) {
      return _buildRestingButtons(training, theme);
    } else if (training.isCompleted) {
      return _buildCompletedButtons(context, training, theme);
    }
    return const SizedBox.shrink();
  }

  Widget _buildIdleButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        // Rest duration setting
        GestureDetector(
          onTap: () {
            DurationPicker.show(
              context,
              initialDurationSeconds: training.restDuration,
              onDurationSelected: (seconds) {
                training.setRestDuration(seconds);
              },
            );
          },
          child: LiquidGlassContainer(
            borderRadius: 16,
            blur: 10,
            opacity: 0.1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: theme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '休息时长',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      Text(
                        _formatTime(training.restDuration),
                        style: TextStyle(
                          fontFamily: '.SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: theme.secondaryTextColor, size: 20),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Start button
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            label: '开始运动',
            icon: Icons.play_arrow_rounded,
            color: theme.primaryColor,
            height: 60,
            onPressed: training.startExercise,
          ),
        ),
      ],
    );
  }

  Widget _buildExercisingButtons(TrainingProvider training, AppThemeData theme) {
    // Check if exercise is paused
    final isPaused = training.isExercisePaused;
    
    return Column(
      children: [
        // 暂停时只显示一个全宽继续按钮
        if (isPaused) 
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: '继续',
              icon: Icons.play_arrow,
              color: theme.primaryColor,
              height: 56,
              onPressed: training.resumeFromPause,
            ),
          )
        else ...[
          // 运动中显示两个按钮
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: '开始休息',
                  icon: Icons.pause_circle_outline,
                  color: theme.successColor,
                  height: 56,
                  onPressed: training.startRest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassOutlineButton(
                  label: '暂停',
                  icon: Icons.pause,
                  color: theme.warningColor,
                  height: 56,
                  onPressed: training.pauseExercise,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GlassOutlineButton(
            label: '结束运动',
            icon: Icons.stop,
            color: theme.accentColor,
            height: 56,
            onPressed: training.endWorkout,
          ),
        ),
      ],
    );
  }

  Widget _buildPausedButtons(TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: '继续',
                icon: Icons.play_arrow,
                color: theme.primaryColor,
                height: 56,
                onPressed: training.resumeFromPause,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                label: '休息',
                icon: Icons.self_improvement,
                color: theme.successColor,
                height: 56,
                onPressed: training.startRest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GlassOutlineButton(
            label: '结束运动',
            icon: Icons.stop,
            color: theme.accentColor,
            height: 56,
            onPressed: training.endWorkout,
          ),
        ),
      ],
    );
  }

  Widget _buildRestingButtons(TrainingProvider training, AppThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        label: '跳过休息',
        icon: Icons.skip_next,
        color: theme.successColor,
        height: 56,
        onPressed: training.skipRest,
      ),
    );
  }

  Widget _buildCompletedButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: '保存记录',
                icon: Icons.save,
                color: theme.primaryColor,
                height: 56,
                onPressed: () => _saveWorkout(context, training),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                label: '继续运动',
                icon: Icons.replay,
                color: theme.successColor,
                height: 56,
                onPressed: training.resumeExercise,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GlassOutlineButton(
            label: '放弃',
            icon: Icons.delete_outline,
            color: theme.warningColor,
            height: 56,
            onPressed: training.resetWorkout,
          ),
        ),
      ],
    );
  }

  Future<void> _saveWorkout(BuildContext context, TrainingProvider training) async {
    final repository = WorkoutRepository();
    final data = training.getWorkoutData();

    try {
      await repository.saveSession(
        data['totalSets'],
        data['sessionDurationMs'],
      );

      training.resetWorkout();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('训练已保存：完成${data['totalSets']}组，总时长 ${training.sessionDurationFormatted}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
