import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/theme/app_theme.dart';

import '../utils/contrast_test_util.dart';

void main() {
  group('ContrastTestUtil', () {
    test('black on white = 21.0', () {
      expect(
        ContrastTestUtil.contrastRatio(Colors.black, Colors.white),
        closeTo(21.0, 0.1),
      );
    });

    test('same color = 1.0', () {
      expect(
        ContrastTestUtil.contrastRatio(Colors.red, Colors.red),
        closeTo(1.0, 0.01),
      );
    });
  });

  group('Light theme contrast ratios', () {
    final themes = allThemes;

    for (final theme in themes) {
      test('${theme.name}: text on surface >= 4.5:1 (AA normal)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          theme.textColor,
          theme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAANormal(ratio),
          isTrue,
          reason:
              '${theme.name}: textColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1, '
              'needs >= 4.5:1',
        );
      });

      test('${theme.name}: secondary text on surface >= 4.5:1 (AA normal)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          theme.secondaryTextColor,
          theme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAANormal(ratio),
          isTrue,
          reason:
              '${theme.name}: secondaryTextColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1',
        );
      });

      test('${theme.name}: accent on surface >= 4.5:1 (AA normal)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          theme.accentColor,
          theme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAANormal(ratio),
          isTrue,
          reason:
              '${theme.name}: accentColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('Dark theme contrast ratios', () {
    for (final theme in allThemes) {
      final darkTheme = theme.dark;

      test('${theme.name} dark: text on surface >= 4.5:1 (AA normal)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          darkTheme.textColor,
          darkTheme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAANormal(ratio),
          isTrue,
          reason:
              '${theme.name} dark: textColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1',
        );
      });

      test('${theme.name} dark: accent on surface >= 4.5:1 (AA normal)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          darkTheme.accentColor,
          darkTheme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAANormal(ratio),
          isTrue,
          reason:
              '${theme.name} dark: accentColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1, '
              'needs >= 4.5:1. '
              'Fix: dark accent should be #7986CB not #1A237E',
        );
      });

      test('${theme.name} dark: ring on surface >= 3.0:1 (AA UI)', () {
        final ratio = ContrastTestUtil.contrastRatio(
          darkTheme.progressRingColor,
          darkTheme.surfaceColor,
        );
        expect(
          ContrastTestUtil.meetsAAUI(ratio),
          isTrue,
          reason:
              '${theme.name} dark: progressRingColor on surfaceColor = ${ratio.toStringAsFixed(2)}:1, '
              'needs >= 3.0:1. '
              'Fix: dark ring should be #536DFE not #1A237E',
        );
      });
    }
  });
}
