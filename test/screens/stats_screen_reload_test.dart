import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/providers/record_provider.dart';
import 'package:workout_timer/screens/ai_analysis_screen.dart';
import 'package:workout_timer/screens/stats_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/services/error_reporter_service.dart';
import 'package:workout_timer/theme/theme_provider.dart';

import '../helpers/fake_record_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // No-isolate factory: StatsScreen._loadData runs inside the fake-async
    // zone, where real-isolate futures would never complete.
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    ServiceLocator.setup();
    SharedPreferences.setMockInitialValues({});
    await DatabaseHelper.resetForTesting();

    // The app's collapsible sections (ExpansionTile inside a decorated
    // Container) trip Flutter's ListTile-background advisory. It is a
    // cosmetic debug warning unrelated to reload behavior; keep real errors.
    final originalOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = originalOnError);
    FlutterError.onError = (details) {
      if (details.toString().contains('ListTile background color')) return;
      originalOnError?.call(details);
    };
  });

  WorkoutRecord recordOf(String id, double weightPerSet) => WorkoutRecord(
    id: id,
    date: DateTime.now(),
    durationSeconds: 600,
    trainedMuscles: const [],
    exercises: [
      RecordedExercise(
        exerciseId: 'ex-$id',
        completedSets: 1,
        maxWeight: weightPerSet,
        setsData: [SetData(setNumber: 1, reps: 10, weight: weightPerSet)],
      ),
    ],
    totalSets: 1,
    createdAt: DateTime.now(),
  );

  Widget app(RecordProvider provider, Key screenKey) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: ThemeProvider()),
      ChangeNotifierProvider.value(value: provider),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StatsScreen(key: screenKey),
    ),
  );

  /// Pre-opens the in-memory app database inside the real event loop so
  /// StatsScreen's repository calls hit a cached handle and complete within
  /// the fake-async test zone (fresh ffi futures would never resolve there).
  Future<void> warmDatabase(WidgetTester tester) async {
    await tester.runAsync(() => DatabaseHelper.instance.database);
  }

  testWidgets('stats screen re-reads the repository on every entry', (
    tester,
  ) async {
    final repo = FakeRecordRepository();
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );

    // Record A exists in the DB and is loaded startup-equivalently, so the
    // provider already has data (recordCount > 0) before any stats entry.
    repo.dbRecords.add(recordOf('a', 30.0));
    // runAsync is required: real asset/IO futures don't complete inside the
    // fake-async zone without it.
    await tester.runAsync(() => provider.loadRecords());
    final callsAfterStartup = repo.getAllRecordsCalls;
    await warmDatabase(tester);

    // First entry into the stats tab.
    await tester.pumpWidget(app(provider, const Key('stats-1')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Second entry (fresh screen state, like switching tabs again).
    await tester.pumpWidget(app(provider, const Key('stats-2')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      repo.getAllRecordsCalls,
      greaterThanOrEqualTo(callsAfterStartup + 2),
      reason:
          'Each stats entry must reload from the repository instead of '
          'trusting the in-memory provider list',
    );
  });

  testWidgets('stats shows a workout that landed only in the database', (
    tester,
  ) async {
    final repo = FakeRecordRepository();
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );

    // Record A was loaded at startup. Its 7-day rolling volume
    // (1 set × 10 reps × 30 kg) shows as "300 kg" in the dose summary.
    repo.dbRecords.add(recordOf('a', 30.0));
    await tester.runAsync(() => provider.loadRecords());
    await warmDatabase(tester);

    await tester.pumpWidget(app(provider, const Key('stats-1')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('300 kg'), findsOneWidget);

    // Record B reaches the database without going through the provider
    // (e.g. recovered after a failed startup load). Re-entering the stats
    // tab must pick it up: combined 7-day volume becomes 550 kg.
    repo.dbRecords.add(recordOf('b', 25.0));
    await tester.pumpWidget(app(provider, const Key('stats-2')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('550 kg'), findsOneWidget);
  });

  testWidgets('a rolling range chip pushes the AI analysis screen', (
    tester,
  ) async {
    final repo = FakeRecordRepository();
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );
    repo.dbRecords.add(recordOf('a', 30.0));
    await tester.runAsync(() => provider.loadRecords());
    await warmDatabase(tester);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ThemeProvider()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // The stats body is a lazy ListView — the AI entry sits at the very
    // bottom and is not built until scrolled into the viewport.
    await tester.scrollUntilVisible(
      find.text('Last 7 days'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Last 7 days'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AIAnalysisScreen), findsOneWidget);
  });
}
