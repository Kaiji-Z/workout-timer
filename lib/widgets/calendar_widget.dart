import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../bloc/plan_provider.dart';

import '../theme/app_theme.dart';

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
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 上个月
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
          icon: Icon(
            Icons.chevron_left,
            color: theme.textColor,
          ),
        ),
        
        // 当前月份
        Text(
          '$year年 ${monthNames[month - 1]}',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        
        // 下个月
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
          },
          icon: Icon(
            Icons.chevron_right,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(AppThemeData theme) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateGrid(Set<DateTime> markedDates, AppThemeData theme) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
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
  final bool isSelected;
  final bool isToday;
  final bool hasPlan;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _DateCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasPlan,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 选中或今天的背景
          if (isSelected || isToday)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          
          // 日期数字
          Text(
            '$day',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 12,
              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
              color: isSelected 
                  ? Colors.white 
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
                  color: isSelected ? Colors.white : theme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 紧凑型日历 - 用于顶部显示
class CompactCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime>? markedDates;

  const CompactCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.markedDates,
  });

  @override
  State<CompactCalendar> createState() => _CompactCalendarState();
}

class _CompactCalendarState extends State<CompactCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    final markedDates = widget.markedDates ?? planProvider.datesWithPlans;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 月份导航
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
                icon: Icon(Icons.chevron_left, color: theme.textColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_currentMonth.year}年${_currentMonth.month}月',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
                icon: Icon(Icons.chevron_right, color: theme.textColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // 日期行（一周）
        _buildWeekRow(markedDates, theme),
      ],
    );
  }

  Widget _buildWeekRow(Set<DateTime> markedDates, AppThemeData theme) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // 获取当前周的所有日期
    final startOfWeek = todayNormalized.subtract(Duration(days: todayNormalized.weekday % 7));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isSelected = _isSameDay(date, widget.selectedDate);
        final isToday = _isSameDay(date, todayNormalized);
        final hasPlan = markedDates.any((d) => _isSameDay(d, date));
        
        return GestureDetector(
          onTap: () => widget.onDateSelected(date),
          child: Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7],
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 11,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected || isToday)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? theme.accentColor
                                : theme.textColor,
                      ),
                    ),
                    if (hasPlan)
                      Positioned(
                        bottom: -2,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : theme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 周日期选择器 - 水平滚动
class WeekDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime>? markedDates;

  const WeekDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.markedDates,
  });

  @override
  State<WeekDatePicker> createState() => _WeekDatePickerState();
}

class _WeekDatePickerState extends State<WeekDatePicker> {
  late ScrollController _scrollController;
  late List<DateTime> _dates;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();
  }

  void _generateDates() {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // 生成前后各30天的日期
    _dates = List.generate(61, (index) {
      return todayNormalized.add(Duration(days: index - 30));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    final markedDates = widget.markedDates ?? planProvider.datesWithPlans;
    
    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, widget.selectedDate);
          final hasPlan = markedDates.any((d) => _isSameDay(d, date));
          
          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7],
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.accentColor : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? null 
                              : Border.all(color: theme.textColor.withValues(alpha: 0.1)),
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (hasPlan)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : theme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
