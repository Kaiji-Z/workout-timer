import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

// ============================================================================
// SHARED UI COMPONENTS — Flat Vitality Design System
// ============================================================================
// Reusable building blocks extracted from repeated patterns across screens.
// These ensure consistent styling for common UI elements.
// ============================================================================

/// Bottom-sheet drag handle — small centered bar at the top of modal sheets.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   builder: (context) => Column(
///     children: [
///       const SheetDragHandle(),
///       // ... sheet content
///     ],
///   ),
/// );
/// ```
class SheetDragHandle extends StatelessWidget {
  final Color? color;

  const SheetDragHandle({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color ?? theme.dragHandleColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
        ),
      ),
    );
  }
}

/// Section header — title row with optional trailing widget.
///
/// Follows Flat Vitality typography: `.SF Pro Text`, w600, 16px title.
///
/// Usage:
/// ```dart
/// SectionHeader(
///   title: '训练计划',
///   trailing: TextButton(onPressed: ..., child: Text('查看全部')),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final TextStyle? titleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              titleStyle ?? context.titleLarge.copyWith(color: theme.textColor),
        ),
        ?trailing,
      ],
    );
  }
}

/// Empty-state placeholder — centered icon + title + subtitle.
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.history,
///   title: '暂无训练记录',
///   subtitle: '完成第一次训练后会在这里显示',
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final subtitle = this.subtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              title,
              style: context.titleLarge.copyWith(
                color: theme.secondaryTextColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  color: theme.secondaryTextColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
