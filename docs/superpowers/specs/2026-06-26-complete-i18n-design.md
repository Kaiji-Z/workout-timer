# 完整多语言（i18n）支持设计文档

**日期:** 2026-06-26
**分支:** master
**作者:** WorkoutTimer Developer
**状态:** 待评审

---

## 1. 背景与现状

### 1.1 现有 i18n 基础设施（已就绪）
- `l10n.yaml` 配置：`arb-dir: lib/l10n`，模板 `app_zh.arb`，输出类 `AppLocalizations`
- `MaterialApp` 已挂 `localizationsDelegates` + `supportedLocales`（main.dart:109-110）
- 中英 ARB 各 60 个 key，覆盖：app 标题、底部导航、计时器、训练流程、记录对话框、通知、铃声名、日历前后月、OEM 后台管理
- `Exercise` model 已有 `nameEn` 字段（英文原名，源自 free-exercise-db 的英文数据）
- `PrimaryMuscleGroup` / `SecondaryMuscleGroup` 都已有 `displayName`（中）+ `nameEn`（英）

### 1.2 主要缺陷
| 缺陷 | 现状 |
|------|------|
| **~15,853 个硬编码中文字符** | 散落在 11 个屏幕 + 大部分 widget + service 层 |
| **11 个主屏幕全部硬编码** | `stats_screen`(1223)、`settings_screen`(992)、`ai_analysis_screen`(783)、`plan_form_screen`(642)、`ai_plan_wizard_screen`(588) 等，**没有一个**导入 AppLocalizations |
| **无 locale 切换机制** | `MaterialApp` 无 `locale:` 参数、无 LocaleProvider、无语言选择器、日期格式硬编码 `zh_CN` |
| **英文 ARB 是死代码** | 因为没 locale 切换，运行时永远解析成中文，英文 key 永远不被消费 |
| **13 个已定义未消费的 key** | `notif*`、`sound*`、`oem*` 在 ARB 里存在但代码用硬编码 |
| **服务层用户可见文本硬编码** | notification_service（通知文案）、error_reporter（错误消息）、data_transfer_service（导入导出提示，471 字符）、ai_prompt_service（AI 提示词，193 字符） |
| **数据层格式化硬编码** | `ExerciseRecommendation.restText`("分钟/秒")、`repsRangeText`("次")、`Exercise.levelDisplayName`("初/中/高级")、`equipmentDisplayName`("杠铃/哑铃...") |

### 1.3 已有良好基础（减少工作量）
- 数据层动作名/肌肉名的英文版**已经存在**（`nameEn` 字段），无需数据迁移
- 数据库原始 JSON 本身就是英文
- ThemeProvider 是 LocaleProvider 的完美模板（同样的 ChangeNotifier + SharedPreferences 模式）

---

## 2. 目标与非目标

### 2.1 目标
1. **应用内语言切换**：设置页提供「跟随系统 / 简体中文 / English」三选项，SharedPreferences 持久化
2. **100% UI 文本本地化**：所有 11 个屏幕 + 所有 widget 的用户可见文本走 AppLocalizations
3. **服务层本地化**：通知、错误消息、AI 提示词、数据导入导出提示全部本地化
4. **数据层本地化**：肌肉名、动作名、器械名、难度名根据 locale 显示对应语言
5. **日期/时间格式本地化**：英文 locale 下用英文日期格式
6. **死代码激活**：13 个已定义未消费的 ARB key 接入代码
7. **远程推送**：原子化 commit + 双推（origin GitHub 触发 CI + gitee 镜像）

### 2.2 非目标
- 不新增第三种语言（仅 zh/en，后续加语言只需复制 ARB 文件）
- 不重构 gen-l10n 体系（保持现有 AppLocalizations 架构）
- 不引入新的 i18n 依赖包（如 easy_localization）
- 不改动数据库 schema（locale 仅影响显示，不影响存储）

---

## 3. 架构设计

### 3.1 整体架构（方案 A：纯 gen-l10n + 服务层注入）

```
┌─────────────────────────────────────────────────────────┐
│  LocaleProvider (ChangeNotifier)                         │
│  - localeCode: 'system' | 'zh' | 'en'                    │
│  - effectiveLocale: Locale (resolve 'system' → 设备)     │
│  - 持久化到 SharedPreferences (key: 'app_locale')        │
└──────────────┬──────────────────────────────────────────┘
               │ watch / read
               ▼
┌─────────────────────────────────────────────────────────┐
│  MaterialApp                                             │
│  - locale: localeProvider.effectiveLocale                │
│  - localizationsDelegates: AppLocalizations.localizationsDelegates │
│  - supportedLocales: AppLocalizations.supportedLocales   │
└──────────────┬──────────────────────────────────────────┘
               │ Flutter 注入
               ▼
┌─────────────────────────────────────────────────────────┐
│  UI 层 (screens + widgets)                               │
│  final l10n = AppLocalizations.of(context)!;             │
│  Text(l10n.someKey)                                      │
└─────────────────────────────────────────────────────────┘
               ▲
               │ 服务层无 BuildContext，需注入
┌──────────────┴──────────────────────────────────────────┐
│  ServiceLocator 注册一个 root AppLocalizations 实例       │
│  - ServiceLocator.get<AppLocalizations>() 返回当前 locale │
│    对应的实例（由 LocaleProvider.locale 变化时刷新）       │
│  - notification/error_reporter/ai_prompt 等服务用它       │
└─────────────────────────────────────────────────────────┘
```

### 3.2 LocaleProvider 设计

新增 `lib/providers/locale_provider.dart`：

```dart
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  // 'system' 表示跟随设备；其它为具体语言代码
  String _localeCode = 'system';
  Locale? _deviceLocale; // 启动时从 platform resolved

  String get localeCode => _localeCode;

  /// 实际生效的 Locale（'system' → 解析设备 locale，回退 zh）
  Locale get effectiveLocale {
    if (_localeCode == 'system') {
      return _deviceLocale ?? const Locale('zh');
    }
    return Locale(_localeCode);
  }

  Future<void> initialize() async { /* 从 prefs 读，并读 platform locale */ }
  Future<void> setLocaleCode(String code) async { /* 存 prefs + notifyListeners */ }
}
```

### 3.3 服务层本地化注入

**问题**：服务（NotificationService、ErrorReporter 等）无 BuildContext，无法 `AppLocalizations.of(context)`。

**方案**：gen-l10n 生成了一个**顶层函数** `lookupAppLocalizations(Locale locale)`（见 `app_localizations.dart:509`），可无 context 直接调用。服务层只需注入一个 **当前 Locale**，需要本地化时调用 `lookupAppLocalizations(locale)`。

具体做法：
- `ServiceLocator` 注册一个 `ValueNotifier<Locale>`（root locale），由 LocaleProvider 在 locale 变化时刷新其 `value`
- 服务层用法：
```dart
// notification_service.dart
final locale = ServiceLocator.get<ValueNotifier<Locale>>().value;
final l10n = lookupAppLocalizations(locale);
title: l10n.notifRestDone;
```
- 启动早期未初始化时，`ValueNotifier` value 默认 `Locale('zh')`（兜底中文），避免崩溃
- 服务层若在非常早期（ServiceLocator.setup 之前）就被调用，用 try/catch 回退中文硬编码字面量

### 3.4 数据层本地化

不动 schema，只改显示。引入一个轻量 helper：

```dart
// lib/utils/localized_display.dart
/// 根据 locale 选择肌肉/动作的显示名
class LocalizedDisplay {
  /// 动作名：英文 locale 用 nameEn，中文用 name（或 nameZh）
  static String exerciseName(Exercise e, Locale locale) {
    if (locale.languageCode == 'en') return e.nameEn.isNotEmpty ? e.nameEn : e.name;
    return e.name; // 中文 name 字段已存中文翻译
  }

  /// 主要肌肉群名
  static String primaryMuscle(PrimaryMuscleGroup m, Locale locale) =>
      locale.languageCode == 'en' ? m.nameEn : m.displayName;

  /// 次要肌肉群名
  static String secondaryMuscle(SecondaryMuscleGroup m, Locale locale) =>
      locale.languageCode == 'en' ? m.nameEn : m.displayName;
}
```

UI 调用处改为：
```dart
final locale = context.read<LocaleProvider>().effectiveLocale;
Text(LocalizedDisplay.primaryMuscle(muscle, locale))
```

`ExerciseRecommendation.restText` / `repsRangeText` 等 getter 改为接受 `AppLocalizations` 参数的方法，或改到 UI 层格式化（更干净）。**决策：getter 改为接受 l10n 参数的方法**，保持单一职责。

`equipmentDisplayName` / `levelDisplayName` 走 ARB key（`equipmentBarbell`、`levelBeginner` 等）。

---

## 4. 实施分层与 commit 计划

按 AGENTS.md 原子提交原则，**每层、每个屏幕单独 commit**，类型分明。共 27 个 commit（阶段 0-5），阶段 6 为 git 推送操作（非 commit）。

### 阶段 0：基础设施（骨架）— 3 commits
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 1 | `feat(i18n)` | providers | 新增 `LocaleProvider`（ChangeNotifier + SharedPreferences + system/zh/en） |
| 2 | `feat(i18n)` | core | ServiceLocator 注册 `ValueNotifier<Locale>`（root locale），LocaleProvider 刷新其 value；服务层用 `lookupAppLocalizations(locale)` 取本地化文本 |
| 3 | `refactor(main)` | main | main.dart 接入 LocaleProvider，MaterialApp 挂 `locale:`，移除硬编码 `initializeDateFormatting('zh_CN')` 改为动态 |

### 阶段 1：数据层本地化 — 3 commits
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 4 | `test(models)` | models | 新增肌肉/动作/器械/难度的显示名 locale 选择测试（RED） |
| 5 | `feat(models)` | models, utils | `LocalizedDisplay` helper + `ExerciseRecommendation` getter 改方法 + `levelDisplayName`/`equipmentDisplayName` 走 ARB（GREEN） |
| 6 | `feat(i18n)` | arb | 新增肌肉群/器械/难度相关的 ARB key（中英） |

### 阶段 2：服务层本地化 — 4 commits
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 7 | `feat(i18n)` | services | notification_service 用 root AppLocalizations（激活 `notif*` key） |
| 8 | `feat(i18n)` | services | notification_sound_service 用 root AppLocalizations（激活 `sound*` key） |
| 9 | `feat(i18n)` | services | error_reporter_service 用 root AppLocalizations（默认错误消息本地化） |
| 10 | `feat(i18n)` | services | data_transfer_service + ai_prompt_service 本地化（含 ARB key 新增） |

### 阶段 3：widgets 本地化 — 3 commits
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 11 | `feat(i18n)` | widgets | 已部分本地化的 widget 补全：training_widget、timer_widget（清 TODO）、set_record_dialog、weight_input_dialog、bulk_exercise_data_dialog、calendar_widget |
| 12 | `feat(i18n)` | widgets | 未本地化的 widget：exercise_selector、glass_widgets、plan_card、duration_picker、completed_medal_display、fullscreen_image_viewer、muscle_selector、ui_components、animated_timer_widget |
| 13 | `feat(i18n)` | arb | widgets 相关 ARB key 补全 |

### 阶段 4：screens 本地化 — 11 commits（每屏 1 个）
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 14 | `feat(i18n)` | settings | settings_screen 全量本地化 + **语言选择器**（跟随系统/中文/English）+ OEM 卡片接 `oem*` key |
| 15 | `feat(i18n)` | stats | stats_screen（1223 字符）本地化 |
| 16 | `feat(i18n)` | ai_analysis | ai_analysis_screen（783 字符）本地化 |
| 17 | `feat(i18n)` | plan_form | plan_form_screen（642 字符）本地化 |
| 18 | `feat(i18n)` | ai_plan_wizard | ai_plan_wizard_screen（588 字符）本地化 |
| 19 | `feat(i18n)` | exercise_selection | exercise_selection_screen（412 字符）本地化 |
| 20 | `feat(i18n)` | plan | plan_screen（313 字符）本地化 |
| 21 | `feat(i18n)` | record_detail | record_detail_screen（298 字符）本地化 |
| 22 | `feat(i18n)` | history | history_screen（153 字符）本地化 |
| 23 | `feat(i18n)` | user_preferences | user_preferences_screen（110 字符）本地化 |
| 24 | `feat(i18n)` | timer | timer_screen 收尾本地化 |

### 阶段 5：验证与收尾 — 3 commits
| # | 类型 | 范围 | 内容 |
|---|------|------|------|
| 25 | `refactor(i18n)` | main | 清理 main.dart 硬编码（title、中心按钮 semantics） |
| 26 | `docs` | docs | 更新 AGENTS.md「KNOWN ISSUES」移除「i18n partial」、补充 locale 切换说明 |
| 27 | `test(i18n)` | test | 新增 locale 切换集成测试 + ARB key 覆盖检查 |

### 阶段 6：推送
- `git push origin` → 触发 GitHub Actions（android + ios CI）
- `git push gitee master` → 同步镜像

---

## 5. ARB key 命名规范

延续现有风格（camelCase + 语义前缀），新增 key 按模块分组：

| 前缀 | 模块 | 示例 |
|------|------|------|
| `settings*` | 设置页 | `settingsLanguage`, `settingsLanguageSystem`, `settingsLanguageZh`, `settingsLanguageEn`, `settingsDarkMode` |
| `stats*` | 统计页 | `statsTitle`, `statsWeeklyView`, `statsMonthlyView`, `statsTotalSets`, `statsVsLastPeriod` |
| `plan*` | 计划 | `planCreateTitle`, `planEditTitle`, `planSelectMuscle`, `planUpperBody`, `planLowerBody` |
| `planForm*` | 计划表单 | `planFormStepMuscle`, `planFormStepExercise`, `planFormStepConfirm` |
| `ai*` | AI 功能 | `aiWizardTitle`, `aiAnalysisTitle`, `aiRecommendation` |
| `history*` | 历史 | `historyEmpty`, `historyTotalDuration` |
| `record*` | 记录详情 | `recordDate`, `recordMuscles`, `recordTotalVolume` |
| `exercise*` | 动作选择 | `exerciseSearchHint`, `exerciseFilterAll`, `exerciseFavorites` |
| `pref*` | 用户偏好 | `prefGoal`, `prefFrequency`, `prefEquipment` |
| `equipment*` | 器械 | `equipmentBarbell`, `equipmentDumbbell`, `equipmentBodyweight` |
| `level*` | 难度 | `levelBeginner`, `levelIntermediate`, `levelExpert` |
| `error*` | 错误 | `errorSaveFailed`, `errorLoadFailed`, `errorGeneric` |
| `dataTransfer*` | 数据迁移 | `dataTransferExportTitle`, `dataTransferImportSuccess` |
| `oem*`（已存在） | OEM 后台 | 复用已有 13 个 key |

**约定**：模板 `app_zh.arb` 是 single source of truth，每个 key 必须带 `@key` 描述（含 placeholders 声明）。`app_en.arb` 同步翻译。

---

## 6. 关键技术决策

### 6.1 为什么用 `ValueNotifier<Locale>` 注入服务层而非传参？
- **传参**（每个方法加 `AppLocalizations`/`Locale` 参数）：侵入性大，每个调用栈都要透传，易漏
- **ValueNotifier 单例**：服务层 `ServiceLocator.get<ValueNotifier<Locale>>().value` 一行拿到当前 locale，再调用 `lookupAppLocalizations(locale)` 即可；与现有 ServiceLocator 模式一致
- 兜底：启动早期 `ValueNotifier` 默认 value 为 `Locale('zh')`，避免崩溃
- 比 `ValueNotifier<AppLocalizations?>` 更简洁——locale 是单一原子值，且 `lookupAppLocalizations` 是现成的顶层函数

### 6.2 数据层为何不改 schema？
- locale 是**显示**关注点，非**存储**关注点
- 动作名/肌肉名在 DB 里存原始英文/枚举值即可，显示时由 `LocalizedDisplay` 按 locale 映射
- 已有 `nameEn` + `nameZh` 字段足够，无需迁移

### 6.3 跟随系统 locale 如何解析？
- 启动时 `PlatformDispatcher.instance.locale` 拿设备 locale
- 若设备 locale 不在 `supportedLocales`（zh/en）内，回退 zh（中文是主要受众）
- 用户显式选了 zh/en 则覆盖系统值
- `effectiveLocale` getter 统一 resolve

### 6.4 日期格式化
- 移除 `initializeDateFormatting('zh_CN', null)` 硬编码
- 改为 `initializeDateFormatting(effectiveLocale.toLanguageTag(), null)`
- 英文 locale 用 `en_US`，中文用 `zh_CN`
- 使用 intl 的 `DateFormat.yMMMd(locale)` 等带 locale 参数的构造

---

## 7. 测试策略

### 7.1 单元测试
- `LocalizedDisplay` 在 zh/en locale 下分别返回正确名称
- `LocaleProvider` system/zh/en 三态切换 + 持久化
- `ExerciseRecommendation.restText(l10n)` 中英格式化

### 7.2 集成测试
- LocaleProvider 切换后 MaterialApp.locale 更新、AppLocalizations 重建
- 设置页语言选择器交互

### 7.3 守卫测试（防回归）
- 一个源码扫描测试：检查「目标文件里不再有硬编码中文字符串字面量」（类似现有 `compliance_guardrail_test.dart` 的模式）
- ARB 一致性测试：`app_zh.arb` 与 `app_en.arb` 的 key 集合完全相等（防止漏译）

### 7.4 人工验证
- 切英文 → 跑一遍 timer/training 流程
- 切英文 → 设置页、统计页、AI 分析页
- 切回中文 → 确认无残留英文
- 重启 app → 确认 locale 持久化

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| 服务层 ValueNotifier 在 locale 切换时通知不及时 | 通知/错误消息短暂显示旧语言 | LocaleProvider.setLocaleCode 后立即 `_refreshRootLocalizations()` 同步刷新 |
| 大量 ARB key 翻译质量参差 | 英文用户体验不佳 | 翻译时对照现有英文 ARB 风格（简洁、健身术语专业）；动作名用数据库原生英文 |
| getter 改方法（如 restText）破坏调用方 | 编译错误 | 编译期暴露，逐一修；范围可控 |
| 忘记给某个新 ARB key 加英文翻译 | 英文 locale 显示 key 名 | ARB 一致性测试守卫 |
| commit 数量多（~27）导致推送前忘了某些文件 | 不原子 | 每次提交前 `git diff --cached --name-status` 核对 |

---

## 9. 验收标准

1. ✅ 设置页有「语言」选择器，三项：跟随系统 / 简体中文 / English
2. ✅ 切换语言后整个 app 立即重渲染，无残留
3. ✅ 重启 app 后语言选择持久化
4. ✅ 跟随系统模式下，英文设备显示英文、中文设备显示中文
5. ✅ 11 个屏幕 + 所有 widget 在英文 locale 下无中文字符串残留
6. ✅ 通知、错误消息、AI 提示词、数据导入导出提示均随 locale 切换
7. ✅ 动作名/肌肉名/器械名/难度名在英文 locale 下显示英文
8. ✅ `app_zh.arb` 与 `app_en.arb` key 集合完全一致
9. ✅ `flutter analyze` 无 error、`flutter test` 全绿
10. ✅ 推送 origin（CI 绿）+ gitee（镜像同步）
