import 'package:flutter/material.dart';

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

