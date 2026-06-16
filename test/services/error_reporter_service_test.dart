import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/services/error_reporter_service.dart';

void main() {
  late ErrorReporter reporter;

  setUp(() {
    reporter = ErrorReporter();
  });

  group('ErrorSeverity', () {
    test('devOnly does not attempt to show a SnackBar', () {
      // No scaffoldMessengerKey attached — a userWarning would log a
      // "no messenger" message, but devOnly must stay completely silent.
      reporter.report(
        Exception('silent failure'),
        severity: ErrorSeverity.devOnly,
      );
      // No exception thrown, no state set beyond internal logging.
      expect(reporter.scaffoldMessengerKey, isNull);
    });

    test(
      'userWarning without a messenger logs gracefully instead of throwing',
      () {
        // During startup or in tests there may be no UI; report must not crash.
        expect(
          () => reporter.report(
            Exception('no ui'),
            severity: ErrorSeverity.userWarning,
          ),
          returnsNormally,
        );
      },
    );
  });

  group('report with ScaffoldMessenger', () {
    testWidgets('userWarning shows a SnackBar with the provided message', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      reporter.scaffoldMessengerKey = messengerKey;

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      reporter.report(
        Exception('save failed'),
        severity: ErrorSeverity.userWarning,
        message: '保存失败，请重试',
      );

      await tester.pump(); // let the SnackBar animate in
      expect(find.text('保存失败，请重试'), findsOneWidget);
    });

    testWidgets('userWarning falls back to a default message when none given', (
      tester,
    ) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      reporter.scaffoldMessengerKey = messengerKey;

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      reporter.report(
        Exception('unspecified'),
        severity: ErrorSeverity.userWarning,
      );

      await tester.pump();
      expect(find.text('操作失败，请重试'), findsOneWidget);
    });

    testWidgets('devOnly never shows a SnackBar', (tester) async {
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      reporter.scaffoldMessengerKey = messengerKey;

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      reporter.report(
        Exception('silent'),
        severity: ErrorSeverity.devOnly,
        message: 'should not appear',
      );

      await tester.pump();
      expect(find.text('should not appear'), findsNothing);
    });
  });
}
