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

  @override
  String get prefTitle => 'Training Preferences';

  @override
  String get prefCloseTooltip => 'Close';

  @override
  String get prefSaved => 'Preferences saved';

  @override
  String get prefBodyWeightSection => 'Body Weight';

  @override
  String get prefBodyWeightHint =>
      'Used to calculate training volume for bodyweight exercises (e.g. pull-ups, push-ups)';

  @override
  String get prefBodyWeightPlaceholder => 'e.g. 70';

  @override
  String get prefGoalSection => 'Training Goal';

  @override
  String get prefGoalMuscleBuilding => 'Muscle Building';

  @override
  String get prefGoalFatLoss => 'Fat Loss';

  @override
  String get prefGoalStrength => 'Strength';

  @override
  String get prefGoalEndurance => 'Endurance';

  @override
  String get prefExperienceSection => 'Experience Level';

  @override
  String get prefExperienceBeginner => 'Beginner';

  @override
  String get prefExperienceIntermediate => 'Intermediate';

  @override
  String get prefExperienceAdvanced => 'Advanced';

  @override
  String get prefEquipmentSection => 'Available Equipment';

  @override
  String get prefEquipmentGym => 'Gym';

  @override
  String get prefEquipmentHomeDumbbell => 'Home Dumbbell';

  @override
  String get prefEquipmentBodyweight => 'Bodyweight';

  @override
  String get prefFrequencySection => 'Weekly Frequency';

  @override
  String prefFrequencyDays(int count) {
    return '$count days';
  }

  @override
  String get prefFocusAreaSection => 'Focus Areas';

  @override
  String get prefFocusAreaChest => 'Chest';

  @override
  String get prefFocusAreaBack => 'Back';

  @override
  String get prefFocusAreaShoulders => 'Shoulders';

  @override
  String get prefFocusAreaArms => 'Arms';

  @override
  String get prefFocusAreaLegs => 'Legs';

  @override
  String get prefFocusAreaCore => 'Core';

  @override
  String get historyTitle => 'History';

  @override
  String get historyLoadFailed => 'Load failed';

  @override
  String get historyEmpty => 'No records yet';

  @override
  String get historyEmptyHint => 'Complete a workout to see results';

  @override
  String get historyClearConfirmTitle => 'Clear history';

  @override
  String get historyClearConfirmBody => 'Clear all history records?';

  @override
  String get historyPlanMode => 'Plan mode';

  @override
  String get historyFreeWorkout => 'Free workout';

  @override
  String get historyCompletedSets => 'Completed sets';

  @override
  String historySetsSuffix(int count) {
    return '$count sets';
  }

  @override
  String historyExercisesSuffix(int count) {
    return '$count exercises';
  }

  @override
  String get recDetailTitle => 'Workout Detail';

  @override
  String get recDetailBackTooltip => 'Back';

  @override
  String get recDetailExercisesSection => 'Exercise Details';

  @override
  String get recDetailStatTotalSets => 'Total Sets';

  @override
  String get recDetailStatExerciseCount => 'Exercises';

  @override
  String get recDetailStatMuscles => 'Muscles';

  @override
  String get recDetailNone => 'None';

  @override
  String get recDetailAddSet => 'Add Set';

  @override
  String get recDetailTotalVolume => 'Total Volume';

  @override
  String get recDetailAddDataPrompt => 'Tap to add training data';

  @override
  String get recDetailSaved => 'Saved';

  @override
  String recDetailSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get recDetailUnsavedTitle => 'Save changes?';

  @override
  String get recDetailUnsavedBody => 'You have unsaved changes. Save them?';

  @override
  String get recDetailDontSave => 'Don\'t save';

  @override
  String get recDetailUnknownExercise => 'Unknown exercise';

  @override
  String get recDetailUnspecifiedMuscle => 'Unspecified';

  @override
  String get recDetailDeleteButton => 'Delete this record';

  @override
  String get recDetailDeleteTitle => 'Delete record';

  @override
  String get recDetailDeleteBody =>
      'Delete this workout record? This action cannot be undone.';

  @override
  String get recDetailDeleted => 'Deleted';

  @override
  String recDetailDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get recDetailDeleteAction => 'Delete';

  @override
  String get planTitle => 'Training Plans';

  @override
  String get planAiButton => 'AI Plan';

  @override
  String get planTodayPlans => 'Today\'s plans';

  @override
  String plansForDate(String date) {
    return 'Plans for $date';
  }

  @override
  String get planAddButton => '+ Add';

  @override
  String get planRemoveTitle => 'Remove plan';

  @override
  String planRemoveFromDateConfirm(int month, int day, String name) {
    return 'Remove \"$name\" from $month/$day?';
  }

  @override
  String get planRemoveAction => 'Remove';

  @override
  String planRemovedToast(int month, int day, String name) {
    return 'Removed \"$name\" from $month/$day';
  }

  @override
  String get planLibraryButton => '📚 My plan library';

  @override
  String get planEmptyAddToday => 'Add today\'s plan';

  @override
  String planSelectToAddTitle(int month, int day) {
    return 'Select a plan to add to $month/$day';
  }

  @override
  String get planCreateNew => 'Create new plan';

  @override
  String get planLibraryTitle => 'My plan library';

  @override
  String get planEdit => 'Edit';

  @override
  String get planDelete => 'Delete';

  @override
  String planAddedToDateToast(int month, int day, String name) {
    return 'Added \"$name\" to $month/$day';
  }

  @override
  String planAddFailed(String error) {
    return 'Add failed: $error';
  }

  @override
  String get planDeleteTitle => 'Delete plan';

  @override
  String planDeleteConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String planDeletedToast(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String planDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String planDetailTargetMuscles(String muscles) {
    return 'Target muscles: $muscles';
  }

  @override
  String get planDetailExerciseCountUnit => 'exercises';

  @override
  String get planDetailSetsUnit => 'sets';

  @override
  String get planDetailMinutesUnit => 'min';

  @override
  String get planDetailExerciseList => 'Exercise list';

  @override
  String get planDetailNoDetailsSuffix => '(no details)';

  @override
  String planDetailEffectiveSets(int count) {
    return '$count sets';
  }

  @override
  String get planDetailAddToCalendar => 'Add to calendar';

  @override
  String get planDetailStartTraining => 'Start workout';

  @override
  String get exSelectTitle => 'Select exercises';

  @override
  String get exFavoritesChip => 'Favorites';

  @override
  String get exSelectHint => 'Tap an exercise card to select';

  @override
  String get equipmentAll => 'All';

  @override
  String get aiCloseTooltip => 'Close';

  @override
  String get aiTitle => 'AI Plan Generator';

  @override
  String get aiPreviousStep => 'Previous';

  @override
  String get aiStepImportAnalysis => 'Import analysis';

  @override
  String get aiStepPreviewImport => 'Preview import';

  @override
  String get aiStepProfile => 'Profile';

  @override
  String get aiStepGeneratePrompt => 'Generate prompt';

  @override
  String get aiStepPasteJson => 'Paste JSON';

  @override
  String get aiTabNewPlan => 'New plan';

  @override
  String get aiTabImportAnalysis => 'Import analysis';

  @override
  String get aiNewPlanHeading => 'Your training profile';

  @override
  String get aiNewPlanSubheading =>
      'Answer these questions to help the AI design the best plan for you';

  @override
  String get aiQuestionFrequency => 'Weekly frequency';

  @override
  String get aiQuestionDuration => 'Session duration';

  @override
  String get aiQuestionEquipment => 'Available equipment';

  @override
  String aiDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String get aiImportHeading => 'Import AI-analyzed plan';

  @override
  String get aiImportSubheading =>
      'Paste the JSON plan returned by the AI below, then preview and import';

  @override
  String get aiJsonLabel => 'JSON content';

  @override
  String get aiJsonHelper => 'Paste the AI-generated workout plan JSON';

  @override
  String get aiParsing => 'Parsing...';

  @override
  String get aiParseJson => 'Parse JSON';

  @override
  String get aiErrorEmptyJson => 'Please enter JSON content';

  @override
  String get aiErrorInvalidJson =>
      'Could not recognize a valid workout plan JSON. Make sure the AI reply contains a \"days\" array.';

  @override
  String aiErrorParseFailed(String error) {
    return 'JSON parse failed: $error';
  }

  @override
  String get aiGeneratePromptHeading => 'Generate AI prompt';

  @override
  String get aiGeneratePromptSubheading =>
      'Set the start date and generate the prompt, then copy it into an AI app to get the plan';

  @override
  String get aiStartDateLabel => 'Start date';

  @override
  String aiDateDisplay(int year, int month, int day) {
    return '$month/$day/$year';
  }

  @override
  String get aiGeneratePromptButton => 'Generate prompt';

  @override
  String get aiGeneratedPromptLabel => 'Generated prompt';

  @override
  String get aiCopyToClipboard => 'Copy to clipboard';

  @override
  String get aiCopyHint =>
      'Copy this prompt into an AI app (Doubao, Qwen, etc.), then return and paste the JSON';

  @override
  String get aiCopiedToast => 'Copied to clipboard';

  @override
  String get aiPasteJsonHeading => 'Paste the JSON returned by the AI';

  @override
  String get aiPasteJsonSubheading =>
      'Paste the AI-generated JSON into the box below';

  @override
  String get aiPreviewEmpty => 'Parse the JSON first to preview the plan';

  @override
  String get aiPreviewHeading => 'Preview workout plan';

  @override
  String aiPlanNameLabel(String name) {
    return 'Plan name: $name';
  }

  @override
  String get aiImporting => 'Importing...';

  @override
  String get aiConfirmImport => 'Confirm import';

  @override
  String aiMatchSummary(int matched, int candidates, int unmatched) {
    return 'Matched: $matched ✅ | Candidates: $candidates ⚠️ | Unmatched: $unmatched';
  }

  @override
  String get aiDayNameMon => 'Mon';

  @override
  String get aiDayNameTue => 'Tue';

  @override
  String get aiDayNameWed => 'Wed';

  @override
  String get aiDayNameThu => 'Thu';

  @override
  String get aiDayNameFri => 'Fri';

  @override
  String get aiDayNameSat => 'Sat';

  @override
  String get aiDayNameSun => 'Sun';

  @override
  String aiDayTitle(int n, String name) {
    return 'Day $n - $name';
  }

  @override
  String get aiRestDay => 'Rest day';

  @override
  String aiExerciseCountSuffix(int count) {
    return '$count exercises';
  }

  @override
  String aiTargetMusclesLabel(String muscles) {
    return 'Target muscles: $muscles';
  }

  @override
  String aiCandidatesBadge(int count) {
    return '$count candidates';
  }

  @override
  String aiOriginalLabel(String name) {
    return 'Orig: $name';
  }

  @override
  String get aiDecreaseSets => 'Decrease';

  @override
  String get aiIncreaseSets => 'Increase';

  @override
  String get aiSetsUnit => 'sets';

  @override
  String get aiSelectMatchTitle => 'Select matching exercise';

  @override
  String aiSelectMatchSubtitle(String name, int count) {
    return 'AI\'s \"$name\" has $count candidates';
  }

  @override
  String get aiKeepUnmatched => 'Keep as \"no details\"';

  @override
  String get aiImportConfirmTitle => 'Confirm import';

  @override
  String get aiImportConfirmBody =>
      'Import this workout plan? The plan will be added to the calendar.';

  @override
  String get aiImportSuccessToast => 'Workout plan imported successfully!';

  @override
  String aiImportFailedToast(String error) {
    return 'Import failed: $error';
  }

  @override
  String get aiNextPreviewImport => 'Next: preview import';

  @override
  String get aiComplete => 'Done';

  @override
  String get aiNextGeneratePrompt => 'Next: generate prompt';

  @override
  String get aiNextPasteJson => 'Next: paste JSON';

  @override
  String get pfCloseTooltip => 'Close';

  @override
  String get pfCreateTitle => 'Create plan';

  @override
  String get pfEditTitle => 'Edit plan';

  @override
  String get pfStepSelectMuscle => 'Muscles';

  @override
  String get pfStepSelectExercise => 'Exercises';

  @override
  String get pfStepConfirm => 'Confirm';

  @override
  String get pfSelectMuscleHeading => 'Select target muscles';

  @override
  String get pfSelectMuscleSubheading =>
      'Pick the muscle groups this plan will cover (multi-select)';

  @override
  String get pfQuickSelect => 'Quick select';

  @override
  String get pfQuickUpper => 'Upper body';

  @override
  String get pfQuickLower => 'Lower body';

  @override
  String get pfQuickFull => 'Full body';

  @override
  String pfQuickRemovedToast(String muscles) {
    return 'Removed: $muscles';
  }

  @override
  String pfQuickAddedToast(String muscles) {
    return 'Added: $muscles';
  }

  @override
  String get pfSelectExerciseHeading => 'Select exercises';

  @override
  String pfSelectedMusclesLine(String muscles) {
    return 'Selected: $muscles';
  }

  @override
  String get pfNotSelected => 'None';

  @override
  String get pfSelectedExercisesHeading => 'Selected exercises';

  @override
  String get pfClearSelectedTitle => 'Clear selected exercises?';

  @override
  String get pfClearSelectedBody =>
      'Clear all selected exercises? This action cannot be undone.';

  @override
  String get pfNoDetailsSuffix => '(no details)';

  @override
  String pfSetsSuffix(int count) {
    return '($count sets)';
  }

  @override
  String get pfContinueAdding => 'Add more exercises';

  @override
  String pfSelectedCountLine(int count) {
    return '$count exercises selected';
  }

  @override
  String get pfConfirmHeading => 'Confirm plan';

  @override
  String get pfPlanNameLabel => 'Plan name';

  @override
  String get pfPlanNameHint => 'e.g. Upper body day';

  @override
  String get pfSummaryHeading => 'Plan summary';

  @override
  String get pfSummaryMuscles => 'Muscles';

  @override
  String get pfSummaryExerciseCount => 'Exercises';

  @override
  String pfExerciseCountValue(int count) {
    return '$count';
  }

  @override
  String get pfSummaryTotalSets => 'Total sets';

  @override
  String pfTotalSetsValue(int count) {
    return '$count sets';
  }

  @override
  String get pfSummaryDuration => 'Est. duration';

  @override
  String pfDurationValue(int count) {
    return '~$count min';
  }

  @override
  String get pfDurationFootnote =>
      '※ Estimated = total sets × 2.5 min (incl. rest)';

  @override
  String get pfAdjustSetsHeading => 'Adjust sets (drag to reorder)';

  @override
  String get pfDecreaseSets => 'Decrease sets';

  @override
  String get pfIncreaseSets => 'Increase sets';

  @override
  String get pfDeleteExercise => 'Remove exercise';

  @override
  String get pfNextSelectExercise => 'Next: select exercises';

  @override
  String get pfNextConfirm => 'Next: confirm plan';

  @override
  String get pfSaveChanges => 'Save changes';

  @override
  String get pfPreviousStep => 'Previous';

  @override
  String get pfDefaultPlanName => 'Workout plan';

  @override
  String pfSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get pfDiscardTitle => 'Discard edits?';

  @override
  String get pfDiscardBody => 'You have unsaved changes. Exit anyway?';

  @override
  String get pfKeepEditing => 'Keep editing';

  @override
  String get pfDiscard => 'Discard';

  @override
  String get anTitle => 'AI Workout Analysis';

  @override
  String get anInstructionsHeading => 'Instructions';

  @override
  String get anInstruction1 => '1. Review the workout data report below';

  @override
  String get anInstruction2 => '2. Copy the generated prompt';

  @override
  String get anInstruction3 =>
      '3. Paste it into ChatGPT / Doubao / Qwen or another AI';

  @override
  String get anInstruction4 => '4. The AI returns analysis and a JSON plan';

  @override
  String get anInstruction5 =>
      '5. Go to the \"Plans\" page → \"Import analysis\" to import the plan';

  @override
  String get anReportHeading => 'Workout data report';

  @override
  String get anPromptHeading => 'Generated prompt';

  @override
  String get anGeneratingPrompt => 'Generating prompt...';

  @override
  String get anCopiedToast => 'Prompt copied to clipboard';

  @override
  String get anCopiedLabel => 'Copied';

  @override
  String get anCopyPrompt => 'Copy prompt';

  @override
  String get anCloseTooltip => 'Close';

  @override
  String get anBasicInfo => 'Basic info';

  @override
  String anSessionsAndDays(int sessions, int days) {
    return '$sessions sessions / $days days';
  }

  @override
  String get anSessionCount => 'Sessions';

  @override
  String get anTotalVolume => 'Total volume';

  @override
  String get anDensity => 'Density';

  @override
  String anDensityValue(String value) {
    return '$value sets/min';
  }

  @override
  String get anAvgPerSession => 'Avg per session';

  @override
  String anAvgPerSessionValue(String volume, int minutes) {
    return '$volume kg / $minutes min';
  }

  @override
  String get anTrendWeek => 'Trend (vs last week)';

  @override
  String get anTrendMonth => 'Trend (vs last month)';

  @override
  String get anMuscleDistribution => 'Muscle volume distribution';

  @override
  String get anSetsPerMuscleWeek => 'Sets per muscle (MEV ref: 10 sets/week)';

  @override
  String get anSetsPerMuscleMonth => 'Sets per muscle (MEV ref: 40 sets/month)';

  @override
  String get anEstimated1rm => 'Estimated 1RM (Mayhew)';

  @override
  String get an1rmProgression => 'Estimated 1RM progression';

  @override
  String get anRecovery => 'Recovery status';

  @override
  String get anNoMuscleData => '- No muscle training data';

  @override
  String get anNoTrendData => '- No trend data';

  @override
  String get anNoSetsData => '- No sets data';

  @override
  String get anNo1rmData =>
      '- No 1RM data (requires per-set weight and rep records)';

  @override
  String get anNo1rmTrendData => '- No 1RM trend data';

  @override
  String get anNoProgressData =>
      '- Each exercise was trained only once this period; cannot compute progression';

  @override
  String get anNoRecoveryData => '- No recovery data';

  @override
  String get anNoMuscleRecoveryData => '- No muscle recovery data';

  @override
  String anMevWeekLabel(int count) {
    return 'Weekly MEV ref: $count sets';
  }

  @override
  String anMevMonthLabel(int count) {
    return 'Monthly MEV ref: $count sets';
  }

  @override
  String get anStatusSufficient => '✅ Sufficient';

  @override
  String get anStatusLow => '⚠️ Low';

  @override
  String get anStatusInsufficient => '🔴 Insufficient';

  @override
  String get anMayhewNote => '  (Estimated via Mayhew formula, ±5-8 kg error)';

  @override
  String get anRecoveryTrainable => '✅ Ready to train';

  @override
  String anRecoveryRestMore(int days) {
    return '⚠️ Rest $days more day(s)';
  }

  @override
  String get anRecoveryJustTrained => '🔴 Trained today';

  @override
  String get anPeriodWeek => 'This week';

  @override
  String get anPeriodMonth => 'This month';

  @override
  String get anWeek => 'week';

  @override
  String get anMonth => 'month';

  @override
  String get anGoalMuscleBuilding => 'Muscle building';

  @override
  String get anGoalFatLoss => 'Fat loss';

  @override
  String get anGoalStrength => 'Strength';

  @override
  String get anGoalEndurance => 'Endurance';

  @override
  String anDateRange(int startMonth, int startDay, int endMonth, int endDay) {
    return '$startMonth/$startDay - $endMonth/$endDay';
  }

  @override
  String get anPromptOpening =>
      'You are a professional fitness coach. Based on my training data report, design my training plan for the next cycle.';

  @override
  String get anPromptWeekNote =>
      'Weekly data is limited; focus on recovery status and next week\'s muscle rotation.';

  @override
  String get anPromptMonthNote =>
      'Monthly data is rich; focus on progressive overload trends and balanced muscle volume allocation.';

  @override
  String get anPromptReportHeader => '## Workout Data Report';

  @override
  String get anPromptBasicInfoHeader => '### Basic Info';

  @override
  String anPromptPeriod(String period, String range) {
    return '- Period: $period ($range)';
  }

  @override
  String anPromptSessions(int sessions, int days) {
    return '- Sessions: $sessions / $days days';
  }

  @override
  String anPromptTotalVolume(String volume) {
    return '- Total volume: $volume kg (sets×reps×weight)';
  }

  @override
  String anPromptDensity(String value) {
    return '- Density: $value sets/min';
  }

  @override
  String anPromptTrendHeader(String period) {
    return '### Trend (vs last $period)';
  }

  @override
  String get anPromptMuscleDistHeader => '### Muscle Volume Distribution';

  @override
  String get anPromptSetsPerMuscleHeader => '### Sets Per Muscle Group';

  @override
  String get anPrompt1rmHeader =>
      '### Estimated 1RM (best this period, TOP 10)';

  @override
  String get anPrompt1rmProgressionHeader => '### Estimated 1RM Progression';

  @override
  String get anPromptRecoveryHeader =>
      '### Recovery Status (as of today, global data)';

  @override
  String get anPromptProfileHeader => '## User Profile';

  @override
  String anPromptGoal(String goal) {
    return '- Goal: $goal';
  }

  @override
  String anPromptExperience(String experience) {
    return '- Experience: $experience';
  }

  @override
  String anPromptFrequency(int frequency) {
    return '- Weekly frequency: $frequency days';
  }

  @override
  String anPromptEquipment(String equipment) {
    return '- Equipment: $equipment';
  }

  @override
  String anPromptFocusAreas(String areas) {
    return '- Focus areas: $areas';
  }

  @override
  String get anPromptOutputHeader => '## Output Format';

  @override
  String get anPromptOutputIntro => 'Reply in two parts:';

  @override
  String get anPromptOutputPart1 => '**Part 1: Plan design rationale**';

  @override
  String get anPromptOutputPart1Detail =>
      'Based on my training data report, explain in detail why you designed the next cycle this way, including:';

  @override
  String anPromptOutputSplit(int days) {
    return '- Split rationale (given my $days-day weekly frequency)';
  }

  @override
  String get anPromptOutputComparison =>
      '- Comparison with this cycle\'s data (which muscles are under-trained and need more, which are over-trained and need recovery)';

  @override
  String get anPromptOutputSelection =>
      '- Exercise selection logic and volume allocation for each training day';

  @override
  String get anPromptOutputOverload =>
      '- Specific progressive overload advice (weight, sets, frequency adjustments)';

  @override
  String get anPromptOutputPart2 => '**Part 2: Workout Plan JSON**';

  @override
  String get anPromptOutputJson =>
      'After the analysis, provide a structured workout plan in a ```json block:';

  @override
  String get anPromptNamingHeader => '## Exercise Naming';

  @override
  String get anPromptNamingIntro => 'Use standard English exercise names:';

  @override
  String get anPromptNamingClosing =>
      'If unsure of the exact name, use standard terminology.';

  @override
  String get anPromptClosing =>
      'Explain your design rationale and analysis first, then generate the workout plan.';

  @override
  String anPromptVolumeTrendWithChange(
    String volume,
    String sign,
    int change,
    String arrow,
  ) {
    return '  - Total volume: $volume ($sign$change% $arrow)';
  }

  @override
  String anPromptVolumeTrendNew(String volume) {
    return '  - Total volume: $volume (new period)';
  }

  @override
  String anPromptFreqTrend(int days, int diff, String arrow) {
    return '  - Frequency: $days days ($diff$arrow)';
  }

  @override
  String anPromptMuscleTrend(
    String muscle,
    String sign,
    int change,
    String arrow,
  ) {
    return '  - $muscle: $sign$change% $arrow';
  }

  @override
  String anPromptMuscleDistLine(
    int index,
    String muscle,
    String volume,
    String pct,
  ) {
    return '  $index. $muscle: $volume kg ($pct%)';
  }

  @override
  String anPromptSetsLine(String muscle, int sets, String status) {
    return '  - $muscle: $sets sets $status';
  }

  @override
  String anPrompt1rmLine(String name, String e1rm, String weight, int reps) {
    return '  - $name: ~$e1rm kg (from ${weight}kg×$reps)';
  }

  @override
  String anPrompt1rmProgressLine(
    String name,
    String from,
    String to,
    String sign,
    String change,
    String arrow,
    String weeks,
  ) {
    return '  - $name: $from → $to kg ($sign$change% $arrow$weeks)';
  }

  @override
  String anPrompt1rmWeeksSuffix(String weeks) {
    return ' / ${weeks}w';
  }

  @override
  String anPromptRecoveryLine(String muscle, int days, String status) {
    return '  - $muscle: rested $days day(s) $status';
  }
}
