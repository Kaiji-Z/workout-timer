import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// 训练完成奖牌显示组件
///
/// 基于 assets/images/medal.svg（用户提供的 Adobe Illustrator 月桂花环素材）。
/// SVG 包含：缎带 + 圆盘外轮廓 + 左右月桂花环 + 底部圆点（全部深靛蓝）。
/// 中心的 "I" 已从 SVG 删除，由本组件用 Text widget 叠加（时长 + 训练完成文案）。
///
/// 动画序列（与之前计时器状态平滑过渡）:
/// Phase 1: 圆环从满环收缩（400ms），圆心不变
/// Phase 2: 奖牌 SVG 从 scale 0.6 弹出到 1.0（easeOutBack 500ms，盖章力度）
/// Phase 3: 中心文字级联登场（check 已在 SVG 内，这里只做文字）
/// Phase 4: 微呼吸（2s 周期，scale 0.98-1.02）
///
/// 圆心对齐：SVG 的 viewBox 已调整使圆盘（圆心 367,448 半径 197）居中。
/// 渲染时用 SizedBox 限定为 widget.size，圆盘中心 = widget.size/2 = 计时器圆心。
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
  // 圆环收缩（从计时器过渡到奖牌）
  late AnimationController _shrinkController;
  late Animation<double> _shrinkAnimation;

  // 奖牌弹出（easeOutBack 盖章）
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  // 文字级联
  late AnimationController _digitController;
  late Animation<double> _digitOpacity;
  late Animation<Offset> _digitSlide;
  late AnimationController _captionController;
  late Animation<double> _captionOpacity;
  late Animation<Offset> _captionSlide;

  // 呼吸
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    // Phase 1: 环收缩（400ms）
    _shrinkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shrinkAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shrinkController, curve: Curves.easeIn),
    );

    // Phase 2: 奖牌弹出（500ms easeOutBack）
    _popController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _popAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );

    // Phase 3a: 时长数字（400ms 淡入+上滑）
    _digitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _digitOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _digitController, curve: Curves.easeOut),
    );
    _digitSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _digitController, curve: Curves.easeOut),
    );

    // Phase 3b: 训练完成文案
    _captionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _captionOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _captionController, curve: Curves.easeOut),
    );
    _captionSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _captionController, curve: Curves.easeOut),
    );

    // Phase 4: 呼吸
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breathAnimation = Tween(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _shrinkController.forward();         // 环收缩
    _popController.forward();                   // 奖牌弹出
    await Future.delayed(const Duration(milliseconds: 250));
    _digitController.forward();                 // 数字登场
    await Future.delayed(const Duration(milliseconds: 150));
    _captionController.forward();               // 文案登场
    await Future.delayed(const Duration(milliseconds: 300));
    _breathController.repeat(reverse: true);    // 呼吸
  }

  @override
  void dispose() {
    _shrinkController.dispose();
    _popController.dispose();
    _digitController.dispose();
    _captionController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 用 TextPainter 测量文字在某字号下的实际宽度，返回需要缩放到
  /// [maxWidth] 的缩放比（<=1.0）。这样不依赖 FittedBox（在 Column/Transition
  /// 嵌套里不可靠），直接算出合适 fontSize。
  double _scaleFactorForText(String text, double fontSize, double maxWidth,
      {FontWeight fontWeight = FontWeight.normal, String? fontFamily}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width <= 0) return 1.0;
    final ratio = maxWidth / painter.width;
    return ratio < 1.0 ? ratio : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    // === 几何对齐计算（用数学，不靠猜）===
    // medal.svg viewBox = "100 25 534 660"，圆盘中心 (367,448) 半径 ≈197（直径 394）。
    // viewBox 高度 660：y[25,685]，覆盖 outline path 最低 y=671.56（底部缎带曲线下沿）。
    //
    // 圆盘直径目标 = size × 0.72（小于 timerSize，给缎带/花环留溢出空间，
    // 防止整体溢出屏幕）。这样 SVG 总高 = 0.72×size × 660/394 ≈ size × 1.21。
    //   缩放比 = (size × 0.72) / 394
    //   SVG 渲染宽 = 534 × scale ≈ size × 0.976
    //   SVG 渲染高 = 660 × scale ≈ size × 1.206
    //   圆盘中心 y 在 viewBox 中的比例 = (448-25)/660 = 0.641
    //   圆盘中心钉到容器中心 (size/2, size/2)。
    const double viewBoxW = 534;
    const double viewBoxH = 660;
    const double diskDiameterInSvg = 394;
    const double diskDiameterFrac = 0.72; // 圆盘占 size 的比例
    const double diskCenterYFrac = 423 / viewBoxH; // 0.641
    final double diskDiameter = size * diskDiameterFrac;
    final double scale = diskDiameter / diskDiameterInSvg;
    final double svgW = viewBoxW * scale; // ≈ size × 0.976
    final double svgH = viewBoxH * scale; // ≈ size × 1.206
    // SVG 左上角位置（容器坐标系，可负 = 溢出 SizedBox）
    final double svgOffsetX = (size - svgW) / 2; // 圆盘水平居中 → SVG 也水平居中
    final double svgOffsetY = size / 2 - svgH * diskCenterYFrac; // 圆盘中心钉到 size/2

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Phase 1: 残留的计时器圆环（居中，收缩消失）
          AnimatedBuilder(
            animation: _shrinkAnimation,
            builder: (context, _) {
              if (_shrinkAnimation.value >= 0.99) {
                return const SizedBox.shrink();
              }
              return Opacity(
                opacity: 1.0 - _shrinkAnimation.value,
                child: Transform.scale(
                  scale: 1.0 - _shrinkAnimation.value * 0.3,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _FadingRingPainter(
                      progress: 1.0,
                      color: widget.theme.accentColor,
                      alpha: 1.0 - _shrinkAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),

          // Phase 2-4: 奖牌（SVG + 文字）一起 pop + breath
          // 圆盘中心已被精确钉到容器中心，所以 scale 用 center 对齐，
          // 缎带/底点会对称地向上下扩散，圆盘不动。
          AnimatedBuilder(
            animation: Listenable.merge([
              _popAnimation,
              _breathAnimation,
            ]),
            builder: (context, child) {
              // pop 完成前不启动呼吸（_breathAnimation 初始值 0.98 会缩太小）
              final breathScale = _popAnimation.value < 0.99
                  ? 1.0
                  : _breathAnimation.value;
              final s = (_popAnimation.value * breathScale).clamp(0.0, 1.05);
              return Transform.scale(scale: s, child: child);
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 奖牌 SVG：Positioned 精确钉位，圆盘中心 = 容器中心
                  Positioned(
                    left: svgOffsetX,
                    top: svgOffsetY,
                    child: SvgPicture.asset(
                      'assets/images/medal.svg',
                      width: svgW,
                      height: svgH,
                      fit: BoxFit.fill,
                    ),
                  ),
                  // 中心文字：圆盘中心 = 容器中心 = (size/2, size/2)。
                  // 用 TextPainter 手动算缩放比（FittedBox 在 Column+Transition 嵌套
                  // 里不可靠），直接设 fontSize，保证文字宽度 <= 圆盘内可用宽度。
                  // 用户要求：时间往下移，接近中心横线（分隔线）。
                  Builder(builder: (context) {
                    // 圆盘内可用宽度：文字总宽 ≤ 圆盘直径 × 0.50（半宽 ≤ 半径×0.5），
                    // 给花环留出边缘空间（花环沿圆盘外缘分布）。
                    // 之前 0.62 导致文字半宽 ≈ 圆盘半径，撞到边缘花环。
                    final maxTextWidth = diskDiameter * 0.50;
                    // 时间数字：理想字号
                    final timeText = _formatTime(widget.sessionDuration);
                    final timeIdealFontSize = diskDiameter * 0.22;
                    final timeScale = _scaleFactorForText(
                      timeText, timeIdealFontSize, maxTextWidth,
                      fontWeight: FontWeight.w700, fontFamily: 'Rajdhani',
                    );
                    final timeFontSize = timeIdealFontSize * timeScale;
                    // 训练完成文案：理想字号
                    final captionText =
                        AppLocalizations.of(context)!.widgetTrainingComplete;
                    final captionIdealFontSize = diskDiameter * 0.085;
                    final captionScale = _scaleFactorForText(
                      captionText, captionIdealFontSize, maxTextWidth,
                      fontWeight: FontWeight.w600,
                    );
                    final captionFontSize = captionIdealFontSize * captionScale;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 时长数字（黑色）— 紧贴分隔线上方
                          SlideTransition(
                            position: _digitSlide,
                            child: FadeTransition(
                              opacity: _digitOpacity,
                              child: Text(
                                timeText,
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: timeFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: diskDiameter * 0.01),
                          // 分隔线（中心横线 — 圆盘的视觉中心锚点）
                          Container(
                            width: diskDiameter * 0.22,
                            height: 1.5,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: diskDiameter * 0.01),
                          // 训练完成文案（黑色，复用 l10n）
                          SlideTransition(
                            position: _captionSlide,
                            child: FadeTransition(
                              opacity: _captionOpacity,
                              child: Text(
                                captionText,
                                style: TextStyle(
                                  fontSize: captionFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 过渡用的收缩圆环（从计时器满环渐隐到无）
class _FadingRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double alpha;

  _FadingRingPainter({
    required this.progress,
    required this.color,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FadingRingPainter old) =>
      old.alpha != alpha || old.progress != progress;
}
