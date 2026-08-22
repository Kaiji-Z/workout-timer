import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/context_l10n.dart';
import '../services/data_transfer_service.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 设置页通用组件与对话框（自 settings_screen.dart 拆出）。
///
/// 全部为无状态顶层函数：状态经参数传入，颜色走 [AppThemeData]。

void showPrivacyPolicyDialog(BuildContext context, AppThemeData theme) {
  final l10n = context.l10n;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.surfaceColor.withValues(alpha: 0.98),
      title: Text(
        l10n.settingsPrivacyPolicy,
        style: TextStyle(color: theme.textColor),
      ),
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
                style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
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

Future<String?> showImportDialog(
  BuildContext context,
  AppThemeData theme,
  List<BackupFileInfo> localBackups,
) async {
  final l10n = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.surfaceColor.withValues(alpha: 0.95),
      title: Text(
        l10n.settingsImportData,
        style: TextStyle(color: theme.textColor),
      ),
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
                style: context.bodyMedium.copyWith(
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
                      context,
                      backup.fileName,
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: context.bodyMedium,
                  ),
                  subtitle: Text(
                    '${backup.sizeText} · ${_formatDate(backup.modifiedTime, Localizations.localeOf(context).languageCode)}',
                    style: context.bodySmall,
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
              title: Text(
                l10n.settingsSelectManually,
                style: TextStyle(color: theme.textColor),
              ),
              subtitle: Text(
                l10n.settingsSelectManuallySubtitle,
                style: context.bodySmall,
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

Widget buildSettingsSectionHeader(
  BuildContext context,
  String title,
  AppThemeData theme,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: context.bodyMedium.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.secondaryTextColor,
        letterSpacing: 1,
      ),
    ),
  );
}

Widget buildSettingsCard({
  required AppThemeData theme,
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  // Use Material (not Container+BoxDecoration) so descendant ListTile/
  // RadioListTile/InkWell widgets paint their ink splash on a proper
  // Material canvas. A plain Container with a background color sits
  // between the ListTile and its Material ancestor, hiding the ripple
  // and tripping Flutter's "ListTile background color or ink splashes
  // may be invisible" assertion in tests.
  return Material(
    color: theme.surfaceColorRaised,
    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
    shadowColor: theme.shadowColor,
    elevation: 2,
    child: Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: child,
    ),
  );
}

/// Builds the OEM-specific battery settings section (Chinese OEMs only).
///
/// Shows manufacturer-specific step-by-step instructions and a button to
/// open the OEM settings page. Returns an empty list when [manufacturer]
/// is null (defensive guard — the build method already checks non-null).

Widget buildSettingsSwitch(
  String title,
  bool value,
  ValueChanged<bool> onChanged,
  AppThemeData theme, {
  String? subtitle,
}) {
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
    subtitle: subtitle != null
        ? Text(subtitle, style: TextStyle(color: theme.secondaryTextColor))
        : null,
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

/// 格式化备份文件名为本地化的可读日期（顶部导入对话框用）。
String _formatBackupName(BuildContext context, String fileName, String locale) {
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
      return '${context.l10n.settingsBackupPrefix} ${df.format(date)}';
    }
  } catch (_) {}
  return fileName;
}

/// 格式化日期
String _formatDate(DateTime dt, String locale) {
  final df = DateFormat.MMMd(locale).add_Hm();
  return df.format(dt);
}
