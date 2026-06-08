import 'dart:math' show pow;

import 'package:flutter/material.dart';

/// WCAG 2.1 contrast ratio utilities for accessibility testing.
class ContrastTestUtil {
  ContrastTestUtil._();

  /// Calculate relative luminance of a color (WCAG formula).
  ///
  /// Flutter's [Color.r], [Color.g], [Color.b] return doubles in 0.0-1.0.
  static double relativeLuminance(Color color) {
    double r = color.r;
    double g = color.g;
    double b = color.b;

    // Apply gamma correction (sRGB linearization).
    r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors (WCAG formula).
  ///
  /// Returns ratio between 1.0 (identical colors) and 21.0 (black vs white).
  static double contrastRatio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA normal text (>= 4.5:1).
  static bool meetsAANormal(double ratio) => ratio >= 4.5;

  /// Check if contrast ratio meets WCAG AA large text (>= 3.0:1).
  static bool meetsAALarge(double ratio) => ratio >= 3.0;

  /// Check if contrast ratio meets WCAG AA UI components (>= 3.0:1).
  static bool meetsAAUI(double ratio) => ratio >= 3.0;

  /// Check if contrast ratio meets WCAG AAA normal text (>= 7.0:1).
  static bool meetsAAANormal(double ratio) => ratio >= 7.0;
}
