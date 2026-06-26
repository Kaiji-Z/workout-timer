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

  /// No description provided for @oemSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'厂商后台管理'**
  String get oemSectionTitle;

  /// No description provided for @oemCardTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name}手机省电管理'**
  String oemCardTitle(String name);

  /// No description provided for @oemExplanation.
  ///
  /// In zh, this message translates to:
  /// **'您的{name}手机有独立的省电管理，标准电池优化白名单可能不够。请点击下方按钮，在打开的设置页面中允许本应用自启动/后台运行。'**
  String oemExplanation(String name);

  /// No description provided for @oemFlowHint.
  ///
  /// In zh, this message translates to:
  /// **'提示：请先完成上方「允许后台活动」（标准白名单），再进行下方的厂商专属设置，两者配合才能确保后台计时正常。'**
  String get oemFlowHint;

  /// No description provided for @oemGoButton.
  ///
  /// In zh, this message translates to:
  /// **'前往{name}设置'**
  String oemGoButton(String name);

  /// No description provided for @oemDefaultInstruction.
  ///
  /// In zh, this message translates to:
  /// **'请在系统设置中允许本应用自启动和后台运行'**
  String get oemDefaultInstruction;

  /// No description provided for @unitMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{m}分钟'**
  String unitMinutes(int m);

  /// No description provided for @unitMinutesSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{m}分{s}秒'**
  String unitMinutesSeconds(int m, int s);

  /// No description provided for @unitSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{s}秒'**
  String unitSeconds(int s);

  /// No description provided for @unitRepsRange.
  ///
  /// In zh, this message translates to:
  /// **'{min}-{max}次'**
  String unitRepsRange(int min, int max);

  /// No description provided for @levelBeginner.
  ///
  /// In zh, this message translates to:
  /// **'初级'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In zh, this message translates to:
  /// **'中级'**
  String get levelIntermediate;

  /// No description provided for @levelExpert.
  ///
  /// In zh, this message translates to:
  /// **'高级'**
  String get levelExpert;

  /// No description provided for @equipmentBarbell.
  ///
  /// In zh, this message translates to:
  /// **'杠铃'**
  String get equipmentBarbell;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In zh, this message translates to:
  /// **'哑铃'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In zh, this message translates to:
  /// **'自重'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentCable.
  ///
  /// In zh, this message translates to:
  /// **'绳索'**
  String get equipmentCable;

  /// No description provided for @equipmentMachine.
  ///
  /// In zh, this message translates to:
  /// **'器械'**
  String get equipmentMachine;

  /// No description provided for @equipmentKettlebells.
  ///
  /// In zh, this message translates to:
  /// **'壶铃'**
  String get equipmentKettlebells;

  /// No description provided for @equipmentBands.
  ///
  /// In zh, this message translates to:
  /// **'弹力带'**
  String get equipmentBands;

  /// No description provided for @equipmentMedicineBall.
  ///
  /// In zh, this message translates to:
  /// **'药球'**
  String get equipmentMedicineBall;

  /// No description provided for @equipmentEzBarbell.
  ///
  /// In zh, this message translates to:
  /// **'曲杆杠铃'**
  String get equipmentEzBarbell;

  /// No description provided for @equipmentSmithMachine.
  ///
  /// In zh, this message translates to:
  /// **'史密斯机'**
  String get equipmentSmithMachine;

  /// No description provided for @errorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get errorGeneric;

  /// 分享备份文件时的文本
  ///
  /// In zh, this message translates to:
  /// **'撸铁计时器数据备份'**
  String get dataTransferShareText;

  /// Web 平台不支持导入时抛出的错误
  ///
  /// In zh, this message translates to:
  /// **'Web 平台暂不支持文件导入'**
  String get dataTransferWebUnsupported;

  /// 备份文件格式无效时抛出的错误
  ///
  /// In zh, this message translates to:
  /// **'无效的备份文件格式'**
  String get dataTransferInvalidFormat;

  /// AI 提示词中的输出格式说明（第一部分设计思路 + 第二部分 JSON）
  ///
  /// In zh, this message translates to:
  /// **'请按以下两部分输出你的回复：\n\n**第一部分：计划设计说明**\n\n详细说明你为什么这样设计这个训练计划，包括：\n- 分化方式的选择理由（如推/拉/腿、上下肢、全身等，结合我的训练频率 {frequency} 天/周）\n- 每个训练日的动作选择逻辑（为什么选这些动作，复合/孤立的搭配原则）\n- 容量分配依据（每个肌群每周的训练组数，如何匹配我的目标 {goal}）\n- 与我的经验水平 {experience} 和器材条件 {equipment} 的适配考虑\n\n**第二部分：训练计划 JSON**\n\n在分析之后，用 ```json 代码块提供结构化训练计划：'**
  String aiPromptOutputInstructions(
    int frequency,
    String goal,
    String experience,
    String equipment,
  );

  /// AI 提示词的结尾指令
  ///
  /// In zh, this message translates to:
  /// **'请根据以上信息（训练频率 {frequency} 天/周），先解释你的设计思路，然后生成训练计划。'**
  String aiPromptClosing(int frequency);

  /// No description provided for @dialogSetTitle.
  ///
  /// In zh, this message translates to:
  /// **'第{set}组'**
  String dialogSetTitle(int set);

  /// No description provided for @dialogSetTitleWithName.
  ///
  /// In zh, this message translates to:
  /// **'第{set}组 - {name}'**
  String dialogSetTitleWithName(int set, String name);

  /// No description provided for @repsWithValue.
  ///
  /// In zh, this message translates to:
  /// **'{reps} 次'**
  String repsWithValue(int reps);

  /// No description provided for @bodyweightReference.
  ///
  /// In zh, this message translates to:
  /// **'体重 {bw}kg × {pct}% = {result}kg'**
  String bodyweightReference(String bw, String pct, String result);

  /// No description provided for @trainingSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String trainingSaveFailed(String error);

  /// No description provided for @calDayHasPlan.
  ///
  /// In zh, this message translates to:
  /// **'有训练计划'**
  String get calDayHasPlan;

  /// No description provided for @calDayToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get calDayToday;

  /// No description provided for @calDaySelected.
  ///
  /// In zh, this message translates to:
  /// **'已选中'**
  String get calDaySelected;

  /// No description provided for @calDaySemantics.
  ///
  /// In zh, this message translates to:
  /// **'{date}，{plan}{today}{selected}'**
  String calDaySemantics(
    String date,
    String plan,
    String today,
    String selected,
  );

  /// No description provided for @widgetSearchExercise.
  ///
  /// In zh, this message translates to:
  /// **'搜索动作'**
  String get widgetSearchExercise;

  /// No description provided for @widgetClearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索'**
  String get widgetClearSearch;

  /// No description provided for @widgetAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get widgetAll;

  /// No description provided for @widgetNoExerciseFound.
  ///
  /// In zh, this message translates to:
  /// **'没有找到动作'**
  String get widgetNoExerciseFound;

  /// No description provided for @widgetSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 个动作'**
  String widgetSelectedCount(int count);

  /// No description provided for @widgetClearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get widgetClearAll;

  /// No description provided for @widgetSetsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'{n}组'**
  String widgetSetsSuffix(int n);

  /// No description provided for @widgetPlanExercisesCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个动作'**
  String widgetPlanExercisesCount(int n);

  /// No description provided for @widgetPlanSetsCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 组'**
  String widgetPlanSetsCount(int n);

  /// No description provided for @widgetPlanDuration.
  ///
  /// In zh, this message translates to:
  /// **'~{n} 分钟'**
  String widgetPlanDuration(int n);

  /// No description provided for @widgetPlanSummaryShort.
  ///
  /// In zh, this message translates to:
  /// **'{exerciseCount}动作 · {totalSets}组'**
  String widgetPlanSummaryShort(int exerciseCount, int totalSets);

  /// No description provided for @widgetCurrentExercise.
  ///
  /// In zh, this message translates to:
  /// **'当前：{name} 第{set}/{total}组'**
  String widgetCurrentExercise(String name, int set, int total);

  /// No description provided for @widgetExerciseProgressHeader.
  ///
  /// In zh, this message translates to:
  /// **'{plan} · {exercise} 第{set}组'**
  String widgetExerciseProgressHeader(String plan, String exercise, int set);

  /// No description provided for @widgetNoDetail.
  ///
  /// In zh, this message translates to:
  /// **'{name} (无详情)'**
  String widgetNoDetail(String name);

  /// No description provided for @widgetSwitchNextExercise.
  ///
  /// In zh, this message translates to:
  /// **'切换下一动作'**
  String get widgetSwitchNextExercise;

  /// No description provided for @widgetEmptyPlanTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有计划'**
  String get widgetEmptyPlanTitle;

  /// No description provided for @widgetEmptyPlanSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点击创建你的第一个训练计划'**
  String get widgetEmptyPlanSubtitle;

  /// No description provided for @widgetProgressSummary.
  ///
  /// In zh, this message translates to:
  /// **'{name} · {current}/{total}组'**
  String widgetProgressSummary(String name, int current, int total);

  /// No description provided for @widgetSelectMuscleTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择训练部位'**
  String get widgetSelectMuscleTitle;

  /// No description provided for @widgetNoDailyData.
  ///
  /// In zh, this message translates to:
  /// **'暂无每日训练量数据'**
  String get widgetNoDailyData;

  /// No description provided for @widgetTrainingComplete.
  ///
  /// In zh, this message translates to:
  /// **'训练完成'**
  String get widgetTrainingComplete;

  /// No description provided for @widgetImageLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get widgetImageLoadFailed;

  /// No description provided for @widgetTapToClose.
  ///
  /// In zh, this message translates to:
  /// **'点击任意位置关闭'**
  String get widgetTapToClose;

  /// No description provided for @widgetClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get widgetClose;

  /// No description provided for @widgetSetRestDuration.
  ///
  /// In zh, this message translates to:
  /// **'设置休息时长'**
  String get widgetSetRestDuration;

  /// No description provided for @widgetRestMinDuration.
  ///
  /// In zh, this message translates to:
  /// **'休息时长至少需要10秒'**
  String get widgetRestMinDuration;

  /// No description provided for @widgetMinuteSuffix.
  ///
  /// In zh, this message translates to:
  /// **'分'**
  String get widgetMinuteSuffix;

  /// No description provided for @widgetSecondSuffix.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get widgetSecondSuffix;

  /// No description provided for @widgetCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get widgetCancel;

  /// No description provided for @widgetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get widgetConfirm;

  /// No description provided for @widgetSelectedDuration.
  ///
  /// In zh, this message translates to:
  /// **'已选择: {duration}'**
  String widgetSelectedDuration(String duration);

  /// No description provided for @widgetConfirmButton.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get widgetConfirmButton;

  /// No description provided for @widgetSearchExerciseHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索动作...'**
  String get widgetSearchExerciseHint;

  /// No description provided for @widgetInvolvedMuscles.
  ///
  /// In zh, this message translates to:
  /// **'涉及部位'**
  String get widgetInvolvedMuscles;

  /// No description provided for @widgetRemoveFromPlan.
  ///
  /// In zh, this message translates to:
  /// **'从计划中移除'**
  String get widgetRemoveFromPlan;

  /// No description provided for @widgetAddToPlan.
  ///
  /// In zh, this message translates to:
  /// **'添加到计划'**
  String get widgetAddToPlan;

  /// No description provided for @widgetImageStepIndicator.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} 步 / 共 {total} 步'**
  String widgetImageStepIndicator(int current, int total);

  /// No description provided for @widgetExerciseInstructions.
  ///
  /// In zh, this message translates to:
  /// **'动作指导'**
  String get widgetExerciseInstructions;

  /// No description provided for @widgetRecommendedConfig.
  ///
  /// In zh, this message translates to:
  /// **'推荐配置'**
  String get widgetRecommendedConfig;

  /// No description provided for @widgetRecommendedSets.
  ///
  /// In zh, this message translates to:
  /// **'推荐组数'**
  String get widgetRecommendedSets;

  /// No description provided for @widgetRecommendedSetsValue.
  ///
  /// In zh, this message translates to:
  /// **'{n} 组'**
  String widgetRecommendedSetsValue(int n);

  /// No description provided for @widgetRepsRangeLabel.
  ///
  /// In zh, this message translates to:
  /// **'次数范围'**
  String get widgetRepsRangeLabel;

  /// No description provided for @widgetRestLabel.
  ///
  /// In zh, this message translates to:
  /// **'组间休息'**
  String get widgetRestLabel;
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
