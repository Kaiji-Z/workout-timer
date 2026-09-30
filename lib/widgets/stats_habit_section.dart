import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../theme/build_context_text_styles.dart';

/// 习惯区 — 问题驱动统计页第四区。
///
/// 回答"坚持了没"。习惯是生活问题，这里用日历语义（全年热力图、
/// 连续达标周、本周 x/y）——与前三区（身体问题，滚动窗口）刻意区分。
class StatsHabitSection extends StatefulWidget {
  /// 全部历史每日容量（date-only → kg），热力图强度着色用
  final Map<DateTime, double> dailyVolume;

  /// 连续达标周数（weeklyRolling… 之外的日历语义指标）
  final int streakWeeks;

  /// 本周（周一起）训练次数
  final int sessionsThisWeek;

  /// 每周目标次数（达标的分母）
  final int weeklyTarget;

  /// 基准日（热力图未来格不画；组件内不取当前时间）
  final DateTime today;

  final AppThemeData theme;

  const StatsHabitSection({
    super.key,
    required this.dailyVolume,
    required this.streakWeeks,
    required this.sessionsThisWeek,
    required this.weeklyTarget,
    required this.today,
    required this.theme,
  });

  @override
  State<StatsHabitSection> createState() => _StatsHabitSectionState();
}

class _StatsHabitSectionState extends State<StatsHabitSection> {
  late int _year = widget.today.year;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = widget.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.surfaceColorRaised,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: AppElevation.raised(theme.shadowColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 16,
                color: theme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.statsHabitTitle,
                style: context.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryTextColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _streakCard(context, l10n),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weekCard(context, l10n),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.statsHabitHeatmapTitle,
            style: context.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildYearSelector(context, l10n),
          const SizedBox(height: 10),
          _buildHeatmap(context),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext context, AppLocalizations l10n) {
    final theme = widget.theme;
    final streak = widget.streakWeeks;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        // The 15% Tint Rule
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            color: streak > 0 ? theme.successColor : theme.secondaryTextColor,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            streak > 0
                ? l10n.statsHabitStreak(streak)
                : l10n.statsHabitNoStreak,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _weekCard(BuildContext context, AppLocalizations l10n) {
    final theme = widget.theme;
    final reached = widget.sessionsThisWeek >= widget.weeklyTarget;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            color: reached ? theme.successColor : theme.accentColor,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.statsHabitThisWeek(
              widget.sessionsThisWeek,
              widget.weeklyTarget,
            ),
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(BuildContext context, AppLocalizations l10n) {
    final theme = widget.theme;
    final canGoNext = _year < widget.today.year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.statsPrevYear,
          onPressed: () => setState(() => _year--),
          icon: Icon(Icons.chevron_left, color: theme.textColor),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          l10n.statsYearLabel(_year),
          style: context.titleLarge.copyWith(color: theme.textColor),
        ),
        IconButton(
          tooltip: l10n.statsNextYear,
          onPressed: canGoNext ? () => setState(() => _year++) : null,
          icon: Icon(
            Icons.chevron_right,
            color: canGoNext
                ? theme.textColor
                : theme.secondaryTextColor.withValues(alpha: 0.3),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final theme = widget.theme;
    final yearData = <DateTime, double>{}; // 仅选中年份，减少绘制遍历
    widget.dailyVolume.forEach((date, volume) {
      if (date.year == _year) yearData[date] = volume;
    });
    final maxVolume = yearData.values.fold<double>(
      0,
      (max, v) => v > max ? v : max,
    );

    final jan1 = DateTime(_year, 1, 1);
    final leadingBlanks = jan1.weekday - 1; // 周一为首列
    final daysInYear = _year % 4 == 0 && (_year % 100 != 0 || _year % 400 == 0)
        ? 366
        : 365;
    final columns = ((leadingBlanks + daysInYear) / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - (columns - 1) * 2) / columns;
        final height = 7 * cell + 6 * 2;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _YearHeatmapPainter(
              year: _year,
              yearData: yearData,
              maxVolume: maxVolume,
              columns: columns,
              leadingBlanks: leadingBlanks,
              cell: cell,
              today: widget.today,
              theme: theme,
            ),
          ),
        );
      },
    );
  }
}

/// 全年训练热力图（GitHub 式）：列=周（周一起），行=星期。
///
/// 强度用 Okabe-Ito blue 的透明度阶梯编码（数据色，色盲安全），
/// 未来日期不画。纯绘制，无交互（克制原则）。
class _YearHeatmapPainter extends CustomPainter {
  final int year;
  final Map<DateTime, double> yearData;
  final double maxVolume;
  final int columns;
  final int leadingBlanks;
  final double cell;
  final DateTime today;
  final AppThemeData theme;

  _YearHeatmapPainter({
    required this.year,
    required this.yearData,
    required this.maxVolume,
    required this.columns,
    required this.leadingBlanks,
    required this.cell,
    required this.today,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final emptyPaint = Paint()
      ..color = theme.textColor.withValues(alpha: 0.06);
    final todayDate = DateTime(today.year, today.month, today.day);
    const gap = 2.0;
    const heatBlue = Color(0xFF0072B2); // Okabe-Ito blue

    for (var dayOfYear = 0; dayOfYear < 366; dayOfYear++) {
      final date = DateTime(year, 1, 1).add(Duration(days: dayOfYear));
      if (date.year != year) break;
      if (date.isAfter(todayDate)) continue;

      final slot = leadingBlanks + dayOfYear;
      final col = slot ~/ 7;
      final row = slot % 7;

      // 有键 = 当天练过（含旧版无容量会话），最低热度也点亮
      final volume = yearData[DateTime(date.year, date.month, date.day)];
      final trained = volume != null;
      final intensity = trained && maxVolume > 0
          ? (volume / maxVolume).clamp(0.0, 1.0)
          : 0.0;

      final paint = trained
          ? (Paint()
              ..color = heatBlue.withValues(alpha: 0.2 + intensity * 0.55))
          : emptyPaint;

      final rect = Rect.fromLTWH(
        col * (cell + gap),
        row * (cell + gap),
        cell,
        cell,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_YearHeatmapPainter oldDelegate) =>
      oldDelegate.year != year ||
      oldDelegate.yearData != yearData ||
      oldDelegate.maxVolume != maxVolume ||
      oldDelegate.today != today;
}
