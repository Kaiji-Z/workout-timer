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

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearanceSection => '外观设置';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsSelectTheme => '选择主题';

  @override
  String get settingsNotificationSection => '通知设置';

  @override
  String get settingsEnableSound => '启用声音';

  @override
  String get settingsNotificationRingtone => '通知铃声';

  @override
  String get settingsEnableVibration => '启用振动';

  @override
  String get settingsDetailedRecording => '详细记录模式';

  @override
  String get settingsSelectRingtone => '选择铃声';

  @override
  String get settingsClose => '关闭';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsClear => '清除';

  @override
  String get settingsCustomMessageDefault => '准备开始下一组！';

  @override
  String get settingsCustomMessageSection => '自定义提醒消息';

  @override
  String get settingsCustomMessageHint => '输入提醒消息';

  @override
  String get settingsBackgroundSection => '后台运行';

  @override
  String get settingsAllowBackground => '允许后台活动';

  @override
  String get settingsBackgroundAllowed => '已允许，计时器可在后台正常运行';

  @override
  String get settingsBackgroundNotAllowed => '未允许，后台计时器可能被系统暂停';

  @override
  String get settingsBackgroundHint =>
      '点击上方选项，在弹出的系统对话框中选择\"允许\"，以确保计时器在后台正常运行';

  @override
  String get settingsDataSection => '数据管理';

  @override
  String get settingsExportData => '导出数据';

  @override
  String get settingsExportSubtitle => '导出全部训练记录、计划等数据为文件';

  @override
  String get settingsImportData => '导入数据';

  @override
  String get settingsImportSubtitle => '从备份文件恢复全部数据（会覆盖现有数据）';

  @override
  String get settingsClearHistory => '清除所有历史记录';

  @override
  String get settingsClearHistoryConfirmTitle => '确认清除';

  @override
  String get settingsClearHistoryConfirmBody => '确定要清除所有历史记录吗？此操作不可撤销。';

  @override
  String get settingsHistoryCleared => '历史记录已清除';

  @override
  String get settingsExport => '导出';

  @override
  String get settingsExportConfirmBody =>
      '将导出全部训练记录、计划、练习等数据。\n\n文件会保存到手机 Downloads 目录，同时弹出分享面板。';

  @override
  String settingsExportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get settingsImportConfirmTitle => '确认导入';

  @override
  String settingsImportConfirmBody(String source) {
    return '⚠️ 导入将覆盖现有全部数据！\n\n将恢复来自：\n$source';
  }

  @override
  String get settingsConfirmImport => '确认导入';

  @override
  String settingsImportSuccess(int count) {
    return '导入成功，共恢复 $count 条记录';
  }

  @override
  String settingsImportFailed(String error) {
    return '导入失败: $error';
  }

  @override
  String get settingsFoundLocalBackups => '发现本地备份';

  @override
  String get settingsSelectManually => '手动选择文件';

  @override
  String get settingsSelectManuallySubtitle => '从其他位置选择 JSON 备份文件';

  @override
  String get settingsAiPreferencesSection => 'AI 训练偏好';

  @override
  String get settingsTrainingPreferences => '训练偏好';

  @override
  String get settingsTrainingPreferencesSubtitle => '设置训练目标、经验水平等，AI功能将自动读取';

  @override
  String get settingsAboutSection => '关于';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsPrivacyPolicySubtitle => '查看本应用的隐私政策';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsBackupPrefix => '备份';

  @override
  String get settingsVersionLoading => '加载中…';

  @override
  String get settingsDeveloper => '开发者';

  @override
  String get settingsDeveloperName => '深圳市露凯文化传播有限公司';

  @override
  String get settingsContactEmail => '联系邮箱';

  @override
  String get settingsEmailCopied => '邮箱已复制';

  @override
  String get settingsPrivacyHeadline => '撸铁计时器不收集任何个人信息';

  @override
  String get settingsPrivacyDataStorage => '数据存储';

  @override
  String get settingsPrivacyDataStorageBody =>
      '所有训练数据均存储在您的设备本地（SQLite 数据库），不上传至任何服务器。卸载应用将永久删除所有数据。';

  @override
  String get settingsPrivacyPermissions => '设备权限';

  @override
  String get settingsPrivacyPermNotifications => '• 通知：计时结束提醒';

  @override
  String get settingsPrivacyPermVibration => '• 振动：计时结束振动提醒';

  @override
  String get settingsPrivacyPermForegroundService => '• 前台服务：后台持续计时';

  @override
  String get settingsPrivacyPermNetwork => '• 网络：仅下载开源健身图片（CC0）';

  @override
  String get settingsPrivacyPermBatteryExempt => '• 电池优化豁免：防止计时器被系统中断';

  @override
  String get settingsPrivacyThirdParty => '第三方服务';

  @override
  String get settingsPrivacyThirdPartyBody => '本应用不集成任何第三方数据分析、广告或追踪 SDK。';

  @override
  String get settingsPrivacyFullPolicy =>
      '完整隐私政策：\nhttps://kaiji-z.github.io/workout-timer/';

  @override
  String get settingsPrivacyLinkCopied => '隐私政策链接已复制';

  @override
  String get settingsCopyLink => '复制链接';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageZh => '简体中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get brandHuawei => '华为';

  @override
  String get brandHonor => '荣耀';

  @override
  String get brandXiaomi => '小米';

  @override
  String get brandOppo => 'OPPO';

  @override
  String get brandVivo => 'vivo';

  @override
  String get brandMeizu => '魅族';

  @override
  String get brandSamsung => '三星';

  @override
  String get brandOneplus => '一加';

  @override
  String get oemInstructionHuawei => '在「应用启动管理」中找到撸铁计时器，关闭「自动管理」，手动开启全部三个开关';

  @override
  String get oemInstructionHonor => '在「应用启动管理」中找到撸铁计时器，关闭「自动管理」，手动开启全部三个开关';

  @override
  String get oemInstructionXiaomi =>
      '在「自启动管理」中找到撸铁计时器，开启自启动开关。然后在「省电策略」中选择「无限制」';

  @override
  String get oemInstructionOppo => '在「自启动管理」中找到撸铁计时器，允许自启动';

  @override
  String get oemInstructionVivo => '在「后台高耗电」或「自启动」中找到撸铁计时器，允许后台运行';

  @override
  String get oemInstructionMeizu => '在「智能休眠」或「后台管理」中找到撸铁计时器，允许后台运行';

  @override
  String get oemInstructionSamsung => '在「电池」设置中找到撸铁计时器，选择「不受限制」';

  @override
  String get oemInstructionOneplus => '在「电池优化」高级设置中找到撸铁计时器，选择「不优化」';

  @override
  String get prefTitle => '训练偏好';

  @override
  String get prefCloseTooltip => '关闭';

  @override
  String get prefSaved => '偏好已保存';

  @override
  String get prefBodyWeightSection => '体重';

  @override
  String get prefBodyWeightHint => '用于计算徒手动作的训练容量（如引体向上、俯卧撑等）';

  @override
  String get prefBodyWeightPlaceholder => '例如 70';

  @override
  String get prefGoalSection => '训练目标';

  @override
  String get prefGoalMuscleBuilding => '增肌';

  @override
  String get prefGoalFatLoss => '减脂';

  @override
  String get prefGoalStrength => '力量';

  @override
  String get prefGoalEndurance => '耐力';

  @override
  String get prefExperienceSection => '经验水平';

  @override
  String get prefExperienceBeginner => '初学者';

  @override
  String get prefExperienceIntermediate => '中级';

  @override
  String get prefExperienceAdvanced => '高级';

  @override
  String get prefEquipmentSection => '可用设备';

  @override
  String get prefEquipmentGym => '健身房';

  @override
  String get prefEquipmentHomeDumbbell => '家用哑铃';

  @override
  String get prefEquipmentBodyweight => '徒手';

  @override
  String get prefFrequencySection => '每周频率';

  @override
  String prefFrequencyDays(int count) {
    return '$count天';
  }

  @override
  String get prefFocusAreaSection => '重点部位';

  @override
  String get prefFocusAreaChest => '胸部';

  @override
  String get prefFocusAreaBack => '背部';

  @override
  String get prefFocusAreaShoulders => '肩部';

  @override
  String get prefFocusAreaArms => '手臂';

  @override
  String get prefFocusAreaLegs => '腿部';

  @override
  String get prefFocusAreaCore => '核心';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyLoadFailed => '加载失败';

  @override
  String get historyEmpty => '暂无记录';

  @override
  String get historyEmptyHint => '完成一次训练后查看结果';

  @override
  String get historyClearConfirmTitle => '清除历史';

  @override
  String get historyClearConfirmBody => '确定要清除所有历史记录吗？';

  @override
  String get historyPlanMode => '计划模式';

  @override
  String get historyFreeWorkout => '自由训练';

  @override
  String get historyCompletedSets => '已完成组数';

  @override
  String historySetsSuffix(int count) {
    return '$count组';
  }

  @override
  String historyExercisesSuffix(int count) {
    return '$count动作';
  }

  @override
  String get recDetailTitle => '训练详情';

  @override
  String get recDetailBackTooltip => '返回';

  @override
  String get recDetailExercisesSection => '动作详情';

  @override
  String get recDetailStatTotalSets => '总组数';

  @override
  String get recDetailStatExerciseCount => '动作数';

  @override
  String get recDetailStatMuscles => '训练部位';

  @override
  String get recDetailNone => '无';

  @override
  String get recDetailAddSet => '添加组';

  @override
  String get recDetailTotalVolume => '总容量';

  @override
  String get recDetailAddDataPrompt => '点击添加训练数据';

  @override
  String get recDetailSaved => '已保存';

  @override
  String recDetailSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get recDetailUnsavedTitle => '保存更改？';

  @override
  String get recDetailUnsavedBody => '你有未保存的更改，是否保存？';

  @override
  String get recDetailDontSave => '不保存';

  @override
  String get recDetailUnknownExercise => '未知动作';

  @override
  String get recDetailUnspecifiedMuscle => '未指定';

  @override
  String get recDetailDeleteButton => '删除此记录';

  @override
  String get recDetailDeleteTitle => '删除记录';

  @override
  String get recDetailDeleteBody => '确定要删除这条训练记录吗？此操作无法撤销。';

  @override
  String get recDetailDeleted => '已删除';

  @override
  String recDetailDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String get recDetailDeleteAction => '删除';

  @override
  String get planTitle => '训练计划';

  @override
  String get planAiButton => 'AI训练计划';

  @override
  String get planTodayPlans => '今日计划';

  @override
  String plansForDate(String date) {
    return '$date 的计划';
  }

  @override
  String get planAddButton => '+ 添加';

  @override
  String get planRemoveTitle => '移除计划';

  @override
  String planRemoveFromDateConfirm(int month, int day, String name) {
    return '确定要从 $month月$day日 移除「$name」吗？';
  }

  @override
  String get planRemoveAction => '移除';

  @override
  String planRemovedToast(int month, int day, String name) {
    return '已从$month月$day日移除「$name」';
  }

  @override
  String get planLibraryButton => '📚 我的计划库';

  @override
  String get planEmptyAddToday => '添加今日计划';

  @override
  String planSelectToAddTitle(int month, int day) {
    return '选择计划添加到 $month月$day日';
  }

  @override
  String get planCreateNew => '创建新计划';

  @override
  String get planLibraryTitle => '我的计划库';

  @override
  String get planEdit => '编辑';

  @override
  String get planDelete => '删除';

  @override
  String planAddedToDateToast(int month, int day, String name) {
    return '已将「$name」添加到 $month月$day日';
  }

  @override
  String planAddFailed(String error) {
    return '添加失败: $error';
  }

  @override
  String get planDeleteTitle => '删除计划';

  @override
  String planDeleteConfirm(String name) {
    return '确定要删除「$name」吗？此操作无法撤销。';
  }

  @override
  String planDeletedToast(String name) {
    return '已删除「$name」';
  }

  @override
  String planDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String planDetailTargetMuscles(String muscles) {
    return '目标部位：$muscles';
  }

  @override
  String get planDetailExerciseCountUnit => '个动作';

  @override
  String get planDetailSetsUnit => '组';

  @override
  String get planDetailMinutesUnit => '分钟';

  @override
  String get planDetailExerciseList => '动作列表';

  @override
  String get planDetailNoDetailsSuffix => '(无详情)';

  @override
  String planDetailEffectiveSets(int count) {
    return '$count组';
  }

  @override
  String get planDetailAddToCalendar => '添加到日历';

  @override
  String get planDetailStartTraining => '开始训练';

  @override
  String get exSelectTitle => '选择训练动作';

  @override
  String get exFavoritesChip => '收藏';

  @override
  String get exSelectHint => '点击动作卡片选择';

  @override
  String get equipmentAll => '全部';

  @override
  String get aiCloseTooltip => '关闭';

  @override
  String get aiTitle => 'AI 计划生成器';

  @override
  String get aiPreviousStep => '上一步';

  @override
  String get aiStepImportAnalysis => '导入分析';

  @override
  String get aiStepPreviewImport => '预览导入';

  @override
  String get aiStepProfile => '个人资料';

  @override
  String get aiStepGeneratePrompt => '生成提示词';

  @override
  String get aiStepPasteJson => '粘贴JSON';

  @override
  String get aiTabNewPlan => '新建计划';

  @override
  String get aiTabImportAnalysis => '导入分析';

  @override
  String get aiNewPlanHeading => '个人训练资料';

  @override
  String get aiNewPlanSubheading => '请回答以下问题，帮助AI生成最适合您的训练计划';

  @override
  String get aiQuestionFrequency => '每周训练频率';

  @override
  String get aiQuestionDuration => '训练时长';

  @override
  String get aiQuestionEquipment => '设备可用性';

  @override
  String aiDurationMinutes(int count) {
    return '$count分钟';
  }

  @override
  String get aiImportHeading => '导入AI分析计划';

  @override
  String get aiImportSubheading => '将AI返回的JSON计划粘贴到下方，预览后直接导入';

  @override
  String get aiJsonLabel => 'JSON内容';

  @override
  String get aiJsonHelper => '请粘贴AI生成的训练计划JSON';

  @override
  String get aiParsing => '解析中...';

  @override
  String get aiParseJson => '解析JSON';

  @override
  String get aiErrorEmptyJson => '请输入JSON内容';

  @override
  String get aiErrorInvalidJson => '未能识别有效的训练计划JSON，请确保AI回复中包含 days 数组。';

  @override
  String aiErrorParseFailed(String error) {
    return 'JSON解析失败: $error';
  }

  @override
  String get aiGeneratePromptHeading => '生成AI提示词';

  @override
  String get aiGeneratePromptSubheading => '设置开始日期并生成提示词，复制到AI应用获取训练计划';

  @override
  String get aiStartDateLabel => '开始日期';

  @override
  String aiDateDisplay(int year, int month, int day) {
    return '$year年$month月$day日';
  }

  @override
  String get aiGeneratePromptButton => '生成提示词';

  @override
  String get aiGeneratedPromptLabel => '生成的提示词';

  @override
  String get aiCopyToClipboard => '复制到剪贴板';

  @override
  String get aiCopyHint => '将此提示词复制到豆包/千问等AI应用，获取JSON后返回粘贴';

  @override
  String get aiCopiedToast => '已复制到剪贴板';

  @override
  String get aiPasteJsonHeading => '粘贴AI返回的JSON';

  @override
  String get aiPasteJsonSubheading => '将AI生成的JSON粘贴到下方文本框';

  @override
  String get aiPreviewEmpty => '请先解析JSON以预览训练计划';

  @override
  String get aiPreviewHeading => '预览训练计划';

  @override
  String aiPlanNameLabel(String name) {
    return '计划名称: $name';
  }

  @override
  String get aiImporting => '导入中...';

  @override
  String get aiConfirmImport => '确认导入';

  @override
  String aiMatchSummary(int matched, int candidates, int unmatched) {
    return '匹配：$matched个 ✅ | 待选：$candidates个 ⚠️ | 未匹配：$unmatched个';
  }

  @override
  String get aiDayNameMon => '周一';

  @override
  String get aiDayNameTue => '周二';

  @override
  String get aiDayNameWed => '周三';

  @override
  String get aiDayNameThu => '周四';

  @override
  String get aiDayNameFri => '周五';

  @override
  String get aiDayNameSat => '周六';

  @override
  String get aiDayNameSun => '周日';

  @override
  String aiDayTitle(int n, String name) {
    return '第$n天 - $name';
  }

  @override
  String get aiRestDay => '休息日';

  @override
  String aiExerciseCountSuffix(int count) {
    return '$count个动作';
  }

  @override
  String aiTargetMusclesLabel(String muscles) {
    return '目标肌群: $muscles';
  }

  @override
  String aiCandidatesBadge(int count) {
    return '$count个候选';
  }

  @override
  String aiOriginalLabel(String name) {
    return '原: $name';
  }

  @override
  String get aiDecreaseSets => '减少';

  @override
  String get aiIncreaseSets => '增加';

  @override
  String get aiSetsUnit => '组';

  @override
  String get aiSelectMatchTitle => '选择匹配的动作';

  @override
  String aiSelectMatchSubtitle(String name, int count) {
    return 'AI生成的\"$name\"有$count个候选';
  }

  @override
  String get aiKeepUnmatched => '保持为\"无详情\"';

  @override
  String get aiImportConfirmTitle => '确认导入';

  @override
  String get aiImportConfirmBody => '确定要导入这个训练计划吗？计划将被添加到日历中。';

  @override
  String get aiImportSuccessToast => '训练计划导入成功！';

  @override
  String aiImportFailedToast(String error) {
    return '导入失败: $error';
  }

  @override
  String get aiNextPreviewImport => '下一步：预览导入';

  @override
  String get aiComplete => '完成';

  @override
  String get aiNextGeneratePrompt => '下一步：生成提示词';

  @override
  String get aiNextPasteJson => '下一步：粘贴JSON';

  @override
  String get pfCloseTooltip => '关闭';

  @override
  String get pfCreateTitle => '创建计划';

  @override
  String get pfEditTitle => '编辑计划';

  @override
  String get pfStepSelectMuscle => '选择部位';

  @override
  String get pfStepSelectExercise => '选择动作';

  @override
  String get pfStepConfirm => '确认计划';

  @override
  String get pfSelectMuscleHeading => '选择训练部位';

  @override
  String get pfSelectMuscleSubheading => '选择计划要覆盖的肌肉部位（可多选）';

  @override
  String get pfQuickSelect => '快速选择';

  @override
  String get pfQuickUpper => '上肢';

  @override
  String get pfQuickLower => '下肢';

  @override
  String get pfQuickFull => '全身';

  @override
  String pfQuickRemovedToast(String muscles) {
    return '已移除：$muscles';
  }

  @override
  String pfQuickAddedToast(String muscles) {
    return '已添加：$muscles';
  }

  @override
  String get pfSelectExerciseHeading => '选择训练动作';

  @override
  String pfSelectedMusclesLine(String muscles) {
    return '已选部位：$muscles';
  }

  @override
  String get pfNotSelected => '未选择';

  @override
  String get pfSelectedExercisesHeading => '已选动作';

  @override
  String get pfClearSelectedTitle => '清空已选动作？';

  @override
  String get pfClearSelectedBody => '确定要清空所有已选动作吗？此操作无法撤销。';

  @override
  String get pfNoDetailsSuffix => '(无详情)';

  @override
  String pfSetsSuffix(int count) {
    return '($count组)';
  }

  @override
  String get pfContinueAdding => '继续添加动作';

  @override
  String pfSelectedCountLine(int count) {
    return '已选 $count 个动作';
  }

  @override
  String get pfConfirmHeading => '确认计划';

  @override
  String get pfPlanNameLabel => '计划名称';

  @override
  String get pfPlanNameHint => '例如：上肢训练日';

  @override
  String get pfSummaryHeading => '计划摘要';

  @override
  String get pfSummaryMuscles => '训练部位';

  @override
  String get pfSummaryExerciseCount => '动作数量';

  @override
  String pfExerciseCountValue(int count) {
    return '$count 个';
  }

  @override
  String get pfSummaryTotalSets => '总组数';

  @override
  String pfTotalSetsValue(int count) {
    return '$count 组';
  }

  @override
  String get pfSummaryDuration => '预估时长';

  @override
  String pfDurationValue(int count) {
    return '~$count 分钟';
  }

  @override
  String get pfDurationFootnote => '※ 预估时长 = 总组数 × 2.5分钟（含休息）';

  @override
  String get pfAdjustSetsHeading => '调整组数（可拖拽排序）';

  @override
  String get pfDecreaseSets => '减少组数';

  @override
  String get pfIncreaseSets => '增加组数';

  @override
  String get pfDeleteExercise => '删除动作';

  @override
  String get pfNextSelectExercise => '下一步：选择动作';

  @override
  String get pfNextConfirm => '下一步：确认计划';

  @override
  String get pfSaveChanges => '保存修改';

  @override
  String get pfPreviousStep => '上一步';

  @override
  String get pfDefaultPlanName => '训练计划';

  @override
  String pfSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get pfDiscardTitle => '放弃编辑？';

  @override
  String get pfDiscardBody => '您有未保存的更改，确定要退出吗？';

  @override
  String get pfKeepEditing => '继续编辑';

  @override
  String get pfDiscard => '放弃';

  @override
  String get anTitle => 'AI 训练分析';

  @override
  String get anInstructionsHeading => '使用说明';

  @override
  String get anInstruction1 => '1. 查看下方的训练数据报告';

  @override
  String get anInstruction2 => '2. 复制生成的提示词';

  @override
  String get anInstruction3 => '3. 粘贴给 ChatGPT / 豆包 / 千问 等 AI';

  @override
  String get anInstruction4 => '4. AI 会返回分析建议和 JSON 计划';

  @override
  String get anInstruction5 => '5. 前往「计划」页面 →「导入分析」导入计划';

  @override
  String get anReportHeading => '训练数据报告';

  @override
  String get anPromptHeading => '生成的提示词';

  @override
  String get anGeneratingPrompt => '正在生成提示词...';

  @override
  String get anCopiedToast => '提示词已复制到剪贴板';

  @override
  String get anCopiedLabel => '已复制';

  @override
  String get anCopyPrompt => '复制提示词';

  @override
  String get anCloseTooltip => '关闭';

  @override
  String get anBasicInfo => '基本信息';

  @override
  String anSessionsAndDays(int sessions, int days) {
    return '$sessions 次 / $days 天';
  }

  @override
  String get anSessionCount => '训练次数';

  @override
  String get anTotalVolume => '总训练量';

  @override
  String get anDensity => '训练密度';

  @override
  String anDensityValue(String value) {
    return '$value 组/分钟';
  }

  @override
  String get anAvgPerSession => '平均每次';

  @override
  String anAvgPerSessionValue(String volume, int minutes) {
    return '$volume kg / $minutes 分钟';
  }

  @override
  String get anTrendWeek => '趋势变化 (vs 上周)';

  @override
  String get anTrendMonth => '趋势变化 (vs 上月)';

  @override
  String get anMuscleDistribution => '肌肉容量分布';

  @override
  String get anSetsPerMuscleWeek => '每肌群组数 (MEV参考: 10组/周)';

  @override
  String get anSetsPerMuscleMonth => '每肌群组数 (MEV参考: 40组/月)';

  @override
  String get anEstimated1rm => '估算1RM (Mayhew公式)';

  @override
  String get an1rmProgression => '估算1RM进步趋势';

  @override
  String get anRecovery => '恢复状态';

  @override
  String get anNoMuscleData => '- 暂无肌肉训练数据';

  @override
  String get anNoTrendData => '- 暂无趋势数据';

  @override
  String get anNoSetsData => '- 暂无组数数据';

  @override
  String get anNo1rmData => '- 暂无1RM数据（需要每组重量和次数记录）';

  @override
  String get anNo1rmTrendData => '- 暂无1RM趋势数据';

  @override
  String get anNoProgressData => '- 本周期内各动作仅训练1次，无法计算进步趋势';

  @override
  String get anNoRecoveryData => '- 暂无恢复数据';

  @override
  String get anNoMuscleRecoveryData => '- 暂无肌肉恢复数据';

  @override
  String anMevWeekLabel(int count) {
    return '周MEV参考: $count 组';
  }

  @override
  String anMevMonthLabel(int count) {
    return '月MEV参考: $count 组';
  }

  @override
  String get anStatusSufficient => '✅ 充足';

  @override
  String get anStatusLow => '⚠️ 偏低';

  @override
  String get anStatusInsufficient => '🔴 不足';

  @override
  String get anMayhewNote => '  (基于 Mayhew 公式估算，±5-8kg 误差)';

  @override
  String get anRecoveryTrainable => '✅ 可训练';

  @override
  String anRecoveryRestMore(int days) {
    return '⚠️ 建议再休息$days天';
  }

  @override
  String get anRecoveryJustTrained => '🔴 今日刚训练';

  @override
  String get anPeriodWeek => '本周';

  @override
  String get anPeriodMonth => '本月';

  @override
  String get anWeek => '周';

  @override
  String get anMonth => '月';

  @override
  String get anGoalMuscleBuilding => '增肌';

  @override
  String get anGoalFatLoss => '减脂';

  @override
  String get anGoalStrength => '力量提升';

  @override
  String get anGoalEndurance => '耐力增强';

  @override
  String anDateRange(int startMonth, int startDay, int endMonth, int endDay) {
    return '$startMonth月$startDay日 - $endMonth月$endDay日';
  }

  @override
  String get anPromptOpening => '你是一位专业的健身教练。根据我的训练数据报告，为我制定下个周期的训练计划。';

  @override
  String get anPromptWeekNote => '本周数据量较少，重点关注恢复状态和下周的肌群轮换安排。';

  @override
  String get anPromptMonthNote => '本月数据较充分，重点关注渐进超负荷趋势和肌群容量分配是否均衡。';

  @override
  String get anPromptReportHeader => '## 训练数据报告';

  @override
  String get anPromptBasicInfoHeader => '### 基本信息';

  @override
  String anPromptPeriod(String period, String range) {
    return '- 分析周期: $period ($range)';
  }

  @override
  String anPromptSessions(int sessions, int days) {
    return '- 训练次数: $sessions 次 / $days 天';
  }

  @override
  String anPromptTotalVolume(String volume) {
    return '- 总训练量: $volume kg (组×次×重量)';
  }

  @override
  String anPromptDensity(String value) {
    return '- 训练密度: $value 组/分钟';
  }

  @override
  String anPromptTrendHeader(String period) {
    return '### 趋势变化（vs 上$period）';
  }

  @override
  String get anPromptMuscleDistHeader => '### 肌肉容量分布';

  @override
  String get anPromptSetsPerMuscleHeader => '### 每肌群组数';

  @override
  String get anPrompt1rmHeader => '### 估算1RM（本周期最佳，TOP 10）';

  @override
  String get anPrompt1rmProgressionHeader => '### 估算1RM进步趋势';

  @override
  String get anPromptRecoveryHeader => '### 恢复状态（截至今天，全局数据）';

  @override
  String get anPromptProfileHeader => '## 用户画像';

  @override
  String anPromptGoal(String goal) {
    return '- 训练目标: $goal';
  }

  @override
  String anPromptExperience(String experience) {
    return '- 经验水平: $experience';
  }

  @override
  String anPromptFrequency(int frequency) {
    return '- 每周频率: $frequency 天';
  }

  @override
  String anPromptEquipment(String equipment) {
    return '- 可用设备: $equipment';
  }

  @override
  String anPromptFocusAreas(String areas) {
    return '- 重点加强: $areas';
  }

  @override
  String get anPromptOutputHeader => '## 输出格式';

  @override
  String get anPromptOutputIntro => '请按以下两部分输出你的回复：';

  @override
  String get anPromptOutputPart1 => '**第一部分：计划设计说明**';

  @override
  String get anPromptOutputPart1Detail =>
      '根据我的训练数据报告，详细说明你为什么这样设计下个周期的训练计划，包括：';

  @override
  String anPromptOutputSplit(int days) {
    return '- 分化方式的选择理由（结合我每周 $days 天的训练频率）';
  }

  @override
  String get anPromptOutputComparison =>
      '- 与本周期数据的对比分析（哪些肌群训练不足需要加强，哪些已经过度需要恢复）';

  @override
  String get anPromptOutputSelection => '- 每个训练日的动作选择逻辑和容量分配依据';

  @override
  String get anPromptOutputOverload => '- 渐进超负荷的具体建议（重量、组数、频率的调整方向）';

  @override
  String get anPromptOutputPart2 => '**第二部分：训练计划 JSON**';

  @override
  String get anPromptOutputJson => '在分析之后，用 ```json 代码块提供结构化训练计划：';

  @override
  String get anPromptNamingHeader => '## 动作命名规范';

  @override
  String get anPromptNamingIntro => '使用标准英文动作名：';

  @override
  String get anPromptNamingClosing => '如果不确定确切名称，使用标准术语即可。';

  @override
  String get anPromptClosing => '请先解释你的设计思路和分析，然后生成训练计划。';

  @override
  String anPromptVolumeTrendWithChange(
    String volume,
    String sign,
    int change,
    String arrow,
  ) {
    return '  - 总训练量: $volume ($sign$change% $arrow)';
  }

  @override
  String anPromptVolumeTrendNew(String volume) {
    return '  - 总训练量: $volume (新周期)';
  }

  @override
  String anPromptFreqTrend(int days, int diff, String arrow) {
    return '  - 训练频率: $days 天 ($diff$arrow)';
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
    return '  - $muscle: $sets 组 $status';
  }

  @override
  String anPrompt1rmLine(String name, String e1rm, String weight, int reps) {
    return '  - $name: ~$e1rm kg (基于 ${weight}kg×$reps)';
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
    return ' / $weeks周';
  }

  @override
  String anPromptRecoveryLine(String muscle, int days, String status) {
    return '  - $muscle: 已休息$days天 $status';
  }
}
