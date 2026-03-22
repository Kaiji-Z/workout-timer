import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/workout_repository.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'user_preferences_screen.dart';


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
  bool _detailedRecordingEnabled = false;
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
      _detailedRecordingEnabled = _prefs.getBool('detailed_recording') ?? false;
      _customMessage = _prefs.getString('custom_message') ?? '准备开始下一组！';
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
        content: Text('确定要清除所有历史记录吗？此操作不可撤销。', style: TextStyle(color: theme.textColor)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('历史记录已清除')),
        );
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 18,
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
          _buildGlassCard(
            theme: theme,
            child: Column(
              children: [
                _buildGlassSwitch(
                  '启用声音',
                  _soundEnabled,
                  (value) {
                    setState(() => _soundEnabled = value);
                    _saveSettings();
                  },
                  theme,
                ),
                Divider(color: theme.surfaceColor.withValues(alpha: 0.1), height: 1),
                _buildGlassSwitch(
                  '启用振动',
                  _vibrationEnabled,
                  (value) {
                    setState(() => _vibrationEnabled = value);
                    _saveSettings();
                  },
                  theme,
                ),
                Divider(color: theme.surfaceColor.withValues(alpha: 0.1), height: 1),
                _buildGlassSwitch(
                  '详细记录模式',
                  _detailedRecordingEnabled,
                  (value) {
                    setState(() => _detailedRecordingEnabled = value);
                    _saveSettings();
                  },
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Settings
          _buildSectionHeader('外观设置', theme),
          _buildGlassCard(
            theme: theme,
            child: ListTile(
              title: Text(
                '主题',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.textColor,
                ),
              ),
              subtitle: Text(
                theme.nameZh,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.secondaryTextColor,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: theme.secondaryTextColor),
              onTap: () => _showThemeSelector(context, themeProvider),
            ),
          ),
          const SizedBox(height: 24),

          // Custom Message
          _buildSectionHeader('自定义提醒消息', theme),
          _buildGlassCard(
            theme: theme,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: TextEditingController(text: _customMessage),
              style: TextStyle(color: theme.textColor),
              onChanged: (value) => _customMessage = value,
              onSubmitted: (_) => _saveSettings(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
          _buildGlassCard(
            theme: theme,
            child: ListTile(
              title: Text(
                '清除所有历史记录',
                style: TextStyle(color: theme.accentColor),
              ),
              trailing: Icon(Icons.delete_outline, color: theme.accentColor),
              onTap: () => _clearHistory(theme),
            ),
          ),
          const SizedBox(height: 24),

          // AI Preferences
          _buildSectionHeader('AI 训练偏好', theme),
          _buildGlassCard(
            theme: theme,
            child: ListTile(
              title: Text(
                '训练偏好',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.textColor,
                ),
              ),
              subtitle: Text(
                '设置训练目标、经验水平等，AI功能将自动读取',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: theme.secondaryTextColor),
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

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.secondaryTextColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required AppThemeData theme, required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            // 统一玻璃效果：white 12%
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // 统一边框：white 30%
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassSwitch(String title, bool value, ValueChanged<bool> onChanged, AppThemeData theme) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          color: theme.textColor,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: theme.primaryColor.withValues(alpha: 0.7),
      inactiveThumbColor: Colors.white.withValues(alpha: 0.9),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white.withValues(alpha: 0.9);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return theme.primaryColor.withValues(alpha: 0.7);
        }
        return Colors.white.withValues(alpha: 0.2);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        return Colors.white.withValues(alpha: 0.9);
      }),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.currentTheme.surfaceColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择主题',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: themeProvider.currentTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...allThemes.map((theme) {
              final isSelected = themeProvider.currentTheme.name == theme.name;
              return ListTile(
                leading: Icon(theme.icon, color: theme.primaryColor),
                title: Text(
                  theme.nameZh,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontWeight: FontWeight.w500,
                    color: themeProvider.currentTheme.textColor,
                  ),
                ),
                subtitle: Text(
                  theme.description,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 12,
                    color: themeProvider.currentTheme.secondaryTextColor,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: themeProvider.currentTheme.primaryColor)
                    : null,
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
    );
  }
}
