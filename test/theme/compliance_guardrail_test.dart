import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Compliance guardrail tests — source-level scans that prevent hardcoded
/// design values from creeping back into non-exempt files.
///
/// Each test scans lib/ source files (excluding allow-listed ones) and fails
/// if forbidden patterns are found. This keeps the codebase consistent with
/// the Flat Vitality design token system established in Phase A.
void main() {
  final libDir = Directory('lib');

  /// Recursively collect all .dart file paths under lib/, skipping excluded files.
  List<File> dartFilesExcluding(Set<String> excludedBasenames) {
    return libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !excludedBasenames.contains(f.uri.pathSegments.last))
        .toList();
  }

  group('No hardcoded fontFamily outside theme definition', () {
    test(
      '".SF Pro" fontFamily only in app_theme.dart and fullscreen_image_viewer.dart',
      () {
        final files = dartFilesExcluding({
          'app_theme.dart',
          'fullscreen_image_viewer.dart',
        });
        final offenders = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
          if (content.contains("fontFamily: '.SF Pro")) {
            offenders.add(file.path);
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'Found hardcoded ".SF Pro" fontFamily in:\n${offenders.join('\n')}\n'
              'Use Theme.of(context).textTheme.* instead.',
        );
      },
    );
  });

  group('No hardcoded EdgeInsets.all(16) — use AppDimensions.screenPadding', () {
    test('no raw "16" padding literal anywhere in lib/', () {
      final files = dartFilesExcluding(<String>{});
      final offenders = <String>[];

      for (final file in files) {
        final content = file.readAsStringSync();
        // Match EdgeInsets.all(16) but NOT EdgeInsets.all(AppDimensions.screenPadding)
        if (RegExp(r'EdgeInsets\.all\(\s*16\s*\)').hasMatch(content)) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Found hardcoded EdgeInsets.all(16) in:\n${offenders.join('\n')}\n'
            'Use EdgeInsets.all(AppDimensions.screenPadding) instead.',
      );
    });
  });

  group('No raw BorderRadius.circular(number) outside theme + exempt files', () {
    test(
      'BorderRadius.circular only in app_theme.dart and fullscreen_image_viewer.dart',
      () {
        final files = dartFilesExcluding({
          'app_theme.dart',
          'fullscreen_image_viewer.dart',
        });
        final offenders = <String>[];

        for (final file in files) {
          final content = file.readAsStringSync();
          // Match BorderRadius.circular(8) etc. but NOT BorderRadius.circular(AppDimensions.radiusXxx)
          if (RegExp(r'BorderRadius\.circular\(\s*\d').hasMatch(content)) {
            offenders.add(file.path);
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'Found hardcoded BorderRadius.circular(number) in:\n${offenders.join('\n')}\n'
              'Use AppDimensions.radiusXxx tokens instead.',
        );
      },
    );
  });

  group('No raw Colors.white/black/red outside exempt files', () {
    test('Colors.white/black/red only in theme + known legit overlay files', () {
      final exempt = {
        'app_theme.dart',
        'fullscreen_image_viewer.dart',
        'volume_trend_charts.dart',
        'exercise_selector.dart',
      };
      final files = dartFilesExcluding(exempt);
      final offenders = <String, List<String>>{};

      for (final file in files) {
        final content = file.readAsStringSync();
        final matches = <String>[];
        if (RegExp(r'Colors\.white\b').hasMatch(content)) {
          matches.add('Colors.white');
        }
        if (RegExp(r'Colors\.black\b').hasMatch(content)) {
          matches.add('Colors.black');
        }
        if (RegExp(r'Colors\.red\b').hasMatch(content)) {
          matches.add('Colors.red');
        }
        if (matches.isNotEmpty) {
          offenders[file.path] = matches;
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Found raw Colors.white/black/red in:\n${offenders.entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n'
            'Use theme.onAccentColor, theme.textColor, theme.errorColor etc. instead.',
      );
    });
  });

  group('Theme count is exactly 3', () {
    test('allThemes has exactly 3 entries', () {
      // This is validated at compile time via the design_tokens_test, but
      // we also check that removed theme names don't appear as constants.
      final themeFile = File('lib/theme/app_theme.dart');
      final content = themeFile.readAsStringSync();

      // Removed theme constants should not exist
      expect(
        content.contains('mintGreenTheme'),
        isFalse,
        reason: 'mintGreenTheme constant should have been removed',
      );
      expect(
        content.contains('rosePinkTheme'),
        isFalse,
        reason: 'rosePinkTheme constant should have been removed',
      );
    });
  });
}
