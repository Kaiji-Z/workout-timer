import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Flat Vitality 风格多环计时器显示
///
/// 设计特点:
/// - 外环：正计时进度条（实线，圆头，每 60 分钟一圈）
/// - 内环：倒计时进度条（虚线 60 段，平头，一秒一段）
/// - idle 状态:外环空轨道 + 内环淡虚线轨道 + 数字 Light 字重 + 极轻呼吸
/// - 扁平设计，高对比度
/// - Rajdhani (Light 用于 idle, SemiBold/Bold 用于激活态)
class AnimatedTimerDisplay extends StatefulWidget {
  final int seconds;
  final String label;
  final AppThemeData theme;
  final double size;
  final int sessionDuration;
  final double countdownProgress;

  const AnimatedTimerDisplay({
    super.key,
    required this.seconds,
    required this.label,
    required this.theme,
    required this.size,
    this.sessionDuration = 0,
    this.countdownProgress = 1.0,
  });

  @override
  State<AnimatedTimerDisplay> createState() => _AnimatedTimerDisplayState();
}

class _AnimatedTimerDisplayState extends State<AnimatedTimerDisplay>
    with SingleTickerProviderStateMixin {
  // idle 状态的呼吸动画:3 秒周期,scale 1.0 → 1.015 → 1.0。
  // 幅度刻意压到 1.5% — 肉眼"察觉不到在动但感觉是活的",不抢戏。
  // 激活态不启动该动画(数字已经在跳秒,不需要额外呼吸)。
  late final AnimationController _idleBreathController;
  late final Animation<double> _idleBreath;
  bool _reduceMotion = false;

  /// idle = 既没累计时长,内环又是满段(training_widget 传入的空闲信号)
  bool get _isIdle =>
      widget.sessionDuration == 0 && widget.countdownProgress >= 1.0;

  @override
  void initState() {
    super.initState();
    _idleBreathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _idleBreath = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(
        parent: _idleBreathController,
        // ease-in-out 让呼吸两端都有减速,模拟自然呼吸节律
        curve: Curves.easeInOut,
      ),
    );
    _idleBreathController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 尊重系统 reduce-motion 设置:开启时禁用呼吸,静态呈现 idle
    _reduceMotion =
        MediaQuery.accessibleNavigationOf(context) ||
        MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _idleBreathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useBreath = _isIdle && !_reduceMotion;
    if (!useBreath) _idleBreathController.stop();
    final ringChild = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _TimerRingPainter(
          sessionDuration: widget.sessionDuration,
          countdownProgress: widget.countdownProgress,
          isIdle: _isIdle,
          theme: widget.theme,
        ),
      ),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          useBreath
              ? AnimatedBuilder(
                  animation: _idleBreath,
                  builder: (context, child) => Transform.scale(
                    scale: _idleBreath.value,
                    child: child,
                  ),
                  child: ringChild,
                )
              : ringChild,
          _buildTimerCard(),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    final timeText = _formatTime(widget.seconds);
    final cardSize = widget.size * 0.65;
    // idle 用 Light 字重 + 0.85 透明,提示"未激活";激活态恢复 SemiBold 实色
    final isIdle = _isIdle;
    final digitColor = isIdle
        ? widget.theme.textColor.withValues(alpha: 0.85)
        : widget.theme.textColor;

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.theme.primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Text(
              timeText,
              key: ValueKey(timeText),
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontFamily: 'Rajdhani',
                fontWeight: isIdle ? FontWeight.w300 : FontWeight.w700,
                fontSize: widget.size * 0.18,
                letterSpacing: -0.5,
                color: digitColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontSize: widget.size * 0.045,
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

/// 多环计时器绘制器
///
/// 外环：正计时进度条（实线，圆头，每 60 分钟一圈，可多环）
/// 内环：倒计时/就绪进度条（虚线 60 段，平头，始终显示）
class _TimerRingPainter extends CustomPainter {
  final int sessionDuration;
  final double countdownProgress;
  final bool isIdle;
  final AppThemeData theme;

  // ── 尺寸常量 ──
  static const double _outerStrokeWidth = 8.0;
  static const double _innerStrokeWidth = 6.0;
  static const double _outerRingGap = 4.0; // 多个外环之间的间距
  static const double _innerOuterGap = 12.0; // 内环与最外环之间的间距（大于外环间距）
  static const double _edgeMargin = 8.0; // 容器边缘留白
  static const int _segmentsPerRing = 60; // 倒计时内环分段数
  static const double _segmentGapRadians =
      math.pi / 180 * 1.2; // 每段之间的间隙角度（~1.2°）
  static const int _secondsPerRing = 3600; // 60 分钟 = 3600 秒

  _TimerRingPainter({
    required this.sessionDuration,
    required this.countdownProgress,
    this.isIdle = false,
    required this.theme,
  });

  /// 计算需要的外环数量（含当前进行中的那一个）
  int get _outerRingCount {
    if (sessionDuration <= 0) return 1; // 空闲状态也显示一个空轨道
    return (sessionDuration ~/ _secondsPerRing) + 1;
  }

  /// 当前外环的进度（0.0 ~ 1.0）
  double get _currentRingProgress {
    if (sessionDuration <= 0) return 0.0;
    return (sessionDuration % _secondsPerRing) / _secondsPerRing;
  }

  /// 已完成的外环数量
  int get _completeRingCount => sessionDuration ~/ _secondsPerRing;

  /// 计算第 N 个外环的半径（0 = 最外层）
  double _outerRingRadius(int index, double totalRadius) {
    return (totalRadius -
            _edgeMargin -
            index * (_outerStrokeWidth + _outerRingGap))
        .clamp(0.0, totalRadius);
  }

  /// 计算内环半径
  double _innerRingRadius(double totalRadius) {
    final lastOuterIndex = _outerRingCount - 1;
    final lastOuterRadius = _outerRingRadius(lastOuterIndex, totalRadius);
    return (lastOuterRadius -
            _outerStrokeWidth / 2 -
            _innerOuterGap -
            _innerStrokeWidth / 2)
        .clamp(0.0, lastOuterRadius - _outerStrokeWidth);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final totalRadius = size.width / 2;

    // ── 绘制外环（正计时） ──
    _paintOuterRings(canvas, center, totalRadius);

    // ── 绘制内环（虚线段，始终显示） ──
    _paintInnerRing(canvas, center, totalRadius);
  }

  void _paintOuterRings(Canvas canvas, Offset center, double totalRadius) {
    final ringCount = _outerRingCount;

    for (int i = ringCount - 1; i >= 0; i--) {
      final radius = _outerRingRadius(i, totalRadius);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final isComplete = i < _completeRingCount;
      final isCurrent = i == _completeRingCount;

      // 背景轨道（始终显示）
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = theme.accentColor.withValues(alpha: 0.12)
          ..strokeWidth = _outerStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // 进度弧
      if (isComplete) {
        // 已完成的环 — 画满一圈
        canvas.drawArc(
          rect,
          -math.pi / 2,
          2 * math.pi,
          false,
          Paint()
            ..color = theme.accentColor
            ..strokeWidth = _outerStrokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      } else if (isCurrent) {
        // 当前进行中的环
        final progress = _currentRingProgress.clamp(0.0, 1.0);
        if (progress > 0) {
          canvas.drawArc(
            rect,
            -math.pi / 2,
            2 * math.pi * progress,
            false,
            Paint()
              ..color = theme.accentColor
              ..strokeWidth = _outerStrokeWidth
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round,
          );
        }
      }
      // ringCount > completeRingCount + 1 的环（未来环）只显示背景轨道
    }
  }

  void _paintInnerRing(Canvas canvas, Offset center, double totalRadius) {
    final radius = _innerRingRadius(totalRadius);
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final totalAngle = 2 * math.pi;
    final segmentAngle = totalAngle / _segmentsPerRing;
    final activeSegmentAngle = segmentAngle - _segmentGapRadians;

    // idle 状态:只画淡虚线轨道(不画活跃段),不透明度提高到 0.18,
    // 让"环已就绪待填充"的暗示比运行中的 0.1 背景段更可见。
    // 激活态:画 0.1 背景段 + 实色活跃段(原有逻辑)。
    final trackAlpha = isIdle ? 0.18 : 0.1;
    final activeSegments = isIdle
        ? 0
        : (countdownProgress.clamp(0.0, 1.0) * _segmentsPerRing).round();

    // 绘制 60 段背景（淡色）
    for (int i = 0; i < _segmentsPerRing; i++) {
      final startAngle =
          -math.pi / 2 + i * segmentAngle + _segmentGapRadians / 2;
      canvas.drawArc(
        rect,
        startAngle,
        activeSegmentAngle,
        false,
        Paint()
          ..color = theme.accentColor.withValues(alpha: trackAlpha)
          ..strokeWidth = _innerStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // 绘制活跃段（实色）— idle 时 activeSegments=0,跳过
    for (int i = 0; i < activeSegments; i++) {
      final startAngle =
          -math.pi / 2 + i * segmentAngle + _segmentGapRadians / 2;
      canvas.drawArc(
        rect,
        startAngle,
        activeSegmentAngle,
        false,
        Paint()
          ..color = theme.accentColor
          ..strokeWidth = _innerStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.sessionDuration != sessionDuration ||
        oldDelegate.countdownProgress != countdownProgress ||
        oldDelegate.isIdle != isIdle ||
        oldDelegate.theme != theme;
  }
}
