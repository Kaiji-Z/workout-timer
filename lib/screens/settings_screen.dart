import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/battery_optimization_service.dart';
import '../services/workout_repository.dart';
import '../services/notification_sound_service.dart';
import '../services/data_transfer_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../utils/dimensions.dart';
import '../animations/page_transitions.dart';
import 'user_preferences_screen.dart';

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
    await _prefs.setString('custom_message', _customMessage);
  }

  Future<void> _clearHistory(AppThemeData theme) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(l10n.settingsClearHistoryConfirmTitle, style: TextStyle(color: theme.textColor)),
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
    final l10n = AppLocalizations.of(context)!;

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
              l10n.settingsTitle,
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
          _buildSectionHeader(l10n.settingsNotificationSection, theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                _buildSettingsSwitch(l10n.settingsEnableSound, _soundEnabled, (value) {
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
                _buildSettingsSwitch(l10n.settingsEnableVibration, _vibrationEnabled, (value) {
                  setState(() => _vibrationEnabled = value);
                  _saveSettings();
                }, theme),
                Divider(
                  color: theme.surfaceColor.withValues(alpha: 0.1),
                  height: 1,
                ),
                _buildSettingsSwitch(l10n.settingsDetailedRecording, _detailedRecordingEnabled, (
                  value,
                ) {
                  setState(() => _detailedRecordingEnabled = value);
                  _saveSettings();
                }, theme),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Background Running Settings (Android only)
          if (!kIsWeb && Platform.isAndroid) ...[
            _buildSectionHeader(l10n.settingsBackgroundSection, theme),
            _buildSettingsCard(
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
          _buildSectionHeader(l10n.settingsAppearanceSection, theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, tp, _) => _buildSettingsSwitch(
                    l10n.settingsDarkMode,
                    tp.isDarkMode,
                    (value) => tp.setDarkMode(value),
                    theme,
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text(l10n.settingsTheme, style: TextStyle(color: theme.textColor)),
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
          _buildSectionHeader(l10n.settingsLanguage, theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                Consumer<LocaleProvider>(
                  builder: (context, lp, _) => Column(
                    children: [
                      RadioListTile<String>(
                        value: 'system',
                        groupValue: lp.localeCode,
                        title: Text(l10n.settingsLanguageSystem),
                        onChanged: (v) =>
                            context.read<LocaleProvider>().setLocaleCode(v!),
                      ),
                      RadioListTile<String>(
                        value: 'zh',
                        groupValue: lp.localeCode,
                        title: Text(l10n.settingsLanguageZh),
                        onChanged: (v) =>
                            context.read<LocaleProvider>().setLocaleCode(v!),
                      ),
                      RadioListTile<String>(
                        value: 'en',
                        groupValue: lp.localeCode,
                        title: Text(l10n.settingsLanguageEn),
                        onChanged: (v) =>
                            context.read<LocaleProvider>().setLocaleCode(v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Message
          _buildSectionHeader(l10n.settingsCustomMessageSection, theme),
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
                hintText: l10n.settingsCustomMessageHint,
                hintStyle: TextStyle(color: theme.secondaryTextColor),
                filled: true,
                fillColor: theme.surfaceColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader(l10n.settingsDataSection, theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.upload_file, color: theme.accentColor),
                  title: Text(l10n.settingsExportData, style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    l10n.settingsExportSubtitle,
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                  onTap: () => _exportData(theme),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  leading: Icon(Icons.download, color: theme.accentColor),
                  title: Text(l10n.settingsImportData, style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    l10n.settingsImportSubtitle,
                    style: Theme.of(context).textTheme.bodySmall!,
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
          _buildSectionHeader(l10n.settingsAiPreferencesSection, theme),
          _buildSettingsCard(
            theme: theme,
            child: ListTile(
              title: Text(l10n.settingsTrainingPreferences, style: TextStyle(color: theme.textColor)),
              subtitle: Text(
                l10n.settingsTrainingPreferencesSubtitle,
                style: Theme.of(context).textTheme.bodySmall!,
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
          _buildSectionHeader(l10n.settingsAboutSection, theme),
          _buildSettingsCard(
            theme: theme,
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.settingsPrivacyPolicy, style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    l10n.settingsPrivacyPolicySubtitle,
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.secondaryTextColor,
                  ),
                  onTap: () => _showPrivacyPolicy(theme),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text(l10n.settingsVersion, style: TextStyle(color: theme.textColor)),
                  trailing: Text(
                    // Dynamic, read from pubspec at runtime (see _loadSettings).
                    _appVersion.isEmpty ? l10n.settingsVersionLoading : _appVersion,
                    style: TextStyle(color: theme.secondaryTextColor),
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text(l10n.settingsDeveloper, style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    l10n.settingsDeveloperName,
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                ),
                Divider(color: theme.dividerColor, height: 1),
                ListTile(
                  title: Text(l10n.settingsContactEmail, style: TextStyle(color: theme.textColor)),
                  subtitle: Text(
                    'lookatmedia@163.com',
                    style: Theme.of(context).textTheme.bodySmall!,
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
                        content: Text(AppLocalizations.of(context)!.settingsEmailCopied),
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
    );
  }

  void _showPrivacyPolicy(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.98),
        title: Text(l10n.settingsPrivacyPolicy, style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsPrivacyHeadline,
                  style: TextStyle(
                    color: theme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.settingsPrivacyDataStorage,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsPrivacyDataStorageBody,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.settingsPrivacyPermissions,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.settingsPrivacyPermNotifications}\n'
                  '${l10n.settingsPrivacyPermVibration}\n'
                  '${l10n.settingsPrivacyPermForegroundService}\n'
                  '${l10n.settingsPrivacyPermNetwork}\n'
                  '${l10n.settingsPrivacyPermBatteryExempt}',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.settingsPrivacyThirdParty,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsPrivacyThirdPartyBody,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.settingsPrivacyFullPolicy,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'https://kaiji-z.github.io/workout-timer/',
                ),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsPrivacyLinkCopied),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(l10n.settingsCopyLink),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsClose),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(AppThemeData theme) async {
    final l10n = AppLocalizations.of(context)!;
    // 先显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(l10n.settingsExportData, style: TextStyle(color: theme.textColor)),
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
      debugPrint('导出失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsExportFailed('$e'))));
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
      }
    }
  }

  Future<void> _importData(AppThemeData theme) async {
    final l10n = AppLocalizations.of(context)!;
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

    if (!mounted) return;
    // 二次确认：导入会覆盖数据
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(l10n.settingsImportConfirmTitle, style: TextStyle(color: theme.textColor)),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsImportSuccess(count))));
      }
    } catch (e) {
      debugPrint('导入失败: $e');
      if (mounted) {
        Navigator.pop(context); // 关闭加载提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.settingsImportFailed('$e'))));
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
        title: Text(l10n.settingsImportData, style: TextStyle(color: theme.textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 本地发现的备份文件
              if (localBackups.isNotEmpty) ...[
                Text(
                  l10n.settingsFoundLocalBackups,
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
                      _formatBackupName(
                        backup.fileName,
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    subtitle: Text(
                      '${backup.sizeText} · ${_formatDate(backup.modifiedTime, Localizations.localeOf(context).languageCode)}',
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
                title: Text(l10n.settingsSelectManually, style: TextStyle(color: theme.textColor)),
                subtitle: Text(
                  l10n.settingsSelectManuallySubtitle,
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
            child: Text(l10n.settingsCancel),
          ),
        ],
      ),
    );
  }

  /// 格式化备份文件名为可读的日期
  String _formatBackupName(String fileName, String locale) {
    // workout_timer_backup_2026-06-04T12-30-45.json
    try {
      final dateStr = fileName
          .replaceFirst('workout_timer_backup_', '')
          .replaceFirst('.json', '');
      // 2026-06-04T12-30-45 -> localized date time
      final parts = dateStr.split('T');
      if (parts.length == 2) {
        final datePart = parts[0]; // 2026-06-04
        final timePart = parts[1].replaceAll('-', ':'); // 12-30-45 -> 12:30:45
        final date = DateTime.parse('$datePart $timePart');
        final df = DateFormat.yMd(locale).add_Hm();
        return '${AppLocalizations.of(context)!.settingsBackupPrefix} ${df.format(date)}';
      }
    } catch (_) {}
    return fileName;
  }

  /// 格式化日期
  String _formatDate(DateTime dt, String locale) {
    final df = DateFormat.MMMd(locale).add_Hm();
    return df.format(dt);
  }

  void _showSoundPicker(BuildContext context, AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: child,
    );
  }

  /// Builds the OEM-specific battery settings section (Chinese OEMs only).
  ///
  /// Shows manufacturer-specific step-by-step instructions and a button to
  /// open the OEM settings page. Returns an empty list when [manufacturer]
  /// is null (defensive guard — the build method already checks non-null).
  List<Widget> _buildOemSection(String? manufacturer, AppThemeData theme) {
    if (manufacturer == null) return const [];
    final l10n = AppLocalizations.of(context)!;
    final displayName = _oemDisplayName(manufacturer, l10n);
    final instruction = _oemInstruction(manufacturer, l10n);

    return [
      _buildSectionHeader(l10n.oemSectionTitle, theme),
      _buildSettingsCard(
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
    final l10n = AppLocalizations.of(context)!;
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
