import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// iOS 26 Liquid Glass Design System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Core Principles (from iOS 26 WWDC):
/// 1. Transparency & Translucency - Semi-transparent materials reflecting environment
/// 2. Fluidity - Elements move like liquid, highlights respond to interaction
/// 3. Spatial Depth - Floating layers above content (from visionOS)
/// 4. Capsule Shapes - Pill shapes for touch-friendly UI
/// 5. Concentricity - Align around shared center
/// 6. Specular Highlights - Glass optical properties
/// 7. Dynamic Response - Press → retreat + become more opaque + slight enlargement
///
/// Typography (Critical for readability):
/// - Bolder weights
/// - Left-aligned for better readability
/// - Clear hierarchy
///
/// ═══════════════════════════════════════════════════════════════════════════

// ============================================================================
// CORE: Liquid Glass Material
// ============================================================================

/// 液态玻璃材质 - iOS 26 核心设计元素
/// 
/// 特点:
/// - 半透明材质,可反射环境
/// - 空间分层,悬浮于内容之上
/// - 高光边缘,玻璃光学特性
/// - 动态响应用户交互
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final double blur;
  final bool showHighlight;
  final bool showReflection;
  final Border? border;
  final Color? tintColor;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.opacity = 0.72,
    this.blur = 20,
    this.showHighlight = true,
    this.showReflection = true,
    this.border,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // 背景模糊层
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  // 半透明材质 - 受环境影响
                  color: _getBackgroundColor(isDark, tintColor),
                  borderRadius: BorderRadius.circular(borderRadius),
                  // 空间分层边框
                  border: border ?? Border.all(
                    color: _getBorderColor(isDark, tintColor),
                    width: 0.5,
                  ),
                  // 内阴影效果 - 景深感
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
            // 顶部高光反射层 - 玻璃光学特性
            if (showHighlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: borderRadius,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getHighlightColor(isDark, tintColor),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark, Color? tint) {
    if (tint != null) {
      return tint.withValues(alpha: isDark ? 0.15 : 0.85);
    }
    return isDark 
        ? Colors.white.withValues(alpha: opacity * 0.15)
        : Colors.white.withValues(alpha: opacity * 0.85);
  }

  Color _getBorderColor(bool isDark, Color? tint) {
    if (tint != null) {
      return tint.withValues(alpha: 0.4);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.6);
  }

  Color _getHighlightColor(bool isDark, Color? tint) {
    if (tint != null) {
      return tint.withValues(alpha: isDark ? 0.15 : 0.4);
    }
    return Colors.white.withValues(alpha: isDark ? 0.15 : 0.4);
  }
}

// ============================================================================
// BUTTONS: Capsule-shaped Interactive Elements
// ============================================================================

/// 液态玻璃按钮 - iOS 26 胶囊按钮
/// 
/// 特点:
/// - 胶囊形状 (borderRadius = height / 2)
/// - 动态响应: 按下时后退+变不透明+轻微放大
/// - 高光效果 - 玻璃光学特性
/// - 触控友好的大尺寸
class LiquidButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isPrimary;
  final double height;
  final bool isLoading;
  final bool isDestructive;

  const LiquidButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isPrimary = true,
    this.height = 50,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // iOS 26 动态响应: 后退 + 变不透明 + 轻微放大
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _translateAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = widget.color ?? Theme.of(context).primaryColor;
    final borderRadius = widget.height / 2; // 胶囊形状

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  // 主体
                  ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        height: widget.height,
                        decoration: BoxDecoration(
                          // 半透明渐变
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.isPrimary
                                ? [
                                    buttonColor.withValues(alpha: 0.95),
                                    buttonColor.withValues(alpha: 0.85),
                                  ]
                                : isDark
                                    ? [
                                        Colors.white.withValues(alpha: 0.18 + _opacityAnimation.value * 0.12),
                                        Colors.white.withValues(alpha: 0.12 + _opacityAnimation.value * 0.08),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.92),
                                        Colors.white.withValues(alpha: 0.85),
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                          // 空间分层边框
                          border: Border.all(
                            color: widget.isPrimary
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: isDark ? 0.2 : 0.5),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isPrimary
                                  ? buttonColor.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      widget.isPrimary ? Colors.white : buttonColor,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.icon != null) ...[
                                      Icon(
                                        widget.icon,
                                        color: widget.isPrimary
                                            ? Colors.white
                                            : buttonColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      widget.label,
                                      style: TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isPrimary
                                            ? Colors.white
                                            : isDark
                                                ? Colors.white
                                                : Colors.black,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  // 顶部高光
                  Positioned(
                    top: 0,
                    left: borderRadius / 2,
                    right: borderRadius / 2,
                    child: IgnorePointer(
                      child: Container(
                        height: widget.height * 0.4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: widget.isPrimary ? 0.3 : 0.4),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            topRight: Radius.circular(borderRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 液态玻璃轮廓按钮 - iOS 26 风格
class LiquidOutlineButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final double height;

  const LiquidOutlineButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.color,
    this.height = 50,
  });

  @override
  State<LiquidOutlineButton> createState() => _LiquidOutlineButtonState();
}

class _LiquidOutlineButtonState extends State<LiquidOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.height / 2;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: widget.color, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// CARDS & CONTAINERS: Spatial Depth Elements
// ============================================================================


/// 扁平化胶囊按钮 - VitalFlow 2.0 风格

/// 

/// 特点:

/// - 纯色填充 (无渐变)

/// - 胶囊形状

/// - 轻阴影

/// - 按下动态缩放

class FlatCapsuleButton extends StatefulWidget {

  final String label;

  final IconData? icon;

  final VoidCallback? onPressed;

  final Color color;

  final bool isPrimary;

  final double height;

  final bool isLoading;


  const FlatCapsuleButton({

    super.key,

    required this.label,

    this.icon,

    this.onPressed,

    required this.color,

    this.isPrimary = true,

    this.height = 56,

    this.isLoading = false,

  });


  @override

  State<FlatCapsuleButton> createState() => _FlatCapsuleButtonState();

}


class _FlatCapsuleButtonState extends State<FlatCapsuleButton>

    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _scaleAnimation;


  @override

  void initState() {

    super.initState();

    _controller = AnimationController(

      duration: const Duration(milliseconds: 150),

      vsync: this,

    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(

      CurvedAnimation(parent: _controller, curve: Curves.easeOut),

    );

  }


  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }


  @override

  Widget build(BuildContext context) {

    final borderRadius = widget.height / 2;


    return GestureDetector(

      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,

      onTapUp: widget.onPressed != null ? (_) {

        _controller.reverse();

        widget.onPressed?.call();

      } : null,

      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,

      child: AnimatedBuilder(

        animation: _controller,

        builder: (context, child) {

          return Transform.scale(

            scale: _scaleAnimation.value,

            child: Container(

              width: double.infinity,

              height: widget.height,

              decoration: BoxDecoration(

                // 主按钮: 纯色填充 | 次要按钮: 透明 + 边框

                color: widget.isPrimary ? widget.color : Colors.transparent,

                borderRadius: BorderRadius.circular(borderRadius),

                border: widget.isPrimary

                    ? null

                    : Border.all(color: widget.color, width: 1.5),

                // 轻阴影 (仅主按钮)

                boxShadow: widget.isPrimary

                    ? [

                        BoxShadow(

                          color: widget.color.withValues(alpha: 0.25),

                          blurRadius: 8,

                          offset: const Offset(0, 3),

                        ),

                      ]

                    : null,

              ),

              child: Center(

                child: widget.isLoading

                    ? SizedBox(

                        width: 22,

                        height: 22,

                        child: CircularProgressIndicator(

                          strokeWidth: 2.5,

                          valueColor: AlwaysStoppedAnimation(

                            widget.isPrimary ? Colors.white : widget.color,

                          ),

                        ),

                      )

                    : Row(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          if (widget.icon != null) ...[

                            Icon(

                              widget.icon,

                              color: widget.isPrimary ? Colors.white : widget.color,

                              size: 20,

                            ),

                            const SizedBox(width: 8),

                          ],

                          Text(

                            widget.label,

                            style: TextStyle(

                              fontFamily: '.SF Pro Text',

                              fontSize: 17,

                              fontWeight: FontWeight.w600,

                              color: widget.isPrimary ? Colors.white : widget.color,

                              letterSpacing: -0.3,

                            ),

                          ),

                        ],

                      ),

              ),

            );

          );

        },

      ),

    );

  }

}
/// 液态玻璃卡片 - 空间分层设计
/// 
/// 特点:
/// - 悬浮于内容之上
/// - 轻微阴影产生景深感
/// - 圆角边界
class LiquidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tintColor;
  final VoidCallback? onTap;

  const LiquidCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = LiquidGlass(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      tintColor: tintColor,
      blur: 15,
      opacity: 0.1,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// 悬浮按钮 - iOS 26 导航控件
/// 
/// 特点:
/// - 药丸形状导航栏
/// - 悬浮于内容之上
/// - 同心圆对齐
class FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<TabItem> items;
  final Color? activeColor;
  final Color? inactiveColor;

  const FloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final active = activeColor ?? theme.primaryColor;
    final inactive = inactiveColor ?? (isDark ? Colors.white54 : Colors.black54);

    return LiquidGlass(
      borderRadius: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      blur: 20,
      opacity: 0.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected ? active : inactive,
                      size: 24,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: active,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TabItem {
  final IconData icon;
  final String label;

  const TabItem({required this.icon, required this.label});
}


// ============================================================================
// LIQUID GLASS SHEET - iOS 26 Bottom Sheet
// ============================================================================

/// iOS 26 风格液态玻璃底部面板
/// 
/// 特点:
/// - 顶部拖动条
/// - 液态模糊背景
/// - 圆角边界
class LiquidGlassSheet extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassSheet({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              if (padding != null)
                Padding(padding: padding!, child: child)
              else
                child,
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BADGES & LABELS: Status Indicators
// ============================================================================

/// 液态玻璃徽章 - 胶囊形状
/// 
/// 特点:
/// - 紧凑的胶囊形状
/// - 半透明背景
/// - 清晰的色彩对比
class LiquidBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const LiquidBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESS & ANIMATION: Visual Feedback
// ============================================================================

/// 液态玻璃进度环 - iOS 26 风格
/// 
/// 特点:
/// - 高光渐变
/// - 发光效果
/// - 半透明背景环
class LiquidProgressRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;

  const LiquidProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 200,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LiquidProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LiquidProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LiquidProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // 背景环 - 半透明
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度环 - 带高光渐变
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
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

    // 高光效果
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth * 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// 动画数字 - iOS 26 风格
/// 
/// 特点:
/// - 平滑的数字切换动画
/// - 下滑过渡效果


// ============================================================================
// TYPOGRAPHY: iOS 26 Style Text
// ============================================================================

/// iOS 26 标题文字 - 更粗、左对齐


/// iOS 26 正文文字 - 清晰可读

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
        height: 1.4,
      ),
    );
  }
}

/// iOS 26 标签文字 - 小字号
class LabelText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const LabelText(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 0,
        height: 1.3,
      ),
    );
  }
}

// ============================================================================
// ALIASES: Backward Compatibility
// ============================================================================

typedef LiquidGlassContainer = LiquidGlass;
typedef LiquidGlassButton = LiquidButton;
typedef LiquidGlassOutlineButton = LiquidOutlineButton;
typedef LiquidGlassBadge = LiquidBadge;
typedef LiquidGlassProgressRing = LiquidProgressRing;
typedef GlassContainer = LiquidGlass;
typedef GlassButton = LiquidButton;
typedef GlassOutlineButton = LiquidOutlineButton;
typedef GlassBadge = LiquidBadge;

// ============================================================================
// SINGLE ROW BUTTON AREA - Unified Button Layout
// ============================================================================

/// 单行按钮区域 - 支持 1/2/3 个按钮的统一布局
///
/// 特点:
/// - 所有按钮在同一行
/// - 等宽分布
/// - 药丸形状 (iOS 26 风格)
class SingleRowButtonArea extends StatelessWidget {
  final List<ButtonConfig> buttons;
  final double height;
  final double gap;

  const SingleRowButtonArea({
    super.key,
    required this.buttons,
    this.height = 56,
    this.gap = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < buttons.length - 1 ? gap : 0,
            ),
            child: button.isPrimary
                ? LiquidButton(
                    label: button.label,
                    icon: button.icon,
                    color: button.color,
                    height: height,
                    onPressed: button.onPressed,
                    isPrimary: true,
                    isDestructive: button.isDestructive,
                  )
                : LiquidOutlineButton(
                    label: button.label,
                    icon: button.icon,
                    color: button.color,
                    height: height,
                    onPressed: button.onPressed,
                  ),
          ),
        );
      }).toList(),
    );
  }
}

/// 按钮配置
class ButtonConfig {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const ButtonConfig({
    required this.label,
    this.icon,
    required this.color,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
  });
}
