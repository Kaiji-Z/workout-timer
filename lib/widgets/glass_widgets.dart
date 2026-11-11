import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

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
  final String? semanticLabel;

  const CircularControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.size = 56,
    this.backgroundColor,
    this.semanticLabel,
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
    final theme = context.watch<ThemeProvider>().currentTheme;
    final child = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.cardColor,
        shape: BoxShape.circle,
        boxShadow: AppElevation.raised(theme.shadowColor),
      ),
      child: Icon(
        widget.icon,
        color: widget.iconColor ?? theme.textColor,
        size: widget.size * 0.45,
      ),
    );
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: buildPressable(onPressed: widget.onPressed, child: child),
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
    final theme = context.watch<ThemeProvider>().currentTheme;
    final bgColor = widget.backgroundColor ?? theme.accentColor;
    // GestureDetector 无按钮角色；显式声明让读屏识别为可按按钮
    return Semantics(
      button: true,
      child: buildPressable(
        onPressed: widget.onPressed,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: AppElevation.raised(bgColor.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: theme.onAccentColor, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: context.titleLarge.copyWith(
                    color: theme.onAccentColor,
                    letterSpacing: 0.5,
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
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
            style: context.labelLarge.copyWith(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BUTTON CONFIG - 按钮配置
