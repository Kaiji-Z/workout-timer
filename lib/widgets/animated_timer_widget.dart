import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_widgets.dart';

/// iOS 26 风格动画计时器显示
class AnimatedTimerDisplay extends StatelessWidget {
  final int seconds;
  final String label;
  final AppThemeData theme;
  final double size;
  final bool isCountdown;
  final double progress;

  const AnimatedTimerDisplay({
    super.key,
    required this.seconds,
    required this.label,
    required this.theme,
    required this.size,
    this.isCountdown = false,
    this.progress = 1.0,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow background - stronger for prominence
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCountdown ? theme.successColor : theme.primaryColor)
                      .withOpacity(0.3),
                  spreadRadius: 20,
                  blurRadius: 50,
                ),
              ],
            ),
          ),
          // Progress ring - thicker for larger timer
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _TimerProgressPainter(
                progress: progress,
                color: isCountdown ? theme.successColor : theme.primaryColor,
                backgroundColor: theme.borderColor,
                strokeWidth: size * 0.1, // 10% of size (30px for 300px timer)
              ),
            ),
          ),
          // 简洁的半透明背景 - 替代毛玻璃
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.surfaceColor.withValues(alpha: 0.6),
              border: Border.all(
                color: (isCountdown ? theme.successColor : theme.primaryColor).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedNumber(
                    value: _formatTime(seconds),
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: size * 0.22, // Proportional to size (~66px for 300px)
                      fontWeight: FontWeight.w300,
                      color: theme.textColor,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: size * 0.07,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color,
          color.withOpacity(0.6),
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = strokeWidth * 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// iOS 26 风格小计时器（总时长显示）
class AnimatedStopwatchDisplay extends StatelessWidget {
  final int seconds;
  final AppThemeData theme;
  final double size;

  const AnimatedStopwatchDisplay({
    super.key,
    required this.seconds,
    required this.theme,
    this.size = 80,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 简洁的半透明背景
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.surfaceColor.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedNumber(
            value: _formatTime(seconds),
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: size * 0.22,
              fontWeight: FontWeight.w500,
              color: theme.textColor,
              letterSpacing: -1,
            ),
          ),
          Text(
            '总时长',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: size * 0.14,
              fontWeight: FontWeight.w400,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 脉冲动画组件
class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.98,
    this.maxScale = 1.02,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
