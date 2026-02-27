import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


/// iOS 26 风格动画计时器显示 - VitalFlow 2.0 霓虹风格
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
    final activeColor = isCountdown ? theme.successColor : theme.primaryColor;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 2a: 外层光晕 - 氛围效果
          Container(
            width: size * 1.25,
            height: size * 1.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  activeColor.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Layer 2b: 内层发光 - 霓虹效果
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.35),
                  spreadRadius: 12,
                  blurRadius: 35,
                ),
              ],
            ),
          ),
          // Layer 2c: Progress ring - 霓虹进度环
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _NeonProgressPainter(
                progress: progress,
                primaryColor: theme.primaryColor,
                secondaryColor: theme.successColor,
                strokeWidth: size * 0.1, // 增加到10%提高可见度
                isCountdown: isCountdown,
              ),
            ),
          ),
          // Layer 3: Timer Card - 毛玻璃圆形卡片
          _buildTimerCard(),
        ],
      ),
    );
  }

  /// 构建计时器毛玻璃卡片
  Widget _buildTimerCard() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),

          child: Padding(
            padding: EdgeInsets.all(size * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(seconds),
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF1A2B3C), // 高透毛玻璃上使用深色
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: size * 0.06,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.6), // 高透毛玻璃上使用深色
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 霓虹进度环绘制器 - VitalFlow 2.0
class _NeonProgressPainter extends ChangeNotifier implements CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final bool isCountdown;

  _NeonProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.isCountdown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final activeColor = isCountdown ? secondaryColor : primaryColor;

    // 背景环 - 增加可见度
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;

    // 外发光层 - 增强霓虹光晕
    final outerGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth * 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      outerGlowPaint,
    );

    // 进度环 - 渐变色 (青到绿)
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [
        primaryColor,
        isCountdown ? secondaryColor : primaryColor.withValues(alpha: 0.7),
        isCountdown ? primaryColor : secondaryColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 内发光 - 增强沿进度环中心发光
    final innerGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.8)
      ..strokeWidth = strokeWidth * 0.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      innerGlowPaint,
    );

    // 发光端点 - 进度头部的高亮效果
    if (progress > 0) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);
      final endPoint = Offset(endX, endY);

      // 外层光晕
      final glowDotPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(endPoint, strokeWidth * 0.8, glowDotPaint);

      // 内层亮点
      final brightDotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(endPoint, strokeWidth * 0.25, brightDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isCountdown != isCountdown;
  }

  @override
  bool shouldRebuildSemantics(covariant _NeonProgressPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool? hitTest(Offset position) => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
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
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.28),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(seconds),
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
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w400,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
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