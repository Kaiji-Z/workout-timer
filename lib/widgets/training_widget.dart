import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/training_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import 'duration_picker.dart';
import 'glass_widgets.dart';
import 'animated_timer_widget.dart';

/// 训练主界面 - Flat Vitality 设计
/// 
/// 参考参考图布局:
/// - 顶部标题
/// - 中央大计时器
/// - 底部状态徽章 + 控制按钮
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
                theme.primaryColor,
                theme.secondaryColor,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 顶部标题
                _buildHeader(theme),
                
                // 主内容区域 - 计时器
                Expanded(
                  child: _buildMainContent(training, theme),
                ),
                
                // 底部区域：状态徽章 + 按钮
                _buildBottomSection(context, training, theme),
                
                // 底部导航栏空间
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 顶部标题 - 简洁扁平
  Widget _buildHeader(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      child: Text(
        'WORKOUT TIMER',
        style: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.textColor,
          letterSpacing: 3,
        ),
      ),
    );
  }

  /// 主内容区域 - 计时器
  Widget _buildMainContent(TrainingProvider training, AppThemeData theme) {
    return Center(
      child: _buildTimerDisplay(training, theme),
    );
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
          const SizedBox(height: 24),
          // 主倒计时
          AnimatedTimerDisplay(
            seconds: training.restRemaining,
            label: '休息倒计时',
            theme: theme,
            size: 280,
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
        size: 320,
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
      size: 320,
      isCountdown: false,
    );
  }

  /// 完成状态显示 - 扁平设计
  Widget _buildCompletedDisplay(TrainingProvider training, AppThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 完成圆圈
        PulsingWidget(
          child: Container(
            width: 200,
            height: 200,
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
                  size: 48,
                  color: theme.progressRingColor,
                ),
                const SizedBox(height: 12),
                Text(
                  _formatTime(training.sessionDuration),
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 40,
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
                    fontSize: 14,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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

  /// 底部区域
  Widget _buildBottomSection(BuildContext context, TrainingProvider training, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 状态徽章
          _buildStatusBadge(training, theme),
          const SizedBox(height: 20),
          // 按钮区域
          _buildButtonArea(context, training, theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 状态徽章 - 扁平设计
  Widget _buildStatusBadge(TrainingProvider training, AppThemeData theme) {
    Color color;
    String text;
    IconData icon;

    if (training.isExercising) {
      color = theme.progressRingColor;
      text = '第 ${training.currentSet} 组 · 运动中';
      icon = Icons.fitness_center;
    } else if (training.isResting) {
      color = theme.progressRingColor;
      text = '第 ${training.currentSet} 组 · 休息中';
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
      text = '准备开始';
      icon = Icons.play_circle_outline;
    }

    return StatusBadge(
      text: text,
      color: color,
      icon: icon,
    );
  }

  /// 按钮区域 - 参考图风格
  Widget _buildButtonArea(BuildContext context, TrainingProvider training, AppThemeData theme) {
    final buttons = _getButtonsForState(context, training, theme);
    
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildButtonRow(buttons),
    );
  }

  /// 构建按钮行 - 参考图风格: 圆形按钮
  List<Widget> _buildButtonRow(List<_ButtonInfo> buttons) {
    if (buttons.length == 1) {
      // 单个按钮 - 大胶囊按钮
      return [
        PrimaryActionButton(
          label: buttons[0].label,
          icon: buttons[0].icon,
          backgroundColor: buttons[0].isDestructive ? Colors.red : null,
          onPressed: buttons[0].onPressed,
          isWide: true,
        ),
      ];
    } else if (buttons.length == 2) {
      // 两个按钮 - 左圆形 + 右胶囊
      return [
        CircularControlButton(
          icon: buttons[0].icon,
          iconColor: buttons[0].isDestructive ? Colors.red : null,
          onPressed: buttons[0].onPressed,
        ),
        const SizedBox(width: 16),
        PrimaryActionButton(
          label: buttons[1].label,
          icon: buttons[1].icon,
          onPressed: buttons[1].onPressed,
          isWide: true,
        ),
      ];
    } else {
      // 三个按钮 - 左圆 + 中圆 + 右胶囊
      return [
        CircularControlButton(
          icon: buttons[0].icon,
          onPressed: buttons[0].onPressed,
        ),
        const SizedBox(width: 12),
        CircularControlButton(
          icon: buttons[1].icon,
          onPressed: buttons[1].onPressed,
        ),
        const SizedBox(width: 12),
        PrimaryActionButton(
          label: buttons[2].label,
          icon: buttons[2].icon,
          onPressed: buttons[2].onPressed,
          isWide: true,
        ),
      ];
    }
  }

  /// 获取当前状态的按钮配置
  List<_ButtonInfo> _getButtonsForState(BuildContext context, TrainingProvider training, AppThemeData theme) {
    // 空闲状态
    if (training.isIdle) {
      return [
        _ButtonInfo(
          label: '设置',
          icon: Icons.timer_outlined,
          onPressed: () => _showDurationPicker(context, training),
        ),
        _ButtonInfo(
          label: '开始运动',
          icon: Icons.play_arrow_rounded,
          onPressed: training.startExercise,
          isPrimary: true,
        ),
      ];
    }

    // 运动中
    if (training.isExercising) {
      return [
        _ButtonInfo(
          icon: Icons.pause,
          onPressed: training.pauseExercise,
        ),
        _ButtonInfo(
          icon: Icons.local_cafe,
          onPressed: training.startRest,
        ),
        _ButtonInfo(
          label: '结束',
          icon: Icons.stop,
          onPressed: training.endWorkout,
        ),
      ];
    }

    // 运动暂停
    if (training.isExercisePaused) {
      return [
        _ButtonInfo(
          icon: Icons.stop,
          onPressed: training.endWorkout,
          isDestructive: true,
        ),
        _ButtonInfo(
          label: '继续',
          icon: Icons.play_arrow,
          onPressed: training.resumeFromPause,
          isPrimary: true,
        ),
      ];
    }

    // 休息中
    if (training.isResting) {
      return [
        _ButtonInfo(
          label: '跳过休息',
          icon: Icons.skip_next,
          onPressed: training.skipRest,
          isPrimary: true,
        ),
      ];
    }

    // 完成状态
    if (training.isCompleted) {
      return [
        _ButtonInfo(
          icon: Icons.delete_outline,
          onPressed: training.resetWorkout,
          isDestructive: true,
        ),
        _ButtonInfo(
          label: '保存',
          icon: Icons.save,
          onPressed: () => _saveWorkout(context, training, theme),
          isPrimary: true,
        ),
      ];
    }

    return [];
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
  Future<void> _saveWorkout(BuildContext context, TrainingProvider training, AppThemeData theme) async {
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
            backgroundColor: theme.progressRingColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

/// 按钮信息
class _ButtonInfo {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  _ButtonInfo({
    this.label = '',
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

