import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_helper.dart';

/// 数据导出/导入服务
/// 导出全部8个SQLite表为JSON文件，支持跨设备数据迁移
class DataTransferService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 需要导出的表名列表（按外键依赖顺序排列）
  static const _tables = [
    DatabaseHelper.tableWorkoutSessions,
    DatabaseHelper.tableExercises,
    DatabaseHelper.tableWorkoutPlans,
    DatabaseHelper.tablePlanExercises,
    DatabaseHelper.tableCalendarPlans,
    DatabaseHelper.tableWorkoutRecords,
    DatabaseHelper.tableRecordExercises,
    DatabaseHelper.tableFavoriteExercises,
  ];

  /// 导出版本号，未来格式变更时可用于兼容
  static const _exportVersion = 1;

  // ==================== 导出 ====================

  /// 导出全部数据为 JSON 字符串
  Future<String> exportToJson() async {
    final db = await _dbHelper.database;
    final Map<String, dynamic> exportData = {
      'version': _exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    };

    for (final table in _tables) {
      final rows = await db.query(table);
      // 将每行的值转为 JSON 安全类型
      exportData[table] = rows.map((row) => _mapToJsonSafe(row)).toList();
    }

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 导出数据到 Downloads 目录并分享
  /// 返回导出文件路径
  Future<String> exportAndShare() async {
    final jsonStr = await exportToJson();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final fileName = 'workout_timer_backup_$timestamp.json';

    // 优先保存到 Downloads 目录
    String savedPath;
    if (Platform.isAndroid) {
      savedPath = await _saveToDownloads(jsonStr, fileName);
    } else {
      // iOS / 其他平台用临时目录 + 分享
      final tempDir = await getTemporaryDirectory();
      savedPath = '${tempDir.path}/$fileName';
      await File(savedPath).writeAsString(jsonStr);
    }

    // 同时弹出系统分享面板（用户可以额外发到微信等）
    if (!kIsWeb) {
      await Share.shareXFiles([XFile(savedPath)], text: '撸铁计时器数据备份');
    }

    return savedPath;
  }

  /// 保存文件到 Android Downloads 目录
  /// 依次尝试 Environment.DIRECTORY_DOWNLOADS 的多个公共路径
  Future<String> _saveToDownloads(String content, String fileName) async {
    // 尝试标准 Downloads 公共目录
    final List<String> downloadPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ];

    // 也尝试通过 path_provider 获取外部存储
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // path_provider 返回的是 app 专用目录，推导公共 Downloads
        final externalPath = externalDir.path;
        final parts = externalPath.split('/');
        final androidIdx = parts.indexOf('Android');
        if (androidIdx > 0) {
          final publicRoot = parts.sublist(0, androidIdx).join('/');
          downloadPaths.add('$publicRoot/Download');
          downloadPaths.add('$publicRoot/Downloads');
        }
      }
    } catch (_) {}

    // 写入第一个可用的 Downloads 目录
    for (final dirPath in downloadPaths) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final filePath = '$dirPath/$fileName';
        await File(filePath).writeAsString(content);
        return filePath;
      }
    }

    // 兜底：所有路径都不可用，用临时目录
    final tempDir = await getTemporaryDirectory();
    final fallbackPath = '${tempDir.path}/$fileName';
    await File(fallbackPath).writeAsString(content);
    return fallbackPath;
  }

  // ==================== 导入 ====================

  /// 扫描 Downloads 目录，查找本 app 导出的备份文件
  /// 返回文件路径列表，按修改时间倒序（最新的在前）
  Future<List<BackupFileInfo>> discoverLocalBackups() async {
    final List<BackupFileInfo> backups = [];

    for (final dirPath in await _getDownloadPaths()) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final name = entity.path.split('/').last;
          if (name.startsWith('workout_timer_backup_')) {
            final stat = await entity.stat();
            backups.add(
              BackupFileInfo(
                path: entity.path,
                fileName: name,
                modifiedTime: stat.modified,
                sizeBytes: stat.size,
              ),
            );
          }
        }
      }
    }

    // 按修改时间倒序排列
    backups.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    return backups;
  }

  /// 获取可能的 Downloads 目录路径列表
  Future<List<String>> _getDownloadPaths() async {
    final paths = <String>[
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ];

    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final parts = externalDir.path.split('/');
        final androidIdx = parts.indexOf('Android');
        if (androidIdx > 0) {
          final publicRoot = parts.sublist(0, androidIdx).join('/');
          paths.add('$publicRoot/Download');
          paths.add('$publicRoot/Downloads');
        }
      }
    } catch (_) {}

    return paths;
  }

  /// 从指定路径导入
  Future<int> importFromFile(String filePath) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    return importFromJson(jsonStr);
  }

  /// 从文件选择器选择 JSON 文件并导入
  /// 返回导入的记录总数
  Future<int> pickAndImport() async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台暂不支持文件导入');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return 0; // 用户取消选择
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      return 0;
    }

    final file = File(filePath);
    final jsonStr = await file.readAsString();
    return importFromJson(jsonStr);
  }

  /// 从 JSON 字符串导入全部数据
  /// 会先清空现有数据再导入（全量替换）
  /// 返回导入的记录总数
  Future<int> importFromJson(String jsonStr) async {
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;

    // 验证格式
    if (!data.containsKey('version') ||
        !data.containsKey(DatabaseHelper.tableWorkoutSessions)) {
      throw const FormatException('无效的备份文件格式');
    }

    final db = await _dbHelper.database;
    int totalImported = 0;

    await db.transaction((txn) async {
      // 按外键依赖的反序清空表（先删子表再删父表）
      for (final table in _tables.reversed) {
        await txn.delete(table);
      }

      // 按外键依赖的顺序插入（先插父表再插子表）
      for (final table in _tables) {
        final List<dynamic>? rows = data[table] as List<dynamic>?;
        if (rows == null || rows.isEmpty) continue;

        for (final row in rows) {
          final Map<String, dynamic> rowMap = _jsonSafeToMap(
            row as Map<String, dynamic>,
          );
          await txn.insert(table, rowMap);
          totalImported++;
        }
      }
    });

    return totalImported;
  }

  /// 获取各表的记录数统计
  Future<Map<String, int>> getTableCounts() async {
    final db = await _dbHelper.database;
    final counts = <String, int>{};

    for (final table in _tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      counts[table] = result.first['count'] as int;
    }

    return counts;
  }

  // ==================== 工具方法 ====================

  /// 将 SQLite 行数据转为 JSON 安全的 Map
  /// 处理 int/BigInt 等类型
  static Map<String, dynamic> _mapToJsonSafe(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is BigInt) {
        return MapEntry(key, value.toInt());
      }
      return MapEntry(key, value);
    });
  }

  /// 将 JSON Map 转回 SQLite 兼容的 Map
  static Map<String, dynamic> _jsonSafeToMap(Map<String, dynamic> map) {
    // JSON 反序列化后类型已经兼容 SQLite，直接返回
    return map;
  }
}

/// 备份文件信息
class BackupFileInfo {
  final String path;
  final String fileName;
  final DateTime modifiedTime;
  final int sizeBytes;

  const BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.modifiedTime,
    required this.sizeBytes,
  });

  /// 格式化文件大小
  String get sizeText {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
