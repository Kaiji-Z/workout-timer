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

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In zh, this message translates to:
  /// **'外观设置'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsDarkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get settingsDarkMode;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// No description provided for @settingsSelectTheme.
  ///
  /// In zh, this message translates to:
  /// **'选择主题'**
  String get settingsSelectTheme;

  /// No description provided for @settingsNotificationSection.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get settingsNotificationSection;

  /// No description provided for @settingsEnableSound.
  ///
  /// In zh, this message translates to:
  /// **'启用声音'**
  String get settingsEnableSound;

  /// No description provided for @settingsNotificationRingtone.
  ///
  /// In zh, this message translates to:
  /// **'通知铃声'**
  String get settingsNotificationRingtone;

  /// No description provided for @settingsEnableVibration.
  ///
  /// In zh, this message translates to:
  /// **'启用振动'**
  String get settingsEnableVibration;

  /// No description provided for @settingsDetailedRecording.
  ///
  /// In zh, this message translates to:
  /// **'详细记录模式'**
  String get settingsDetailedRecording;

  /// No description provided for @settingsSelectRingtone.
  ///
  /// In zh, this message translates to:
  /// **'选择铃声'**
  String get settingsSelectRingtone;

  /// No description provided for @settingsClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get settingsClose;

  /// No description provided for @settingsCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get settingsCancel;

  /// No description provided for @settingsClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get settingsClear;

  /// No description provided for @settingsCustomMessageDefault.
  ///
  /// In zh, this message translates to:
  /// **'准备开始下一组！'**
  String get settingsCustomMessageDefault;

  /// No description provided for @settingsCustomMessageSection.
  ///
  /// In zh, this message translates to:
  /// **'自定义提醒消息'**
  String get settingsCustomMessageSection;

  /// No description provided for @settingsCustomMessageHint.
  ///
  /// In zh, this message translates to:
  /// **'输入提醒消息'**
  String get settingsCustomMessageHint;

  /// No description provided for @settingsBackgroundSection.
  ///
  /// In zh, this message translates to:
  /// **'后台运行'**
  String get settingsBackgroundSection;

  /// No description provided for @settingsAllowBackground.
  ///
  /// In zh, this message translates to:
  /// **'允许后台活动'**
  String get settingsAllowBackground;

  /// No description provided for @settingsBackgroundAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许，计时器可在后台正常运行'**
  String get settingsBackgroundAllowed;

  /// No description provided for @settingsBackgroundNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'未允许，后台计时器可能被系统暂停'**
  String get settingsBackgroundNotAllowed;

  /// No description provided for @settingsBackgroundHint.
  ///
  /// In zh, this message translates to:
  /// **'点击上方选项，在弹出的系统对话框中选择\"允许\"，以确保计时器在后台正常运行'**
  String get settingsBackgroundHint;

  /// No description provided for @settingsDataSection.
  ///
  /// In zh, this message translates to:
  /// **'数据管理'**
  String get settingsDataSection;

  /// No description provided for @settingsExportData.
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get settingsExportData;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'导出全部训练记录、计划等数据为文件'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportData.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get settingsImportData;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从备份文件恢复全部数据（会覆盖现有数据）'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsClearHistory.
  ///
  /// In zh, this message translates to:
  /// **'清除所有历史记录'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清除'**
  String get settingsClearHistoryConfirmTitle;

  /// No description provided for @settingsClearHistoryConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有历史记录吗？此操作不可撤销。'**
  String get settingsClearHistoryConfirmBody;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In zh, this message translates to:
  /// **'历史记录已清除'**
  String get settingsHistoryCleared;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get settingsExport;

  /// No description provided for @settingsExportConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'将导出全部训练记录、计划、练习等数据。\n\n文件会保存到手机 Downloads 目录，同时弹出分享面板。'**
  String get settingsExportConfirmBody;

  /// No description provided for @settingsExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsImportConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get settingsImportConfirmTitle;

  /// No description provided for @settingsImportConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 导入将覆盖现有全部数据！\n\n将恢复来自：\n{source}'**
  String settingsImportConfirmBody(String source);

  /// No description provided for @settingsConfirmImport.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get settingsConfirmImport;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入成功，共恢复 {count} 条记录'**
  String settingsImportSuccess(int count);

  /// No description provided for @settingsImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsFoundLocalBackups.
  ///
  /// In zh, this message translates to:
  /// **'发现本地备份'**
  String get settingsFoundLocalBackups;

  /// No description provided for @settingsSelectManually.
  ///
  /// In zh, this message translates to:
  /// **'手动选择文件'**
  String get settingsSelectManually;

  /// No description provided for @settingsSelectManuallySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从其他位置选择 JSON 备份文件'**
  String get settingsSelectManuallySubtitle;

  /// No description provided for @settingsAiPreferencesSection.
  ///
  /// In zh, this message translates to:
  /// **'AI 训练偏好'**
  String get settingsAiPreferencesSection;

  /// No description provided for @settingsTrainingPreferences.
  ///
  /// In zh, this message translates to:
  /// **'训练偏好'**
  String get settingsTrainingPreferences;

  /// No description provided for @settingsTrainingPreferencesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设置训练目标、经验水平等，AI功能将自动读取'**
  String get settingsTrainingPreferencesSubtitle;

  /// No description provided for @settingsAboutSection.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAboutSection;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看本应用的隐私政策'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsVersion;

  /// No description provided for @settingsBackupPrefix.
  ///
  /// In zh, this message translates to:
  /// **'备份'**
  String get settingsBackupPrefix;

  /// No description provided for @settingsVersionLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get settingsVersionLoading;

  /// No description provided for @settingsDeveloper.
  ///
  /// In zh, this message translates to:
  /// **'开发者'**
  String get settingsDeveloper;

  /// No description provided for @settingsDeveloperName.
  ///
  /// In zh, this message translates to:
  /// **'深圳市露凯文化传播有限公司'**
  String get settingsDeveloperName;

  /// No description provided for @settingsContactEmail.
  ///
  /// In zh, this message translates to:
  /// **'联系邮箱'**
  String get settingsContactEmail;

  /// No description provided for @settingsEmailCopied.
  ///
  /// In zh, this message translates to:
  /// **'邮箱已复制'**
  String get settingsEmailCopied;

  /// No description provided for @settingsPrivacyHeadline.
  ///
  /// In zh, this message translates to:
  /// **'撸铁计时器不收集任何个人信息'**
  String get settingsPrivacyHeadline;

  /// No description provided for @settingsPrivacyDataStorage.
  ///
  /// In zh, this message translates to:
  /// **'数据存储'**
  String get settingsPrivacyDataStorage;

  /// No description provided for @settingsPrivacyDataStorageBody.
  ///
  /// In zh, this message translates to:
  /// **'所有训练数据均存储在您的设备本地（SQLite 数据库），不上传至任何服务器。卸载应用将永久删除所有数据。'**
  String get settingsPrivacyDataStorageBody;

  /// No description provided for @settingsPrivacyPermissions.
  ///
  /// In zh, this message translates to:
  /// **'设备权限'**
  String get settingsPrivacyPermissions;

  /// No description provided for @settingsPrivacyPermNotifications.
  ///
  /// In zh, this message translates to:
  /// **'• 通知：计时结束提醒'**
  String get settingsPrivacyPermNotifications;

  /// No description provided for @settingsPrivacyPermVibration.
  ///
  /// In zh, this message translates to:
  /// **'• 振动：计时结束振动提醒'**
  String get settingsPrivacyPermVibration;

  /// No description provided for @settingsPrivacyPermForegroundService.
  ///
  /// In zh, this message translates to:
  /// **'• 前台服务：后台持续计时'**
  String get settingsPrivacyPermForegroundService;

  /// No description provided for @settingsPrivacyPermNetwork.
  ///
  /// In zh, this message translates to:
  /// **'• 网络：仅下载开源健身图片（CC0）'**
  String get settingsPrivacyPermNetwork;

  /// No description provided for @settingsPrivacyPermBatteryExempt.
  ///
  /// In zh, this message translates to:
  /// **'• 电池优化豁免：防止计时器被系统中断'**
  String get settingsPrivacyPermBatteryExempt;

  /// No description provided for @settingsPrivacyThirdParty.
  ///
  /// In zh, this message translates to:
  /// **'第三方服务'**
  String get settingsPrivacyThirdParty;

  /// No description provided for @settingsPrivacyThirdPartyBody.
  ///
  /// In zh, this message translates to:
  /// **'本应用不集成任何第三方数据分析、广告或追踪 SDK。'**
  String get settingsPrivacyThirdPartyBody;

  /// No description provided for @settingsPrivacyFullPolicy.
  ///
  /// In zh, this message translates to:
  /// **'完整隐私政策：\nhttps://kaiji-z.github.io/workout-timer/'**
  String get settingsPrivacyFullPolicy;

  /// No description provided for @settingsPrivacyLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策链接已复制'**
  String get settingsPrivacyLinkCopied;

  /// No description provided for @settingsCopyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get settingsCopyLink;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @brandHuawei.
  ///
  /// In zh, this message translates to:
  /// **'华为'**
  String get brandHuawei;

  /// No description provided for @brandHonor.
  ///
  /// In zh, this message translates to:
  /// **'荣耀'**
  String get brandHonor;

  /// No description provided for @brandXiaomi.
  ///
  /// In zh, this message translates to:
  /// **'小米'**
  String get brandXiaomi;

  /// No description provided for @brandOppo.
  ///
  /// In zh, this message translates to:
  /// **'OPPO'**
  String get brandOppo;

  /// No description provided for @brandVivo.
  ///
  /// In zh, this message translates to:
  /// **'vivo'**
  String get brandVivo;

  /// No description provided for @brandMeizu.
  ///
  /// In zh, this message translates to:
  /// **'魅族'**
  String get brandMeizu;

  /// No description provided for @brandSamsung.
  ///
  /// In zh, this message translates to:
  /// **'三星'**
  String get brandSamsung;

  /// No description provided for @brandOneplus.
  ///
  /// In zh, this message translates to:
  /// **'一加'**
  String get brandOneplus;

  /// No description provided for @oemInstructionHuawei.
  ///
  /// In zh, this message translates to:
  /// **'在「应用启动管理」中找到撸铁计时器，关闭「自动管理」，手动开启全部三个开关'**
  String get oemInstructionHuawei;

  /// No description provided for @oemInstructionHonor.
  ///
  /// In zh, this message translates to:
  /// **'在「应用启动管理」中找到撸铁计时器，关闭「自动管理」，手动开启全部三个开关'**
  String get oemInstructionHonor;

  /// No description provided for @oemInstructionXiaomi.
  ///
  /// In zh, this message translates to:
  /// **'在「自启动管理」中找到撸铁计时器，开启自启动开关。然后在「省电策略」中选择「无限制」'**
  String get oemInstructionXiaomi;

  /// No description provided for @oemInstructionOppo.
  ///
  /// In zh, this message translates to:
  /// **'在「自启动管理」中找到撸铁计时器，允许自启动'**
  String get oemInstructionOppo;

  /// No description provided for @oemInstructionVivo.
  ///
  /// In zh, this message translates to:
  /// **'在「后台高耗电」或「自启动」中找到撸铁计时器，允许后台运行'**
  String get oemInstructionVivo;

  /// No description provided for @oemInstructionMeizu.
  ///
  /// In zh, this message translates to:
  /// **'在「智能休眠」或「后台管理」中找到撸铁计时器，允许后台运行'**
  String get oemInstructionMeizu;

  /// No description provided for @oemInstructionSamsung.
  ///
  /// In zh, this message translates to:
  /// **'在「电池」设置中找到撸铁计时器，选择「不受限制」'**
  String get oemInstructionSamsung;

  /// No description provided for @oemInstructionOneplus.
  ///
  /// In zh, this message translates to:
  /// **'在「电池优化」高级设置中找到撸铁计时器，选择「不优化」'**
  String get oemInstructionOneplus;

  /// No description provided for @prefTitle.
  ///
  /// In zh, this message translates to:
  /// **'训练偏好'**
  String get prefTitle;

  /// No description provided for @prefCloseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get prefCloseTooltip;

  /// No description provided for @prefSaved.
  ///
  /// In zh, this message translates to:
  /// **'偏好已保存'**
  String get prefSaved;

  /// No description provided for @prefBodyWeightSection.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get prefBodyWeightSection;

  /// No description provided for @prefBodyWeightHint.
  ///
  /// In zh, this message translates to:
  /// **'用于计算徒手动作的训练容量（如引体向上、俯卧撑等）'**
  String get prefBodyWeightHint;

  /// No description provided for @prefBodyWeightPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'例如 70'**
  String get prefBodyWeightPlaceholder;

  /// No description provided for @prefGoalSection.
  ///
  /// In zh, this message translates to:
  /// **'训练目标'**
  String get prefGoalSection;

  /// No description provided for @prefGoalMuscleBuilding.
  ///
  /// In zh, this message translates to:
  /// **'增肌'**
  String get prefGoalMuscleBuilding;

  /// No description provided for @prefGoalFatLoss.
  ///
  /// In zh, this message translates to:
  /// **'减脂'**
  String get prefGoalFatLoss;

  /// No description provided for @prefGoalStrength.
  ///
  /// In zh, this message translates to:
  /// **'力量'**
  String get prefGoalStrength;

  /// No description provided for @prefGoalEndurance.
  ///
  /// In zh, this message translates to:
  /// **'耐力'**
  String get prefGoalEndurance;

  /// No description provided for @prefExperienceSection.
  ///
  /// In zh, this message translates to:
  /// **'经验水平'**
  String get prefExperienceSection;

  /// No description provided for @prefExperienceBeginner.
  ///
  /// In zh, this message translates to:
  /// **'初学者'**
  String get prefExperienceBeginner;

  /// No description provided for @prefExperienceIntermediate.
  ///
  /// In zh, this message translates to:
  /// **'中级'**
  String get prefExperienceIntermediate;

  /// No description provided for @prefExperienceAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级'**
  String get prefExperienceAdvanced;

  /// No description provided for @prefEquipmentSection.
  ///
  /// In zh, this message translates to:
  /// **'可用设备'**
  String get prefEquipmentSection;

  /// No description provided for @prefEquipmentGym.
  ///
  /// In zh, this message translates to:
  /// **'健身房'**
  String get prefEquipmentGym;

  /// No description provided for @prefEquipmentHomeDumbbell.
  ///
  /// In zh, this message translates to:
  /// **'家用哑铃'**
  String get prefEquipmentHomeDumbbell;

  /// No description provided for @prefEquipmentBodyweight.
  ///
  /// In zh, this message translates to:
  /// **'徒手'**
  String get prefEquipmentBodyweight;

  /// No description provided for @prefFrequencySection.
  ///
  /// In zh, this message translates to:
  /// **'每周频率'**
  String get prefFrequencySection;

  /// No description provided for @prefFrequencyDays.
  ///
  /// In zh, this message translates to:
  /// **'{count}天'**
  String prefFrequencyDays(int count);

  /// No description provided for @prefFocusAreaSection.
  ///
  /// In zh, this message translates to:
  /// **'重点部位'**
  String get prefFocusAreaSection;

  /// No description provided for @prefFocusAreaChest.
  ///
  /// In zh, this message translates to:
  /// **'胸部'**
  String get prefFocusAreaChest;

  /// No description provided for @prefFocusAreaBack.
  ///
  /// In zh, this message translates to:
  /// **'背部'**
  String get prefFocusAreaBack;

  /// No description provided for @prefFocusAreaShoulders.
  ///
  /// In zh, this message translates to:
  /// **'肩部'**
  String get prefFocusAreaShoulders;

  /// No description provided for @prefFocusAreaArms.
  ///
  /// In zh, this message translates to:
  /// **'手臂'**
  String get prefFocusAreaArms;

  /// No description provided for @prefFocusAreaLegs.
  ///
  /// In zh, this message translates to:
  /// **'腿部'**
  String get prefFocusAreaLegs;

  /// No description provided for @prefFocusAreaCore.
  ///
  /// In zh, this message translates to:
  /// **'核心'**
  String get prefFocusAreaCore;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get historyTitle;

  /// No description provided for @historyLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get historyLoadFailed;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无记录'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'完成一次训练后查看结果'**
  String get historyEmptyHint;

  /// No description provided for @historyClearConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除历史'**
  String get historyClearConfirmTitle;

  /// No description provided for @historyClearConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有历史记录吗？'**
  String get historyClearConfirmBody;

  /// No description provided for @historyPlanMode.
  ///
  /// In zh, this message translates to:
  /// **'计划模式'**
  String get historyPlanMode;

  /// No description provided for @historyFreeWorkout.
  ///
  /// In zh, this message translates to:
  /// **'自由训练'**
  String get historyFreeWorkout;

  /// No description provided for @historyCompletedSets.
  ///
  /// In zh, this message translates to:
  /// **'已完成组数'**
  String get historyCompletedSets;

  /// No description provided for @historySetsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'{count}组'**
  String historySetsSuffix(int count);

  /// No description provided for @historyExercisesSuffix.
  ///
  /// In zh, this message translates to:
  /// **'{count}动作'**
  String historyExercisesSuffix(int count);

  /// No description provided for @recDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'训练详情'**
  String get recDetailTitle;

  /// No description provided for @recDetailBackTooltip.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get recDetailBackTooltip;

  /// No description provided for @recDetailExercisesSection.
  ///
  /// In zh, this message translates to:
  /// **'动作详情'**
  String get recDetailExercisesSection;

  /// No description provided for @recDetailStatTotalSets.
  ///
  /// In zh, this message translates to:
  /// **'总组数'**
  String get recDetailStatTotalSets;

  /// No description provided for @recDetailStatExerciseCount.
  ///
  /// In zh, this message translates to:
  /// **'动作数'**
  String get recDetailStatExerciseCount;

  /// No description provided for @recDetailStatMuscles.
  ///
  /// In zh, this message translates to:
  /// **'训练部位'**
  String get recDetailStatMuscles;

  /// No description provided for @recDetailNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get recDetailNone;

  /// No description provided for @recDetailAddSet.
  ///
  /// In zh, this message translates to:
  /// **'添加组'**
  String get recDetailAddSet;

  /// No description provided for @recDetailTotalVolume.
  ///
  /// In zh, this message translates to:
  /// **'总容量'**
  String get recDetailTotalVolume;

  /// No description provided for @recDetailAddDataPrompt.
  ///
  /// In zh, this message translates to:
  /// **'点击添加训练数据'**
  String get recDetailAddDataPrompt;

  /// No description provided for @recDetailSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get recDetailSaved;

  /// No description provided for @recDetailSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String recDetailSaveFailed(String error);

  /// No description provided for @recDetailUnsavedTitle.
  ///
  /// In zh, this message translates to:
  /// **'保存更改？'**
  String get recDetailUnsavedTitle;

  /// No description provided for @recDetailUnsavedBody.
  ///
  /// In zh, this message translates to:
  /// **'你有未保存的更改，是否保存？'**
  String get recDetailUnsavedBody;

  /// No description provided for @recDetailDontSave.
  ///
  /// In zh, this message translates to:
  /// **'不保存'**
  String get recDetailDontSave;

  /// No description provided for @recDetailUnknownExercise.
  ///
  /// In zh, this message translates to:
  /// **'未知动作'**
  String get recDetailUnknownExercise;

  /// No description provided for @recDetailUnspecifiedMuscle.
  ///
  /// In zh, this message translates to:
  /// **'未指定'**
  String get recDetailUnspecifiedMuscle;

  /// No description provided for @recDetailDeleteButton.
  ///
  /// In zh, this message translates to:
  /// **'删除此记录'**
  String get recDetailDeleteButton;

  /// No description provided for @recDetailDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get recDetailDeleteTitle;

  /// No description provided for @recDetailDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这条训练记录吗？此操作无法撤销。'**
  String get recDetailDeleteBody;

  /// No description provided for @recDetailDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get recDetailDeleted;

  /// No description provided for @recDetailDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String recDetailDeleteFailed(String error);

  /// No description provided for @recDetailDeleteAction.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get recDetailDeleteAction;

  /// No description provided for @planTitle.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get planTitle;

  /// No description provided for @planAiButton.
  ///
  /// In zh, this message translates to:
  /// **'AI训练计划'**
  String get planAiButton;

  /// No description provided for @planTodayPlans.
  ///
  /// In zh, this message translates to:
  /// **'今日计划'**
  String get planTodayPlans;

  /// No description provided for @plansForDate.
  ///
  /// In zh, this message translates to:
  /// **'{date} 的计划'**
  String plansForDate(String date);

  /// No description provided for @planAddButton.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加'**
  String get planAddButton;

  /// No description provided for @planRemoveTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除计划'**
  String get planRemoveTitle;

  /// No description provided for @planRemoveFromDateConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要从 {month}月{day}日 移除「{name}」吗？'**
  String planRemoveFromDateConfirm(int month, int day, String name);

  /// No description provided for @planRemoveAction.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get planRemoveAction;

  /// No description provided for @planRemovedToast.
  ///
  /// In zh, this message translates to:
  /// **'已从{month}月{day}日移除「{name}」'**
  String planRemovedToast(int month, int day, String name);

  /// No description provided for @planLibraryButton.
  ///
  /// In zh, this message translates to:
  /// **'📚 我的计划库'**
  String get planLibraryButton;

  /// No description provided for @planEmptyAddToday.
  ///
  /// In zh, this message translates to:
  /// **'添加今日计划'**
  String get planEmptyAddToday;

  /// No description provided for @planSelectToAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择计划添加到 {month}月{day}日'**
  String planSelectToAddTitle(int month, int day);

  /// No description provided for @planCreateNew.
  ///
  /// In zh, this message translates to:
  /// **'创建新计划'**
  String get planCreateNew;

  /// No description provided for @planLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的计划库'**
  String get planLibraryTitle;

  /// No description provided for @planEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get planEdit;

  /// No description provided for @planDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get planDelete;

  /// No description provided for @planAddedToDateToast.
  ///
  /// In zh, this message translates to:
  /// **'已将「{name}」添加到 {month}月{day}日'**
  String planAddedToDateToast(int month, int day, String name);

  /// No description provided for @planAddFailed.
  ///
  /// In zh, this message translates to:
  /// **'添加失败: {error}'**
  String planAddFailed(String error);

  /// No description provided for @planDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除计划'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{name}」吗？此操作无法撤销。'**
  String planDeleteConfirm(String name);

  /// No description provided for @planDeletedToast.
  ///
  /// In zh, this message translates to:
  /// **'已删除「{name}」'**
  String planDeletedToast(String name);

  /// No description provided for @planDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String planDeleteFailed(String error);

  /// No description provided for @planDetailTargetMuscles.
  ///
  /// In zh, this message translates to:
  /// **'目标部位：{muscles}'**
  String planDetailTargetMuscles(String muscles);

  /// No description provided for @planDetailExerciseCountUnit.
  ///
  /// In zh, this message translates to:
  /// **'个动作'**
  String get planDetailExerciseCountUnit;

  /// No description provided for @planDetailSetsUnit.
  ///
  /// In zh, this message translates to:
  /// **'组'**
  String get planDetailSetsUnit;

  /// No description provided for @planDetailMinutesUnit.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get planDetailMinutesUnit;

  /// No description provided for @planDetailExerciseList.
  ///
  /// In zh, this message translates to:
  /// **'动作列表'**
  String get planDetailExerciseList;

  /// No description provided for @planDetailNoDetailsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'(无详情)'**
  String get planDetailNoDetailsSuffix;

  /// No description provided for @planDetailEffectiveSets.
  ///
  /// In zh, this message translates to:
  /// **'{count}组'**
  String planDetailEffectiveSets(int count);

  /// No description provided for @planDetailAddToCalendar.
  ///
  /// In zh, this message translates to:
  /// **'添加到日历'**
  String get planDetailAddToCalendar;

  /// No description provided for @planDetailStartTraining.
  ///
  /// In zh, this message translates to:
  /// **'开始训练'**
  String get planDetailStartTraining;

  /// No description provided for @exSelectTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择训练动作'**
  String get exSelectTitle;

  /// No description provided for @exFavoritesChip.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get exFavoritesChip;

  /// No description provided for @exSelectHint.
  ///
  /// In zh, this message translates to:
  /// **'点击动作卡片选择'**
  String get exSelectHint;

  /// No description provided for @equipmentAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get equipmentAll;

  /// No description provided for @aiCloseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get aiCloseTooltip;

  /// No description provided for @aiTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 计划生成器'**
  String get aiTitle;

  /// No description provided for @aiPreviousStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get aiPreviousStep;

  /// No description provided for @aiStepImportAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'导入分析'**
  String get aiStepImportAnalysis;

  /// No description provided for @aiStepPreviewImport.
  ///
  /// In zh, this message translates to:
  /// **'预览导入'**
  String get aiStepPreviewImport;

  /// No description provided for @aiStepProfile.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get aiStepProfile;

  /// No description provided for @aiStepGeneratePrompt.
  ///
  /// In zh, this message translates to:
  /// **'生成提示词'**
  String get aiStepGeneratePrompt;

  /// No description provided for @aiStepPasteJson.
  ///
  /// In zh, this message translates to:
  /// **'粘贴JSON'**
  String get aiStepPasteJson;

  /// No description provided for @aiTabNewPlan.
  ///
  /// In zh, this message translates to:
  /// **'新建计划'**
  String get aiTabNewPlan;

  /// No description provided for @aiTabImportAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'导入分析'**
  String get aiTabImportAnalysis;

  /// No description provided for @aiNewPlanHeading.
  ///
  /// In zh, this message translates to:
  /// **'个人训练资料'**
  String get aiNewPlanHeading;

  /// No description provided for @aiNewPlanSubheading.
  ///
  /// In zh, this message translates to:
  /// **'请回答以下问题，帮助AI生成最适合您的训练计划'**
  String get aiNewPlanSubheading;

  /// No description provided for @aiQuestionFrequency.
  ///
  /// In zh, this message translates to:
  /// **'每周训练频率'**
  String get aiQuestionFrequency;

  /// No description provided for @aiQuestionDuration.
  ///
  /// In zh, this message translates to:
  /// **'训练时长'**
  String get aiQuestionDuration;

  /// No description provided for @aiQuestionEquipment.
  ///
  /// In zh, this message translates to:
  /// **'设备可用性'**
  String get aiQuestionEquipment;

  /// No description provided for @aiDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{count}分钟'**
  String aiDurationMinutes(int count);

  /// No description provided for @aiImportHeading.
  ///
  /// In zh, this message translates to:
  /// **'导入AI分析计划'**
  String get aiImportHeading;

  /// No description provided for @aiImportSubheading.
  ///
  /// In zh, this message translates to:
  /// **'将AI返回的JSON计划粘贴到下方，预览后直接导入'**
  String get aiImportSubheading;

  /// No description provided for @aiJsonLabel.
  ///
  /// In zh, this message translates to:
  /// **'JSON内容'**
  String get aiJsonLabel;

  /// No description provided for @aiJsonHelper.
  ///
  /// In zh, this message translates to:
  /// **'请粘贴AI生成的训练计划JSON'**
  String get aiJsonHelper;

  /// No description provided for @aiParsing.
  ///
  /// In zh, this message translates to:
  /// **'解析中...'**
  String get aiParsing;

  /// No description provided for @aiParseJson.
  ///
  /// In zh, this message translates to:
  /// **'解析JSON'**
  String get aiParseJson;

  /// No description provided for @aiErrorEmptyJson.
  ///
  /// In zh, this message translates to:
  /// **'请输入JSON内容'**
  String get aiErrorEmptyJson;

  /// No description provided for @aiErrorInvalidJson.
  ///
  /// In zh, this message translates to:
  /// **'未能识别有效的训练计划JSON，请确保AI回复中包含 days 数组。'**
  String get aiErrorInvalidJson;

  /// No description provided for @aiErrorParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'JSON解析失败: {error}'**
  String aiErrorParseFailed(String error);

  /// No description provided for @aiGeneratePromptHeading.
  ///
  /// In zh, this message translates to:
  /// **'生成AI提示词'**
  String get aiGeneratePromptHeading;

  /// No description provided for @aiGeneratePromptSubheading.
  ///
  /// In zh, this message translates to:
  /// **'设置开始日期并生成提示词，复制到AI应用获取训练计划'**
  String get aiGeneratePromptSubheading;

  /// No description provided for @aiStartDateLabel.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get aiStartDateLabel;

  /// No description provided for @aiDateDisplay.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月{day}日'**
  String aiDateDisplay(int year, int month, int day);

  /// No description provided for @aiGeneratePromptButton.
  ///
  /// In zh, this message translates to:
  /// **'生成提示词'**
  String get aiGeneratePromptButton;

  /// No description provided for @aiGeneratedPromptLabel.
  ///
  /// In zh, this message translates to:
  /// **'生成的提示词'**
  String get aiGeneratedPromptLabel;

  /// No description provided for @aiCopyToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'复制到剪贴板'**
  String get aiCopyToClipboard;

  /// No description provided for @aiCopyHint.
  ///
  /// In zh, this message translates to:
  /// **'将此提示词复制到豆包/千问等AI应用，获取JSON后返回粘贴'**
  String get aiCopyHint;

  /// No description provided for @aiCopiedToast.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get aiCopiedToast;

  /// No description provided for @aiPasteJsonHeading.
  ///
  /// In zh, this message translates to:
  /// **'粘贴AI返回的JSON'**
  String get aiPasteJsonHeading;

  /// No description provided for @aiPasteJsonSubheading.
  ///
  /// In zh, this message translates to:
  /// **'将AI生成的JSON粘贴到下方文本框'**
  String get aiPasteJsonSubheading;

  /// No description provided for @aiPreviewEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请先解析JSON以预览训练计划'**
  String get aiPreviewEmpty;

  /// No description provided for @aiPreviewHeading.
  ///
  /// In zh, this message translates to:
  /// **'预览训练计划'**
  String get aiPreviewHeading;

  /// No description provided for @aiPlanNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'计划名称: {name}'**
  String aiPlanNameLabel(String name);

  /// No description provided for @aiImporting.
  ///
  /// In zh, this message translates to:
  /// **'导入中...'**
  String get aiImporting;

  /// No description provided for @aiConfirmImport.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get aiConfirmImport;

  /// No description provided for @aiMatchSummary.
  ///
  /// In zh, this message translates to:
  /// **'匹配：{matched}个 ✅ | 待选：{candidates}个 ⚠️ | 未匹配：{unmatched}个'**
  String aiMatchSummary(int matched, int candidates, int unmatched);

  /// No description provided for @aiDayNameMon.
  ///
  /// In zh, this message translates to:
  /// **'周一'**
  String get aiDayNameMon;

  /// No description provided for @aiDayNameTue.
  ///
  /// In zh, this message translates to:
  /// **'周二'**
  String get aiDayNameTue;

  /// No description provided for @aiDayNameWed.
  ///
  /// In zh, this message translates to:
  /// **'周三'**
  String get aiDayNameWed;

  /// No description provided for @aiDayNameThu.
  ///
  /// In zh, this message translates to:
  /// **'周四'**
  String get aiDayNameThu;

  /// No description provided for @aiDayNameFri.
  ///
  /// In zh, this message translates to:
  /// **'周五'**
  String get aiDayNameFri;

  /// No description provided for @aiDayNameSat.
  ///
  /// In zh, this message translates to:
  /// **'周六'**
  String get aiDayNameSat;

  /// No description provided for @aiDayNameSun.
  ///
  /// In zh, this message translates to:
  /// **'周日'**
  String get aiDayNameSun;

  /// No description provided for @aiDayTitle.
  ///
  /// In zh, this message translates to:
  /// **'第{n}天 - {name}'**
  String aiDayTitle(int n, String name);

  /// No description provided for @aiRestDay.
  ///
  /// In zh, this message translates to:
  /// **'休息日'**
  String get aiRestDay;

  /// No description provided for @aiExerciseCountSuffix.
  ///
  /// In zh, this message translates to:
  /// **'{count}个动作'**
  String aiExerciseCountSuffix(int count);

  /// No description provided for @aiTargetMusclesLabel.
  ///
  /// In zh, this message translates to:
  /// **'目标肌群: {muscles}'**
  String aiTargetMusclesLabel(String muscles);

  /// No description provided for @aiCandidatesBadge.
  ///
  /// In zh, this message translates to:
  /// **'{count}个候选'**
  String aiCandidatesBadge(int count);

  /// No description provided for @aiOriginalLabel.
  ///
  /// In zh, this message translates to:
  /// **'原: {name}'**
  String aiOriginalLabel(String name);

  /// No description provided for @aiDecreaseSets.
  ///
  /// In zh, this message translates to:
  /// **'减少'**
  String get aiDecreaseSets;

  /// No description provided for @aiIncreaseSets.
  ///
  /// In zh, this message translates to:
  /// **'增加'**
  String get aiIncreaseSets;

  /// No description provided for @aiSetsUnit.
  ///
  /// In zh, this message translates to:
  /// **'组'**
  String get aiSetsUnit;

  /// No description provided for @aiSelectMatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择匹配的动作'**
  String get aiSelectMatchTitle;

  /// No description provided for @aiSelectMatchSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'AI生成的\"{name}\"有{count}个候选'**
  String aiSelectMatchSubtitle(String name, int count);

  /// No description provided for @aiKeepUnmatched.
  ///
  /// In zh, this message translates to:
  /// **'保持为\"无详情\"'**
  String get aiKeepUnmatched;

  /// No description provided for @aiImportConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get aiImportConfirmTitle;

  /// No description provided for @aiImportConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要导入这个训练计划吗？计划将被添加到日历中。'**
  String get aiImportConfirmBody;

  /// No description provided for @aiImportSuccessToast.
  ///
  /// In zh, this message translates to:
  /// **'训练计划导入成功！'**
  String get aiImportSuccessToast;

  /// No description provided for @aiImportFailedToast.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String aiImportFailedToast(String error);

  /// No description provided for @aiNextPreviewImport.
  ///
  /// In zh, this message translates to:
  /// **'下一步：预览导入'**
  String get aiNextPreviewImport;

  /// No description provided for @aiComplete.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get aiComplete;

  /// No description provided for @aiNextGeneratePrompt.
  ///
  /// In zh, this message translates to:
  /// **'下一步：生成提示词'**
  String get aiNextGeneratePrompt;

  /// No description provided for @aiNextPasteJson.
  ///
  /// In zh, this message translates to:
  /// **'下一步：粘贴JSON'**
  String get aiNextPasteJson;

  /// No description provided for @pfCloseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get pfCloseTooltip;

  /// No description provided for @pfCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建计划'**
  String get pfCreateTitle;

  /// No description provided for @pfEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑计划'**
  String get pfEditTitle;

  /// No description provided for @pfStepSelectMuscle.
  ///
  /// In zh, this message translates to:
  /// **'选择部位'**
  String get pfStepSelectMuscle;

  /// No description provided for @pfStepSelectExercise.
  ///
  /// In zh, this message translates to:
  /// **'选择动作'**
  String get pfStepSelectExercise;

  /// No description provided for @pfStepConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认计划'**
  String get pfStepConfirm;

  /// No description provided for @pfSelectMuscleHeading.
  ///
  /// In zh, this message translates to:
  /// **'选择训练部位'**
  String get pfSelectMuscleHeading;

  /// No description provided for @pfSelectMuscleSubheading.
  ///
  /// In zh, this message translates to:
  /// **'选择计划要覆盖的肌肉部位（可多选）'**
  String get pfSelectMuscleSubheading;

  /// No description provided for @pfQuickSelect.
  ///
  /// In zh, this message translates to:
  /// **'快速选择'**
  String get pfQuickSelect;

  /// No description provided for @pfQuickUpper.
  ///
  /// In zh, this message translates to:
  /// **'上肢'**
  String get pfQuickUpper;

  /// No description provided for @pfQuickLower.
  ///
  /// In zh, this message translates to:
  /// **'下肢'**
  String get pfQuickLower;

  /// No description provided for @pfQuickFull.
  ///
  /// In zh, this message translates to:
  /// **'全身'**
  String get pfQuickFull;

  /// No description provided for @pfQuickRemovedToast.
  ///
  /// In zh, this message translates to:
  /// **'已移除：{muscles}'**
  String pfQuickRemovedToast(String muscles);

  /// No description provided for @pfQuickAddedToast.
  ///
  /// In zh, this message translates to:
  /// **'已添加：{muscles}'**
  String pfQuickAddedToast(String muscles);

  /// No description provided for @pfSelectExerciseHeading.
  ///
  /// In zh, this message translates to:
  /// **'选择训练动作'**
  String get pfSelectExerciseHeading;

  /// No description provided for @pfSelectedMusclesLine.
  ///
  /// In zh, this message translates to:
  /// **'已选部位：{muscles}'**
  String pfSelectedMusclesLine(String muscles);

  /// No description provided for @pfNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get pfNotSelected;

  /// No description provided for @pfSelectedExercisesHeading.
  ///
  /// In zh, this message translates to:
  /// **'已选动作'**
  String get pfSelectedExercisesHeading;

  /// No description provided for @pfClearSelectedTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空已选动作？'**
  String get pfClearSelectedTitle;

  /// No description provided for @pfClearSelectedBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有已选动作吗？此操作无法撤销。'**
  String get pfClearSelectedBody;

  /// No description provided for @pfNoDetailsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'(无详情)'**
  String get pfNoDetailsSuffix;

  /// No description provided for @pfSetsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'({count}组)'**
  String pfSetsSuffix(int count);

  /// No description provided for @pfContinueAdding.
  ///
  /// In zh, this message translates to:
  /// **'继续添加动作'**
  String get pfContinueAdding;

  /// No description provided for @pfSelectedCountLine.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 个动作'**
  String pfSelectedCountLine(int count);

  /// No description provided for @pfConfirmHeading.
  ///
  /// In zh, this message translates to:
  /// **'确认计划'**
  String get pfConfirmHeading;

  /// No description provided for @pfPlanNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'计划名称'**
  String get pfPlanNameLabel;

  /// No description provided for @pfPlanNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：上肢训练日'**
  String get pfPlanNameHint;

  /// No description provided for @pfSummaryHeading.
  ///
  /// In zh, this message translates to:
  /// **'计划摘要'**
  String get pfSummaryHeading;

  /// No description provided for @pfSummaryMuscles.
  ///
  /// In zh, this message translates to:
  /// **'训练部位'**
  String get pfSummaryMuscles;

  /// No description provided for @pfSummaryExerciseCount.
  ///
  /// In zh, this message translates to:
  /// **'动作数量'**
  String get pfSummaryExerciseCount;

  /// No description provided for @pfExerciseCountValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String pfExerciseCountValue(int count);

  /// No description provided for @pfSummaryTotalSets.
  ///
  /// In zh, this message translates to:
  /// **'总组数'**
  String get pfSummaryTotalSets;

  /// No description provided for @pfTotalSetsValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 组'**
  String pfTotalSetsValue(int count);

  /// No description provided for @pfSummaryDuration.
  ///
  /// In zh, this message translates to:
  /// **'预估时长'**
  String get pfSummaryDuration;

  /// No description provided for @pfDurationValue.
  ///
  /// In zh, this message translates to:
  /// **'~{count} 分钟'**
  String pfDurationValue(int count);

  /// No description provided for @pfDurationFootnote.
  ///
  /// In zh, this message translates to:
  /// **'※ 预估时长 = 总组数 × 2.5分钟（含休息）'**
  String get pfDurationFootnote;

  /// No description provided for @pfAdjustSetsHeading.
  ///
  /// In zh, this message translates to:
  /// **'调整组数（可拖拽排序）'**
  String get pfAdjustSetsHeading;

  /// No description provided for @pfDecreaseSets.
  ///
  /// In zh, this message translates to:
  /// **'减少组数'**
  String get pfDecreaseSets;

  /// No description provided for @pfIncreaseSets.
  ///
  /// In zh, this message translates to:
  /// **'增加组数'**
  String get pfIncreaseSets;

  /// No description provided for @pfDeleteExercise.
  ///
  /// In zh, this message translates to:
  /// **'删除动作'**
  String get pfDeleteExercise;

  /// No description provided for @pfNextSelectExercise.
  ///
  /// In zh, this message translates to:
  /// **'下一步：选择动作'**
  String get pfNextSelectExercise;

  /// No description provided for @pfNextConfirm.
  ///
  /// In zh, this message translates to:
  /// **'下一步：确认计划'**
  String get pfNextConfirm;

  /// No description provided for @pfSaveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get pfSaveChanges;

  /// No description provided for @pfPreviousStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get pfPreviousStep;

  /// No description provided for @pfDefaultPlanName.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get pfDefaultPlanName;

  /// No description provided for @pfSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String pfSaveFailed(String error);

  /// No description provided for @pfDiscardTitle.
  ///
  /// In zh, this message translates to:
  /// **'放弃编辑？'**
  String get pfDiscardTitle;

  /// No description provided for @pfDiscardBody.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的更改，确定要退出吗？'**
  String get pfDiscardBody;

  /// No description provided for @pfKeepEditing.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get pfKeepEditing;

  /// No description provided for @pfDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get pfDiscard;
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
