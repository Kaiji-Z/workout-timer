import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/training_history_export_sheet.dart';

void main() {
  setUp(() {
    ServiceLocator.setup();
  });

  /// Helper: pumps the export sheet inside a MaterialApp + ThemeProvider.
  Future<void> pumpSheet(
    WidgetTester tester, {
    required int totalRecords,
    required ExportRangeCallback onExport,
  }) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showTrainingHistoryExportSheet(
                  context,
                  totalRecords: totalRecords,
                  onExport: onExport,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('TrainingHistoryExportSheet', () {
    testWidgets('renders all six preset range chips', (tester) async {
      await pumpSheet(
        tester,
        totalRecords: 10,
        onExport: (_, __) async {},
      );

      // Four duration presets + "all" + "custom"
      expect(find.text('Last 4 weeks'), findsOneWidget);
      expect(find.text('Last 3 months'), findsOneWidget);
      expect(find.text('Last 6 months'), findsOneWidget);
      expect(find.text('Last 12 months'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('shows the export button with the total record count', (tester) async {
      await pumpSheet(
        tester,
        totalRecords: 12,
        onExport: (_, __) async {},
      );

      // Default selection (last 4 weeks) shows the button with count = 12.
      expect(find.textContaining('12'), findsWidgets);
    });

    testWidgets('disables the export button when there are no records', (tester) async {
      await pumpSheet(
        tester,
        totalRecords: 0,
        onExport: (_, __) async {},
      );

      // Find the "no records" message and verify the button is disabled.
      expect(find.text('No training records in this range'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.enabled, isFalse,
          reason: 'export button must be disabled when there are 0 records');
    });

    testWidgets('tapping a preset invokes onExport with a date range ending today',
        (tester) async {
      DateTime? capturedFrom;
      DateTime? capturedTo;

      await pumpSheet(
        tester,
        totalRecords: 5,
        onExport: (from, to) async {
          capturedFrom = from;
          capturedTo = to;
        },
      );

      // Tap "Last 4 weeks" preset chip.
      await tester.tap(find.text('Last 4 weeks'));
      await tester.pumpAndSettle();

      // Tap the export button.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(capturedFrom, isNotNull);
      expect(capturedTo, isNotNull);

      // The `to` end of the range should be today.
      final today = DateTime.now();
      expect(capturedTo!.year, today.year);
      expect(capturedTo!.month, today.month);
      expect(capturedTo!.day, today.day);

      // `from` should be roughly 4 weeks (27-28 days) before today.
      final diff = today.difference(capturedFrom!).inDays;
      expect(diff, inInclusiveRange(27, 28));
    });

    testWidgets('tapping "All" invokes onExport with a wide range', (tester) async {
      DateTime? capturedFrom;
      DateTime? capturedTo;

      await pumpSheet(
        tester,
        totalRecords: 5,
        onExport: (from, to) async {
          capturedFrom = from;
          capturedTo = to;
        },
      );

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(capturedFrom, isNotNull);
      expect(capturedTo, isNotNull);

      // "All" should reach back at least 10 years (effectively all history).
      final today = DateTime.now();
      expect(capturedFrom!.year, lessThan(today.year - 5));
    });

    testWidgets('tapping "Custom" does not invoke onExport directly '
        '(delegates to caller via onCustomRequested)', (tester) async {
      bool exportCalled = false;
      bool customCalled = false;

      await pumpSheet(
        tester,
        totalRecords: 5,
        onExport: (from, to) async {
          exportCalled = true;
        },
        onCustomRequested: () {
          customCalled = true;
        },
      );

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Tapping "Custom" should not fire the export; it should call the
      // custom-range hook so the caller can open showDateRangePicker.
      expect(exportCalled, isFalse);
      expect(customCalled, isTrue);
    });
  });
}
