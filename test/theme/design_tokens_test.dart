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
}
