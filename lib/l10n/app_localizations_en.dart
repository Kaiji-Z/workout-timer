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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsSelectTheme => 'Select Theme';

  @override
  String get settingsNotificationSection => 'Notifications';

  @override
  String get settingsEnableSound => 'Enable Sound';

  @override
  String get settingsNotificationRingtone => 'Notification Ringtone';

  @override
  String get settingsEnableVibration => 'Enable Vibration';

  @override
  String get settingsDetailedRecording => 'Detailed Recording Mode';

  @override
  String get settingsSelectRingtone => 'Select Ringtone';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsCustomMessageDefault => 'Get ready for the next set!';

  @override
  String get settingsCustomMessageSection => 'Custom Reminder Message';

  @override
  String get settingsCustomMessageHint => 'Enter reminder message';

  @override
  String get settingsBackgroundSection => 'Background Running';

  @override
  String get settingsAllowBackground => 'Allow Background Activity';

  @override
  String get settingsBackgroundAllowed =>
      'Allowed — the timer can run normally in the background';

  @override
  String get settingsBackgroundNotAllowed =>
      'Not allowed — the background timer may be paused by the system';

  @override
  String get settingsBackgroundHint =>
      'Tap the option above and choose \"Allow\" in the system dialog so the timer can keep running in the background';

  @override
  String get settingsDataSection => 'Data Management';

  @override
  String get settingsExportData => 'Export Data';

  @override
  String get settingsExportSubtitle =>
      'Export all workout records, plans, etc. to a file';

  @override
  String get settingsImportData => 'Import Data';

  @override
  String get settingsImportSubtitle =>
      'Restore all data from a backup file (overwrites existing data)';

  @override
  String get settingsClearHistory => 'Clear All History';

  @override
  String get settingsClearHistoryConfirmTitle => 'Confirm Clear';

  @override
  String get settingsClearHistoryConfirmBody =>
      'Are you sure you want to clear all history? This action cannot be undone.';

  @override
  String get settingsHistoryCleared => 'History cleared';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportConfirmBody =>
      'All workout records, plans, exercises, etc. will be exported.\n\nThe file will be saved to your phone\'s Downloads folder and a share sheet will appear.';

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get settingsImportConfirmTitle => 'Confirm Import';

  @override
  String settingsImportConfirmBody(String source) {
    return '⚠️ Importing will overwrite all existing data!\n\nRestoring from:\n$source';
  }

  @override
  String get settingsConfirmImport => 'Confirm Import';

  @override
  String settingsImportSuccess(int count) {
    return 'Import successful — $count records restored';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsFoundLocalBackups => 'Local backups found';

  @override
  String get settingsSelectManually => 'Select file manually';

  @override
  String get settingsSelectManuallySubtitle =>
      'Choose a JSON backup file from another location';

  @override
  String get settingsAiPreferencesSection => 'AI Training Preferences';

  @override
  String get settingsTrainingPreferences => 'Training Preferences';

  @override
  String get settingsTrainingPreferencesSubtitle =>
      'Set training goals, experience level, etc. — AI features will read these automatically';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'View this app\'s privacy policy';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsBackupPrefix => 'Backup';

  @override
  String get settingsVersionLoading => 'Loading…';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String get settingsDeveloperName =>
      'Shenzhen Lukai Culture Communication Co., Ltd.';

  @override
  String get settingsContactEmail => 'Contact Email';

  @override
  String get settingsEmailCopied => 'Email copied';

  @override
  String get settingsPrivacyHeadline =>
      'Iron Timer does not collect any personal information';

  @override
  String get settingsPrivacyDataStorage => 'Data Storage';

  @override
  String get settingsPrivacyDataStorageBody =>
      'All workout data is stored locally on your device (SQLite database) and is never uploaded to any server. Uninstalling the app permanently deletes all data.';

  @override
  String get settingsPrivacyPermissions => 'Device Permissions';

  @override
  String get settingsPrivacyPermNotifications =>
      '• Notifications: end-of-timer reminder';

  @override
  String get settingsPrivacyPermVibration =>
      '• Vibration: end-of-timer vibration reminder';

  @override
  String get settingsPrivacyPermForegroundService =>
      '• Foreground service: keep timing in the background';

  @override
  String get settingsPrivacyPermNetwork =>
      '• Network: only to download open-source fitness images (CC0)';

  @override
  String get settingsPrivacyPermBatteryExempt =>
      '• Battery optimization exemption: prevent the timer from being interrupted by the system';

  @override
  String get settingsPrivacyThirdParty => 'Third-Party Services';

  @override
  String get settingsPrivacyThirdPartyBody =>
      'This app does not integrate any third-party analytics, advertising, or tracking SDKs.';

  @override
  String get settingsPrivacyFullPolicy =>
      'Full privacy policy:\nhttps://kaiji-z.github.io/workout-timer/';

  @override
  String get settingsPrivacyLinkCopied => 'Privacy policy link copied';

  @override
  String get settingsCopyLink => 'Copy Link';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow system';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get brandHuawei => 'Huawei';

  @override
  String get brandHonor => 'Honor';

  @override
  String get brandXiaomi => 'Xiaomi';

  @override
  String get brandOppo => 'OPPO';

  @override
  String get brandVivo => 'vivo';

  @override
  String get brandMeizu => 'Meizu';

  @override
  String get brandSamsung => 'Samsung';

  @override
  String get brandOneplus => 'OnePlus';

  @override
  String get oemInstructionHuawei =>
      'In \"App launch management\", find Iron Timer, turn off \"Automatic management\", then manually enable all three toggles';

  @override
  String get oemInstructionHonor =>
      'In \"App launch management\", find Iron Timer, turn off \"Automatic management\", then manually enable all three toggles';

  @override
  String get oemInstructionXiaomi =>
      'In \"Autostart management\", find Iron Timer and enable autostart. Then under \"Battery saver policy\" choose \"No restrictions\"';

  @override
  String get oemInstructionOppo =>
      'In \"Autostart management\", find Iron Timer and allow autostart';

  @override
  String get oemInstructionVivo =>
      'In \"High background power use\" or \"Autostart\", find Iron Timer and allow background running';

  @override
  String get oemInstructionMeizu =>
      'In \"Smart sleep\" or \"Background management\", find Iron Timer and allow background running';

  @override
  String get oemInstructionSamsung =>
      'In \"Battery\" settings, find Iron Timer and choose \"Unrestricted\"';

  @override
  String get oemInstructionOneplus =>
      'In \"Battery optimization\" advanced settings, find Iron Timer and choose \"Don\'t optimize\"';
}
