import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'撸铁计时器'**
  String get appTitle;

  /// No description provided for @navPlans.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get navPlans;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get navHistory;

  /// No description provided for @navStats.
  ///
  /// In zh, this message translates to:
  /// **'训练统计'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @navTimer.
  ///
  /// In zh, this message translates to:
  /// **'训练计时器'**
  String get navTimer;

  /// No description provided for @timerSecondsRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {seconds} 秒'**
  String timerSecondsRemaining(int seconds);

  /// No description provided for @timerInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get timerInProgress;

  /// No description provided for @timerReady.
  ///
  /// In zh, this message translates to:
  /// **'准备就绪'**
  String get timerReady;

  /// No description provided for @timerCompletedSets.
  ///
  /// In zh, this message translates to:
  /// **'完成组数'**
  String get timerCompletedSets;

  /// No description provided for @timerReset.
  ///
  /// In zh, this message translates to:
  /// **'重置计时器'**
  String get timerReset;

  /// No description provided for @timerPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get timerPause;

  /// No description provided for @timerStart.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get timerStart;

  /// No description provided for @timerSkipSet.
  ///
  /// In zh, this message translates to:
  /// **'跳过当前组'**
  String get timerSkipSet;

  /// No description provided for @timerSecondsLabel.
  ///
  /// In zh, this message translates to:
  /// **'{seconds}秒'**
  String timerSecondsLabel(int seconds);

  /// No description provided for @trainingNextExercise.
  ///
  /// In zh, this message translates to:
  /// **'下一个：{name}'**
  String trainingNextExercise(String name);

  /// No description provided for @trainingNextDone.
  ///
  /// In zh, this message translates to:
  /// **'下一个：训练完成'**
  String get trainingNextDone;

  /// No description provided for @trainingRestCountdown.
  ///
  /// In zh, this message translates to:
  /// **'休息倒计时'**
  String get trainingRestCountdown;

  /// No description provided for @trainingExercising.
  ///
  /// In zh, this message translates to:
  /// **'运动中'**
  String get trainingExercising;

  /// No description provided for @trainingRestDuration.
  ///
  /// In zh, this message translates to:
  /// **'休息时长'**
  String get trainingRestDuration;

  /// No description provided for @trainingExerciseProgress.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 第{set}组 · 运动'**
  String trainingExerciseProgress(String name, int set);

  /// No description provided for @trainingSetExercising.
  ///
  /// In zh, this message translates to:
  /// **'第 {set} 组 · 运动中'**
  String trainingSetExercising(int set);

  /// No description provided for @trainingExerciseRest.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 已完成{set}组 · 休息中'**
  String trainingExerciseRest(String name, int set);

  /// No description provided for @trainingSetRest.
  ///
  /// In zh, this message translates to:
  /// **'第 {set} 组 · 休息中'**
  String trainingSetRest(int set);

  /// No description provided for @trainingCompleted.
  ///
  /// In zh, this message translates to:
  /// **'训练完成'**
  String get trainingCompleted;

  /// No description provided for @trainingSetPaused.
  ///
  /// In zh, this message translates to:
  /// **'第 {set} 组 · 已暂停'**
  String trainingSetPaused(int set);

  /// No description provided for @trainingPlanReady.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 准备开始'**
  String trainingPlanReady(String name);

  /// No description provided for @trainingReady.
  ///
  /// In zh, this message translates to:
  /// **'准备开始'**
  String get trainingReady;

  /// No description provided for @trainingSetCount.
  ///
  /// In zh, this message translates to:
  /// **'{set} 组'**
  String trainingSetCount(int set);

  /// No description provided for @trainingStartExercise.
  ///
  /// In zh, this message translates to:
  /// **'开始运动'**
  String get trainingStartExercise;

  /// No description provided for @trainingRest.
  ///
  /// In zh, this message translates to:
  /// **'休息'**
  String get trainingRest;

  /// No description provided for @trainingContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get trainingContinue;

  /// No description provided for @trainingSkipRest.
  ///
  /// In zh, this message translates to:
  /// **'跳过休息'**
  String get trainingSkipRest;

  /// No description provided for @trainingSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get trainingSave;

  /// No description provided for @trainingNoPlan.
  ///
  /// In zh, this message translates to:
  /// **'还没有计划，请先创建计划'**
  String get trainingNoPlan;

  /// No description provided for @trainingSelectPlan.
  ///
  /// In zh, this message translates to:
  /// **'选择训练计划'**
  String get trainingSelectPlan;

  /// No description provided for @trainingCancelPlan.
  ///
  /// In zh, this message translates to:
  /// **'取消计划'**
  String get trainingCancelPlan;

  /// No description provided for @trainingPlanSummary.
  ///
  /// In zh, this message translates to:
  /// **'{exerciseCount}动作 · {totalSets}组'**
  String trainingPlanSummary(int exerciseCount, int totalSets);

  /// No description provided for @trainingSavedDetail.
  ///
  /// In zh, this message translates to:
  /// **'训练已保存：{sets}组，总时长 {duration}'**
  String trainingSavedDetail(int sets, String duration);

  /// No description provided for @trainingSavedCompleted.
  ///
  /// In zh, this message translates to:
  /// **'训练已保存：完成{sets}组，总时长 {duration}'**
  String trainingSavedCompleted(int sets, String duration);

  /// No description provided for @notifNextSet.
  ///
  /// In zh, this message translates to:
  /// **'准备开始下一组！'**
  String get notifNextSet;

  /// No description provided for @notifRestDone.
  ///
  /// In zh, this message translates to:
  /// **'休息结束！'**
  String get notifRestDone;

  /// No description provided for @soundDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get soundDefault;

  /// No description provided for @soundBeep.
  ///
  /// In zh, this message translates to:
  /// **'哔声'**
  String get soundBeep;

  /// No description provided for @soundRing.
  ///
  /// In zh, this message translates to:
  /// **'铃声'**
  String get soundRing;

  /// No description provided for @soundChime.
  ///
  /// In zh, this message translates to:
  /// **'钟声'**
  String get soundChime;

  /// No description provided for @soundWhistle.
  ///
  /// In zh, this message translates to:
  /// **'哨声'**
  String get soundWhistle;

  /// No description provided for @recReps.
  ///
  /// In zh, this message translates to:
  /// **'次数'**
  String get recReps;

  /// No description provided for @recSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get recSkip;

  /// No description provided for @recSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get recSave;

  /// No description provided for @recWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'重量 (kg)'**
  String get recWeightKg;

  /// No description provided for @recAddedWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'附加重量 (kg)'**
  String get recAddedWeightKg;

  /// No description provided for @recBodyweightOnly.
  ///
  /// In zh, this message translates to:
  /// **'0 = 纯自重'**
  String get recBodyweightOnly;

  /// No description provided for @recInvalidInput.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的重量和次数'**
  String get recInvalidInput;

  /// No description provided for @recRecordData.
  ///
  /// In zh, this message translates to:
  /// **'记录训练数据'**
  String get recRecordData;

  /// No description provided for @recScrollHint.
  ///
  /// In zh, this message translates to:
  /// **'滚动选择次数，输入重量'**
  String get recScrollHint;

  /// No description provided for @recAdded.
  ///
  /// In zh, this message translates to:
  /// **'附加'**
  String get recAdded;

  /// No description provided for @calPrevMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get calPrevMonth;

  /// No description provided for @calNextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下个月'**
  String get calNextMonth;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
