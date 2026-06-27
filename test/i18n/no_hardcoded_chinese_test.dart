import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard: detect hardcoded Chinese (CJK) characters inside string
/// literals in the UI layer. User-visible strings must flow through
/// `AppLocalizations` so they switch with the locale.
///
/// Scope: `lib/screens/`, `lib/widgets/`, and `lib/main.dart`. These are the
/// only layers that render user-facing text. The data/service layers may carry
/// localized display names via `LocalizedDisplay` / model getters, and comments
/// anywhere may stay Chinese (the project deliberately mixes zh/en comments).
///
/// The scanner strips `//` line comments and `/* */` block comments first, then
/// flags any remaining single- or double-quoted string literal containing a CJK
/// Unified Ideograph (U+4E00..U+9FFF). It cannot perfectly tokenize Dart, so a
/// few false positives are possible — if one is legitimate (e.g. a string used
/// only as a debug/log key, not shown to users), add the file to
/// `_knownExemptions` with a short reason.
void main() {
  test('no hardcoded Chinese in UI-layer string literals', () {
    final offenders = <String>[];

    for (final entity in _dartFiles()) {
      final path = entity.path;
      // Normalize to forward slashes for stable matching.
      final rel = path.replaceAll('\\', '/');
      if (_isExempt(rel)) continue;

      final source = File(path).readAsStringSync();
      final stripped = _stripComments(source);
      final matches = _cjkStringPattern.allMatches(stripped);
      for (final match in matches) {
        final literal = match.group(0)!;
        // Only flag literals that actually contain a CJK ideograph.
        if (_cjkCharPattern.hasMatch(literal)) {
          offenders
              .add('$rel:${_lineOf(stripped, match.start)}: $literal');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Found hardcoded Chinese in UI string literals. Move these to the ARB '
          'files and resolve them via AppLocalizations:\n${offenders.join('\n')}',
    );
  });
}

/// Files exempt from the scan. Keep this list small and always cite why.
const _knownExemptions = <String>{
  // The ARB sources themselves are the Chinese strings — they are the source of
  // truth, not a regression.
  // (lib/l10n/ is excluded wholesale by _isExempt, listed here for clarity.)
};

final RegExp _cjkStringPattern = RegExp(
  r"""(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")""",
);

/// Matches a single CJK Unified Ideograph (U+4E00..U+9FFF).
final RegExp _cjkCharPattern = RegExp(r'[\u4e00-\u9fff]');

bool _isExempt(String relPath) {
  // ARB / generated localization output is the source of truth.
  if (relPath.startsWith('lib/l10n/')) return true;
  // LocalizedDisplay maps codes to display helpers — it intentionally references
  // the model fields, no literals.
  if (_knownExemptions.contains(relPath)) return true;
  return false;
}

Iterable<File> _dartFiles() {
  final dirs = [
    Directory('lib/screens'),
    Directory('lib/widgets'),
    Directory('lib/main.dart'),
  ];
  final files = <File>[];
  for (final d in dirs) {
    if (d.path.endsWith('.dart')) {
      if (File(d.path).existsSync()) files.add(File(d.path));
      continue;
    }
    if (d.existsSync()) {
      files.addAll(d
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')));
    }
  }
  return files;
}

/// Strip // line comments and /* */ block comments. Brace/string-aware would be
/// ideal, but this is sufficient for catching literals (a literal "//" inside a
/// string would over-strip, which only makes the scan more permissive — safe).
String _stripComments(String source) {
  // Block comments
  source = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  // Line comments (to end of line)
  source = source.replaceAll(RegExp(r'//[^\n]*'), '');
  return source;
}

int _lineOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
