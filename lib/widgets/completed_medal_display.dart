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
    _shrinkAnimation = Tween(begin: 1.0, end: 0.0).animate(
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

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // SVG viewBox 是 534×620，圆盘占中间约 394×394（直径=半径197×2）。
    // 为让圆盘对齐 size，SVG 总高度 = size × (620/394) ≈ size × 1.57。
    // 宽度同理 = size × (534/394) ≈ size × 1.35。
    // 但这样缎带会超出 size 高度 — 用 Clip.none 允许溢出。
    final medalW = size * 1.35;
    final medalH = size * 1.57;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Phase 1: 残留的计时器圆环（收缩消失）
          // 用一个简单的 CustomPaint 画正在收缩的环，过渡到奖牌
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

          // Phase 2-4: 奖牌（SVG + 文字）+ 呼吸
          AnimatedBuilder(
            animation: Listenable.merge([
              _popAnimation,
              _breathAnimation,
            ]),
            builder: (context, _) {
              // pop 完成前不启动呼吸（_breathAnimation 初始值 0.98 会缩太小）
              final breathScale = _popAnimation.value < 0.99
                  ? 1.0
                  : _breathAnimation.value;
              final scale = _popAnimation.value * breathScale;
              return Transform.scale(
                scale: scale.clamp(0.0, 1.05),
                child: SizedBox(
                  width: medalW,
                  height: medalH,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 奖牌 SVG（缎带+圆盘+花环）
                      SvgPicture.asset(
                        'assets/images/medal.svg',
                        width: medalW,
                        height: medalH,
                        fit: BoxFit.contain,
                      ),
                      // 中心文字叠加层（对齐圆盘中心）
                      // SVG 圆盘中心在 viewBox 垂直偏下处（(448-25)/620 ≈ 0.68），
                      // 但我们把整个 SVG 居中放，圆盘偏下 = 文字也要偏下对齐圆盘。
                      // 用 FractionalOffset 对齐到圆盘中心。
                      Positioned(
                        // 圆盘中心在 SVG 高度的 (448-25)/620 ≈ 68.2% 处
                        top: medalH * 0.68 - size * 0.12,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 时长数字（黑色）
                            SlideTransition(
                              position: _digitSlide,
                              child: FadeTransition(
                                opacity: _digitOpacity,
                                child: Text(
                                  _formatTime(widget.sessionDuration),
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: size * 0.16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: size * 0.01),
                            // 分隔线
                            Container(
                              width: size * 0.18,
                              height: 1.5,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            SizedBox(height: size * 0.01),
                            // 训练完成文案（黑色，复用 l10n）
                            SlideTransition(
                              position: _captionSlide,
                              child: FadeTransition(
                                opacity: _captionOpacity,
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .widgetTrainingComplete,
                                  style: TextStyle(
                                    fontSize: size * 0.05,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
