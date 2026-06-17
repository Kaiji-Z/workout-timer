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
}
