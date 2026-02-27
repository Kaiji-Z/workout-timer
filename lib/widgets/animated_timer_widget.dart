import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';


/// iOS 26 风格动画计时器显示 - VitalFlow 2.0 霓虹风格
/// 增强版：添加呼吸氛围动画
class AnimatedTimerDisplay extends StatefulWidget {
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

  @override
  State<AnimatedTimerDisplay> createState() => _AnimatedTimerDisplayState();
}

class _AnimatedTimerDisplayState extends State<AnimatedTimerDisplay>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _glowController;
  late Animation<double> _breathAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // 呼吸动画 - 缓慢缩放
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // 发光脉冲动画 - 更快的光晕变化
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.45).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isCountdown ? widget.theme.successColor : widget.theme.primaryColor;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnimation, _glowAnimation]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: 呼吸外光晕 - 氛围效果（带动画）
              Transform.scale(
                scale: _breathAnimation.value * 1.1,
                child: Container(
                  width: widget.size * 1.35,
                  height: widget.size * 1.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        activeColor.withValues(alpha: _glowAnimation.value * 0.3),
                        activeColor.withValues(alpha: _glowAnimation.value * 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Layer 2: 涟漪效果（当倒计时时）
              if (widget.isCountdown) ...[
                _buildRipple(1.3, 0.15),
                _buildRipple(1.45, 0.08),
              ],
              // Layer 3: 内层发光 - 霓虹效果（带动画）
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: _glowAnimation.value + 0.1),
                      spreadRadius: 12 + (_breathAnimation.value - 1) * 20,
                      blurRadius: 35 + (_breathAnimation.value - 1) * 10,
                    ),
                  ],
                ),
              ),
              // Layer 4: Progress ring - 霓虹进度环
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _NeonProgressPainter(
                    progress: widget.progress,
                    primaryColor: widget.theme.primaryColor,
                    secondaryColor: widget.theme.successColor,
                    strokeWidth: widget.size * 0.1,
                    isCountdown: widget.isCountdown,
                    glowIntensity: _glowAnimation.value,
                  ),
                ),
              ),
              // Layer 5: Timer Card - 毛玻璃圆形卡片
              _buildTimerCard(),
            ],
          ),
        );
      },
    );
  }

  /// 构建涟漪效果
  Widget _buildRipple(double scale, double opacity) {
    return Transform.scale(
      scale: _breathAnimation.value * scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.theme.successColor.withValues(alpha: opacity * _glowAnimation.value),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// 构建计时器毛玻璃卡片
  Widget _buildTimerCard() {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: widget.size * 0.82,
          height: widget.size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.size * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(widget.seconds),
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: widget.size * 0.18,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF1A2B3C),
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: widget.size * 0.05,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.6),
                    letterSpacing: 1,
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

class _NeonProgressPainter extends ChangeNotifier implements CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final bool isCountdown;
  final double glowIntensity;

  _NeonProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.isCountdown,
    this.glowIntensity = 0.35,
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
      ..color = activeColor.withValues(alpha: glowIntensity + 0.15)
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
        oldDelegate.isCountdown != isCountdown ||
        oldDelegate.glowIntensity != glowIntensity;
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