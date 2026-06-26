// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Iron Timer';

  @override
  String get navPlans => 'Plans';

  @override
  String get navHistory => 'History';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get navTimer => 'Timer';

  @override
  String timerSecondsRemaining(int seconds) {
    return '${seconds}s remaining';
  }

  @override
  String get timerInProgress => 'In Progress';

  @override
  String get timerReady => 'Ready';

  @override
  String get timerCompletedSets => 'Completed Sets';

  @override
  String get timerReset => 'Reset Timer';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerStart => 'Start';

  @override
  String get timerSkipSet => 'Skip Set';

  @override
  String timerSecondsLabel(int seconds) {
    return '${seconds}s';
  }

  @override
  String trainingNextExercise(String name) {
    return 'Next: $name';
  }

  @override
  String get trainingNextDone => 'Next: Done';

  @override
  String get trainingRestCountdown => 'Rest Countdown';

  @override
  String get trainingExercising => 'Exercising';

  @override
  String get trainingRestDuration => 'Rest Duration';

  @override
  String trainingExerciseProgress(String name, int set) {
    return '$name · Set $set · Exercise';
  }

  @override
  String trainingSetExercising(int set) {
    return 'Set $set · Exercising';
  }

  @override
  String trainingExerciseRest(String name, int set) {
    return '$name · $set sets done · Resting';
  }

  @override
  String trainingSetRest(int set) {
    return 'Set $set · Resting';
  }

  @override
  String get trainingCompleted => 'Training Complete';

  @override
  String trainingSetPaused(int set) {
    return 'Set $set · Paused';
  }

  @override
  String trainingPlanReady(String name) {
    return '$name · Ready';
  }

  @override
  String get trainingReady => 'Ready';

  @override
  String trainingSetCount(int set) {
    return '$set sets';
  }

  @override
  String get trainingStartExercise => 'Start';

  @override
  String get trainingRest => 'Rest';

  @override
  String get trainingContinue => 'Continue';

  @override
  String get trainingSkipRest => 'Skip Rest';

  @override
  String get trainingSave => 'Save';

  @override
  String get trainingNoPlan => 'No plan yet, create one first';

  @override
  String get trainingSelectPlan => 'Select Plan';

  @override
  String get trainingCancelPlan => 'Cancel Plan';

  @override
  String trainingPlanSummary(int exerciseCount, int totalSets) {
    return '$exerciseCount exercises · $totalSets sets';
  }

  @override
  String trainingSavedDetail(int sets, String duration) {
    return 'Saved: $sets sets, $duration total';
  }

  @override
  String trainingSavedCompleted(int sets, String duration) {
    return 'Saved: $sets sets complete, $duration total';
  }

  @override
  String get notifNextSet => 'Get ready for the next set!';

  @override
  String get notifRestDone => 'Rest time over!';

  @override
  String get soundDefault => 'Default';

  @override
  String get soundBeep => 'Beep';

  @override
  String get soundRing => 'Ring';

  @override
  String get soundChime => 'Chime';

  @override
  String get soundWhistle => 'Whistle';

  @override
  String get recReps => 'Reps';

  @override
  String get recSkip => 'Skip';

  @override
  String get recSave => 'Save';

  @override
  String get recWeightKg => 'Weight (kg)';

  @override
  String get recAddedWeightKg => 'Added Weight (kg)';

  @override
  String get recBodyweightOnly => '0 = bodyweight only';

  @override
  String get recInvalidInput => 'Please enter valid weight and reps';

  @override
  String get recRecordData => 'Record Workout Data';

  @override
  String get recScrollHint => 'Scroll to select reps, enter weight';

  @override
  String get recAdded => 'Added';

  @override
  String get calPrevMonth => 'Previous month';

  @override
  String get calNextMonth => 'Next month';

  @override
  String get oemSectionTitle => 'OEM Background Manager';

  @override
  String oemCardTitle(String name) {
    return '$name Power Manager';
  }

  @override
  String oemExplanation(String name) {
    return 'Your $name phone has its own power management that may override the standard battery whitelist. Tap below and allow this app to run in the background.';
  }

  @override
  String get oemFlowHint =>
      'Tip: complete \'Allow background activity\' (the standard whitelist) above first, then do the OEM-specific setting below — both are needed for reliable background timing.';

  @override
  String oemGoButton(String name) {
    return 'Open $name Settings';
  }

  @override
  String get oemDefaultInstruction =>
      'Allow this app to auto-start and run in the background in system settings';

  @override
  String unitMinutes(int m) {
    return '$m min';
  }

  @override
  String unitMinutesSeconds(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String unitSeconds(int s) {
    return '${s}s';
  }

  @override
  String unitRepsRange(int min, int max) {
    return '$min-$max reps';
  }

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelExpert => 'Advanced';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentBodyweight => 'Bodyweight';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentKettlebells => 'Kettlebells';

  @override
  String get equipmentBands => 'Bands';

  @override
  String get equipmentMedicineBall => 'Medicine Ball';

  @override
  String get equipmentEzBarbell => 'EZ Barbell';

  @override
  String get equipmentSmithMachine => 'Smith Machine';

  @override
  String get errorGeneric => 'Operation failed, please retry';

  @override
  String get dataTransferShareText => 'Iron Timer data backup';

  @override
  String get dataTransferWebUnsupported =>
      'File import is not supported on Web';

  @override
  String get dataTransferInvalidFormat => 'Invalid backup file format';

  @override
  String aiPromptOutputInstructions(
    int frequency,
    String goal,
    String experience,
    String equipment,
  ) {
    return 'Please structure your reply in the following two parts:\n\n**Part 1: Plan Design Rationale**\n\nExplain in detail why you designed the plan this way, including:\n- The reasoning behind the split you chose (e.g. push/pull/legs, upper/lower, full body, etc., considering my training frequency of $frequency days/week)\n- The exercise selection logic for each training day (why these exercises were chosen, and the compound/isolation pairing principles)\n- The volume allocation rationale (weekly sets per muscle group, and how they match my goal of $goal)\n- How the plan fits my experience level $experience and equipment access $equipment\n\n**Part 2: Workout Plan JSON**\n\nAfter your analysis, provide the structured workout plan in a ```json code block:';
  }

  @override
  String aiPromptClosing(int frequency) {
    return 'Based on the above information (training frequency of $frequency days/week), first explain your design rationale, then generate the workout plan.';
  }

  @override
  String dialogSetTitle(int set) {
    return 'Set $set';
  }

  @override
  String dialogSetTitleWithName(int set, String name) {
    return 'Set $set - $name';
  }

  @override
  String repsWithValue(int reps) {
    return '$reps reps';
  }

  @override
  String bodyweightReference(String bw, String pct, String result) {
    return 'Bodyweight ${bw}kg × $pct% = ${result}kg';
  }

  @override
  String trainingSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get calDayHasPlan => 'has workout plan';

  @override
  String get calDayToday => 'today';

  @override
  String get calDaySelected => 'selected';

  @override
  String calDaySemantics(
    String date,
    String plan,
    String today,
    String selected,
  ) {
    return '$date, $plan$today$selected';
  }

  @override
  String get widgetSearchExercise => 'Search exercises';

  @override
  String get widgetClearSearch => 'Clear search';

  @override
  String get widgetAll => 'All';

  @override
  String get widgetNoExerciseFound => 'No exercises found';

  @override
  String widgetSelectedCount(int count) {
    return '$count exercises selected';
  }

  @override
  String get widgetClearAll => 'Clear';

  @override
  String widgetSetsSuffix(int n) {
    return '$n sets';
  }

  @override
  String widgetPlanExercisesCount(int n) {
    return '$n exercises';
  }

  @override
  String widgetPlanSetsCount(int n) {
    return '$n sets';
  }

  @override
  String widgetPlanDuration(int n) {
    return '~$n min';
  }

  @override
  String widgetPlanSummaryShort(int exerciseCount, int totalSets) {
    return '$exerciseCount exercises · $totalSets sets';
  }

  @override
  String widgetCurrentExercise(String name, int set, int total) {
    return 'Current: $name Set $set/$total';
  }

  @override
  String widgetExerciseProgressHeader(String plan, String exercise, int set) {
    return '$plan · $exercise Set $set';
  }

  @override
  String widgetNoDetail(String name) {
    return '$name (no details)';
  }

  @override
  String get widgetSwitchNextExercise => 'Next exercise';

  @override
  String get widgetEmptyPlanTitle => 'No plan yet';

  @override
  String get widgetEmptyPlanSubtitle => 'Tap to create your first workout plan';

  @override
  String widgetProgressSummary(String name, int current, int total) {
    return '$name · $current/$total sets';
  }

  @override
  String get widgetSelectMuscleTitle => 'Select target muscles';

  @override
  String get widgetNoDailyData => 'No daily volume data yet';

  @override
  String get widgetTrainingComplete => 'Workout complete';

  @override
  String get widgetImageLoadFailed => 'Image failed to load';

  @override
  String get widgetTapToClose => 'Tap anywhere to close';

  @override
  String get widgetClose => 'Close';

  @override
  String get widgetSetRestDuration => 'Set rest duration';

  @override
  String get widgetRestMinDuration =>
      'Rest duration must be at least 10 seconds';

  @override
  String get widgetMinuteSuffix => 'min';

  @override
  String get widgetSecondSuffix => 'sec';

  @override
  String get widgetCancel => 'Cancel';

  @override
  String get widgetConfirm => 'Done';

  @override
  String widgetSelectedDuration(String duration) {
    return 'Selected: $duration';
  }

  @override
  String get widgetConfirmButton => 'Confirm';

  @override
  String get widgetSearchExerciseHint => 'Search exercises...';

  @override
  String get widgetInvolvedMuscles => 'Muscles';

  @override
  String get widgetRemoveFromPlan => 'Remove from plan';

  @override
  String get widgetAddToPlan => 'Add to plan';

  @override
  String widgetImageStepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get widgetExerciseInstructions => 'Instructions';

  @override
  String get widgetRecommendedConfig => 'Recommended';

  @override
  String get widgetRecommendedSets => 'Sets';

  @override
  String widgetRecommendedSetsValue(int n) {
    return '$n sets';
  }

  @override
  String get widgetRepsRangeLabel => 'Reps';

  @override
  String get widgetRestLabel => 'Rest';
}
