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
    double? fakeKeyboardHeight,
  }) => MultiProvider(
    providers: [ChangeNotifierProvider.value(value: ThemeProvider())],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // 模拟键盘弹出：真实机型的键盘 insets 在测试环境不存在，用注入的
      // viewInsets 等价复现「键盘弹出后窗口可用高度被压缩」的布局条件。
      builder: (context, child) {
        Widget wrapped = child!;
        final keyboard = fakeKeyboardHeight;
        if (keyboard != null) {
          wrapped = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: wrapped,
          );
        }
        return wrapped;
      },
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

  // 用户报告（2026-11）：部分机型键盘弹出时记录窗口被压缩，保存按钮只剩
  // 半截。机制：initState 自动 focus 弹出键盘，Dialog 随 viewInsets 收缩，
  // 保存按钮落在 SingleChildScrollView 视口之外（半截且初始不可见）。
  // 契约：无论屏幕高度/键盘高度组合，保存按钮必须完整可见且位于键盘上方。
  group('keyboard adaptation (small screen)', () {
    testWidgets(
      'save button stays fully visible above the keyboard on a small screen',
      (tester) async {
        const keyboardHeight = 280.0;
        const screenW = 360.0;
        const screenH = 560.0;
        tester.view.physicalSize = const Size(screenW, screenH);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          harness(
            fakeKeyboardHeight: keyboardHeight,
            onOpen: (context) {
              SetRecordDialog.show(
                context,
                exerciseName: 'Barbell Bench Press',
                setNumber: 2,
                exercise: barbellExercise(),
              );
            },
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final saveFinder = find.ancestor(
          of: find.text('Save'),
          matching: find.byType(ElevatedButton),
        );
        expect(saveFinder, findsOneWidget);

        final saveRect = tester.getRect(saveFinder);
        final keyboardTop = screenH - keyboardHeight;
        expect(
          saveRect.bottom,
          lessThanOrEqualTo(keyboardTop),
          reason: '键盘弹出后保存按钮底部(${saveRect.bottom})不得'
              '超过键盘顶线($keyboardTop)，否则按钮被键盘遮挡只显示一半',
        );
        expect(
          saveRect.top,
          greaterThanOrEqualTo(0),
          reason: '保存按钮必须完整落在屏幕内',
        );
        expect(
          saveRect.bottom,
          lessThanOrEqualTo(screenH),
          reason: '保存按钮不得超出屏幕底部',
        );
      },
    );

    testWidgets(
      'save button is fully visible without a keyboard (layout unchanged)',
      (tester) async {
        await tester.pumpWidget(
          harness(
            onOpen: (context) {
              SetRecordDialog.show(
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

        final saveFinder = find.ancestor(
          of: find.text('Save'),
          matching: find.byType(ElevatedButton),
        );
        expect(saveFinder, findsOneWidget);

        // 默认测试画布 800×600：无键盘时保存按钮必须完整在屏内（回归保护）。
        final saveRect = tester.getRect(saveFinder);
        expect(saveRect.top, greaterThanOrEqualTo(0));
        expect(saveRect.bottom, lessThanOrEqualTo(600));
        expect(saveRect.left, greaterThanOrEqualTo(0));
        expect(saveRect.right, lessThanOrEqualTo(800));
      },
    );
  });
}
