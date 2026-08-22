import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/battery_optimization_service.dart';
import '../services/workout_repository.dart';
import '../services/notification_sound_service.dart';
import '../services/data_transfer_service.dart';
import '../widgets/settings_widgets.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../providers/locale_provider.dart';
import '../utils/dimensions.dart';
import '../animations/page_transitions.dart';
import 'user_preferences_screen.dart';
import '../theme/build_context_text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final WorkoutRepository _repository = WorkoutRepository();
  final NotificationSoundService _soundService = NotificationSoundService();
  final DataTransferService _dataTransferService = DataTransferService();
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _detailedRecordingEnabled = false;
  bool _idleReminderEnabled = true;
  int _idleReminderMinutes = 10;
  String _customMessage = '';
  String _selectedSound = 'default';
  bool _isBatteryOptimizationIgnored = true; // Default true (non-Android)
  String? _oemManufacturer;
  bool _oemAutoStartAvailable = false;
  late final TextEditingController _messageController;
  // App version read at runtime from pubspec (package_info_plus). Avoids the
  // stale-hardcoded-version bug where the About screen fell 2 minor versions
  // behind the actual release.
  String _appVersion = '';

  /// OEM manufacturer code -> localized display name.
  String _oemDisplayName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'huawei':
        return l10n.brandHuawei;
      case 'honor':
        return l10n.brandHonor;
      case 'xiaomi':
        return l10n.brandXiaomi;
      case 'oppo':
        return l10n.brandOppo;
      case 'vivo':
        return l10n.brandVivo;
      case 'meizu':
        return l10n.brandMeizu;
      case 'samsung':
        return l10n.brandSamsung;
      case 'oneplus':
        return l10n.brandOneplus;
      default:
        return code;
    }
  }

  /// OEM manufacturer code -> localized step-by-step instruction text.
  String _oemInstruction(String code, AppLocalizations l10n) {
    switch (code) {
      case 'huawei':
        return l10n.oemInstructionHuawei;
      case 'honor':
        return l10n.oemInstructionHonor;
      case 'xiaomi':
        return l10n.oemInstructionXiaomi;
      case 'oppo':
        return l10n.oemInstructionOppo;
      case 'vivo':
        return l10n.oemInstructionVivo;
      case 'meizu':
        return l10n.oemInstructionMeizu;
      case 'samsung':
        return l10n.oemInstructionSamsung;
      case 'oneplus':
        return l10n.oemInstructionOneplus;
      default:
        return l10n.oemDefaultInstruction;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController(text: _customMessage);
    _loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb && Platform.isAndroid) {
      // Refresh battery optimization status when user returns from system settings
      BatteryOptimizationService.isIgnoringBatteryOptimizations().then((
        ignored,
      ) {
        if (mounted) {
          setState(() => _isBatteryOptimizationIgnored = ignored);
        }
      });
      _checkOemStatus();
    }
  }

  /// Checks OEM-specific battery/auto-start settings (Chinese OEMs only).
  ///
  /// Updates [_oemManufacturer] and [_oemAutoStartAvailable] when the device is
  /// a Chinese OEM (华为/小米/OPPO/vivo/魅族/三星/OnePlus).
  void _checkOemStatus() {
    BatteryOptimizationService.getOemManufacturer().then((oem) {
      if (!mounted || oem == null) return;
      BatteryOptimizationService.isOemAutoStartAvailable().then((available) {
        if (!mounted) return;
        setState(() {
          _oemManufacturer = oem;
          _oemAutoStartAvailable = available;
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    await _soundService.init();

    // Read app version at runtime so the About screen never lags behind a
    // release. Shows only the version (e.g. "1.2.0") to match the version
    // registered for software copyright / store listing — not the build
    // number, which is an internal detail users don't see elsewhere.
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (e) {
      debugPrint('Failed to read package info: $e');
    }

    setState(() {
      _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
      _detailedRecordingEnabled = _prefs.getBool('detailed_recording') ?? false;
      _idleReminderEnabled = _prefs.getBool('idle_reminder_enabled') ?? true;
      _idleReminderMinutes = _prefs.getInt('idle_reminder_minutes') ?? 10;
      _customMessage = _prefs.getString('custom_message') ?? '';
      _messageController.text = _customMessage;
      _selectedSound = _soundService.getSelectedSound();
    });

    // Check battery optimization status (Android only)
    if (!kIsWeb && Platform.isAndroid) {
      final ignored =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();
      if (mounted) {
        setState(() => _isBatteryOptimizationIgnored = ignored);
      }
      // Check OEM-specific battery settings
      _checkOemStatus();
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('sound_enabled', _soundEnabled);
    await _prefs.setBool('vibration_enabled', _vibrationEnabled);
    await _prefs.setBool('detailed_recording', _detailedRecordingEnabled);
    await _prefs.setBool('idle_reminder_enabled', _idleReminderEnabled);
    await _prefs.setInt('idle_reminder_minutes', _idleReminderMinutes);
    await _prefs.setString('custom_message', _customMessage);
  }

  /// 空闲提醒阈值选择（5/10/15/30/60 分钟）
  Future<void> _showIdleReminderPicker(
    BuildContext context,
    AppThemeData theme,
  ) async {
    final l10n = context.l10n;
    const options = [5, 10, 15, 30, 60];
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          l10n.settingsIdleReminderAfter,
          style: TextStyle(color: theme.textColor),
        ),
        children: options
            .map(
              (minutes) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(minutes),
                child: Row(
                  children: [
                    Icon(
                      minutes == _idleReminderMinutes
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: minutes == _idleReminderMinutes
                          ? theme.accentColor
                          : theme.secondaryTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.settingsMinutes(minutes),
                      style: TextStyle(color: theme.textColor),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && selected != _idleReminderMinutes) {
      setState(() => _idleReminderMinutes = selected);
      _saveSettings();
    }
  }

  Future<void> _clearHistory(AppThemeData theme) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(
          l10n.settingsClearHistoryConfirmTitle,
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          l10n.settingsClearHistoryConfirmBody,
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: Text(l10n.settingsClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.clearAllSessions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsHistoryCleared)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          l10n.settingsTitle,
          style: context.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.textColor,
          ),
        ),
      ),
      // SingleChildScrollView + Column（非惰性）而非 ListView：设置页区块数量
      // 有限，一次性构建开销可忽略；换成惰性列表会把首屏外的区块（如语言区）
      // 推出构建范围，widget 测试里 find.text/ensureVisible 就找不到了。
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 86,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notification Settings
            buildSettingsSectionHeader(
              context,
              l10n.settingsNotificationSection,
              theme,
            ),
            buildSettingsCard(
              theme: theme,
              child: Column(
                children: [
                  buildSettingsSwitch(l10n.settingsEnableSound, _soundEnabled, (
                    value,
                  ) {
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
                        l10n.settingsNotificationRingtone,
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
                  buildSettingsSwitch(
                    l10n.settingsEnableVibration,
                    _vibrationEnabled,
                    (value) {
                      setState(() => _vibrationEnabled = value);
                      _saveSettings();
                    },
                    theme,
                  ),
                  Divider(
                    color: theme.surfaceColor.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  buildSettingsSwitch(
                    l10n.settingsDetailedRecording,
                    _detailedRecordingEnabled,
                    (value) {
                      setState(() => _detailedRecordingEnabled = value);
                      _saveSettings();
                    },
                    theme,
                  ),
                  Divider(
                    color: theme.surfaceColor.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  // 空闲提醒（方案 A）：运动中长时间无操作时通知提醒
                  buildSettingsSwitch(
                    l10n.settingsIdleReminder,
                    _idleReminderEnabled,
                    (value) {
                      setState(() => _idleReminderEnabled = value);
                      _saveSettings();
                    },
                    theme,
                    subtitle: l10n.settingsIdleReminderDesc,
                  ),
                  if (_idleReminderEnabled) ...[
                    Divider(
                      color: theme.surfaceColor.withValues(alpha: 0.1),
                      height: 1,
                    ),
                    ListTile(
                      title: Text(
                        l10n.settingsIdleReminderAfter,
                        style: TextStyle(color: theme.textColor),
                      ),
                      trailing: Text(
                        l10n.settingsMinutes(_idleReminderMinutes),
                        style: TextStyle(color: theme.accentColor),
                      ),
                      onTap: () => _showIdleReminderPicker(context, theme),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Background Running Settings (Android only)
            if (!kIsWeb && Platform.isAndroid) ...[
              buildSettingsSectionHeader(
                context,
                l10n.settingsBackgroundSection,
                theme,
              ),
              buildSettingsCard(
                theme: theme,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        l10n.settingsAllowBackground,
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        _isBatteryOptimizationIgnored
                            ? l10n.settingsBackgroundAllowed
                            : l10n.settingsBackgroundNotAllowed,
                        style: TextStyle(
                          color: _isBatteryOptimizationIgnored
                              ? theme.secondaryTextColor
                              : theme.errorColor,
                        ),
                      ),
                      trailing: Icon(
                        _isBatteryOptimizationIgnored
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: _isBatteryOptimizationIgnored
                            ? theme.successColor
                            : theme.warningColor,
                      ),
                      onTap: () async {
                        if (!_isBatteryOptimizationIgnored) {
                          await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
                        }
                      },
                    ),
                    if (!_isBatteryOptimizationIgnored) ...[
                      Divider(
                        color: theme.surfaceColor.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.settingsBackgroundHint,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_oemManufacturer != null && _oemAutoStartAvailable)
                ..._buildOemSection(_oemManufacturer, theme),
            ],

            // Appearance Settings
            buildSettingsSectionHeader(
              context,
              l10n.settingsAppearanceSection,
              theme,
            ),
            buildSettingsCard(
              theme: theme,
              child: Column(
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, tp, _) => buildSettingsSwitch(
                      l10n.settingsDarkMode,
                      tp.isDarkMode,
                      (value) => tp.setDarkMode(value),
                      theme,
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text(
                      l10n.settingsTheme,
                      style: TextStyle(color: theme.textColor),
                    ),
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

            // Language
            buildSettingsSectionHeader(context, l10n.settingsLanguage, theme),
            buildSettingsCard(
              theme: theme,
              child: Column(
                children: [
                  Consumer<LocaleProvider>(
                    builder: (context, lp, _) => RadioGroup<String>(
                      groupValue: lp.localeCode,
                      onChanged: (v) {
                        if (v != null) {
                          context.read<LocaleProvider>().setLocaleCode(v);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'system',
                            title: Text(l10n.settingsLanguageSystem),
                          ),
                          RadioListTile<String>(
                            value: 'zh',
                            title: Text(l10n.settingsLanguageZh),
                          ),
                          RadioListTile<String>(
                            value: 'en',
                            title: Text(l10n.settingsLanguageEn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Custom Message
            buildSettingsSectionHeader(
              context,
              l10n.settingsCustomMessageSection,
              theme,
            ),
            buildSettingsCard(
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
                  hintText: l10n.settingsCustomMessageHint,
                  hintStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.surfaceColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data Management
            buildSettingsSectionHeader(
              context,
              l10n.settingsDataSection,
              theme,
            ),
            buildSettingsCard(
              theme: theme,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.upload_file, color: theme.accentColor),
                    title: Text(
                      l10n.settingsExportData,
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      l10n.settingsExportSubtitle,
                      style: context.bodySmall,
                    ),
                    onTap: () => _exportData(theme),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    leading: Icon(Icons.download, color: theme.accentColor),
                    title: Text(
                      l10n.settingsImportData,
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      l10n.settingsImportSubtitle,
                      style: context.bodySmall,
                    ),
                    onTap: () => _importData(theme),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text(
                      l10n.settingsClearHistory,
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
            buildSettingsSectionHeader(
              context,
              l10n.settingsAiPreferencesSection,
              theme,
            ),
            buildSettingsCard(
              theme: theme,
              child: ListTile(
                title: Text(
                  l10n.settingsTrainingPreferences,
                  style: TextStyle(color: theme.textColor),
                ),
                subtitle: Text(
                  l10n.settingsTrainingPreferencesSubtitle,
                  style: context.bodySmall,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.secondaryTextColor,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    FadeUpPageRoute(page: const UserPreferencesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // About
            buildSettingsSectionHeader(
              context,
              l10n.settingsAboutSection,
              theme,
            ),
            buildSettingsCard(
              theme: theme,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      l10n.settingsPrivacyPolicy,
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      l10n.settingsPrivacyPolicySubtitle,
                      style: context.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.secondaryTextColor,
                    ),
                    onTap: () => showPrivacyPolicyDialog(context, theme),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text(
                      l10n.settingsVersion,
                      style: TextStyle(color: theme.textColor),
                    ),
                    trailing: Text(
                      // Dynamic, read from pubspec at runtime (see _loadSettings).
                      _appVersion.isEmpty
                          ? l10n.settingsVersionLoading
                          : _appVersion,
                      style: TextStyle(color: theme.secondaryTextColor),
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text(
                      l10n.settingsDeveloper,
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      l10n.settingsDeveloperName,
                      style: context.bodySmall,
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  ListTile(
                    title: Text(
                      l10n.settingsContactEmail,
                      style: TextStyle(color: theme.textColor),
                    ),
                    subtitle: Text(
                      'lookatmedia@163.com',
                      style: context.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.content_copy,
                      color: theme.secondaryTextColor,
                      size: 20,
                    ),
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'lookatmedia@163.com'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.settingsEmailCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(AppThemeData theme) async {
    final l10n = context.l10n;
    // 先显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(
          l10n.settingsExportData,
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          l10n.settingsExportConfirmBody,
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: Text(l10n.settingsExport),
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
      debugPrint('Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsExportFailed('$e'))),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
      }
    }
  }

  Future<void> _importData(AppThemeData theme) async {
    final l10n = context.l10n;
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
    final result = await showImportDialog(context, theme, localBackups);
    if (result == null || result.isEmpty) return;

    if (!mounted) return;
    // 二次确认：导入会覆盖数据
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(
          l10n.settingsImportConfirmTitle,
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          l10n.settingsImportConfirmBody(result),
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: theme.accentColor),
            child: Text(l10n.settingsConfirmImport),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsImportSuccess(count))),
        );
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsImportFailed('$e'))),
        );
      }
    }
  }

  void _showSoundPicker(BuildContext context, AppThemeData theme) {
    final l10n = context.l10n;
    final sounds = _soundService.getAvailableSounds();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(
          l10n.settingsSelectRingtone,
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
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOemSection(String? manufacturer, AppThemeData theme) {
    if (manufacturer == null) return const [];
    final l10n = context.l10n;
    final displayName = _oemDisplayName(manufacturer, l10n);
    final instruction = _oemInstruction(manufacturer, l10n);

    return [
      buildSettingsSectionHeader(context, l10n.oemSectionTitle, theme),
      buildSettingsCard(
        theme: theme,
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with manufacturer name
            Row(
              children: [
                Icon(Icons.phone_android, size: 20, color: theme.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.oemCardTitle(displayName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Explanation text
            Text(
              l10n.oemExplanation(displayName),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.secondaryTextColor,
              ),
            ),
            // Flow hint: do standard whitelist first, then OEM setting.
            // Show only when standard whitelist is NOT yet granted.
            if (!_isBatteryOptimizationIgnored) ...[
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.oemFlowHint,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Step-by-step instructions box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.checklist, size: 16, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action button to open OEM settings
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  BatteryOptimizationService.requestOemAutoStart();
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.oemGoButton(displayName)),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    final l10n = context.l10n;
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
                l10n.settingsSelectTheme,
                style: context.headlineMedium.copyWith(
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
                              ? AppElevation.resting(
                                  theme.accentColor.withValues(alpha: 0.3),
                                )
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
                    style: context.bodySmall.copyWith(
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
