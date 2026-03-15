# AI训练计划导入功能 - 开发计划

**Created:** 2026-03-14
**Status:** Planning Complete
**Priority:** High

---

## 功能概述

让用户通过AI（豆包/千问等）生成个性化周训练计划，一键导入到App日历中。

### 目标用户
- 健身新手（不知道如何安排计划）
- 懒得自己规划的用户

### 核心体验
> 用户只需：选6个选项 → 复制Prompt → 粘贴AI回复 → 预览确认 → 完成

---

## 开发阶段

### 第一阶段：AI计划导入（核心功能）

#### 1.1 用户资料收集页面
**文件**: `lib/screens/ai_plan_wizard_screen.dart`

**6个问题**:
| # | 问题 | 选项 |
|---|------|------|
| 1 | 训练目标 | 增肌 / 减脂 / 力量 / 耐力 |
| 2 | 每周训练次数 | 2-3次 / 4-5次 / 6次+ |
| 3 | 每次训练时长 | 30分钟 / 45分钟 / 60分钟 / 90分钟 |
| 4 | 经验水平 | 新手(0-1年) / 中级(1-3年) / 高级(3年+) |
| 5 | 器械条件 | 健身房 / 家用哑铃 / 徒手 |
| 6 | 偏好部位（多选，可选） | 胸 / 背 / 肩 / 臂 / 腿 / 核心 |
| 7 | 计划起始日期 | 下周一 / 本周一 / 自定义日期 |

**UI设计**:
- 简洁的单选/多选卡片
- 使用现有主题样式
- 底部"下一步"按钮

#### 1.2 Prompt生成服务
**文件**: `lib/services/ai_prompt_service.dart`

```dart
class AIPromptService {
  /// 根据用户资料生成英文Prompt
  String generatePrompt(UserProfile profile);
}

class UserProfile {
  final String goal;        // muscle_building, fat_loss, strength, endurance
  final int weeklyFrequency; // 2-3, 4-5, 6+
  final int sessionDuration; // 30, 45, 60, 90
  final String experience;   // beginner, intermediate, advanced
  final String equipment;    // gym, home_dumbbell, bodyweight
  final List<String> focusAreas; // chest, back, shoulders, arms, legs, core
  final DateTime startDate;
}
```

#### 1.3 Prompt展示页面
**文件**: `lib/screens/ai_plan_wizard_screen.dart` (Step 2)

**内容**:
- 生成的完整英文Prompt
- 一键复制按钮
- 操作指引（4步说明）

#### 1.4 JSON粘贴页面
**文件**: `lib/screens/ai_plan_wizard_screen.dart` (Step 3)

**内容**:
- 文本输入框
- 粘贴/清空按钮
- 解析按钮

#### 1.5 动作智能匹配服务
**文件**: `lib/services/exercise_matcher_service.dart`

```dart
class ExerciseMatcherService {
  /// 匹配英文动作名称到本地数据库
  /// 返回匹配结果（成功/失败/多个候选）
  Future<MatchResult> matchExercise(String englishName);
  
  /// 批量匹配
  Future<List<MatchResult>> matchAll(List<String> englishNames);
}

class MatchResult {
  final bool success;
  final Exercise? exercise;
  final List<Exercise> candidates; // 多个候选时
  final String? errorMessage;
}
```

**匹配策略**:
1. 精确匹配 `nameEn` (不区分大小写)
2. 包含匹配 (`nameEn.contains()`)
3. 模糊匹配 (Levenshtein距离)
4. 返回相似度最高的候选列表

#### 1.6 预览编辑页面
**文件**: `lib/screens/ai_plan_wizard_screen.dart` (Step 4)

**内容**:
- 按天分组展示计划
- 每个动作显示匹配状态
  - ✅ 已匹配：显示中文名 + 组数下拉框
  - ⚠️ 多个候选：点击选择
  - ❌ 未匹配：点击手动搜索
- 有未匹配动作时禁用"确认"按钮

#### 1.7 JSON解析模型
**文件**: `lib/models/weekly_plan_import.dart`

```dart
/// AI生成的周计划导入格式
class WeeklyPlanImport {
  final String name;
  final List<DailyPlanImport> days;
  
  factory WeeklyPlanImport.fromJson(Map<String, dynamic> json);
}

class DailyPlanImport {
  final int dayOfWeek;      // 1-7 (Monday-Sunday)
  final List<String> targetMuscles;
  final List<ExerciseEntryImport> exercises;
}

class ExerciseEntryImport {
  final String exerciseName;  // 英文名称
  final int targetSets;
}
```

#### 1.8 导入到日历
**流程**:
1. 为每一天创建独立的 `WorkoutPlan`
2. 保存到 `workout_plans` 和 `plan_exercises` 表
3. 创建 `CalendarPlan` 关联到对应日期

**PlanProvider扩展**:
```dart
/// 批量创建计划并添加到日历
Future<void> importWeeklyPlan(WeeklyPlanImport weeklyPlan, DateTime startDate);
```

---

### 第二阶段：训练记录增强

#### 2.1 数据模型扩展
**文件**: `lib/models/recorded_exercise.dart`

```dart
class RecordedExercise {
  // 现有字段...
  
  // 新增字段
  final List<int> reps;        // 每组次数
  final List<double> weights;  // 每组重量(kg)
}
```

#### 2.2 数据库迁移
**文件**: `lib/services/database_helper.dart`

```sql
ALTER TABLE record_exercises ADD COLUMN reps TEXT;      -- JSON数组
ALTER TABLE record_exercises ADD COLUMN weights TEXT;   -- JSON数组
```

#### 2.3 设置页面开关
**文件**: `lib/screens/settings_screen.dart`

```dart
// 详细记录模式（开关）
bool _detailedRecordingMode = false;
```

#### 2.4 训练记录UI
**文件**: `lib/widgets/set_recording_widget.dart`

- 每组输入：次数 + 重量
- 快捷按钮：+5kg / -5kg
- 复制上一组

---

### 第三阶段：统计页面重构

#### 3.1 指标计算服务
**文件**: `lib/services/stats_calculator_service.dart`

```dart
class StatsCalculatorService {
  /// 计算训练容量 (sets × reps × weight)
  double calculateVolume(List<WorkoutRecord> records);
  
  /// 按部位计算容量分布
  Map<PrimaryMuscleGroup, double> calculateVolumeByMuscle(List<WorkoutRecord> records);
  
  /// 计算训练密度 (容量/时长)
  double calculateDensity(WorkoutRecord record);
  
  /// 计算动作进步（同动作重量变化）
  List<ExerciseProgress> calculateExerciseProgress(String exerciseId);
}
```

#### 3.2 周视图重设计
**内容**:
- 概览卡片：训练容量 / 组数 / 时长 / 频率
- 每日柱状图
- 部位分布环形图
- 数据完整度提示（无详细数据时）

#### 3.3 月视图重设计
**内容**:
- 概览卡片：总容量 / 总组数 / 总时长 / 平均密度
- 训练容量趋势折线图
- 部位容量横向条形图
- 动作进步追踪列表
- 月度训练日历热力图

#### 3.4 自定义图表组件
**文件**: `lib/widgets/charts/`

```
charts/
├── donut_chart.dart        # 环形图（部位分布）
├── bar_chart.dart          # 条形图（部位容量）
├── line_chart.dart         # 折线图（趋势）
└── heatmap_calendar.dart   # 热力图日历
```

---

## Prompt模板

```text
You are a professional fitness coach. Generate a personalized weekly workout plan based on my profile.

## My Profile

- **Goal**: {goal}
- **Weekly Frequency**: {frequency}
- **Session Duration**: {duration}
- **Experience Level**: {level}
- **Equipment Access**: {equipment}
- **Focus Areas**: {focusAreas}

## Exercise Database

We use the free-exercise-db database (800+ exercises) with standard English naming conventions:
- Compound movements: Barbell Bench Press, Barbell Squat, Deadlift, Overhead Press, etc.
- Isolation movements: Dumbbell Fly, Cable Crossover, Tricep Pushdown, Bicep Curl, etc.
- Equipment types: Barbell, Dumbbell, Cable, Machine, Body Only, Kettlebell

Naming format examples:
- Barbell Bench Press, Incline Dumbbell Press, Cable Fly
- Pull-up, Chin-up, Dips
- Goblet Squat, Romanian Deadlift, Hip Thrust

If unsure about exact names, use standard exercise terminology and we'll match the closest equivalent.

## Output Format

Output ONLY valid JSON. No explanations or markdown:

```json
{
  "name": "Plan Name",
  "days": [
    {
      "dayOfWeek": 1,
      "targetMuscles": ["chest", "shoulders"],
      "exercises": [
        {"exerciseName": "Barbell Bench Press", "targetSets": 4},
        {"exerciseName": "Incline Dumbbell Press", "targetSets": 3}
      ]
    }
  ]
}
```

## Rules

1. `dayOfWeek`: 1=Monday ... 7=Sunday
2. `targetMuscles`: chest, back, shoulders, arms, legs, core
3. `targetSets`: 3-5 per exercise
4. 4-6 exercises per session (based on {duration})
5. Compound first, isolation last
6. Include rest days based on {frequency}

Generate my weekly plan. JSON only:
```

---

## 文件清单

### 新增文件
| 文件 | 用途 |
|------|------|
| `lib/screens/ai_plan_wizard_screen.dart` | AI计划导入向导（4步） |
| `lib/services/ai_prompt_service.dart` | Prompt生成服务 |
| `lib/services/exercise_matcher_service.dart` | 动作匹配服务 |
| `lib/models/weekly_plan_import.dart` | JSON导入模型 |
| `lib/widgets/charts/donut_chart.dart` | 环形图组件 |
| `lib/widgets/charts/bar_chart.dart` | 条形图组件 |
| `lib/widgets/charts/line_chart.dart` | 折线图组件 |
| `lib/widgets/charts/heatmap_calendar.dart` | 热力图组件 |
| `lib/services/stats_calculator_service.dart` | 统计计算服务 |
| `lib/widgets/set_recording_widget.dart` | 组记录组件 |

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `lib/models/recorded_exercise.dart` | 添加 reps, weights 字段 |
| `lib/services/database_helper.dart` | 数据库迁移 |
| `lib/screens/settings_screen.dart` | 详细记录模式开关 |
| `lib/screens/stats_screen.dart` | 页面重构 |
| `lib/bloc/plan_provider.dart` | 添加 importWeeklyPlan 方法 |
| `lib/screens/plan_screen.dart` | 添加"AI生成计划"入口 |

---

## 数据库变更

### 新增字段 (record_exercises表)
```sql
reps TEXT,      -- JSON数组，如 "[10, 10, 8]"
weights TEXT    -- JSON数组，如 "[60.0, 60.0, 55.0]"
```

---

## 验收标准

### 第一阶段
- [ ] 用户可以填写6个问题 + 选择起始日期
- [ ] 可以一键复制生成的Prompt
- [ ] 可以粘贴AI返回的JSON
- [ ] JSON解析成功后显示预览
- [ ] 动作自动匹配成功/失败状态正确显示
- [ ] 未匹配动作可以手动选择
- [ ] 所有动作匹配后可以保存
- [ ] 保存后计划出现在日历对应日期

### 第二阶段
- [ ] 设置中可以开启详细记录模式
- [ ] 开启后训练时可输入每组次数和重量
- [ ] 数据正确保存到数据库

### 第三阶段
- [ ] 周视图显示新指标
- [ ] 月视图显示趋势和分布
- [ ] 无详细数据时显示引导提示
- [ ] 图表正确渲染

---

## 风险与依赖

| 风险 | 缓解措施 |
|------|----------|
| AI返回格式不标准 | JSON解析容错 + 用户可见错误提示 |
| 动作匹配不准确 | 提供候选列表 + 手动搜索 |
| 数据库迁移失败 | 保留旧字段兼容 |
| string_similarity包兼容性 | 使用最新稳定版本，测试覆盖 |

---

## 技术决策 (2026-03-14 确认)

| 决策项 | 选择 | 说明 |
|--------|------|------|
| 模糊匹配算法 | `string_similarity` 包 | 更精确的相似度计算 |
| 休息日处理 | 跳过，不创建计划 | AI返回的JSON中某天没有exercises时不创建计划 |
| 重复计划处理 | 显示确认对话框 | 如果某日期已有计划，询问用户是否替换 |
| 测试基础设施 | 创建共享工具文件 | `test/helpers/test_fixtures.dart` |

---

## 实施计划 (Phase 1)

### Wave 1: 基础模型 (并行)
| 任务 | 文件 | 状态 |
|------|------|------|
| T1.1 WeeklyPlanImport模型 | `lib/models/weekly_plan_import.dart` | ⬜ |
| T1.2 ExerciseMatcherService | `lib/services/exercise_matcher_service.dart` | ⬜ |
| T1.3 AIPromptService | `lib/services/ai_prompt_service.dart` | ⬜ |
| T1.4 UserProfile模型 | `lib/models/user_profile.dart` | ⬜ |
| T1.5 测试工具文件 | `test/helpers/test_fixtures.dart` | ⬜ |

### Wave 2: Repository & Provider (依赖Wave 1)
| 任务 | 文件 | 状态 |
|------|------|------|
| T2.1 PlanRepository扩展 | `lib/services/plan_repository.dart` | ⬜ |
| T2.2 PlanProvider扩展 | `lib/bloc/plan_provider.dart` | ⬜ |

### Wave 3: UI组件
| 任务 | 文件 | 状态 |
|------|------|------|
| T3.1 AIPlanWizardScreen (步骤1-2) | `lib/screens/ai_plan_wizard_screen.dart` | ⬜ |
| T3.2 AIPlanWizardScreen (步骤3-4) | `lib/screens/ai_plan_wizard_screen.dart` | ⬜ |

### Wave 4: 集成
| 任务 | 文件 | 状态 |
|------|------|------|
| T4.1 PlanScreen入口按钮 | `lib/screens/plan_screen.dart` | ⬜ |
| T4.2 E2E测试 | `test/integration/ai_plan_import_e2e_test.dart` | ⬜ |

---

## 时间估算

| 阶段 | 估算 |
|------|------|
| 第一阶段 | 3-4天 |
| 第二阶段 | 1-2天 |
| 第三阶段 | 2-3天 |
| **总计** | **6-9天** |
