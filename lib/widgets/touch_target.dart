import 'package:flutter/material.dart';
import '../utils/dimensions.dart';

/// Wraps a child widget to ensure it meets the minimum touch target size.
///
/// Uses a [ConstrainedBox] to expand the hit area to at least
/// [AppDimensions.minTouchTarget] in both dimensions, without
/// changing the visual size of the child.
///
/// Example:
/// ```dart
/// TouchTarget(
///   onTap: () => Navigator.pop(context),
///   child: Icon(Icons.close),
/// )
/// ```
class TouchTarget extends StatelessWidget {
  final Widget child;
  final double minSize;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const TouchTarget({
    super.key,
    required this.child,
    this.minSize = AppDimensions.minTouchTarget,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Center(child: child),
      ),
    );
  }
}
