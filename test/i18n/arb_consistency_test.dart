import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB consistency', () {
    final zh = _loadArb('lib/l10n/app_zh.arb');
    final en = _loadArb('lib/l10n/app_en.arb');

    test('zh and en have identical key sets', () {
      final zhKeys = zh.keys.where((k) => !k.startsWith('@')).toSet();
      final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
      final missingInEn = zhKeys.difference(enKeys);
      final missingInZh = enKeys.difference(zhKeys);
      expect(missingInEn, isEmpty,
          reason: 'Keys missing English translation: $missingInEn');
      expect(missingInZh, isEmpty,
          reason: 'Keys missing from template (zh): $missingInZh');
    });

    test('every value key in the zh template has @key metadata', () {
      final zhKeys = zh.keys.where((k) => !k.startsWith('@')).toSet();
      final metaKeys = zh.keys.where((k) => k.startsWith('@')).toSet();
      // @@locale is the ARB locale marker; skip it.
      final valueKeys = zhKeys.where((k) => k != '@@locale').toSet();
      final withoutMeta =
          valueKeys.where((k) => !metaKeys.contains('@$k')).toSet();
      expect(withoutMeta, isEmpty,
          reason: 'Keys without @key metadata: $withoutMeta');
    });
  });
}

Map<String, dynamic> _loadArb(String path) {
  final raw = File(path).readAsStringSync();
  return json.decode(raw) as Map<String, dynamic>;
}
