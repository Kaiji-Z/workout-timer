import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/workout_repository.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _customMessage = '准备开始下一组！';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
      _customMessage = _prefs.getString('custom_message') ?? '准备开始下一组！';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('sound_enabled', _soundEnabled);
    await _prefs.setBool('vibration_enabled', _vibrationEnabled);
    await _prefs.setString('custom_message', _customMessage);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearAllSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('历史记录已清除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: theme.timerGradientColors,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Selection
          _buildSectionHeader('外观', theme),
          _buildThemeSelector(context, theme),
          const SizedBox(height: 24),

          // Notification Settings
          _buildSectionHeader('通知设置', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    '启用声音',
                    style: TextStyle(color: theme.textColor),
                  ),
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                    _saveSettings();
                  },
                ),
                Divider(color: theme.borderColor, height: 1),
                SwitchListTile(
                  title: Text(
                    '启用振动',
                    style: TextStyle(color: theme.textColor),
                  ),
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Message
          _buildSectionHeader('自定义提醒消息', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: TextEditingController(text: _customMessage),
              style: TextStyle(color: theme.textColor),
              onChanged: (value) => _customMessage = value,
              onSubmitted: (_) => _saveSettings(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '输入提醒消息',
                hintStyle: TextStyle(color: theme.secondaryTextColor),
                filled: true,
                fillColor: theme.backgroundColor,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader('数据管理', theme),
          Container(
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: ListTile(
              title: Text(
                '清除所有历史记录',
                style: TextStyle(color: theme.warningColor),
              ),
              trailing: Icon(Icons.delete_outline, color: theme.warningColor),
              onTap: _clearHistory,
            ),
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
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.secondaryTextColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, AppThemeData theme) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentThemeName = themeProvider.currentTheme.nameZh;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: ListTile(
        leading: Icon(
          themeProvider.currentTheme.icon,
          color: theme.primaryColor,
        ),
        title: Text(
          '主题',
          style: TextStyle(color: theme.textColor),
        ),
        subtitle: Text(
          currentThemeName,
          style: TextStyle(color: theme.secondaryTextColor),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.secondaryTextColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ThemeSelectionScreen(),
            ),
          );
        },
      ),
    );
  }
}