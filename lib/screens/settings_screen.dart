import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/workout_repository.dart';
import '../services/notification_sound_service.dart';
import '../services/data_transfer_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import 'user_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  final NotificationSoundService _soundService = NotificationSoundService();
  final DataTransferService _dataTransferService = DataTransferService();
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _detailedRecordingEnabled = false;
  String _customMessage = '准备开始下一组！';
  String _selectedSound = 'default';
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: _customMessage);
    _loadSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    await _soundService.init();
    setState(() {
      _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
      _detailedRecordingEnabled = _prefs.getBool('detailed_recording') ?? false;
      _customMessage = _prefs.getString('custom_message') ?? '准备开始下一组！';
      _messageController.text = _customMessage;
      _selectedSound = _soundService.getSelectedSound();
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('sound_enabled', _soundEnabled);
    await _prefs.setBool('vibration_enabled', _vibrationEnabled);
    await _prefs.setBool('detailed_recording', _detailedRecordingEnabled);
    await _prefs.setString('custom_message', _customMessage);
  }

  Future<void> _clearHistory(AppThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text('确认清除', style: TextStyle(color: theme.textColor)),
        content: Text(
          '确定要清除所有历史记录吗？此操作不可撤销。',
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearAllSessions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('历史记录已清除')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.timerGradientColors),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            Text(
              '设置',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 86,
        ),
        children: [
          // Notification Settings
          _buildSectionHeader('通知设置', theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                _buildSettingsSwitch('启用声音', _soundEnabled, (value) {
                  setState(() => _soundEnabled = value);
                  _saveSettings();
                }, theme),
                if (_soundEnabled) ...[
                  Divider(
                    color: theme.surfaceColor.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  ListTile(
                    title: Text(
                      '通知铃声',
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      _soundService.getSoundDisplayName(_selectedSound),
                      style: TextStyle(color: theme.secondaryTextColor),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.secondaryTextColor,
                    ),
                    onTap: () => _showSoundPicker(context, theme),
                  ),
                ],
                Divider(
                  color: theme.surfaceColor.withValues(alpha: 0.1),
                  height: 1,
                ),
                _buildSettingsSwitch('启用振动', _vibrationEnabled, (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSettings();
                }, theme),
                Divider(
                  color: theme.surfaceColor.withValues(alpha: 0.1),
                  height: 1,
                ),
                _buildSettingsSwitch('详细记录模式', _detailedRecordingEnabled, (
                  value,
                ) {
                  setState(() => _detailedRecordingEnabled = value);
                  _saveSettings();
                }, theme),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Settings
          _buildSectionHeader('外观设置', theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, tp, _) => _buildSettingsSwitch(
                    '深色模式',
                    tp.isDarkMode,
                    (value) => tp.setDarkMode(value),
                    theme,
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text('主题', style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    theme.nameZh,
                    style: TextStyle(color: theme.secondaryTextColor),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.secondaryTextColor,
                  ),
                  onTap: () => _showThemeSelector(context, themeProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Message
          _buildSectionHeader('自定义提醒消息', theme),
          _buildSettingsCard(
            theme: theme,
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: theme.textColor),
              onChanged: (value) => _customMessage = value,
              onSubmitted: (_) => _saveSettings(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                hintText: '输入提醒消息',
                hintStyle: TextStyle(color: theme.secondaryTextColor),
                filled: true,
                fillColor: theme.surfaceColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader('数据管理', theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.upload_file, color: theme.accentColor),
                  title: Text('导出数据', style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    '导出全部训练记录、计划等数据为文件',
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                  onTap: () => _exportData(theme),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.download, color: theme.accentColor),
                  title: Text('导入数据', style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    '从备份文件恢复全部数据（会覆盖现有数据）',
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                  onTap: () => _importData(theme),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text(
                    '清除所有历史记录',
                    style: TextStyle(color: theme.accentColor),
                  ),
                  trailing: Icon(
                    Icons.delete_outline,
                    color: theme.accentColor,
                  ),
                  onTap: () => _clearHistory(theme),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // AI Preferences
          _buildSectionHeader('AI 训练偏好', theme),
          _buildSettingsCard(
            theme: theme,
            child: ListTile(
              title: Text('训练偏好', style: TextStyle(color: theme.textColor)),
              subtitle: Text(
                '设置训练目标、经验水平等，AI功能将自动读取',
                style: Theme.of(context).textTheme.bodySmall!,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.secondaryTextColor,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserPreferencesScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(AppThemeData theme) async {
    // 先显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text('导出数据', style: TextStyle(color: theme.textColor)),
        content: Text(
          '将导出全部训练记录、计划、练习等数据。\n\n文件会保存到手机 Downloads 目录，同时弹出分享面板。',
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: const Text('导出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 显示加载提示
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: theme.accentColor)),
    );

    try {
      await _dataTransferService.exportAndShare();
    } catch (e) {
      debugPrint('导出失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
      }
    }
  }

  Future<void> _importData(AppThemeData theme) async {
    // 先显示加载提示，扫描本地备份文件
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: theme.accentColor)),
    );

    final localBackups = await _dataTransferService.discoverLocalBackups();

    if (!mounted) return;
    Navigator.pop(context); // 关闭加载提示

    // 显示导入选择对话框
    final result = await _showImportDialog(context, theme, localBackups);
    if (result == null || result.isEmpty) return;

    // 二次确认：导入会覆盖数据
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text('确认导入', style: TextStyle(color: theme.textColor)),
        content: Text(
          '⚠️ 导入将覆盖现有全部数据！\n\n将恢复来自：\n$result',
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.errorColor),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 执行导入
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: theme.accentColor)),
    );

    try {
      int count;
      if (result.startsWith('/')) {
        // 本地文件路径
        count = await _dataTransferService.importFromFile(result);
      } else {
        // 文件选择器模式
        count = await _dataTransferService.pickAndImport();
      }

      if (!mounted) return;
      Navigator.pop(context); // 关闭加载提示

      if (count > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入成功，共恢复 $count 条记录')));
      }
    } catch (e) {
      debugPrint('导入失败: $e');
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  /// 显示导入选择对话框
  /// 返回选中的文件路径，或 "file_picker" 表示手动选择
  Future<String?> _showImportDialog(
    BuildContext context,
    AppThemeData theme,
    List<BackupFileInfo> localBackups,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text('导入数据', style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 本地发现的备份文件
              if (localBackups.isNotEmpty) ...[
                Text(
                  '发现本地备份',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryTextColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ...localBackups.map(
                  (backup) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      _formatBackupName(backup.fileName),
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    subtitle: Text(
                      '${backup.sizeText} · ${_formatDate(backup.modifiedTime)}',
                      style: Theme.of(context).textTheme.bodySmall!,
                    ),
                    trailing: Icon(
                      Icons.restore,
                      color: theme.accentColor,
                      size: 20,
                    ),
                    onTap: () => Navigator.pop(context, backup.path),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: theme.dividerColor, height: 1),
                const SizedBox(height: 4),
              ],
              // 手动选择文件
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.folder_open, color: theme.accentColor),
                title: Text('手动选择文件', style: TextStyle(color: theme.textColor)),
                subtitle: Text(
                  '从其他位置选择 JSON 备份文件',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
                onTap: () => Navigator.pop(context, 'file_picker'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 格式化备份文件名为可读的日期
  String _formatBackupName(String fileName) {
    // workout_timer_backup_2026-06-04T12-30-45.json
    try {
      final dateStr = fileName
          .replaceFirst('workout_timer_backup_', '')
          .replaceFirst('.json', '');
      // 2026-06-04T12-30-45 -> 2026年6月4日 12:30
      final parts = dateStr.split('T');
      if (parts.length == 2) {
        final datePart = parts[0]; // 2026-06-04
        final timePart = parts[1].replaceAll('-', ':'); // 12-30-45 -> 12:30:45
        final date = DateTime.parse('$datePart $timePart');
        return '备份 ${date.year}年${date.month}月${date.day}日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return fileName;
  }

  /// 格式化日期
  String _formatDate(DateTime dt) {
    return '${dt.month}月${dt.day}日 ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSoundPicker(BuildContext context, AppThemeData theme) {
    final sounds = _soundService.getAvailableSounds();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(
          '选择铃声',
          style: TextStyle(fontWeight: FontWeight.w600, color: theme.textColor),
        ),
        content: RadioGroup<String>(
          groupValue: _selectedSound,
          onChanged: (value) async {
            if (value == null) return;
            await _soundService.setSelectedSound(value);
            setState(() => _selectedSound = value);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sounds.map((sound) {
              return RadioListTile<String>(
                title: Text(
                  _soundService.getSoundDisplayName(sound),
                  style: TextStyle(color: theme.textColor),
                ),
                value: sound,
                activeColor: theme.accentColor,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.secondaryTextColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required AppThemeData theme,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: theme.dividerColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    AppThemeData theme,
  ) {
    // 根据深色/浅色模式确定关闭态颜色
    final bool isDark = theme.isDark;
    final Color inactiveTrack = isDark
        ? theme.surfaceColor.withValues(alpha: 0.4)
        : theme.dividerColor;
    final Color inactiveThumb = isDark
        ? theme.surfaceColor.withValues(alpha: 0.9)
        : theme.cardColor;
    final Color inactiveOutline = isDark
        ? theme.surfaceColor.withValues(alpha: 0.5)
        : theme.dividerColor;

    return SwitchListTile(
      title: Text(title, style: TextStyle(color: theme.textColor)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.surfaceColor,
      activeTrackColor: theme.accentColor,
      inactiveThumbColor: inactiveThumb,
      inactiveTrackColor: inactiveTrack,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return theme.surfaceColor;
        }
        return inactiveThumb;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return theme.accentColor;
        }
        return inactiveTrack;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return theme.accentColor.withValues(alpha: 0.5);
        }
        return inactiveOutline;
      }),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surfaceColor.withValues(
            alpha: 0.95,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusChip),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择主题',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 20,
                  color: themeProvider.currentTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              ...allThemes.map((theme) {
                final isSelected =
                    themeProvider.currentTheme.name == theme.name;
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient color swatch preview
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusChip,
                          ),
                          gradient: LinearGradient(
                            colors: [theme.primaryColor, theme.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: isSelected
                              ? Border.all(color: theme.accentColor, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.accentColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: theme.onAccentColor,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Theme icon
                      Icon(theme.icon, color: theme.primaryColor),
                    ],
                  ),
                  title: Text(
                    theme.nameZh,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: themeProvider.currentTheme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    theme.description,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: themeProvider.currentTheme.secondaryTextColor,
                    ),
                  ),

                  onTap: () {
                    final themeType = AppThemeType.values.firstWhere(
                      (t) => getThemeData(t).name == theme.name,
                      orElse: () => AppThemeType.amberGold,
                    );
                    themeProvider.setTheme(themeType);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
