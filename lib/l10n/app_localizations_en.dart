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
}
