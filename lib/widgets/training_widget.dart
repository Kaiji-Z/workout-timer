import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/training_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import 'duration_picker.dart';
import 'glass_widgets.dart';
import 'animated_timer_widget.dart';

/// 训练主界面 - 参考参考图布局
/// 
/// 布局结构：
/// - 紧凑 Header
/// - 大型计时器（垂直居中）
/// - 状态徽章
/// - 单行按钮区域
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
        return SafeArea(
          bottom: false, // 底部导航栏在外部
          child: Column(
            children: [
              // 紧凑 Header
              _buildCompactHeader(theme),
              
              // 主内容区域 - 计时器垂直居中
              Expanded(
                child: _buildMainContent(training, theme),
              ),
              
              // 底部固定区域：状态徽章 + 按钮区域
              _buildBottomSection(context, training, theme),
              
              // 为底部导航栏留出空间
              const SizedBox(height: 70),
            ],
          ),
        );
      },
    );
  }

  /// 紧凑 Header - 单行
  Widget _buildCompactHeader(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: theme.timerGradientColors,
        ).createShader(bounds),
        child: Text(
          'WORKOUT TIMER',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 6,
          ),
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

  /// 计时器显示 - 根据状态显示不同大小
  Widget _buildTimerDisplay(TrainingProvider training, AppThemeData theme) {
    // 休息状态：显示秒表 + 倒计时
    if (training.isResting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 小秒表显示总时长
          AnimatedStopwatchDisplay(
            seconds: training.sessionDuration,
            theme: theme,
            size: 60,
          ),
          const SizedBox(height: 20),
          // 主倒计时 - 280px
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

    // 运动中或暂停 - 360px 大计时器
    if (training.isExercising || training.isExercisePaused) {
      return AnimatedTimerDisplay(
        seconds: training.sessionDuration,
        label: '运动中',
        theme: theme,
        size: 360,
        isCountdown: false,
      );
    }

    // 完成状态 - 280px 完成显示
    if (training.isCompleted) {
      return _buildCompletedDisplay(training, theme);
    }

    // 空闲状态 - 360px 预览计时器
    return AnimatedTimerDisplay(
      seconds: training.restDuration,
      label: '休息时长',
      theme: theme,
      size: 360,
      isCountdown: false,
    );
  }

  /// 完成状态显示
  Widget _buildCompletedDisplay(TrainingProvider training, AppThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
PulsingWidget(
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.30),
                  border: Border.all(
                    color: theme.successColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
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
                      color: theme.successColor,
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
          ),
        ),
        const SizedBox(height: 20),
        // 统计徽章
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

  /// 底部区域：状态徽章 + 按钮区域卡片
  Widget _buildBottomSection(BuildContext context, TrainingProvider training, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 状态徽章
          _buildStatusBadge(training, theme),
          const SizedBox(height: 16),
          // 按钮区域 - 毛玻璃卡片
          _buildButtonAreaCard(context, training, theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 按钮区域毛玻璃卡片
  Widget _buildButtonAreaCard(BuildContext context, TrainingProvider training, AppThemeData theme) {
    final buttons = _getButtonsForState(context, training, theme);
    
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // 参考底部导航栏: 深色背景用低 alpha
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: SingleRowButtonArea(
            buttons: buttons,
            height: 52,
            gap: 10,
          ),
        ),
      ),
    );
  }

  /// 状态徽章
  Widget _buildStatusBadge(TrainingProvider training, AppThemeData theme) {
    Color color;
    String text;
    IconData icon;

    if (training.isExercising) {
      color = theme.primaryColor;
      text = '第 ${training.currentSet} 组 · 运动中';
      icon = Icons.fitness_center;
    } else if (training.isResting) {
      color = theme.successColor;
      text = '第 ${training.currentSet} 组 · 休息中';
      icon = Icons.self_improvement;
    } else if (training.isCompleted) {
      color = theme.successColor;
      text = '训练完成';
      icon = Icons.emoji_events;
    } else if (training.isExercisePaused) {
      color = theme.warningColor;
      text = '第 ${training.currentSet} 组 · 已暂停';
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



  /// 获取当前状态的统一颜色
  Color _getStateColor(TrainingProvider training, AppThemeData theme) {
    if (training.isExercising || training.isExercisePaused) {
      return theme.primaryColor; // 运动状态 - 主色调青绿
    }
    if (training.isResting) {
      return theme.successColor; // 休息状态 - 活力绿
    }
    if (training.isCompleted) {
      return theme.successColor; // 完成状态 - 活力绿
    }
    return theme.primaryColor; // 空闲状态 - 主色调
  }

  /// 根据状态获取按钮配置
  List<ButtonConfig> _getButtonsForState(BuildContext context, TrainingProvider training, AppThemeData theme) {
    final stateColor = _getStateColor(training, theme);
    
    // 空闲状态 - 主色调
    if (training.isIdle) {
      return [
        ButtonConfig(
          label: '设置时长',
          icon: Icons.timer_outlined,
          color: stateColor,
          isPrimary: false,
          onPressed: () => _showDurationPicker(context, training),
        ),
        ButtonConfig(
          label: '开始运动',
          icon: Icons.play_arrow_rounded,
          color: stateColor,
          onPressed: training.startExercise,
        ),
      ];
    }

    // 运动中 - 运动色
    if (training.isExercising) {
      return [
        ButtonConfig(
          label: '开始休息',
          icon: Icons.pause_circle_outline,
          color: stateColor,
          onPressed: training.startRest,
        ),
        ButtonConfig(
          label: '暂停',
          icon: Icons.pause,
          color: stateColor,
          isPrimary: false,
          onPressed: training.pauseExercise,
        ),
        ButtonConfig(
          label: '结束',
          icon: Icons.stop,
          color: stateColor,
          isPrimary: false,
          onPressed: training.endWorkout,
        ),
      ];
    }

    // 运动暂停 - 运动色 (只保留继续和结束)
    if (training.isExercisePaused) {
      return [
        ButtonConfig(
          label: '继续',
          icon: Icons.play_arrow,
          color: stateColor,
          onPressed: training.resumeFromPause,
        ),
        ButtonConfig(
          label: '结束',
          icon: Icons.stop,
          color: stateColor,
          isPrimary: false,
          onPressed: training.endWorkout,
        ),
      ];
    }

    // 休息中 - 休息色
    if (training.isResting) {
      return [
        ButtonConfig(
          label: '跳过休息',
          icon: Icons.skip_next,
          color: stateColor,
          onPressed: training.skipRest,
        ),
      ];
    }

    // 完成状态 - 完成色
    if (training.isCompleted) {
      return [
        ButtonConfig(
          label: '保存',
          icon: Icons.save,
          color: stateColor,
          onPressed: () => _saveWorkout(context, training),
        ),
        ButtonConfig(
          label: '继续',
          icon: Icons.replay,
          color: stateColor,
          onPressed: training.resumeExercise,
        ),
        ButtonConfig(
          label: '放弃',
          icon: Icons.delete_outline,
          color: stateColor,
          isPrimary: false,
          isDestructive: true,
          onPressed: training.resetWorkout,
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
