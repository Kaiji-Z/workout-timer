import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/utils/dimensions.dart';

/// Design-token existence tests — guardrail for Phase A consistency work.
///
/// These tests ensure that:
/// 1. All radius tokens exist in AppDimensions with correct values
/// 2. AppThemeData has the isDark field working correctly
/// 3. New convenience getters (onAccentColor, shadowColor, dragHandleColor) exist
/// 4. Dark mode derivation produces isDark == true
void main() {
  group('AppDimensions radius tokens', () {
    test('all consolidated radius tokens exist with correct values', () {
      expect(AppDimensions.radiusXxs, 3.0);
      expect(AppDimensions.radiusSm, 4.0);
      expect(AppDimensions.radiusMd, 8.0);
      expect(AppDimensions.radiusLg, 12.0);
      expect(AppDimensions.radiusXl, 16.0);
      expect(AppDimensions.radiusChip, 20.0);
      expect(AppDimensions.radiusSheet, 24.0);
      expect(AppDimensions.radiusPill, 28.0);
    });

    test('screenPadding token exists', () {
      expect(AppDimensions.screenPadding, 16.0);
    });
  });

  group('AppThemeData isDark field', () {
    test('light themes have isDark == false', () {
      for (final theme in allThemes) {
        expect(
          theme.isDark,
          isFalse,
          reason: '${theme.name} should have isDark == false in light mode',
        );
      }
    });

    test('dark variant has isDark == true', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.isDark,
          isTrue,
          reason: '${theme.name}.dark should have isDark == true',
        );
      }
    });

    test('toThemeData() produces correct brightness for light and dark', () {
      final light = amberGoldTheme.toThemeData();
      final dark = amberGoldTheme.dark.toThemeData();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });
  });

  group('AppThemeData convenience getters', () {
    test('onAccentColor returns white', () {
      expect(amberGoldTheme.onAccentColor, Colors.white);
      expect(amberGoldTheme.dark.onAccentColor, Colors.white);
    });

    test('shadowColor is derived from textColor', () {
      // Light: textColor is #212121 → alpha 0.12
      final lightShadow = amberGoldTheme.shadowColor;
      expect(lightShadow, amberGoldTheme.textColor.withValues(alpha: 0.12));

      // Dark: textColor is #E8E8E8 → alpha 0.12
      final darkShadow = amberGoldTheme.dark.shadowColor;
      expect(darkShadow, amberGoldTheme.dark.textColor.withValues(alpha: 0.12));
    });

    test('dragHandleColor equals dividerColor', () {
      expect(amberGoldTheme.dragHandleColor, amberGoldTheme.dividerColor);
      expect(
        amberGoldTheme.dark.dragHandleColor,
        amberGoldTheme.dark.dividerColor,
      );
    });
  });

  // ==========================================================================
  // Phase B Wave 0 — Foundation tokens
  // ==========================================================================

  group('Surface hierarchy tokens (3-tier depth system)', () {
    test('surfaceColorRaised exists on all light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.surfaceColorRaised,
          isNotNull,
          reason: '${theme.name} must define surfaceColorRaised',
        );
      }
    });

    test('surfaceColorRaised exists on all dark themes', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.surfaceColorRaised,
          isNotNull,
          reason: '${theme.name}.dark must define surfaceColorRaised',
        );
      }
    });

    test('surfaceColorOverlay exists on all light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.surfaceColorOverlay,
          isNotNull,
          reason: '${theme.name} must define surfaceColorOverlay',
        );
      }
    });

    test('surfaceColorOverlay exists on all dark themes', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.surfaceColorOverlay,
          isNotNull,
          reason: '${theme.name}.dark must define surfaceColorOverlay',
        );
      }
    });

    test('scrimColor exists on all light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.scrimColor,
          isNotNull,
          reason: '${theme.name} must define scrimColor',
        );
      }
    });

    test('scrimColor exists on all dark themes', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.scrimColor,
          isNotNull,
          reason: '${theme.name}.dark must define scrimColor',
        );
      }
    });

    test('dark scrimColor is more opaque than light', () {
      for (final theme in allThemes) {
        expect(
          (theme.dark.scrimColor.a * 255).round(),
          greaterThan((theme.scrimColor.a * 255).round()),
          reason:
              '${theme.name}.dark scrim should be more opaque for readability',
        );
      }
    });
  });

  group('Extended semantic colors', () {
    test('warningColor exists with constructor default on light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.warningColor,
          const Color(0xFFFF9800),
          reason: '${theme.name} should have warningColor == #FF9800',
        );
      }
    });

    test('infoColor exists with constructor default on light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.infoColor,
          const Color(0xFF2196F3),
          reason: '${theme.name} should have infoColor == #2196F3',
        );
      }
    });

    test('warningColor on dark themes is lighter (#FFB74D)', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.warningColor,
          const Color(0xFFFFB74D),
          reason: '${theme.name}.dark should have warningColor == #FFB74D',
        );
      }
    });

    test('infoColor on dark themes is lighter (#64B5F6)', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.infoColor,
          const Color(0xFF64B5F6),
          reason: '${theme.name}.dark should have infoColor == #64B5F6',
        );
      }
    });

    test('highlightColor exists on all light themes', () {
      for (final theme in allThemes) {
        expect(
          theme.highlightColor,
          isNotNull,
          reason: '${theme.name} must define highlightColor',
        );
      }
    });

    test('highlightColor exists on all dark themes', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.highlightColor,
          isNotNull,
          reason: '${theme.name}.dark must define highlightColor',
        );
      }
    });
  });

  group('Dark mode WCAG contrast fix', () {
    test('dark accentColor is Indigo 300 (#7986CB)', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.accentColor,
          const Color(0xFF7986CB),
          reason:
              '${theme.name}.dark must use #7986CB (Indigo 300) for WCAG contrast',
        );
      }
    });

    test('dark progressRingColor is Indigo Accent 400 (#536DFE)', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.progressRingColor,
          const Color(0xFF536DFE),
          reason:
              '${theme.name}.dark must use #536DFE (Indigo Accent 400) for vivid rings',
        );
      }
    });

    test('dark accentColor differs from light (no longer unchanged)', () {
      for (final theme in allThemes) {
        expect(
          theme.dark.accentColor,
          isNot(theme.accentColor),
          reason:
              '${theme.name}.dark must NOT reuse light accentColor (was a WCAG bug)',
        );
      }
    });
  });

  group('ChartPalette', () {
    test('colors list has exactly 7 entries', () {
      expect(ChartPalette.colors, hasLength(7));
    });

    test('byIndex returns valid color for in-range indices', () {
      expect(ChartPalette.byIndex(0), ChartPalette.colors.first);
      expect(ChartPalette.byIndex(6), ChartPalette.colors.last);
    });

    test('byIndex wraps around for out-of-range indices', () {
      expect(ChartPalette.byIndex(7), ChartPalette.colors.first);
      expect(ChartPalette.byIndex(8), ChartPalette.colors[1]);
    });
  });

  group('AppElevation', () {
    const testShadowColor = Color(0x1F000000);

    test('resting returns non-empty list of BoxShadows', () {
      final shadows = AppElevation.resting(testShadowColor);
      expect(shadows, isNotEmpty);
      expect(shadows, hasLength(1));
    });

    test('raised returns non-empty list of BoxShadows', () {
      final shadows = AppElevation.raised(testShadowColor);
      expect(shadows, isNotEmpty);
      expect(shadows, hasLength(2));
    });

    test('floating returns non-empty list of BoxShadows', () {
      final shadows = AppElevation.floating(testShadowColor);
      expect(shadows, isNotEmpty);
      expect(shadows, hasLength(2));
    });

    test('shadow blur radius increases with elevation tier', () {
      final resting = AppElevation.resting(testShadowColor);
      final raised = AppElevation.raised(testShadowColor);
      final floating = AppElevation.floating(testShadowColor);

      expect(floating.first.blurRadius, greaterThan(raised.first.blurRadius));
      expect(raised.first.blurRadius, greaterThan(resting.first.blurRadius));
    });
  });

  group('AppDimensions minTouchTarget', () {
    test('minTouchTarget equals 48.0 (a11y upgrade from 44.0)', () {
      expect(AppDimensions.minTouchTarget, 48.0);
    });
  });
}
