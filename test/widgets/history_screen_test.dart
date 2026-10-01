import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/providers/record_provider.dart';
import 'package:workout_timer/screens/history_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/services/error_reporter_service.dart';
import 'package:workout_timer/theme/theme_provider.dart';

import '../helpers/fake_record_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // No-isolate factory：屏幕的仓库调用在 fake-async 区内完成
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    ServiceLocator.setup();
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.resetForTesting();
  });

  final bench = Exercise(
    id: 'bench',
    name: '杠铃卧推',
    nameEn: 'Barbell Bench Press',
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: [],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: const ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 60,
    ),
  );

  WorkoutRecord recordOf(String id, DateTime date, double weight) =>
      WorkoutRecord(
        id: id,
        date: date,
        durationSeconds: 1800,
        trainedMuscles: const [],
        exercises: [
          RecordedExercise(
            exerciseId: bench.id,
            exercise: bench,
            completedSets: 1,
            setsData: [SetData(setNumber: 1, reps: 5, weight: weight)],
          ),
        ],
        totalSets: 1,
        createdAt: date,
      );

  Widget app(RecordProvider provider) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ThemeProvider()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HistoryScreen(),
        ),
      );

  Future<void> pumpHistory(
    WidgetTester tester,
    FakeRecordRepository repo,
  ) async {
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );
    // runAsync：动作库 asset 加载需要真实事件循环
    await tester.runAsync(() => provider.loadRecords());
    await tester.runAsync(() => DatabaseHelper.instance.database);
    await tester.pumpWidget(app(provider));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('groups records by month with year chips', (tester) async {
    final repo = FakeRecordRepository()
      ..dbRecords.addAll([
        recordOf('a', DateTime(2026, 9, 15), 80),
        recordOf('b', DateTime(2026, 8, 20), 60),
        recordOf('c', DateTime(2025, 12, 1), 50),
      ]);
    await pumpHistory(tester, repo);

    // 月份分组头（en: {month}/{year}）
    expect(find.text('9/2026'), findsOneWidget);
    expect(find.text('8/2026'), findsOneWidget);
    expect(find.text('12/2025'), findsOneWidget);
    // 年份 chips（跨两年才渲染）
    expect(find.text('All'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
  });

  testWidgets('year chip filters the grouped list', (tester) async {
    final repo = FakeRecordRepository()
      ..dbRecords.addAll([
        recordOf('a', DateTime(2026, 9, 15), 80),
        recordOf('c', DateTime(2025, 12, 1), 50),
      ]);
    await pumpHistory(tester, repo);

    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('12/2025'), findsOneWidget);
    expect(find.text('9/2026'), findsNothing);
  });

  testWidgets('exercise search lists best set per session', (tester) async {
    final repo = FakeRecordRepository()
      ..dbRecords.addAll([
        recordOf('a', DateTime(2026, 9, 15), 80),
        recordOf('c', DateTime(2025, 12, 1), 50),
      ]);
    await pumpHistory(tester, repo);

    // 进入搜索模式（AppBar 搜索按钮）并输入动作名
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bench');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // 两次训练各一行，动作名 + 当次最佳组
    expect(find.text('杠铃卧推'), findsNWidgets(2));
    expect(find.textContaining('Best 80.0kg × 5'), findsOneWidget);
    expect(find.textContaining('Best 50.0kg × 5'), findsOneWidget);
    // 搜索模式下分组头不显示
    expect(find.text('9/2026'), findsNothing);
  });

  testWidgets('swipe delete offers undo that restores the record', (
    tester,
  ) async {
    final repo = FakeRecordRepository()
      ..dbRecords.add(recordOf('a', DateTime(2026, 9, 15), 80));
    await pumpHistory(tester, repo);
    expect(find.text('9/2026'), findsOneWidget);

    // 滑动删除（endToStart）
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(repo.dbRecords, isEmpty);
    expect(find.text('9/2026'), findsNothing);
    // SnackBar 提供撤销入口
    expect(find.text('Deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // 撤销 → 记录完整恢复
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(repo.dbRecords, hasLength(1));
    expect(find.text('9/2026'), findsOneWidget);
  });

  testWidgets('clearing the query returns to grouped list', (tester) async {
    final repo = FakeRecordRepository()
      ..dbRecords.addAll([recordOf('a', DateTime(2026, 9, 15), 80)]);
    await pumpHistory(tester, repo);

    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bench');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('杠铃卧推'), findsOneWidget);

    // 清空搜索词
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('9/2026'), findsOneWidget);
    expect(find.text('杠铃卧推'), findsNothing);
  });
}
