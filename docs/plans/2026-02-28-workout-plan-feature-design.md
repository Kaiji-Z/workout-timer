# 健身计划功能 - 完整设计文档

**创建日期**: 2026-02-28
**状态**: 待实现
**分支**: feature/workout-plan

---

## 一、功能概述

### 1.1 核心目标
健身计划功能需要同时实现：
- **训练计划管理** - 帮助用户提前规划和组织训练内容，减少每次训练前的决策成本
- **训练追踪** - 详细记录每次训练的具体数据（动作、组数、重量），用于分析进步

### 1.2 核心设计原则
- **简化操作** - 训练过程中不给用户增加不必要的复杂操作
- **计划作为参考** - 训练过程中，计划只是给作为参考和提示用的
- **灵活记录** - 自由模式不强迫用户输入动作和组数，结束后可自行补充
- **三层选项** - 用户创建计划时通过选项快速选择，免去打字麻烦

---

## 二、数据模型设计

### 2.1 肌肉部位分类（系统预设）

```dart
// 6个主要部位
enum PrimaryMuscleGroup {
  chest,      // 胸
  back,       // 背
  shoulders,  // 肩
  arms,       // 手臂
  legs,       // 腿
  core,       // 核心
}

// 15个子分类
enum SecondaryMuscleGroup {
  // 胸
  upperChest, middleChest, lowerChest,
  // 背
  lats, upperBack, rhomboids, lowerBack,
  // 肩
  frontDelt, sideDelt, rearDelt,
  // 手臂
  biceps, triceps, forearms,
  // 腿
  quads, hamstrings, glutes, calves,
  // 核心
  abs, obliques,
}
```

### 2.2 动作库模型

```dart
class Exercise {
  final String id;
  final String name;              // 动作名称（中文）
  final String nameEn;            // 英文原名
  final PrimaryMuscleGroup primaryMuscle;  // 主要部位
  final List<SecondaryMuscleGroup> secondaryMuscles; // 次要部位
  final String equipment;         // 器械要求（哑铃、杠铃、自重等）
  final String level;             // 难度（初级/中级/高级）
  final String imageUrl;          // 动作演示图URL（按需加载）
  final String muscleImageUrl;     // 肌肉部位图URL（按需加载）
  final ExerciseRecommendation recommendation; // 推荐组数/次数
}

class ExerciseRecommendation {
  final int recommendedSets;      // 推荐组数（如3-4组）
  final int minReps;             // 最小次数
  final int maxReps;             // 最大次数
  final int restSeconds;          // 推荐组间休息
}
```

### 2.3 训练计划模型

```dart
class WorkoutPlan {
  final String id;
  final String name;              // 计划名称（用户可编辑）
  final List<PrimaryMuscleGroup> targetMuscles;  // 目标部位（可多选）
  final List<PlanExercise> exercises;  // 动作列表（含顺序）
  final DateTime createdAt;
  final int estimatedDuration;    // 预估时长（分钟）
}

class PlanExercise {
  final Exercise exercise;
  final int targetSets;          // 目标组数
  final int? customSets;         // 用户自定义组数（如果修改过）
  final int order;               // 顺序号
}
```

### 2.4 训练记录模型

```dart
class WorkoutRecord {
  final String id;
  final DateTime date;
  final int durationSeconds;      // 训练时长
  final List<PrimaryMuscleGroup> trainedMuscles; // 训练部位
  final List<RecordedExercise> exercises;  // 实际完成的动作
  final String? planId;           // 关联的计划ID（如果是计划模式）
  final DateTime createdAt;
}

class RecordedExercise {
  final Exercise exercise;
  final int completedSets;       // 实际完成组数
  final double? maxWeight;        // 最大重量（kg）
}
```

### 2.5 日历计划模型

```dart
class CalendarPlan {
  final DateTime date;
  final List<String> planIds;     // 当天安排的计划ID列表
}
```

---

## 三、数据库Schema设计

### 3.1 新增表结构

```sql
-- 动作库表（内置数据，只读）
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_en TEXT,
  primary_muscle TEXT NOT NULL,
  secondary_muscles TEXT,
  equipment TEXT,
  level TEXT,
  image_url TEXT,
  muscle_image_url TEXT,
  recommended_sets INTEGER,
  recommended_min_reps INTEGER,
  recommended_max_reps INTEGER,
  rest_seconds INTEGER
);

-- 训练计划表
CREATE TABLE workout_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  target_muscles TEXT NOT NULL,
  estimated_duration INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 计划动作关联表
CREATE TABLE plan_exercises (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  exercise_id TEXT NOT NULL,
  target_sets INTEGER NOT NULL,
  exercise_order INTEGER NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (exercise_id) REFERENCES exercises(id)
);

-- 日历计划关联表
CREATE TABLE calendar_plans (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  plan_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
  UNIQUE(date, plan_id)
);

-- 训练记录表
CREATE TABLE workout_records (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  trained_muscles TEXT,
  plan_id TEXT,
  total_sets INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL
);

-- 记录动作详情表
CREATE TABLE record_exercises (
  id TEXT PRIMARY KEY,
  record_id TEXT NOT NULL,
  exercise_id TEXT NOT NULL,
  completed_sets INTEGER NOT NULL,
  max_weight REAL,
  FOREIGN KEY (record_id) REFERENCES workout_records(id) ON DELETE CASCADE,
  FOREIGN KEY (exercise_id) REFERENCES exercises(id)
);
```

### 3.2 数据库版本
- 当前版本: 1
- 新版本: 2
- 升级策略: _onUpgrade 迁移，保留原有 workout_sessions 表

---

## 四、UI/UX设计

### 4.1 页面结构

```
底部导航栏调整：
├── 计时器（保持）
├── 计划（新增）← 原来的"历史"位置
├── 历史（移到第3位）
├── 统计（保持）
├── 设置（保持）
```

### 4.2 计划页面（PlanScreen）

**布局：上半部分日历 + 下半部分计划列表**

```
┌─────────────────────────────────────┐
│     📅 2026年2月                      │
│  日  一  二  三  四  五  六           │
│                          1   2       │
│   3   4   5   6   7   8   9   ← 今天 │
│  10  11  12  13  14  15  16         │
│  17  18  19  20  21  22  23  • ← 有计划│
│  24  25  26  27  28                 │
├─────────────────────────────────────┤
│  2月9日 周六的计划                    │
│  ┌─────────────────────────────────┐│
│  │ 🏋️ 上肢训练日                   ││
│  │ 胸、肩、手臂 · 4个动作 · 16组   ││
│  │ 预估时长: 45分钟               ││
│  │                    [开始] [编辑]││
│  └─────────────────────────────────┘│
│  [+ 添加今日计划]                    │
├─────────────────────────────────────┤
│  📚 我的计划库                       │
│  ┌─────────────────────────────────┐│
│  │ 上肢训练日 · 胸肩臂             ││
│  │ 下肢训练日 · 腿部               ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

**日历交互：**
- 点击日期：显示该日期的计划列表
- 有计划的日期：显示小圆点标记
- 今天：高亮显示
- 可以左右滑动切换月份

### 4.3 创建/编辑计划页面（PlanFormScreen）

**三层选项流程：**

```
第1步：选择训练部位（可多选）
第2步：选择训练动作（按部位筛选，可调整顺序）
第3步：确认组数（自动填写推荐值，可修改）
```

**动作详情弹窗（按需加载图片）：**
- 动作演示图
- 肌肉部位图
- 主要/次要部位
- 器械要求
- 难度
- 推荐组数/次数/休息时间

### 4.4 计时器页面改造（TimerScreen）

**核心设计：保持现有UI不变，仅新增可折叠计划按钮**

```
计划模式（未展开）：
┌─────────────────────────────────────┐
│ [自由模式] [计划模式]                 │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📋 上肢训练日 · 卧推 第2组  ▼  │ │ ← 可点击展开
│ └─────────────────────────────────┘ │
│                                     │
│         [大圆形计时器按钮]            │
│              00:45                  │
│                                     │
│   [开始运动] [开始休息] [结束训练]    │
└─────────────────────────────────────┘

点击展开后：
┌─────────────────────────────────────┐
│ [自由模式] [计划模式]                 │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📋 上肢训练日 · 卧推 第2组  ▲  │ │ ← 点击收起
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 当前：卧推 第2组/共4组          │ │
│ │ ─────────────────────────────  │ │
│ │ ✓ 卧推      2/4                │ │
│ │ ○ 上斜卧推  0/3                │ │
│ │ ○ 肩推      0/4                │ │
│ │ ○ 二头弯举  0/3                │ │
│ │ ─────────────────────────────  │ │
│ │ [切换下一动作]                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [大圆形计时器按钮]            │
│              00:45                  │
│                                     │
│   [开始运动] [开始休息] [结束训练]    │
└─────────────────────────────────────┘
```

**交互逻辑：**
- 未展开时：仅显示一行 "📋 计划名 · 当前动作 第X组 ▼"
- 点击展开：显示完整计划列表，可查看进度
- 列表中当前动作高亮
- 达到目标组数时，出现"切换下一动作"按钮
- 计划模式下的状态显示：
  - 运动中：显示"正在进行 卧推 第2组"
  - 休息中：显示倒计时 + "卧推 已完成2组"
  - 切换动作提示：达到目标组数时弹出

### 4.5 历史记录页面（HistoryScreen）

**列表视图：**
- 按日期降序显示
- 每条记录显示：日期、训练时长、训练部位、动作数量
- 计划模式记录：显示计划名称
- 自由模式记录：显示"自由训练"

**详情/编辑页：**
- 日期、训练时长
- 训练部位（可编辑）
- 每个动作的完成组数
- 每个动作的最大重量（可编辑）

### 4.6 训练结束流程

**计划模式结束：**
```
训练结束弹窗：
- 训练时长
- 训练部位
- 各动作完成组数
- 填写各动作最大重量（可选）
- [保存记录] [跳过]
```

**自由模式结束：**
```
训练结束弹窗：
- 训练时长
- 完成组数
- 选择训练部位（可选）
- [保存记录] [跳过]
```

### 4.7 统计页面扩展

- 本周训练统计（次数、时长、组数）
- 部位训练分布（柱状图）
- 最近使用的计划

---

## 五、核心功能流程

### 5.1 创建计划流程

1. 用户进入计划页面
2. 点击"创建新计划"或日历上的"+ 添加今日计划"
3. 第1步：选择训练部位（可多选）
4. 第2步：选择训练动作（按部位筛选，可查看详情）
5. 第3步：确认组数（自动填写推荐值，可修改）
6. 输入计划名称，保存

### 5.2 安排计划到日历

1. 用户在计划页面选择日期
2. 从计划库中选择已有计划
3. 计划被关联到该日期

### 5.3 按计划训练流程

1. 用户进入计时器页面
2. 切换到"计划模式"
3. 选择今天的计划
4. 点击"开始运动"
5. 每组完成后点击"开始休息"
6. 达到目标组数时提示切换下一动作
7. 训练结束点击"结束训练"
8. 弹窗填写重量（可选）
9. 保存记录

### 5.4 自由训练流程

1. 用户进入计时器页面
2. 保持"自由模式"
3. 按现有方式操作（开始运动/开始休息/结束训练）
4. 训练结束可选择保存最简记录
5. 可在历史记录中编辑补充

---

## 六、Provider状态管理设计

### 6.1 新增Providers

```dart
// 计划管理Provider
class PlanProvider extends ChangeNotifier {
  List<WorkoutPlan> _plans = [];
  Map<String, List<CalendarPlan>> _calendarPlans = {};
  WorkoutPlan? _selectedPlan;
  
  // 加载所有计划
  Future<void> loadPlans() async { ... }
  
  // 创建/更新/删除计划
  Future<void> createPlan(WorkoutPlan plan) async { ... }
  Future<void> updatePlan(WorkoutPlan plan) async { ... }
  Future<void> deletePlan(String planId) async { ... }
  
  // 日历操作
  List<WorkoutPlan> getPlansForDate(DateTime date) { ... }
  Future<void> assignPlanToDate(String planId, DateTime date) async { ... }
  Future<void> removePlanFromDate(String planId, DateTime date) async { ... }
  
  // 选择计划（进入训练）
  void selectPlan(WorkoutPlan plan) { ... }
}

// 训练记录Provider
class RecordProvider extends ChangeNotifier {
  List<WorkoutRecord> _records = [];
  
  Future<void> loadRecords() async { ... }
  Future<void> saveRecord(WorkoutRecord record) async { ... }
  Future<void> updateRecord(WorkoutRecord record) async { ... }
  Future<void> deleteRecord(String recordId) async { ... }
  Future<Map<String, dynamic>> getStats(DateTime from, DateTime to) async { ... }
}

// 训练进度Provider（训练时使用）
class TrainingProgressProvider extends ChangeNotifier {
  WorkoutPlan? _currentPlan;
  int _currentExerciseIndex = 0;
  Map<String, int> _completedSets = {};
  
  void startPlan(WorkoutPlan plan) { ... }
  void completeSet() { ... }
  void nextExercise() { ... }
  void goToExercise(int index) { ... }
  int getCompletedSets(String exerciseId) { ... }
  WorkoutRecord generateRecord(int durationSeconds) { ... }
}
```

### 6.2 MultiProvider 更新

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: themeProvider),
    ChangeNotifierProvider(create: (_) => TimerProvider()),
    ChangeNotifierProvider(create: (_) => TrainingProvider()),
    ChangeNotifierProvider(create: (_) => PlanProvider()),        // 新增
    ChangeNotifierProvider(create: (_) => RecordProvider()),      // 新增
    ChangeNotifierProvider(create: (_) => TrainingProgressProvider()), // 新增
  ],
  // ...
);
```

---

## 七、文件结构规划

```
lib/
├── main.dart
├── models/
│   ├── workout_session.dart      # 保留
│   ├── exercise.dart             # 新增
│   ├── workout_plan.dart         # 新增
│   ├── workout_record.dart       # 新增
│   ├── calendar_plan.dart        # 新增
│   └── muscle_group.dart         # 新增
├── bloc/
│   ├── timer_provider.dart       # 保留
│   ├── training_provider.dart    # 保留
│   ├── plan_provider.dart        # 新增
│   ├── record_provider.dart      # 新增
│   └── training_progress_provider.dart  # 新增
├── services/
│   ├── database_helper.dart      # 扩展
│   ├── workout_repository.dart   # 保留
│   ├── plan_repository.dart      # 新增
│   ├── record_repository.dart    # 新增
│   └── exercise_repository.dart  # 新增
├── screens/
│   ├── timer_screen.dart         # 改造
│   ├── plan_screen.dart          # 新增
│   ├── plan_form_screen.dart     # 新增
│   ├── history_screen.dart       # 改造
│   ├── record_detail_screen.dart # 新增
│   ├── stats_screen.dart         # 改造
│   └── settings_screen.dart      # 保留
├── widgets/
│   ├── calendar_widget.dart      # 新增
│   ├── plan_card.dart            # 新增
│   ├── exercise_selector.dart    # 新增
│   ├── muscle_selector.dart      # 新增
│   └── ...
├── data/
│   └── exercise_data.dart        # 新增
└── assets/
    └── data/
        └── exercises.json        # 新增
```

---

## 八、动作库数据来源

### 8.1 数据来源
- **主要来源**: yuhonas/free-exercise-db (Public Domain, 800+动作)
- **备选**: MuscleWiki API (1800+动作，免费tier)

### 8.2 数据格式
```json
{
  "id": "barbell_bench_press",
  "name": "卧推（杠铃）",
  "nameEn": "Barbell Bench Press",
  "primaryMuscle": "chest",
  "secondaryMuscles": ["frontDelt", "triceps"],
  "equipment": "barbell",
  "level": "intermediate",
  "imageUrl": "https://...",
  "muscleImageUrl": "https://...",
  "recommendedSets": 4,
  "recommendedMinReps": 8,
  "recommendedMaxReps": 12,
  "restSeconds": 90
}
```

### 8.3 图片资源
- wger API: 342+动作示意图 (AGPL-3.0)
- react-body-highlighter: 肌肉高亮SVG (MIT)
- 按需加载，不强制显示

---

## 九、开发计划

### Phase 1: 数据层（2-3天）
- 创建所有Model类
- 数据库Schema升级
- 导入动作库数据
- 实现Repository层

### Phase 2: 状态管理（1-2天）
- 实现PlanProvider
- 实现RecordProvider
- 实现TrainingProgressProvider
- 更新MultiProvider

### Phase 3: UI页面（4-5天）
- 计划页面（日历+列表）
- 创建计划页面（三层选项）
- 计时器改造（模式切换+折叠按钮）
- 训练结束流程
- 历史记录改造
- 统计页面扩展

### Phase 4: 测试优化（2天）
- 单元测试
- Widget测试
- 集成测试
- 数据迁移测试
- 性能优化

**预计总工时**: 9-12天

---

## 十、关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 动作数据来源 | yuhonas/free-exercise-db | Public Domain，800+动作，免费商用 |
| 肌肉分类 | 6主类+15子类 | 参考Hevy/Strong，科学且实用 |
| 图片加载 | 按需加载 | 节省流量和存储，用户体验不受影响 |
| 训练进度追踪 | TrainingProgressProvider | 独立管理，不污染现有TrainingProvider |
| 数据库升级 | _onUpgrade迁移 | 保持用户现有数据不丢失 |
| 计划模式UI | 折叠按钮 | 保持简洁，不改变现有计时器核心体验 |

---

## 十一、风险与注意事项

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 动作库数据量大 | 首次启动可能慢 | 后台异步导入，显示加载进度 |
| 数据库迁移失败 | 用户数据丢失 | 充分测试，提供备份机制 |
| 图片资源缺失 | 部分动作无图 | 使用占位图，按需加载不阻塞 |
| 旧版数据兼容 | 历史记录丢失 | 保留workout_sessions表，迁移时合并 |

---

**文档结束**
