import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 训练完成奖牌显示组件
///
/// 从计时器圆环变形为奖牌的动画效果:
/// Phase 1: 圆环收缩 (400ms)
/// Phase 2: 圆环 → 奖牌变形 (500ms)
/// Phase 3: 内容淡入 (300ms)
/// Phase 4: 微呼吸动画 (永久)
///
/// 奖牌大小对齐计时器内环内缘:
/// medalRadius = innerRingRadius - innerStrokeWidth/2
class CompletedMedalDisplay extends StatefulWidget {
  final int sessionDuration;
  final AppThemeData theme;
  final double size;

  const CompletedMedalDisplay({
    super.key,
    required this.sessionDuration,
    required this.theme,
    required this.size,
  });

  @override
  State<CompletedMedalDisplay> createState() => _CompletedMedalDisplayState();
}

class _CompletedMedalDisplayState extends State<CompletedMedalDisplay>
    with TickerProviderStateMixin {
  // ── 尺寸常量（与 _TimerRingPainter 一致） ──
  static const double _outerStrokeWidth = 8.0;
  static const double _innerStrokeWidth = 6.0;
  static const double _outerRingGap = 4.0;
  static const double _innerOuterGap = 12.0;
  static const double _edgeMargin = 8.0;
  static const int _segmentsPerRing = 60;
  static const double _segmentGapRadians = math.pi / 180 * 1.2;

  // ── 奖牌装饰 ──
  static const double _medalBorderWidth = 4.0;
  static const double _medalInnerRingWidth = 2.0;

  // Animation controllers
  late AnimationController _shrinkController;
  late AnimationController _morphController;
  late AnimationController _contentFadeController;
  late AnimationController _breathingController;

  // Animations
  late Animation<double> _shrinkAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _contentOpacityAnimation;
  late Animation<double> _breathingAnimation;

  /// 奖牌半径 — 对齐内环内缘
  double get _medalRadius {
    final totalRadius = widget.size / 2;
    final outerRadius = totalRadius - _edgeMargin;
    final innerRingRadius =
        (outerRadius -
                _outerStrokeWidth / 2 -
                _innerOuterGap -
                _innerStrokeWidth / 2)
            .clamp(0.0, outerRadius - _outerStrokeWidth);
    return (innerRingRadius - _innerStrokeWidth / 2).clamp(
      0.0,
      innerRingRadius,
    );
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Phase 1: Ring shrink (400ms, ease-out)
    _shrinkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shrinkAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeOut),
    );

    // Phase 2: Ring → medal morph (500ms, ease-out)
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _morphController, curve: Curves.easeOut));

    // Phase 3: Content fade in (300ms)
    _contentFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOut),
    );

    // Phase 4: Breathing animation (forever, 2s cycle)
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Phase 1: Shrink
    await _shrinkController.forward();

    // Phase 2: Morph
    _morphController.forward();

    // Phase 3: Content fade in (after morph starts)
    await Future.delayed(const Duration(milliseconds: 200));
    _contentFadeController.forward();

    // Phase 4: Start breathing (after all phases complete)
    await Future.delayed(const Duration(milliseconds: 400));
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _shrinkController.dispose();
    _morphController.dispose();
    _contentFadeController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 保持与 AnimatedTimerDisplay 相同的容器大小，确保位置对齐
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, _) {
          return ScaleTransition(
            scale: _breathingAnimation,
            child: AnimatedBuilder(
              animation: Listenable.merge([_shrinkAnimation, _morphAnimation]),
              builder: (context, _) {
                return Transform.scale(
                  scale: _shrinkAnimation.value,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ring that morphs to medal border
                        CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _MedalMorphPainter(
                            morphProgress: _morphAnimation.value,
                            theme: widget.theme,
                            medalRadius: _medalRadius,
                          ),
                        ),
                        // Medal filled content (fades in)
                        FadeTransition(
                          opacity: _contentOpacityAnimation,
                          child: _buildMedalContent(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedalContent() {
    final diameter = _medalRadius * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.theme.accentColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            _formatTime(widget.sessionDuration),
            style: const TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '训练完成',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              color: Color(0xCCFFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 奖牌变形绘制器
///
/// - morphProgress = 0.0: 显示完整的计时器圆环（与 _TimerRingPainter 相同风格）
/// - morphProgress = 1.0: 显示奖牌装饰边框
class _MedalMorphPainter extends CustomPainter {
  final double morphProgress;
  final AppThemeData theme;
  final double medalRadius;

  // Dimensions (matching _TimerRingPainter)
  static const double _outerStrokeWidth = 8.0;
  static const double _innerStrokeWidth = 6.0;
  static const double _innerOuterGap = 12.0;
  static const double _edgeMargin = 8.0;
  static const int _segmentsPerRing = 60;
  static const double _segmentGapRadians = math.pi / 180 * 1.2;

  // Medal decoration
  static const double _medalBorderWidth = 4.0;
  static const double _medalInnerRingWidth = 2.0;

  _MedalMorphPainter({
    required this.morphProgress,
    required this.theme,
    required this.medalRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final totalRadius = size.width / 2;

    final outerRadius = totalRadius - _edgeMargin;
    final innerRadius =
        (outerRadius -
                _outerStrokeWidth / 2 -
                _innerOuterGap -
                _innerStrokeWidth / 2)
            .clamp(0.0, outerRadius - _outerStrokeWidth);

    if (morphProgress < 0.5) {
      final ringProgress = morphProgress * 2;
      _paintMorphingRings(
        canvas,
        center,
        outerRadius,
        innerRadius,
        ringProgress,
      );
    } else {
      final medalProgress = (morphProgress - 0.5) * 2;
      _paintMedalBorder(canvas, center, medalProgress);
    }
  }

  void _paintMorphingRings(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double progress,
  ) {
    final opacity = 1.0 - progress * 0.7;
    final strokeThicken = 1.0 + progress * 1.5;

    // Outer ring background (fading)
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = theme.accentColor.withValues(alpha: 0.12 * opacity)
        ..strokeWidth = _outerStrokeWidth * strokeThicken
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Outer ring full circle (fading)
    final rect = Rect.fromCircle(center: center, radius: outerRadius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = theme.accentColor.withValues(alpha: opacity)
        ..strokeWidth = _outerStrokeWidth * strokeThicken
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Inner dashed ring (fading)
    if (innerRadius > 0) {
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
      final segmentAngle = 2 * math.pi / _segmentsPerRing;
      final activeSegmentAngle = segmentAngle - _segmentGapRadians;

      for (int i = 0; i < _segmentsPerRing; i++) {
        final startAngle =
            -math.pi / 2 + i * segmentAngle + _segmentGapRadians / 2;
        canvas.drawArc(
          innerRect,
          startAngle,
          activeSegmentAngle,
          false,
          Paint()
            ..color = theme.accentColor.withValues(alpha: opacity * 0.5)
            ..strokeWidth = _innerStrokeWidth * strokeThicken
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt,
        );
      }
    }
  }

  void _paintMedalBorder(Canvas canvas, Offset center, double progress) {
    // Outer decorative ring — 外缘对齐内环内缘
    final outerBorderRadius = medalRadius + _medalBorderWidth;
    canvas.drawCircle(
      center,
      outerBorderRadius,
      Paint()
        ..color = theme.accentColor.withValues(alpha: 0.3 * progress)
        ..strokeWidth = _medalBorderWidth
        ..style = PaintingStyle.stroke,
    );

    // Inner decorative ring
    final innerRingRadius = medalRadius - _medalBorderWidth - 4;
    if (innerRingRadius > 0) {
      canvas.drawCircle(
        center,
        innerRingRadius,
        Paint()
          ..color = const Color(0x33FFFFFF).withValues(alpha: 0.33 * progress)
          ..strokeWidth = _medalInnerRingWidth
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MedalMorphPainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.theme != theme ||
        oldDelegate.medalRadius != medalRadius;
  }
}
