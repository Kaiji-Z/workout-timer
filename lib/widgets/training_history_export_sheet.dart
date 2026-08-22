import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import 'ui_components.dart';

/// Callback fired when the user picks a range and taps the export button.
typedef ExportRangeCallback = Future<void> Function(DateTime from, DateTime to);

/// Preset time ranges for the export sheet.
enum _ExportPreset { weeks4, months3, months6, months12, all, custom }

/// Shows a bottom sheet that lets the user pick a time range for exporting
/// training history.
///
/// [totalRecords] is the count of records currently visible in the history
/// list (used to render the export button label and to disable export when
/// there are zero records).
///
/// [onExport] is called with the chosen `[from, to]` range when the user taps
/// the export button after selecting a preset. The sheet closes itself before
/// invoking the callback.
///
/// [onCustomRequested] is called when the user taps the "Custom" chip. The
/// caller is responsible for opening [showDateRangePicker] and re-invoking
/// [onExport] with the chosen range. The sheet closes itself first so the
/// date range picker is not stacked above it.
Future<void> showTrainingHistoryExportSheet(
  BuildContext context, {
  required int totalRecords,
  required ExportRangeCallback onExport,
  VoidCallback? onCustomRequested,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ExportSheet(
      totalRecords: totalRecords,
      onExport: onExport,
      onCustomRequested: onCustomRequested,
    ),
  );
}

class _ExportSheet extends StatefulWidget {
  final int totalRecords;
  final ExportRangeCallback onExport;
  final VoidCallback? onCustomRequested;

  const _ExportSheet({
    required this.totalRecords,
    required this.onExport,
    required this.onCustomRequested,
  });

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  _ExportPreset? _selected;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);

    final hasRecords = widget.totalRecords > 0;
    final canExport =
        hasRecords &&
        (_selected != null || (_customFrom != null && _customTo != null));

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.screenPadding,
        right: AppDimensions.screenPadding,
        top: 8,
        bottom: mediaQuery.padding.bottom + AppDimensions.screenPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetDragHandle(),
          const SizedBox(height: 12),
          _buildHeader(l10n, theme),
          const SizedBox(height: 16),
          _buildChipGrid(l10n, theme),
          const SizedBox(height: 16),
          _buildRangeSummary(l10n, theme),
          const SizedBox(height: 16),
          _buildExportButton(l10n, theme, canExport, hasRecords),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exportHistorySheetTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.exportHistorySheetDescription,
          style: TextStyle(
            fontSize: 13,
            color: theme.secondaryTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildChipGrid(AppLocalizations l10n, AppThemeData theme) {
    final chips = <(_ExportPreset, String)>[
      (_ExportPreset.weeks4, l10n.exportHistoryRange4w),
      (_ExportPreset.months3, l10n.exportHistoryRange3m),
      (_ExportPreset.months6, l10n.exportHistoryRange6m),
      (_ExportPreset.months12, l10n.exportHistoryRange12m),
      (_ExportPreset.all, l10n.exportHistoryRangeAll),
      (_ExportPreset.custom, l10n.exportHistoryRangeCustom),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((entry) {
        final preset = entry.$1;
        final label = entry.$2;
        final isSelected = _selected == preset;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: theme.accentColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? theme.accentColor : theme.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            side: BorderSide(
              color: isSelected ? theme.accentColor : theme.dividerColor,
            ),
          ),
          onSelected: (_) => _handlePresetTap(preset),
        );
      }).toList(),
    );
  }

  void _handlePresetTap(_ExportPreset preset) {
    if (preset == _ExportPreset.custom) {
      // Custom: clear preset selection, fire hook, let caller pick a range.
      setState(() {
        _selected = null;
        _customFrom = null;
        _customTo = null;
      });
      // Close the sheet first so the date range picker isn't stacked on top.
      Navigator.of(context).maybePop();
      widget.onCustomRequested?.call();
      return;
    }
    setState(() {
      _selected = preset;
      _customFrom = null;
      _customTo = null;
    });
  }

  Widget _buildRangeSummary(AppLocalizations l10n, AppThemeData theme) {
    final range = _currentRange();
    final String summaryText;
    if (range == null) {
      summaryText = '—';
    } else {
      summaryText = l10n.exportHistoryRangeFromTo(
        _dateLabel(range.$1),
        _dateLabel(range.$2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: theme.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summaryText,
              style: TextStyle(
                fontSize: 13,
                color: theme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    AppLocalizations l10n,
    AppThemeData theme,
    bool canExport,
    bool hasRecords,
  ) {
    final label = !hasRecords
        ? l10n.exportHistoryNoRecords
        : l10n.exportHistoryButtonLabel(widget.totalRecords);

    return ElevatedButton(
      key: const ValueKey('export_history_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: canExport
            ? theme.accentColor
            : theme.accentColor.withValues(alpha: 0.4),
        foregroundColor: theme.surfaceColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        elevation: 0,
      ),
      onPressed: canExport ? () => _onExportPressed() : null,
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _onExportPressed() async {
    final range = _currentRange();
    if (range == null) return;

    // Close the sheet before invoking the async export (which may show its
    // own progress indicator and share sheet).
    Navigator.of(context).maybePop();
    await widget.onExport(range.$1, range.$2);
  }

  (DateTime, DateTime)? _currentRange() {
    final customFrom = _customFrom;
    final customTo = _customTo;
    if (customFrom != null && customTo != null) {
      return (customFrom, customTo);
    }
    final selected = _selected;
    if (selected == null) return null;
    return _presetRange(selected);
  }

  (DateTime, DateTime) _presetRange(_ExportPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _ExportPreset.weeks4:
        return (today.subtract(const Duration(days: 28)), today);
      case _ExportPreset.months3:
        return (DateTime(today.year, today.month - 3, today.day), today);
      case _ExportPreset.months6:
        return (DateTime(today.year, today.month - 6, today.day), today);
      case _ExportPreset.months12:
        return (DateTime(today.year - 1, today.month, today.day), today);
      case _ExportPreset.all:
        // Reach back far enough to cover any plausible history.
        return (DateTime(today.year - 20, 1, 1), today);
      case _ExportPreset.custom:
        // Should never be reached: custom path fires onCustomRequested.
        return (today, today);
    }
  }

  String _dateLabel(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
