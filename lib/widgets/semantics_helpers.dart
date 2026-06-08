import 'package:flutter/material.dart';

// ============================================================================
// SEMANTIC HELPER WIDGETS — Flat Vitality Accessibility Primitives
// ============================================================================
// Wrapper widgets that add Semantics annotations to common UI patterns.
// These ensure TalkBack/VoiceOver can announce interactive elements and
// data visualizations that are otherwise invisible to assistive technology.
// ============================================================================

/// IconButton with required semantic label for screen readers.
///
/// Wraps [IconButton] with a [Semantics] widget that provides
/// an accessible label, ensuring all icon-only buttons are
/// properly announced by TalkBack/VoiceOver.
///
/// Example:
/// ```dart
/// SemanticIconButton(
///   icon: Icons.close,
///   semanticLabel: '关闭',
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class SemanticIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final double? iconSize;
  final String? tooltip;

  const SemanticIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon, semanticLabel: semanticLabel),
        onPressed: onPressed,
        color: color,
        iconSize: iconSize,
        tooltip: tooltip ?? semanticLabel,
      ),
    );
  }
}

/// Wraps a card-like widget with semantic role and label.
///
/// Announces the card as a single semantic node with a label,
/// preventing child widgets from being read individually.
///
/// Example:
/// ```dart
/// SemanticCard(
///   label: '卧推计划，4组，每组12次',
///   onTap: () => _navigateToDetail(),
///   child: _buildPlanCard(plan),
/// )
/// ```
class SemanticCard extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;

  const SemanticCard({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      enabled: onTap != null,
      child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
    );
  }
}

/// Wraps a chart widget with a text summary for screen readers.
///
/// Charts are inherently visual and inaccessible to screen readers.
/// This wrapper hides the chart from assistive technology and
/// provides a text-based summary instead.
///
/// Example:
/// ```dart
/// SemanticChart(
///   chart: BarChart(barChartData),
///   summary: '本周训练4次，总计32组，胸肌训练最多',
/// )
/// ```
class SemanticChart extends StatelessWidget {
  final Widget chart;
  final String summary;

  const SemanticChart({super.key, required this.chart, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: summary,
      child: ExcludeSemantics(child: chart),
    );
  }
}

/// Marks the timer display as a live region for screen reader updates.
///
/// Screen readers will announce updates to the timer value as they change.
/// The child widget is excluded from the semantics tree so the [value]
/// string is read instead of the raw timer text.
///
/// Example:
/// ```dart
/// LiveTimer(
///   value: '剩余时间 30 秒',
///   child: Text('00:30'),
/// )
/// ```
class LiveTimer extends StatelessWidget {
  final Widget child;
  final String value;
  final bool assertive;

  const LiveTimer({
    super.key,
    required this.child,
    required this.value,
    this.assertive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: value,
      child: ExcludeSemantics(child: child),
    );
  }
}
