// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '撸铁计时器';

  @override
  String get navPlans => '训练计划';

  @override
  String get navHistory => '历史记录';

  @override
  String get navStats => '训练统计';

  @override
  String get navSettings => '设置';

  @override
  String get navTimer => '训练计时器';

  @override
  String timerSecondsRemaining(int seconds) {
    return '剩余 $seconds 秒';
  }

  @override
  String get timerInProgress => '进行中';

  @override
  String get timerReady => '准备就绪';

  @override
  String get timerCompletedSets => '完成组数';

  @override
  String get timerReset => '重置计时器';

  @override
  String get timerPause => '暂停';

  @override
  String get timerStart => '开始';

  @override
  String get timerSkipSet => '跳过当前组';

  @override
  String timerSecondsLabel(int seconds) {
    return '$seconds秒';
  }

  @override
  String trainingNextExercise(String name) {
    return '下一个：$name';
  }

  @override
  String get trainingNextDone => '下一个：训练完成';

  @override
  String get trainingRestCountdown => '休息倒计时';

  @override
  String get trainingExercising => '运动中';

  @override
  String get trainingRestDuration => '休息时长';

  @override
  String trainingExerciseProgress(String name, int set) {
    return '$name · 第$set组 · 运动';
  }

  @override
  String trainingSetExercising(int set) {
    return '第 $set 组 · 运动中';
  }

  @override
  String trainingExerciseRest(String name, int set) {
    return '$name · 已完成$set组 · 休息中';
  }

  @override
  String trainingSetRest(int set) {
    return '第 $set 组 · 休息中';
  }

  @override
  String get trainingCompleted => '训练完成';

  @override
  String trainingSetPaused(int set) {
    return '第 $set 组 · 已暂停';
  }

  @override
  String trainingPlanReady(String name) {
    return '$name · 准备开始';
  }

  @override
  String get trainingReady => '准备开始';

  @override
  String trainingSetCount(int set) {
    return '$set 组';
  }

  @override
  String get trainingStartExercise => '开始运动';

  @override
  String get trainingRest => '休息';

  @override
  String get trainingContinue => '继续';

  @override
  String get trainingSkipRest => '跳过休息';

  @override
  String get trainingSave => '保存';

  @override
  String get trainingNoPlan => '还没有计划，请先创建计划';

  @override
  String get trainingSelectPlan => '选择训练计划';

  @override
  String get trainingCancelPlan => '取消计划';

  @override
  String trainingPlanSummary(int exerciseCount, int totalSets) {
    return '$exerciseCount动作 · $totalSets组';
  }

  @override
  String trainingSavedDetail(int sets, String duration) {
    return '训练已保存：$sets组，总时长 $duration';
  }

  @override
  String trainingSavedCompleted(int sets, String duration) {
    return '训练已保存：完成$sets组，总时长 $duration';
  }

  @override
  String get notifNextSet => '准备开始下一组！';

  @override
  String get notifRestDone => '休息结束！';

  @override
  String get soundDefault => '默认';

  @override
  String get soundBeep => '哔声';

  @override
  String get soundRing => '铃声';

  @override
  String get soundChime => '钟声';

  @override
  String get soundWhistle => '哨声';

  @override
  String get recReps => '次数';

  @override
  String get recSkip => '跳过';

  @override
  String get recSave => '保存';

  @override
  String get recWeightKg => '重量 (kg)';

  @override
  String get recAddedWeightKg => '附加重量 (kg)';

  @override
  String get recBodyweightOnly => '0 = 纯自重';

  @override
  String get recInvalidInput => '请输入有效的重量和次数';

  @override
  String get recRecordData => '记录训练数据';

  @override
  String get recScrollHint => '滚动选择次数，输入重量';

  @override
  String get recAdded => '附加';

  @override
  String get calPrevMonth => '上个月';

  @override
  String get calNextMonth => '下个月';

  @override
  String get oemSectionTitle => '厂商后台管理';

  @override
  String oemCardTitle(String name) {
    return '$name手机省电管理';
  }

  @override
  String oemExplanation(String name) {
    return '您的$name手机有独立的省电管理，标准电池优化白名单可能不够。请点击下方按钮，在打开的设置页面中允许本应用自启动/后台运行。';
  }

  @override
  String get oemFlowHint =>
      '提示：请先完成上方「允许后台活动」（标准白名单），再进行下方的厂商专属设置，两者配合才能确保后台计时正常。';

  @override
  String oemGoButton(String name) {
    return '前往$name设置';
  }

  @override
  String get oemDefaultInstruction => '请在系统设置中允许本应用自启动和后台运行';

  @override
  String unitMinutes(int m) {
    return '$m分钟';
  }

  @override
  String unitMinutesSeconds(int m, int s) {
    return '$m分$s秒';
  }

  @override
  String unitSeconds(int s) {
    return '$s秒';
  }

  @override
  String unitRepsRange(int min, int max) {
    return '$min-$max次';
  }

  @override
  String get levelBeginner => '初级';

  @override
  String get levelIntermediate => '中级';

  @override
  String get levelExpert => '高级';

  @override
  String get equipmentBarbell => '杠铃';

  @override
  String get equipmentDumbbell => '哑铃';

  @override
  String get equipmentBodyweight => '自重';

  @override
  String get equipmentCable => '绳索';

  @override
  String get equipmentMachine => '器械';

  @override
  String get equipmentKettlebells => '壶铃';

  @override
  String get equipmentBands => '弹力带';

  @override
  String get equipmentMedicineBall => '药球';

  @override
  String get equipmentEzBarbell => '曲杆杠铃';

  @override
  String get equipmentSmithMachine => '史密斯机';

  @override
  String get errorGeneric => '操作失败，请重试';

  @override
  String get dataTransferShareText => '撸铁计时器数据备份';

  @override
  String get dataTransferWebUnsupported => 'Web 平台暂不支持文件导入';

  @override
  String get dataTransferInvalidFormat => '无效的备份文件格式';

  @override
  String aiPromptOutputInstructions(
    int frequency,
    String goal,
    String experience,
    String equipment,
  ) {
    return '请按以下两部分输出你的回复：\n\n**第一部分：计划设计说明**\n\n详细说明你为什么这样设计这个训练计划，包括：\n- 分化方式的选择理由（如推/拉/腿、上下肢、全身等，结合我的训练频率 $frequency 天/周）\n- 每个训练日的动作选择逻辑（为什么选这些动作，复合/孤立的搭配原则）\n- 容量分配依据（每个肌群每周的训练组数，如何匹配我的目标 $goal）\n- 与我的经验水平 $experience 和器材条件 $equipment 的适配考虑\n\n**第二部分：训练计划 JSON**\n\n在分析之后，用 ```json 代码块提供结构化训练计划：';
  }

  @override
  String aiPromptClosing(int frequency) {
    return '请根据以上信息（训练频率 $frequency 天/周），先解释你的设计思路，然后生成训练计划。';
  }

  @override
  String dialogSetTitle(int set) {
    return '第$set组';
  }

  @override
  String dialogSetTitleWithName(int set, String name) {
    return '第$set组 - $name';
  }

  @override
  String repsWithValue(int reps) {
    return '$reps 次';
  }

  @override
  String bodyweightReference(String bw, String pct, String result) {
    return '体重 ${bw}kg × $pct% = ${result}kg';
  }

  @override
  String trainingSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get calDayHasPlan => '有训练计划';

  @override
  String get calDayToday => '今天';

  @override
  String get calDaySelected => '已选中';

  @override
  String calDaySemantics(
    String date,
    String plan,
    String today,
    String selected,
  ) {
    return '$date，$plan$today$selected';
  }

  @override
  String get widgetSearchExercise => '搜索动作';

  @override
  String get widgetClearSearch => '清除搜索';

  @override
  String get widgetAll => '全部';

  @override
  String get widgetNoExerciseFound => '没有找到动作';

  @override
  String widgetSelectedCount(int count) {
    return '已选 $count 个动作';
  }

  @override
  String get widgetClearAll => '清空';

  @override
  String widgetSetsSuffix(int n) {
    return '$n组';
  }

  @override
  String widgetPlanExercisesCount(int n) {
    return '$n 个动作';
  }

  @override
  String widgetPlanSetsCount(int n) {
    return '$n 组';
  }

  @override
  String widgetPlanDuration(int n) {
    return '~$n 分钟';
  }

  @override
  String widgetPlanSummaryShort(int exerciseCount, int totalSets) {
    return '$exerciseCount动作 · $totalSets组';
  }

  @override
  String widgetCurrentExercise(String name, int set, int total) {
    return '当前：$name 第$set/$total组';
  }

  @override
  String widgetExerciseProgressHeader(String plan, String exercise, int set) {
    return '$plan · $exercise 第$set组';
  }

  @override
  String widgetNoDetail(String name) {
    return '$name (无详情)';
  }

  @override
  String get widgetSwitchNextExercise => '切换下一动作';

  @override
  String get widgetEmptyPlanTitle => '还没有计划';

  @override
  String get widgetEmptyPlanSubtitle => '点击创建你的第一个训练计划';

  @override
  String widgetProgressSummary(String name, int current, int total) {
    return '$name · $current/$total组';
  }

  @override
  String get widgetSelectMuscleTitle => '选择训练部位';

  @override
  String get widgetNoDailyData => '暂无每日训练量数据';

  @override
  String get widgetTrainingComplete => '训练完成';

  @override
  String get widgetImageLoadFailed => '图片加载失败';

  @override
  String get widgetTapToClose => '点击任意位置关闭';

  @override
  String get widgetClose => '关闭';

  @override
  String get widgetSetRestDuration => '设置休息时长';

  @override
  String get widgetRestMinDuration => '休息时长至少需要10秒';

  @override
  String get widgetMinuteSuffix => '分';

  @override
  String get widgetSecondSuffix => '秒';

  @override
  String get widgetCancel => '取消';

  @override
  String get widgetConfirm => '确定';

  @override
  String widgetSelectedDuration(String duration) {
    return '已选择: $duration';
  }

  @override
  String get widgetConfirmButton => '确认';

  @override
  String get widgetSearchExerciseHint => '搜索动作...';

  @override
  String get widgetInvolvedMuscles => '涉及部位';

  @override
  String get widgetRemoveFromPlan => '从计划中移除';

  @override
  String get widgetAddToPlan => '添加到计划';

  @override
  String widgetImageStepIndicator(int current, int total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String get widgetExerciseInstructions => '动作指导';

  @override
  String get widgetRecommendedConfig => '推荐配置';

  @override
  String get widgetRecommendedSets => '推荐组数';

  @override
  String widgetRecommendedSetsValue(int n) {
    return '$n 组';
  }

  @override
  String get widgetRepsRangeLabel => '次数范围';

  @override
  String get widgetRestLabel => '组间休息';
}
