import 'package:flutter/material.dart';
import '../utils/dimensions.dart';

/// Named animation curves for consistent motion language
class AppCurves {
  AppCurves._();

  /// Snappy deceleration for button presses
  static const Curve press = Curves.easeOutCubic;

  /// Smooth entry for list items
  static const Curve entry = Curves.easeOut;

  /// Bouncy exit for completions
  static const Curve celebration = Curves.elasticOut;

  /// Gentle for ambient loops
  static const Curve ambient = Curves.easeInOut;
}

/// Spring description presets for physics-based animations
class SpringConfigs {
  SpringConfigs._();

  /// Snappy press feedback (fast, no overshoot)
  static SpringDescription get press => SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 400.0,
    ratio: 1.2,
  );

  /// Gentle card entry
  static SpringDescription get entry => SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 200.0,
    ratio: 0.9,
  );

  /// Bouncy celebration
  static SpringDescription get celebration =>
      SpringDescription.withDampingRatio(
        mass: 1.0,
        stiffness: 150.0,
        ratio: 0.6,
      );
}

/// Card widget that scales down on press (0.96) and springs back on release
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.press));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    _isPressed = pressed;
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // When no onTap is provided, render child without gesture detection
    if (widget.onTap == null) {
      return widget.child;
    }
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Shimmer placeholder for loading states
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.dividerColor.withValues(alpha: 0.3);
    final highlightColor = theme.dividerColor.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppDimensions.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.topRight,
                _controller.value,
              )!,
              end: Alignment.lerp(
                Alignment.topLeft,
                Alignment.topRight,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              )!,
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Animated number that counts up from 0 to target value
class CountUp extends StatefulWidget {
  final double target;
  final int durationMillis;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;

  const CountUp({
    super.key,
    required this.target,
    this.durationMillis = 800,
    this.style,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMillis),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.target,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.entry));
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.target,
      ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.entry));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}'
          '${_animation.value.toStringAsFixed(widget.decimalPlaces)}'
          '${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
