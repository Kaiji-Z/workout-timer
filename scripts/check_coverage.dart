// 解析 coverage/lcov.info，对核心业务层（providers/services/models）强制行覆盖率阈值。
//
// 用法：
//   flutter test --coverage
//   dart run scripts/check_coverage.dart [--min 75]
//
// 退出码：0 = 达标；1 = 低于阈值；2 = 没找到覆盖率文件（先跑 flutter test --coverage）。
import 'dart:io';

const coreDirs = <String>['lib/providers/', 'lib/services/', 'lib/models/'];

void main(List<String> args) {
  var min = 55.0;
  final minIndex = args.indexOf('--min');
  if (minIndex != -1 && args.length > minIndex + 1) {
    min = double.tryParse(args[minIndex + 1]) ?? min;
  }

  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln('coverage/lcov.info 不存在——先运行 `flutter test --coverage`。');
    exit(2);
  }

  // SF:lib/xxx.dart ... LF:<总行> LH:<命中行>，按目录聚合。
  final found = <String, int>{};
  final hit = <String, int>{};
  String? currentFile;
  for (final rawLine in lcov.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
    } else if (line.startsWith('LF:')) {
      final dir = _coreDirOf(currentFile);
      if (dir == null) continue;
      found[dir] = (found[dir] ?? 0) + int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      final dir = _coreDirOf(currentFile);
      if (dir == null) continue;
      hit[dir] = (hit[dir] ?? 0) + int.parse(line.substring(3));
    }
  }

  if (found.isEmpty) {
    stderr.writeln('lcov 中没有核心层（$coreDirs）的数据。');
    exit(2);
  }

  var totalFound = 0;
  var totalHit = 0;

  final order = coreDirs.where(found.containsKey).toList();
  for (final dir in order) {
    final f = found[dir]!;
    final h = hit[dir]!;
    totalFound += f;
    totalHit += h;
    final pct = f == 0 ? 100.0 : h * 100 / f;
    // 目录级只展示不设门禁；门禁只看核心层合计（分目录收紧留待后续棘轮）。
    stdout.writeln('  $dir  ${pct.toStringAsFixed(1)}% ($h/$f)');
  }
  final totalPct = totalFound == 0 ? 100.0 : totalHit * 100 / totalFound;
  final failed = totalPct < min;
  stdout.writeln(
    '${totalPct >= min ? "✓" : "✗"} 核心层合计  ${totalPct.toStringAsFixed(1)}% '
    '($totalHit/$totalFound)，阈值 $min%',
  );
  exit(failed ? 1 : 0);
}

String? _coreDirOf(String? filePath) {
  if (filePath == null) return null;
  final normalized = filePath.replaceAll('\\', '/');
  // lcov 的 SF 可能是绝对路径（含盘符）或相对路径，统一按 /lib/ 段切分。
  final libIndex = normalized.indexOf('/lib/');
  final relative = libIndex == -1
      ? normalized
      : normalized.substring(libIndex + 1); // 保留 'lib/...'
  for (final dir in coreDirs) {
    if (relative.startsWith(dir)) return dir;
  }
  return null;
}
