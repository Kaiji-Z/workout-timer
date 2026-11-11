import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/context_l10n.dart';
import '../theme/theme_provider.dart';
import '../providers/plan_provider.dart';

import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 日历组件 - Flat Vitality 设计
///
/// 显示月历视图，标记有计划的日期
class CalendarWidget extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 日期选择回调
  final ValueChanged<DateTime> onDateSelected;

  /// 有计划的日期列表（用于标记）
  final Set<DateTime>? markedDates;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.markedDates,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();

    // 获取有计划的日期
    final markedDates = widget.markedDates ?? planProvider.datesWithPlans;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.resting(theme.shadowColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份导航
          _buildMonthNavigation(theme),
          const SizedBox(height: 12),

          // 星期标题
          _buildWeekdayHeaders(theme),
          const SizedBox(height: 4),

          // 日期网格
          _buildDateGrid(markedDates, theme),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(AppThemeData theme) {
    final locale = Localizations.localeOf(context).languageCode;
    final monthYearText = DateFormat.yMMM(locale).format(_currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 上个月
        IconButton(
          tooltip: context.l10n.calPrevMonth,
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          icon: Icon(Icons.chevron_left, color: theme.textColor),
        ),

        // 当前月份
        Text(
          monthYearText,
          style: context.headlineMedium.copyWith(color: theme.textColor),
        ),

        // 下个月
        IconButton(
          tooltip: context.l10n.calNextMonth,
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          icon: Icon(Icons.chevron_right, color: theme.textColor),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(AppThemeData theme) {
    final locale = Localizations.localeOf(context).languageCode;
    // 2024-01-07 is a Sunday; build Sun..Sat in locale-aware short form.
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2024, 1, 7 + i)),
    ];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: context.labelLarge.copyWith(
                fontSize: 13,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateGrid(Set<DateTime> markedDates, AppThemeData theme) {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];

    // 空白格子（月份开始前的空白）
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // 日期格子
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _isSameDay(date, widget.selectedDate);
      final isToday = _isSameDay(date, todayNormalized);
      final hasPlan = markedDates.any((d) => _isSameDay(d, date));

      cells.add(
        _DateCell(
          day: day,
          date: date,
          isSelected: isSelected,
          isToday: isToday,
          hasPlan: hasPlan,
          onTap: () => widget.onDateSelected(date),
          theme: theme,
        ),
      );
    }

    // 计算精确的行数，避免 shrinkWrap 产生多余空白行
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells + 6) ~/ 7; // 向上取整

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算单元格大小（正方形）
        const crossAxisSpacing = 2.0;
        const mainAxisSpacing = 4.0;
        final cellWidth = (constraints.maxWidth - (6 * crossAxisSpacing)) / 7;
        final gridHeight = rows * cellWidth + (rows - 1) * mainAxisSpacing;

        return SizedBox(
          height: gridHeight,
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: 1.0,
            children: cells,
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 日期单元格
class _DateCell extends StatelessWidget {
  final int day;
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasPlan;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _DateCell({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasPlan,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat.yMd(locale).format(date);
    final semanticsLabel = l10n.calDaySemantics(
      dateStr,
      hasPlan ? l10n.calDayHasPlan : '',
      isToday ? l10n.calDayToday : '',
      isSelected ? l10n.calDaySelected : '',
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Semantics(
          button: true,
          label: semanticsLabel,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 选中或今天的背景
              if (isSelected || isToday)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),

              // 日期数字
              Text(
                '$day',
                style: context.bodySmall.copyWith(
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? theme.onAccentColor
                      : isToday
                      ? theme.accentColor
                      : theme.textColor,
                ),
              ),

              // 计划标记点
              if (hasPlan)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.onAccentColor
                          : theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

