import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/training_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/workout_repository.dart';
import 'duration_picker.dart';

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
              colors: [theme.backgroundColor, theme.surfaceColor],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildMainDisplay(training, theme),
                  const SizedBox(height: 16),
                  _buildStatusBadge(training, theme),
                  const SizedBox(height: 24),
                  _buildButtons(context, training, theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'WORKOUT TIMER',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: theme.timerGradientColors.take(2).toList(),
              ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainDisplay(TrainingProvider training, AppThemeData theme) {
    String displayTime;
    String label;
    double progress;

    if (training.isExercising || training.isExercisePaused) {
      displayTime = _formatTime(training.exerciseTime);
      label = '运动时长';
      progress = 1.0;
    } else if (training.isResting) {
      displayTime = _formatTime(training.restRemaining);
      label = '休息倒计时';
      progress = training.restRemaining / training.restDuration;
    } else if (training.isCompleted) {
      displayTime = _formatTime(training.totalExerciseTime + training.totalRestTime);
      label = '总用时';
      progress = 1.0;
    } else {
      displayTime = _formatTime(training.restDuration);
      label = '休息时长';
      progress = 1.0;
    }

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                gradientColors: training.isResting
                    ? [theme.successColor, theme.successColor.withOpacity(0.5)]
                    : theme.timerGradientColors,
                backgroundColor: theme.borderColor,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayTime,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  shadows: [
                    Shadow(
                      color: training.isResting ? theme.successColor : theme.primaryColor,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TrainingProvider training, AppThemeData theme) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (training.isExercising) {
      bgColor = theme.primaryColor.withOpacity(0.08);
      borderColor = theme.primaryColor.withOpacity(0.25);
      textColor = theme.primaryColor;
    } else if (training.isResting) {
      bgColor = theme.successColor.withOpacity(0.08);
      borderColor = theme.successColor.withOpacity(0.25);
      textColor = theme.successColor;
    } else if (training.isCompleted) {
      bgColor = theme.accentColor.withOpacity(0.08);
      borderColor = theme.accentColor.withOpacity(0.25);
      textColor = theme.accentColor;
    } else if (training.isExercisePaused) {
      bgColor = theme.warningColor.withOpacity(0.08);
      borderColor = theme.warningColor.withOpacity(0.25);
      textColor = theme.warningColor;
    } else {
      bgColor = theme.surfaceColor;
      borderColor = theme.borderColor;
      textColor = theme.secondaryTextColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        training.statusText,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
    if (training.isIdle) {
      return _buildIdleButtons(context, training, theme);
    } else if (training.isExercising) {
      return _buildExercisingButtons(training, theme);
    } else if (training.isExercisePaused) {
      return _buildPausedButtons(training, theme);
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
        // 休息时长设置
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border.all(color: theme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '休息时长: ${_formatTime(training.restDuration)}',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, color: theme.secondaryTextColor, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 开始运动按钮
        _PrimaryButton(
          label: '开始运动',
          icon: Icons.play_arrow_rounded,
          color: theme.primaryColor,
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
          ),
          theme: theme,
          onPressed: training.startExercise,
        ),
      ],
    );
  }

  Widget _buildExercisingButtons(TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _PrimaryButton(
                label: '开始休息',
                icon: Icons.pause_circle_outline,
                color: theme.successColor,
                theme: theme,
                onPressed: training.startRest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                label: '暂停',
                icon: Icons.pause,
                color: theme.warningColor,
                theme: theme,
                onPressed: training.pauseExercise,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: '结束运动',
          icon: Icons.stop,
          color: theme.accentColor,
          theme: theme,
          onPressed: training.endWorkout,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildPausedButtons(TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _PrimaryButton(
                label: '继续',
                icon: Icons.play_arrow,
                color: theme.primaryColor,
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                ),
                theme: theme,
                onPressed: training.resumeFromPause,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(
                label: '开始休息',
                icon: Icons.pause_circle_outline,
                color: theme.successColor,
                theme: theme,
                onPressed: training.startRest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: '结束运动',
          icon: Icons.stop,
          color: theme.accentColor,
          theme: theme,
          onPressed: training.endWorkout,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildRestingButtons(TrainingProvider training, AppThemeData theme) {
    return _PrimaryButton(
      label: '跳过休息',
      icon: Icons.skip_next,
      color: theme.successColor,
      theme: theme,
      onPressed: training.skipRest,
      isFullWidth: true,
    );
  }

  Widget _buildCompletedButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _PrimaryButton(
                label: '保存',
                icon: Icons.save,
                color: theme.primaryColor,
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                ),
                theme: theme,
                onPressed: () => _saveWorkout(context, training),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                label: '继续运动',
                icon: Icons.play_arrow,
                color: theme.successColor,
                theme: theme,
                onPressed: training.resumeExercise,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SecondaryButton(
          label: '放弃',
          icon: Icons.delete_outline,
          color: theme.warningColor,
          theme: theme,
          onPressed: training.resetWorkout,
          isFullWidth: true,
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
        data['totalExerciseTimeMs'] + data['totalRestTimeMs'],
      );

      training.resetWorkout();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('训练已保存：完成${data['totalSets']}组'),
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

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.gradientColors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    final gradient = LinearGradient(
      colors: gradientColors,
      stops: List.generate(gradientColors.length, (i) => i / (gradientColors.length - 1)),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.gradientColors != gradientColors;
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final LinearGradient? gradient;
  final VoidCallback onPressed;
  final AppThemeData theme;
  final bool isFullWidth;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    this.gradient,
    required this.onPressed,
    required this.theme,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: gradient == null ? color : Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (gradient != null) return Colors.transparent;
          return color;
        }),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: gradient != null ? theme.backgroundColor : theme.textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: gradient != null ? theme.backgroundColor : theme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final AppThemeData theme;
  final bool isFullWidth;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.theme,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
