import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/providers/record_provider.dart';
import 'package:workout_timer/screens/history_screen.dart';
import 'package:workout_timer/services/database_helper.dart';
import 'package:workout_timer/theme/theme_provider.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite_ffi so DatabaseHelper works on the desktop test runner.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    ServiceLocator.setup();
    SharedPreferences.setMockInitialValues({});

    // Reset the DatabaseHelper singleton so each test starts from a clean
    // in-memory schema.
    await DatabaseHelper.resetForTesting();
  });

  /// Pump HistoryScreen inside the providers it expects.
  Future<void> pumpHistoryScreen(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => RecordProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HistoryScreen(),
        ),
      ),
    );

    // Two pumps: first triggers FutureBuilder rebuild, second settles the
    // 'empty state' UI (no records). Use a small fixed delay instead of
    // pumpAndSettle to avoid any infinite animation hang.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  group('HistoryScreen AppBar', () {
    testWidgets('shows the export action', (tester) async {
      await pumpHistoryScreen(tester);
      // i18n key historyExportAction -> "Export Archive" in en.
      expect(find.text('Export Archive'), findsOneWidget);
    });

    testWidgets('does NOT show the old Clear button', (tester) async {
      await pumpHistoryScreen(tester);
      // The old AppBar action text was "Clear" (settingsClear in en).
      // It may legitimately appear elsewhere (e.g. long-press menus), so we
      // look specifically for it as a TextButton inside the AppBar.
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      final clearInAppBar = find.descendant(
        of: appBarFinder,
        matching: find.text('Clear'),
      );
      expect(clearInAppBar, findsNothing,
          reason: 'Clear button must be removed from history AppBar');
    });
  });
}
