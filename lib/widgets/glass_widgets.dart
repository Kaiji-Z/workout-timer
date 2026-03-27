import 'package:flutter/material.dart';

// ============================================================================
// PRESSABLE MIXIN - 按压动画混入
// ============================================================================

/// 按压缩放动画混入
///
/// 为按钮提供统一的按压缩放动画效果。
/// 使用方式：
/// ```dart
/// class _MyButtonState extends State<MyButton>
///     with SingleTickerProviderStateMixin, PressableMixin {
///   @override
///   double get pressedScale => 0.92; // 可选，默认 0.95
///
///   @override
///   void initState() {
///     super.initState();
///     initPressAnimation();
///   }
///
///   @override
///   void dispose() {
///     disposePressAnimation();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return buildPressable(
///       onPressed: widget.onPressed,
///       child: Container(...),
///     );
///   }
/// }
/// ```
mixin PressableMixin<T extends StatefulWidget> on State<T>, TickerProvider {
  late AnimationController _pressController;
  late Animation<double> _pressScaleAnimation;

  /// 按压时的缩放比例，子类可覆盖
  double get pressedScale => 0.95;

  void initPressAnimation() {
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressScaleAnimation = Tween<double>(
      begin: 1.0,
      end: pressedScale,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  void disposePressAnimation() {
    _pressController.dispose();
  }

  Widget buildPressable({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTapDown: onPressed != null ? (_) => _pressController.forward() : null,
      onTapUp: onPressed != null
          ? (_) {
              _pressController.reverse();
              onPressed.call();
            }
          : null,
      onTapCancel: onPressed != null ? () => _pressController.reverse() : null,
      child: AnimatedBuilder(
        animation: _pressScaleAnimation,
        builder: (context, _) =>
            Transform.scale(scale: _pressScaleAnimation.value, child: child),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Flat Vitality 设计系统 - 参考图风格
/// ═══════════════════════════════════════════════════════════════════════════
///
/// 设计原则:
/// - 扁平设计，无玻璃效果
/// - 白色圆形按钮 + 深色图标
/// - 简洁阴影
/// - 高对比度
///

// ============================================================================
// CIRCULAR CONTROL BUTTON - 参考图核心按钮样式
// ============================================================================

/// 圆形控制按钮 - 参考图风格
///
/// 特点:
/// - 纯白色背景
/// - 深色图标
/// - 圆形形状
/// - 轻微阴影
class CircularControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double size;
  final Color? backgroundColor;

  const CircularControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.size = 56,
    this.backgroundColor,
  });

  @override
  State<CircularControlButton> createState() => _CircularControlButtonState();
}

class _CircularControlButtonState extends State<CircularControlButton>
    with SingleTickerProviderStateMixin, PressableMixin {
  @override
  double get pressedScale => 0.92;

  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      onPressed: widget.onPressed,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: widget.iconColor ?? const Color(0xFF212121),
          size: widget.size * 0.45,
        ),
      ),
    );
  }
}

// ============================================================================
// PRIMARY ACTION BUTTON - 主操作按钮 (胶囊形)
// ============================================================================

/// 主操作按钮 - 胶囊形状
///
/// 特点:
/// - 深蓝色背景
/// - 白色文字/图标
/// - 胶囊形状
class PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double height;
  final bool isWide;
  final bool isDestructive;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.height = 56,
    this.isWide = false,
    this.isDestructive = false,
  });

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton>
    with SingleTickerProviderStateMixin, PressableMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      onPressed: widget.onPressed,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: (widget.backgroundColor ?? const Color(0xFF1A237E))
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
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
// FLAT CARD - 扁平卡片
// ============================================================================

/// 扁平卡片 - 白色背景
class FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const FlatCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// FLAT BADGE - 扁平徽章
// ============================================================================

/// 扁平徽章 - 胶囊形状
class FlatBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const FlatBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFFA726),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? Colors.white, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE - 状态徽章
// ============================================================================

/// 状态徽章 - 带背景色
/// 简化版本：只需传入一个 color 参数
class StatusBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const StatusBadge({
    super.key,
    required this.text,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
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
    );
  }
}

// ============================================================================
// BUTTON CONFIG - 按钮配置
// ============================================================================

/// 按钮配置类
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

// ============================================================================
// SINGLE ROW BUTTON AREA - 单行按钮区域
// ============================================================================

/// 单行按钮区域 - 支持 1/2/3 个按钮
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons.map((button) {
        return Padding(
          padding: EdgeInsets.only(
            left: buttons.indexOf(button) == 0 ? 0 : gap / 2,
            right: buttons.indexOf(button) == buttons.length - 1 ? 0 : gap / 2,
          ),
          child: button.isPrimary
              ? PrimaryActionButton(
                  label: button.label,
                  icon: button.icon,
                  backgroundColor: button.isDestructive
                      ? Colors.red
                      : button.color,
                  onPressed: button.onPressed,
                  height: height,
                )
              : _SecondaryButton(
                  label: button.label,
                  icon: button.icon,
                  color: button.color,
                  onPressed: button.onPressed,
                  height: height,
                ),
        );
      }).toList(),
    );
  }
}

/// 次要按钮 - 边框样式
class _SecondaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final double height;

  const _SecondaryButton({
    required this.label,
    this.icon,
    required this.color,
    this.onPressed,
    this.height = 56,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin, PressableMixin {
  @override
  void initState() {
    super.initState();
    initPressAnimation();
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildPressable(
      onPressed: widget.onPressed,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
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
// ALIASES - 向后兼容
// ============================================================================

// 保留旧名称以兼容现有代码
typedef LiquidGlass = FlatCard;
typedef LiquidButton = PrimaryActionButton;
typedef LiquidOutlineButton = _SecondaryButton;
typedef LiquidBadge = FlatBadge;
typedef GlassBadge = StatusBadge;
typedef GlassContainer = FlatCard;
typedef GlassButton = PrimaryActionButton;
typedef GlassOutlineButton = _SecondaryButton;
