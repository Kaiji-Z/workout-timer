import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flat Vitality 风格动画计时器显示
/// 
/// 设计特点:
/// - 粗进度环 (10px)
/// - 无发光/霓虹效果
/// - 扁平设计
/// - 高对比度
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

class _AnimatedTimerDisplayState extends State<AnimatedTimerDisplay> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度环 - 粗线条，无发光
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _FlatProgressPainter(
                progress: widget.progress,
                progressColor: widget.theme.progressRingColor,
                bgColor: widget.theme.progressBgColor,
                strokeWidth: widget.theme.progressStrokeWidth,
              ),
            ),
          ),
          // 中心内容卡片
          _buildTimerCard(),
        ],
      ),
    );
  }

  /// 构建计时器卡片 - 扁平设计
  Widget _buildTimerCard() {
    final timeText = _formatTime(widget.seconds);
    final cardSize = widget.size * 0.75;

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 扁平背景色 - 使用主背景色
        color: widget.theme.primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 计时器数字 - 带动画过渡效果
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              timeText,
              key: ValueKey(timeText),
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: widget.size * 0.2,
                fontWeight: FontWeight.w700,
                color: widget.theme.textColor,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: widget.size * 0.055,
              fontWeight: FontWeight.w500,
              color: widget.theme.secondaryTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 扁平进度环绘制器 - 无发光效果
class _FlatProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color bgColor;
  final double strokeWidth;

  _FlatProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // 背景环 - 浅色
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度环 - 深蓝色，粗线条
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlatProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.bgColor != bgColor;
  }
}

/// 小计时器（总时长显示）- 扁平设计
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              letterSpacing: -1,
            ),
          ),
          Text(
            '总时长',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: size * 0.11,
              fontWeight: FontWeight.w400,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 脉冲动画组件 - 保留用于完成状态
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
