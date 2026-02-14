import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/timer_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.surfaceColor,
              ],
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
                  _buildTimerDisplay(timer, context, theme),
                  const SizedBox(height: 16),
                  _buildPresetChips(timer, theme),
                  const SizedBox(height: 12),
                  _buildCompletedSets(timer, theme),
                  const SizedBox(height: 24),
                  _buildControlButtons(timer, theme),
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

  Widget _buildTimerDisplay(TimerProvider timer, BuildContext context, AppThemeData theme) {
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
                progress: timer.progress,
                isRunning: timer.isRunning,
                gradientColors: theme.timerGradientColors,
                backgroundColor: theme.borderColor,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(timer.remainingSeconds),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  shadows: [
                    Shadow(
                      color: theme.primaryColor,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(timer, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TimerProvider timer, AppThemeData theme) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String text;

    if (timer.isRunning) {
      bgColor = theme.successColor.withOpacity(0.08);
      borderColor = theme.successColor.withOpacity(0.25);
      textColor = theme.successColor;
      text = 'ACTIVE';
    } else {
      bgColor = theme.primaryColor.withOpacity(0.06);
      borderColor = theme.primaryColor.withOpacity(0.19);
      textColor = theme.primaryColor;
      text = 'READY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPresetChips(TimerProvider timer, AppThemeData theme) {
    final presets = [30, 60, 90, 120];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.asMap().entries.map((entry) {
        final seconds = entry.value;
        final index = entry.key;
        final isSelected = timer.selectedPresetIndex == index && !timer.isRunning;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PresetChip(
            seconds: seconds,
            isSelected: isSelected,
            onPressed: () => timer.selectPreset(index),
            theme: theme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedSets(TimerProvider timer, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border.all(color: theme.borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${timer.totalSets}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
              shadows: [
                Shadow(
                  color: theme.primaryColor,
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '完成组数',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.secondaryTextColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(TimerProvider timer, AppThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ControlButton(
          label: timer.isRunning ? 'PAUSE' : 'START',
          color: timer.isRunning ? theme.warningColor : theme.primaryColor,
          gradient: timer.isRunning
              ? null
              : LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                ),
          onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
          theme: theme,
        ),
        _ControlButton(
          label: 'SKIP',
          color: theme.successColor,
          onPressed: timer.skipSet,
          theme: theme,
        ),
        _ControlButton(
          label: 'FINISH',
          color: theme.secondaryColor,
          onPressed: timer.finishWorkout,
          theme: theme,
        ),
        _ControlButton(
          label: 'RESET',
          color: theme.accentColor,
          onPressed: timer.resetTimer,
          theme: theme,
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final List<Color> gradientColors;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.isRunning,
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

    final gradient = LinearGradient(
      colors: gradientColors,
      stops: List.generate(gradientColors.length, (i) => i / (gradientColors.length - 1)),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..color = gradientColors.first
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
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.gradientColors != gradientColors;
  }
}

class _PresetChip extends StatelessWidget {
  final int seconds;
  final bool isSelected;
  final VoidCallback onPressed;
  final AppThemeData theme;

  const _PresetChip({
    required this.seconds,
    required this.isSelected,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final label = seconds >= 120 ? '2min' : '${seconds}s';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? theme.primaryColor : theme.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final Color color;
  final LinearGradient? gradient;
  final VoidCallback onPressed;
  final AppThemeData theme;

  const _ControlButton({
    required this.label,
    required this.color,
    this.gradient,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: gradient == null ? BorderSide(color: color.withOpacity(0.8), width: 2) : BorderSide.none,
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          border: gradient != null ? null : Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: gradient != null ? theme.backgroundColor : color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
