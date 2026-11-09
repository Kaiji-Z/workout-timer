import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/l10n/app_localizations.dart';
import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/set_data.dart';
import 'package:workout_timer/theme/theme_provider.dart';
import 'package:workout_timer/widgets/set_record_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// 自重动作（引体向上，系数表命中 0.70），用于自重存储约定测试
  Exercise bodyweightExercise() => const Exercise(
    id: 'Pullups',
    name: '引体向上',
    nameEn: 'Pull-up',
    primaryMuscle: PrimaryMuscleGroup.back,
    secondaryMuscles: [SecondaryMuscleGroup.biceps],
    equipment: 'body only',
    level: 'intermediate',
    recommendation: ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  );

  Exercise barbellExercise() => const Exercise(
    id: 'barbell_bench_press',
    name: '杠铃卧推',
    nameEn: 'Barbell Bench Press',
    primaryMuscle: PrimaryMuscleGroup.chest,
    secondaryMuscles: [SecondaryMuscleGroup.triceps],
    equipment: 'barbell',
    level: 'intermediate',
    recommendation: ExerciseRecommendation(
      recommendedSets: 3,
      minReps: 8,
      maxReps: 12,
      restSeconds: 90,
    ),
  );

  Widget harness({
    required void Function(BuildContext context) onOpen,
  }) => MultiProvider(
    providers: [ChangeNotifierProvider.value(value: ThemeProvider())],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => onOpen(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  /// Regression guard for the bodyweight storage convention.
  ///
  /// Root cause: the dialog used to store the *equivalent* weight
  /// (bodyWeight × coefficient + added weight) into `SetData.weight`, while
  /// `RecordedExercise.bodyweightAdjustedVolume` adds the bodyweight part
  /// again at aggregation time. Worse, the next set's dialog prefills from
  /// the previous set's stored weight, so the polluted value compounded
  /// set over set — the user saw 59.0 in set 2 after entering 10 in set 1.
  ///
  /// Contract: `SetData.weight` always stores the *raw added weight* the
  /// user typed; the bodyweight coefficient is applied exactly once, at
  /// aggregation (bodyweightAdjustedVolume).
  testWidgets(
    'bodyweight set stores raw added weight; next-set prefill does not compound',
    (tester) async {
      SharedPreferences.setMockInitialValues({'pref_body_weight': 70.0});
      Future<SetData?>? dialogFuture;

      await tester.pumpWidget(
        harness(
          onOpen: (context) {
            dialogFuture = SetRecordDialog.show(
              context,
              exerciseName: 'Pull-up',
              setNumber: 1,
              exercise: bodyweightExercise(),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 第一组：输入配重 10kg，保存
      await tester.enterText(find.byType(TextField), '10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final firstSet = await dialogFuture;
      expect(firstSet!.weight, 10.0, reason: '存原始配重，而非 70×0.70+10=59');
      expect(firstSet.reps, 12);

      // 第二组：以上一组原始配重预填，不改数值直接保存仍是 10（不滚雪球）
      dialogFuture = null;
      await tester.pumpWidget(
        harness(
          onOpen: (context) {
            dialogFuture = SetRecordDialog.show(
              context,
              exerciseName: 'Pull-up',
              setNumber: 2,
              initialReps: firstSet.reps,
              initialWeight: firstSet.weight,
              exercise: bodyweightExercise(),
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final weightField = tester.widget<TextField>(find.byType(TextField));
      expect(
        weightField.controller!.text,
        '10.0',
        reason: '第二组预填必须显示真实配重，而非加自重系数后的值',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final secondSet = await dialogFuture;
      expect(secondSet!.weight, 10.0);
    },
  );

  testWidgets('pure bodyweight with empty input stores null weight', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'pref_body_weight': 70.0});
    Future<SetData?>? dialogFuture;

    await tester.pumpWidget(
      harness(
        onOpen: (context) {
          dialogFuture = SetRecordDialog.show(
            context,
            exerciseName: 'Pull-up',
            setNumber: 1,
            exercise: bodyweightExercise(),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final setData = await dialogFuture;
    expect(setData!.weight, isNull, reason: '纯自重（无配重）不写重量');
  });

  testWidgets('weighted exercise stores the entered weight as-is', (
    tester,
  ) async {
    Future<SetData?>? dialogFuture;

    await tester.pumpWidget(
      harness(
        onOpen: (context) {
          dialogFuture = SetRecordDialog.show(
            context,
            exerciseName: 'Barbell Bench Press',
            setNumber: 1,
            exercise: barbellExercise(),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final setData = await dialogFuture;
    expect(setData!.weight, 60.0);
  });

  /// Regression guard for the Save button contrast bug.
  ///
  /// Root cause: the global `elevatedButtonTheme` hardcoded
  /// `foregroundColor: accentColor`, which in Material 3 collided with the
  /// local `styleFrom(foregroundColor: onAccentColor)` on dark-filled buttons,
  /// rendering the label in the inherited `DefaultTextStyle` color (near-black)
  /// on an indigo fill = unreadable. Pixel-confirmed: zero white pixels.
  ///
  /// The theme no longer sets a global foregroundColor, so the local style
  /// resolves to white on indigo. This test locks that contract.
  testWidgets(
    'Save button renders white text on indigo background (contrast fixed)',
    (tester) async {
      final themeProvider = ThemeProvider();
      final accent = themeProvider.currentTheme.accentColor;
      final onAccent = themeProvider.currentTheme.onAccentColor;

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: themeProvider)],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => SetRecordDialog.show(
                    context,
                    exerciseName: 'Bench Press',
                    setNumber: 1,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Locate the Save button by its label (the launcher "open" button is also
      // an ElevatedButton, so type-based finding matches both).
      final saveTextFinder = find.text('Save');
      expect(saveTextFinder, findsOneWidget, reason: 'Save label should render');

      final saveFinder = find.ancestor(
        of: saveTextFinder,
        matching: find.byType(ElevatedButton),
      );
      expect(saveFinder, findsOneWidget, reason: 'Save must be an ElevatedButton');

      // Render the text and assert its effective color is white (onAccent),
      // resolved through the widget tree — this is exactly what rendered black
      // before the theme fix.
      final textWidget = tester.widget<Text>(
        find.descendant(of: saveFinder, matching: find.byType(Text)),
      );
      final resolvedColor =
          (textWidget.style?.color ?? onAccent);

      expect(
        resolvedColor,
        onAccent,
        reason: 'Save text color must be white (onAccent), not inherited black',
      );

      // And the button's own foreground should resolve to white.
      final button = tester.widget<ElevatedButton>(saveFinder);
      final style = button.style;
      final fg = style?.foregroundColor?.resolve({}) ?? Colors.transparent;
      expect(fg, onAccent, reason: 'Button foreground must be white');
      final bg = style?.backgroundColor?.resolve({}) ?? Colors.transparent;
      expect(bg, accent, reason: 'Button background must be indigo accent');
    },
  );
}
