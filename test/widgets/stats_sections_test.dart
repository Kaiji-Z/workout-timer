import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/widgets/stats_dose_section.dart';
import 'package:workout_timer/widgets/stats_habit_section.dart';
import 'package:workout_timer/widgets/stats_progress_section.dart';

void main() {
  final today = DateTime(2026, 9, 30); // 周三

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  Map<PrimaryMuscleGroup, DoseStatus> statusOf(
    Map<PrimaryMuscleGroup, DoseStatus> override,
  ) =>
      {
        for (final m in PrimaryMuscleGroup.values) m: override[m] ?? DoseStatus.belowMev,
      };

  group('StatsDoseSection', () {
    testWidgets('renders reference lines, statuses and summary volume', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          StatsDoseSection(
            setsPerMuscle: const {
              PrimaryMuscleGroup.chest: 15,
              PrimaryMuscleGroup.arms: 25,
              PrimaryMuscleGroup.legs: 4,
            },
            doseStatus: statusOf(const {
              PrimaryMuscleGroup.chest: DoseStatus.inRange,
              PrimaryMuscleGroup.arms: DoseStatus.aboveMrv,
            }),
            volume7d: 500,
            theme: amberGoldTheme,
          ),
        ),
      );

      expect(find.text('MEV 10'), findsOneWidget);
      expect(find.text('MRV 20'), findsOneWidget);
      expect(find.text('In range'), findsOneWidget);
      expect(find.text('Above'), findsOneWidget);
      // legs 4 组 + back/shoulders/core 完全没练 → 4 个 Below
      expect(find.text('Below'), findsNWidgets(4));
      expect(find.text('500 kg'), findsOneWidget);
      // 免责声明在场（参考线不是医学标准）
      expect(
        find.text(
          'MEV/MRV are practice-informed reference lines, not medical standards',
        ),
        findsOneWidget,
      );
    });
  });

  group('StatsProgressSection', () {
    Estimated1RMPoint p(DateTime d, double e1, double w, int reps) =>
        Estimated1RMPoint(date: d, estimated1RM: e1, weight: w, reps: reps);

    List<RollingVolumePoint> trend(List<double> volumes) => List.generate(
          volumes.length,
          (i) => RollingVolumePoint(
            windowEnd: today.subtract(Duration(days: 7 * (volumes.length - 1 - i))),
            windowDays: 7,
            volume: volumes[i],
          ),
        );

    testWidgets('renders exercise summary, trend label and latest PR', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          StatsProgressSection(
            e1rmTrends: {
              'Bench Press': [
                p(DateTime(2026, 8, 1), 100, 90, 5),
                p(DateTime(2026, 9, 15), 120, 100, 5),
              ],
              'Squat': [p(DateTime(2026, 9, 20), 140, 120, 3)],
            },
            weeklyTrend: trend([1000, 1200, 1400, 1600, 1800, 2000]),
            today: today,
            theme: amberGoldTheme,
          ),
        ),
      );

      // 默认选中会话数最多的动作
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      // 区间摘要（多点位动作）
      expect(find.text('100.0 → 120.0 kg'), findsOneWidget);
      // 6 周滚动容量递进 → 上升提示
      expect(find.text('Rising — plan a deload'), findsOneWidget);
      // 最近 PR = 全部动作里日期最新的那组
      expect(find.text('Latest PR'), findsOneWidget);
      expect(find.text('Squat: 120.0kg × 3'), findsOneWidget);
      // 范围切换 chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
    });

    testWidgets('shows empty hint when no per-set data exists', (tester) async {
      await tester.pumpWidget(
        wrap(
          StatsProgressSection(
            e1rmTrends: const {},
            weeklyTrend: trend([1000, 1000, 1000, 1000, 1000, 1000]),
            today: today,
            theme: amberGoldTheme,
          ),
        ),
      );
      expect(
        find.text('No exercises with per-set data yet (needs weight × reps per set)'),
        findsOneWidget,
      );
    });
  });

  group('StatsHabitSection', () {
    testWidgets('renders streak, this-week progress and heatmap year', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          StatsHabitSection(
            dailyVolume: {
              DateTime(2026, 1, 15): 1500,
              DateTime(2026, 9, 28): 1000,
              DateTime(2026, 9, 29): 2000,
            },
            streakWeeks: 3,
            sessionsThisWeek: 2,
            weeklyTarget: 4,
            today: today,
            theme: amberGoldTheme,
          ),
        ),
      );

      expect(find.text('3-week streak'), findsOneWidget);
      expect(find.text('This week 2/4'), findsOneWidget);
      expect(find.text('Year in training'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      // 热力图横坐标：月份起始列标签
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Sep'), findsOneWidget);
      // 纵坐标：GitHub 式隔行星期标签（一/三/五行）
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('shows no-streak hint when streak is zero', (tester) async {
      await tester.pumpWidget(
        wrap(
          StatsHabitSection(
            dailyVolume: {},
            streakWeeks: 0,
            sessionsThisWeek: 0,
            weeklyTarget: 3,
            today: today,
            theme: amberGoldTheme,
          ),
        ),
      );
      expect(find.text('No qualifying week yet'), findsOneWidget);
    });
  });
}
