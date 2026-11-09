import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/services/stats_calculator_service.dart';
import 'package:workout_timer/theme/app_theme.dart';
import 'package:workout_timer/widgets/stats_charts.dart';
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

    testWidgets('heatmap scrolls horizontally and anchors to today', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          StatsHabitSection(
            dailyVolume: {},
            streakWeeks: 0,
            sessionsThisWeek: 0,
            weeklyTarget: 3,
            // 用真实"今天"，与组件的当前年份判定保持一致
            today: DateTime.now(),
            theme: amberGoldTheme,
          ),
        ),
      );
      await tester.pump(); // post-frame 锚定跳转

      final scrollableFinder = find.descendant(
        of: find.byType(StatsHabitSection),
        matching: find.byType(Scrollable),
      );
      expect(scrollableFinder, findsOneWidget);
      final position = tester.state<ScrollableState>(scrollableFinder).position;
      // 全年 53 列固定大格远宽于视口 → 可横向滑动
      expect(position.maxScrollExtent, greaterThan(0));
      // 当前年份初始锚定到最右（今天附近），而非年初
      expect(position.pixels, greaterThan(0));

      // 向右拖 → 回到年初
      await tester.drag(scrollableFinder, const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, 0);

      // 切到过去年份停在年初；切回当前年份重新锚定到今天
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      expect(position.pixels, 0);
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(position.pixels, greaterThan(0));
    });
  });

  group('DensityMetricCard', () {
    WorkoutRecord rec(String id, DateTime date, int sets, int seconds) =>
        WorkoutRecord(
          id: id,
          date: date,
          durationSeconds: seconds,
          trainedMuscles: const [],
          exercises: const [],
          totalSets: sets,
          createdAt: date,
        );

    final asOf = DateTime(2026, 9, 30);
    // 密度刻意两两可分辨：7 天窗只有 a，30 天窗 a+b，全部 a+b+c
    final records = [
      rec('a', DateTime(2026, 9, 24), 10, 600),
      rec('b', DateTime(2026, 9, 10), 30, 600),
      rec('c', DateTime(2026, 7, 31), 60, 600),
    ];

    testWidgets('defaults to 30-day window and switches 7d/all', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityMetricCard(
            records: records,
            asOf: asOf,
            theme: amberGoldTheme,
          ),
        ),
      );

      // 默认近30天：a+b = 40 组 / 20 分钟 = 2.0
      expect(find.text('2.0 sets/min'), findsOneWidget);
      expect(find.text('40 sets / 20 min'), findsOneWidget);

      await tester.tap(find.text('7 days'));
      await tester.pump();
      // 近7天：只剩 a = 10 组 / 10 分钟 = 1.0
      expect(find.text('1.0 sets/min'), findsOneWidget);
      expect(find.text('10 sets / 10 min'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pump();
      // 全部：a+b+c = 100 组 / 30 分钟 = 3.3
      expect(find.text('3.3 sets/min'), findsOneWidget);
      expect(find.text('100 sets / 30 min'), findsOneWidget);
    });

    testWidgets('hidden when there are no records at all', (tester) async {
      await tester.pumpWidget(
        wrap(
          DensityMetricCard(
            records: const [],
            asOf: asOf,
            theme: amberGoldTheme,
          ),
        ),
      );
      expect(find.text('Density'), findsNothing);
    });

    testWidgets('uses the same section chrome as sibling sections', (
      tester,
    ) async {
      // 与 StatsDoseSection 同树渲染，直接对比根 Container 装饰：
      // 密度卡必须与其他统计区共用区块制服（raised 面 + radiusXl +
      // raised 阴影 + 无描边），区头遵循 16px 图标 + 13px 标题惯例。
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              StatsDoseSection(
                setsPerMuscle: const {PrimaryMuscleGroup.chest: 10},
                doseStatus: statusOf(const {}),
                volume7d: 500,
                theme: amberGoldTheme,
              ),
              DensityMetricCard(
                records: records,
                asOf: asOf,
                theme: amberGoldTheme,
              ),
            ],
          ),
        ),
      );

      BoxDecoration chromeOf(Type type) {
        final container = tester.widget<Container>(
          find
              .descendant(of: find.byType(type), matching: find.byType(Container))
              .first,
        );
        return container.decoration! as BoxDecoration;
      }

      final dose = chromeOf(StatsDoseSection);
      final density = chromeOf(DensityMetricCard);
      expect(density.color, dose.color, reason: '同用 surfaceColorRaised');
      expect(density.borderRadius, dose.borderRadius, reason: '同用 radiusXl');
      expect(density.border, dose.border, reason: '区块外壳不带描边');
      expect(
        density.boxShadow?.length,
        dose.boxShadow?.length,
        reason: '同用 AppElevation.raised 阴影',
      );

      // 区头惯例：16px accent 图标（不与剂量区的 speed 撞车）+ 13px 标题
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(DensityMetricCard),
          matching: find.byIcon(Icons.bolt),
        ),
      );
      expect(icon.size, 16);
      expect(icon.color, amberGoldTheme.accentColor);
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(DensityMetricCard),
          matching: find.text('Density'),
        ),
      );
      expect(title.style?.fontSize, 13);
    });

    testWidgets('range chips expose button and selected semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DensityMetricCard(
            records: records,
            asOf: asOf,
            theme: amberGoldTheme,
          ),
        ),
      );

      Semantics? chipSemantics(String label) {
        final f = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.button == true,
          ),
        );
        return f.evaluate().isEmpty ? null : tester.firstWidget<Semantics>(f);
      }

      // 默认近30天：button 角色 + selected 态可被读屏播报
      expect(chipSemantics('30 days')!.properties.selected, isTrue);
      expect(chipSemantics('7 days')!.properties.selected, isNot(isTrue));
      expect(chipSemantics('All')!.properties.selected, isNot(isTrue));

      await tester.tap(find.text('7 days'));
      await tester.pump();
      expect(chipSemantics('7 days')!.properties.selected, isTrue);
      expect(chipSemantics('30 days')!.properties.selected, isNot(isTrue));
    });

    testWidgets('header carries a tap tooltip explaining the metric', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          DensityMetricCard(
            records: records,
            asOf: asOf,
            theme: amberGoldTheme,
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(DensityMetricCard),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.triggerMode, TooltipTriggerMode.tap);
      expect(
        tooltip.message,
        'Average sets/min per workout in the selected range',
      );
    });
  });
}
