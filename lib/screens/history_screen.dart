import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../main.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../services/data_transfer_service.dart';
import '../services/exercise_history_service.dart';
import '../services/training_history_export_service.dart';
import '../services/user_preferences_service.dart';
import '../services/workout_repository.dart';
import '../providers/record_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../animations/list_animations.dart';
import '../animations/page_transitions.dart';
import '../animations/animation_primitives.dart';
import '../widgets/training_history_export_sheet.dart';
import 'record_detail_screen.dart';
import '../theme/build_context_text_styles.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _repository = WorkoutRepository();

  // 动作史检索模式（"上次这个动作练了多少"）
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 年份筛选（null = 全部）；月份分组始终生效
  int? _yearFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 记录的展示日期（旧会话用 createdAt，新记录用 date）
  DateTime _recordDate(dynamic record) {
    if (record is WorkoutSession) return DateTime.parse(record.createdAt);
    if (record is WorkoutRecord) return record.date;
    return DateTime.now();
  }

  Future<List<dynamic>> _loadAllRecords() async {
    // 加载旧记录
    final oldSessions = await _repository.getAllSessions();

    if (!mounted) return [];

    // 获取新记录（从Provider中直接获取，需要先加载）
    final recordProvider = context.read<RecordProvider>();
    await recordProvider.loadRecords();
    final newRecords = recordProvider.records;

    // 按日期排序
    final allRecords = <dynamic>[...oldSessions, ...newRecords];
    allRecords.sort((a, b) {
      final dateA = a is WorkoutSession ? DateTime.parse(a.createdAt) : a.date;
      final dateB = b is WorkoutSession ? DateTime.parse(b.createdAt) : b.date;
      return dateB.compareTo(dateA);
    });

    return allRecords;
  }

  Future<void> _deleteSession(String id) async {
    try {
      await _repository.deleteSession(id);
      setState(() {});
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  /// 滑动删除详细记录：删除后给 SnackBar 撤销入口（可完整恢复）。
  Future<void> _deleteRecordWithUndo(WorkoutRecord record) async {
    final l10n = context.l10n;
    try {
      await context.read<RecordProvider>().deleteRecord(record.id);
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.historyDeletedSnack),
          action: SnackBarAction(
            label: l10n.historyUndo,
            onPressed: () async {
              try {
                await context.read<RecordProvider>().saveRecord(record);
                if (mounted) setState(() {});
              } catch (e) {
                debugPrint('Error restoring record: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  /// 旧版会话无法整体恢复（saveSession 会生成新 id），改为确认后删除。
  Future<void> _deleteSessionConfirmed(WorkoutSession session) async {
    final l10n = context.l10n;
    final theme = context.read<ThemeProvider>().currentTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteConfirmTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.widgetCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.recDetailDeleteAction,
              style: TextStyle(color: theme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteSession(session.id);
    }
  }

  /// Open the training-history export sheet, then on range selection build
  /// the Markdown archive, write it to Downloads, and open the share sheet.
  Future<void> _exportTrainingHistory() async {
    // Load records once — same source the list view uses.
    final List<dynamic> allRecords;
    try {
      allRecords = await _loadAllRecords();
    } catch (e) {
      debugPrint('Error loading records for export: $e');
      return;
    }

    if (!mounted) return;

    await showTrainingHistoryExportSheet(
      context,
      totalRecords: allRecords.length,
      onExport: (from, to) => _performExport(from, to, allRecords),
      onCustomRequested: () => _pickCustomRangeAndExport(allRecords),
    );
  }

  Future<void> _pickCustomRangeAndExport(List<dynamic> allRecords) async {
    final l10n = context.l10n;
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 20, 1, 1),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 90)),
        end: now,
      ),
      helpText: l10n.exportHistoryCustomRangeTitle,
    );

    if (picked == null) return;
    await _performExport(picked.start, picked.end, allRecords);
  }

  Future<void> _performExport(
    DateTime from,
    DateTime to,
    List<dynamic> allRecords,
  ) async {
    final l10n = context.l10n;
    final theme = context.read<ThemeProvider>().currentTheme;

    // Show progress indicator (export may take a moment for large histories).
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: theme.accentColor)),
    );

    try {
      final profile = await UserPreferencesService().loadPreferences();
      final result = TrainingHistoryExportService().export(
        from: from,
        to: to,
        records: allRecords,
        profile: profile,
      );

      // Write to Downloads on Android, otherwise fall back to temp dir.
      final dataTransfer = DataTransferService();
      String savedPath;
      if (!kIsWeb) {
        try {
          savedPath = await dataTransfer.saveToDownloads(
            result.markdown,
            result.fileName,
          );
        } catch (_) {
          // saveToDownloads always returns a path (Downloads or temp fallback).
          savedPath = await dataTransfer.saveToDownloads(
            result.markdown,
            result.fileName,
          );
        }
      } else {
        // Web: no file system — copy to clipboard as a fallback.
        savedPath = result.fileName;
      }

      // Pop progress dialog.
      if (mounted) Navigator.of(context).pop();

      // Open share sheet (native only).
      if (!kIsWeb) {
        await Share.shareXFiles([
          XFile(savedPath),
        ], text: l10n.exportHistorySheetTitle);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportHistorySuccess)));
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (mounted) Navigator.of(context).pop(); // pop progress dialog
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(l10n.exportHistoryFailedGeneric)),
        );
      }
    }
  }

  String _formatDate(dynamic record) {
    DateTime date;
    if (record is WorkoutSession) {
      date = DateTime.parse(record.createdAt);
    } else if (record is WorkoutRecord) {
      date = record.date;
    } else {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.historyTitle,
          style: context.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.historySearchTooltip,
            onPressed: () => setState(() => _searchMode = !_searchMode),
            icon: Icon(
              _searchMode ? Icons.search_off : Icons.search,
              size: 22,
              color: theme.accentColor,
            ),
          ),
          TextButton.icon(
            onPressed: () => _exportTrainingHistory(),
            icon: Icon(Icons.ios_share, size: 18, color: theme.accentColor),
            label: Text(
              l10n.historyExportAction,
              style: context.labelLarge.copyWith(color: theme.accentColor),
            ),
          ),
        ],
        // 动作史搜索框（仅搜索模式显示）
        bottom: _searchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: context.bodyMedium.copyWith(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: l10n.historySearchHint,
                      hintStyle: context.bodyMedium.copyWith(
                        color: theme.secondaryTextColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: theme.secondaryTextColor,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: theme.secondaryTextColor,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      filled: true,
                      fillColor: theme.textColor.withValues(alpha: 0.05),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXl,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.historyLoadFailed,
                style: context.bodyMedium.copyWith(
                  color: theme.accentColor,
                  letterSpacing: 2,
                ),
              ),
            );
          } else if (snapshot.data?.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: theme.secondaryTextColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.historyEmpty,
                    style: context.titleLarge.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.historyEmptyHint,
                    style: context.bodyMedium.copyWith(
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to timer tab (index 2)
                      MainNavigation.switchToTab(2);
                    },
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: theme.accentColor,
                    ),
                    label: Text(
                      l10n.trainingStartExercise,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.accentColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusChip,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final records = snapshot.data ?? <dynamic>[];
            return _buildRecordList(l10n, theme, records);
          }
        },
      ),
    );
  }

  /// 记录列表：搜索模式 → 动作史检索结果；否则 → 年份筛选 + 月份分组。
  Widget _buildRecordList(
    AppLocalizations l10n,
    AppThemeData theme,
    List<dynamic> records,
  ) {
    if (_searchMode && _searchQuery.trim().isNotEmpty) {
      final entries = searchExerciseHistory(
        records.whereType<WorkoutRecord>().toList(),
        _searchQuery,
      );
      if (entries.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.historySearchNoResults,
              style: context.bodyMedium.copyWith(
                color: theme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 86,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) => ListAnimation(
          index: index,
          child: _SearchResultRow(
            entry: entries[index],
            theme: theme,
            onTap: () => _navigateToDetail(entries[index].record),
          ),
        ),
      );
    }

    final filtered = _yearFilter == null
        ? records
        : records
              .where((r) => _recordDate(r).year == _yearFilter)
              .toList();

    return Column(
      children: [
        _buildYearChips(l10n, theme, records),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.historyEmpty,
                    style: context.bodyMedium.copyWith(
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
              : _buildGroupedList(l10n, theme, filtered),
        ),
      ],
    );
  }

  /// 年份 chips（只有一年时不渲染，避免空转占位）
  Widget _buildYearChips(
    AppLocalizations l10n,
    AppThemeData theme,
    List<dynamic> records,
  ) {
    final years = records.map(_recordDate).map((d) => d.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (years.length < 2) return const SizedBox.shrink();

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          // 触控目标 ≥48dp
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The 15% Tint Rule — 选中态实底 accent
            color: selected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
          ),
          child: Text(
            label,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? theme.onAccentColor : theme.accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(l10n.historyYearAll, _yearFilter == null, () {
            setState(() => _yearFilter = null);
          }),
          const SizedBox(width: 8),
          for (final year in years) ...[
            chip('$year', _yearFilter == year, () {
              setState(() => _yearFilter = year);
            }),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// 月份分组列表（档案按日历组织——历史是"生活问题"，
  /// 与统计页的分析轴刻意区分，见 .goal/SPEC.md 组织原则）
  Widget _buildGroupedList(
    AppLocalizations l10n,
    AppThemeData theme,
    List<dynamic> filtered,
  ) {
    final groups = <_MonthGroup>[];
    for (final record in filtered) {
      final date = _recordDate(record);
      final last = groups.isEmpty ? null : groups.last;
      if (last != null && last.year == date.year && last.month == date.month) {
        last.records.add(record);
      } else {
        groups.add(_MonthGroup(date.year, date.month)..records.add(record));
      }
    }

    final rows = <Widget>[];
    var animIndex = 0;
    for (final group in groups) {
      rows.add(
        _MonthHeader(
          label: l10n.historyMonthHeader(group.year, group.month),
          countLabel: l10n.historyMonthCount(group.records.length),
          theme: theme,
        ),
      );
      for (final record in group.records) {
        rows.add(
          ListAnimation(
            index: animIndex++,
            child: record is WorkoutRecord
                ? _RecordCard(
                    record: record,
                    formatDate: _formatDate,
                    onDelete: () => _deleteRecordWithUndo(record),
                    onTap: () => _navigateToDetail(record),
                    theme: theme,
                  )
                : _SessionCard(
                    session: record as WorkoutSession,
                    formatDate: _formatDate,
                    onDelete: () => _deleteSessionConfirmed(record),
                    theme: theme,
                  ),
          ),
        );
      }
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 86,
      ),
      children: rows,
    );
  }

  void _navigateToDetail(WorkoutRecord record) async {
    await Navigator.push(
      context,
      FadeUpPageRoute(page: RecordDetailScreen(record: record)),
    );
    // 返回后刷新列表以反映编辑后的数据
    if (mounted) {
      setState(() {});
    }
  }
}

/// 月份分组（可变列表在分组构建期聚合）
class _MonthGroup {
  final int year;
  final int month;
  final List<dynamic> records = [];

  _MonthGroup(this.year, this.month);
}

/// 月份分组头："{year}年{month}月 · N 次训练"
class _MonthHeader extends StatelessWidget {
  final String label;
  final String countLabel;
  final AppThemeData theme;

  const _MonthHeader({
    required this.label,
    required this.countLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: context.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.secondaryTextColor,
              letterSpacing: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            countLabel,
            style: context.bodySmall.copyWith(
              color: theme.secondaryTextColor.withValues(alpha: 0.7),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 动作史检索结果行：动作名 + 当次最佳组(按估算1RM) + 日期。
///
/// 回答"上次这个动作我练了多少"——点击进入当次训练详情。
class _SearchResultRow extends StatelessWidget {
  final ExerciseHistoryEntry entry;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _SearchResultRow({
    required this.entry,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weight = entry.bestWeight;
    final reps = entry.bestReps ?? 0;
    final e1RM = entry.bestE1RM;
    final bestLine = weight != null && e1RM != null
        ? '${l10n.historySearchBestSet(weight.toStringAsFixed(1), reps)}  ·  '
            '${l10n.historySearch1rm(e1RM.toStringAsFixed(1))}'
        : l10n.historySearchNoSetData;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surfaceColorRaised,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: AppElevation.raised(theme.shadowColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exerciseName,
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bestLine,
                    style: context.bodySmall.copyWith(
                      color: theme.accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy-MM-dd').format(entry.record.date),
              style: context.bodySmall.copyWith(
                color: theme.secondaryTextColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 新记录卡片 - 支持计划模式记录
class _RecordCard extends StatelessWidget {
  final WorkoutRecord record;
  final String Function(dynamic) formatDate;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _RecordCard({
    required this.record,
    required this.formatDate,
    required this.onDelete,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // 破坏性动作用 error 语义色，不用品牌靛蓝
          color: theme.errorColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: theme.onAccentColor),
      ),
      onDismissed: (direction) => onDelete(),
      child: AnimatedCard(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          decoration: BoxDecoration(
            color: theme.surfaceColorRaised,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: AppElevation.raised(theme.shadowColor),
          ),
          child: Row(
            children: [
              // 图标 — 深靛蓝实心,与暖背景形成对决
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Center(
                  child: record.isPlanMode
                      ? Icon(
                          Icons.playlist_add_check,
                          color: theme.onAccentColor,
                          size: 24,
                        )
                      : Text(
                          '${record.totalSets}',
                          style: context.headlineMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.onAccentColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 计划名称或"自由训练"
                    Row(
                      children: [
                        if (record.isPlanMode) ...[
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Text(
                                record.planName ?? l10n.historyPlanMode,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: context.bodySmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.accentColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(record.dateText(l10n), style: context.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 训练部位
                    if (record.trainedMuscles.isNotEmpty)
                      Text(
                        localizedMuscleList(context, record.trainedMuscles),
                        style: context.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        l10n.historyFreeWorkout,
                        style: context.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // 统计信息
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.durationText(context.l10n),
                          style: context.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.historySetsSuffix(record.totalSets),
                          style: context.bodySmall,
                        ),
                        if (record.exerciseCount > 0) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.historyExercisesSuffix(record.exerciseCount),
                            style: context.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 箭头
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 旧记录卡片 - 保持兼容性
class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final String Function(dynamic) formatDate;
  final VoidCallback onDelete;
  final AppThemeData theme;

  const _SessionCard({
    required this.session,
    required this.formatDate,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // 破坏性动作用 error 语义色，不用品牌靛蓝
          color: theme.errorColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: theme.onAccentColor),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: BoxDecoration(
          color: theme.surfaceColorRaised,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          boxShadow: AppElevation.raised(theme.shadowColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Center(
                child: Text(
                  '${session.totalSets}',
                  style: context.headlineMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.onAccentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.historyCompletedSets,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(formatDate(session), style: context.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
