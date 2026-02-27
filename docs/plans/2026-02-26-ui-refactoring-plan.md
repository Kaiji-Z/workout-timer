# WorkoutTimer UI 重构实施计划

**日期**: 2026-02-26  
**状态**: 待实施  
**范围**: training_widget.dart 布局重构、计时器视觉增强、按钮简化

---

## 1. 目标概述

**将计时器重塑为屏幕的绝对视觉焦点，使辅助按钮退居次要地位，同时保持所有现有功能逻辑不变。**

---

## 2. 架构方法

采用**增量式重构**策略：先调整布局结构和尺寸比例，再优化按钮视觉权重，最后统一设计语言。全程保持 `training_provider.dart` 的状态管理逻辑不变，仅修改 `training_widget.dart` 的视图层。

---

## 3. 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.10+ | UI框架 |
| Provider | 状态管理（保持不变） |
| glass_widgets.dart | iOS 26 液态玻璃组件 |
| animated_timer_widget.dart | 计时器显示组件 |
| CustomPaint | 进度环绘制 |

---

## 4. 设计对比

### 4.1 当前布局 vs 目标布局

```
┌─────────────────────────────────────┐
│         当前布局                      │
├─────────────────────────────────────┤
│  Header (WORKOUT / TIMER)           │  ← 保留，简化
│  ─────────────────────────────────  │
│  AnimatedTimerDisplay (260px)       │  ← 扩大至屏幕70-80%
│  StatusBadge                        │  ← 合并到计时器内部
│  ─────────────────────────────────  │
│  [开始休息] [暂停]                    │  ← 简化为图标按钮
│  [      结束运动      ]              │  ← 简化视觉权重
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│         目标布局                      │
├─────────────────────────────────────┤
│  极简 Header (可选)                  │  ← 最小化或移除
│  ─────────────────────────────────  │
│                                     │
│     ╭───────────────────────╮      │
│     │                       │      │
│     │    大型圆形计时器       │      │  ← 屏幕70-80%
│     │    (进度环 + 时间)      │      │
│     │    (状态标签内置)       │      │
│     │                       │      │
│     ╰───────────────────────╯      │
│                                     │
│  ─────────────────────────────────  │
│      [↻]     [⏸]                   │  ← 极简图标按钮
│                                     │
│  [        结束运动        ]          │  ← 轮廓按钮，低视觉权重
└─────────────────────────────────────┘
```

### 4.2 尺寸变化

| 元素 | 当前尺寸 | 目标尺寸 | 变化 |
|------|----------|----------|------|
| 运动中计时器 | 260px | 屏幕宽度 × 0.75 | +40-50% |
| 休息计时器 | 220px | 屏幕宽度 × 0.70 | +50-60% |
| 小秒表(休息时) | 90px | 屏幕宽度 × 0.25 | 微调 |
| 主按钮高度 | 56px | 48px | -14% |
| 辅助按钮 | 全宽 | 48×48px 图标 | 极简化 |

---

## 5. 任务清单

### Phase 1: 布局结构重构 (预计 30 分钟)

#### Task 1.1: 创建屏幕尺寸计算工具方法
**文件**: `lib/widgets/training_widget.dart`  
**操作**: 在 `_buildMainDisplay` 方法顶部添加屏幕尺寸计算

```dart
// 在 build 方法内获取屏幕尺寸
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;
final timerSize = screenWidth * 0.75; // 主计时器占屏幕75%
```

**验证**: 运行 `flutter analyze` 无错误  
**Commit**: `refactor: add responsive timer size calculation`

---

#### Task 1.2: 修改运动状态计时器尺寸
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildMainDisplay` 方法，`isExercising` 分支

**当前代码 (行 120-137)**:
```dart
if (training.isExercising || training.isExercisePaused) {
  return Column(
    children: [
      AnimatedTimerDisplay(
        seconds: training.sessionDuration,
        label: '运动中',
        theme: theme,
        size: 260,  // ← 修改此处
        isCountdown: false,
      ),
      // ...
    ],
  );
}
```

**目标代码**:
```dart
if (training.isExercising || training.isExercisePaused) {
  return Column(
    children: [
      AnimatedTimerDisplay(
        seconds: training.sessionDuration,
        label: '运动中',
        theme: theme,
        size: timerSize,  // ← 使用响应式尺寸
        isCountdown: false,
      ),
      // 状态标签移除，合并到计时器内部
    ],
  );
}
```

**验证**: 计时器在运动状态时占据更大面积  
**Commit**: `refactor: increase exercise timer to 75% screen width`

---

#### Task 1.3: 修改休息状态双计时器布局
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildMainDisplay` 方法，`isResting` 分支

**当前代码 (行 96-117)**:
```dart
if (training.isResting) {
  return Column(
    children: [
      AnimatedStopwatchDisplay(
        seconds: training.sessionDuration,
        theme: theme,
        size: 90,  // ← 调整
      ),
      const SizedBox(height: 24),
      AnimatedTimerDisplay(
        seconds: training.restRemaining,
        label: '休息倒计时',
        theme: theme,
        size: 220,  // ← 调整
        isCountdown: true,
        progress: training.restDuration > 0 
            ? training.restRemaining / training.restDuration 
            : 0,
      ),
    ],
  );
}
```

**目标代码**:
```dart
if (training.isResting) {
  final smallTimerSize = screenWidth * 0.22;
  final mainTimerSize = screenWidth * 0.70;
  
  return Column(
    children: [
      // 小秒表移到计时器上方，更紧凑
      AnimatedStopwatchDisplay(
        seconds: training.sessionDuration,
        theme: theme,
        size: smallTimerSize,
      ),
      const SizedBox(height: 16),  // 减少间距
      AnimatedTimerDisplay(
        seconds: training.restRemaining,
        label: '休息倒计时',
        theme: theme,
        size: mainTimerSize,
        isCountdown: true,
        progress: training.restDuration > 0 
            ? training.restRemaining / training.restDuration 
            : 0,
      ),
    ],
  );
}
```

**验证**: 休息时主计时器仍为焦点，小秒表不抢视觉  
**Commit**: `refactor: adjust rest timer layout proportions`

---

#### Task 1.4: 修改空闲状态计时器尺寸
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildMainDisplay` 方法，idle 分支 (行 206-226)

**修改**: 将 `size: 220` 改为 `size: screenWidth * 0.65`

**验证**: 空闲状态预览计时器也放大  
**Commit**: `refactor: increase idle timer preview size`

---

### Phase 2: 按钮简化 (预计 45 分钟)

#### Task 2.1: 创建极简图标按钮组件
**文件**: `lib/widgets/training_widget.dart`  
**操作**: 在类底部添加新的私有方法

```dart
/// 极简圆形图标按钮 - 用于辅助操作
Widget _buildMinimalIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  required Color color,
  double size = 48,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    ),
  );
}
```

**验证**: `flutter analyze` 无错误  
**Commit**: `feat: add minimal icon button component`

---

#### Task 2.2: 重构运动中按钮布局
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildExercisingButtons` 方法 (行 346-403)

**当前布局**:
```
┌─────────────────────────────────────┐
│  [    开始休息    ] [   暂停   ]     │  ← 两个全宽按钮
│  [          结束运动          ]      │  ← 全宽轮廓按钮
└─────────────────────────────────────┘
```

**目标布局**:
```
┌─────────────────────────────────────┐
│         [↻]     [⏸]                 │  ← 两个小图标按钮
│                                     │
│  [        结束运动        ]          │  ← 轮廓按钮
└─────────────────────────────────────┘
```

**修改代码**:
```dart
Widget _buildExercisingButtons(TrainingProvider training, AppThemeData theme) {
  final isPaused = training.isExercisePaused;
  
  if (isPaused) {
    // 暂停状态：显示继续按钮（保持较大以引导用户）
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            label: '继续',
            icon: Icons.play_arrow,
            color: theme.primaryColor,
            height: 52,
            onPressed: training.resumeFromPause,
          ),
        ),
        const SizedBox(height: 16),
        _buildMinimalIconButton(
          icon: Icons.stop,
          onPressed: training.endWorkout,
          color: theme.accentColor,
        ),
      ],
    );
  }
  
  // 运动中：极简辅助按钮
  return Column(
    children: [
      // 辅助按钮行 - 极简图标
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMinimalIconButton(
            icon: Icons.pause,
            onPressed: training.pauseExercise,
            color: theme.warningColor,
          ),
          const SizedBox(width: 32),
          _buildMinimalIconButton(
            icon: Icons.self_improvement,
            onPressed: training.startRest,
            color: theme.successColor,
          ),
        ],
      ),
      const SizedBox(height: 24),
      // 主操作 - 轮廓按钮，降低视觉权重
      SizedBox(
        width: double.infinity,
        child: GlassOutlineButton(
          label: '结束运动',
          icon: Icons.stop,
          color: theme.accentColor.withOpacity(0.7),
          height: 48,
          onPressed: training.endWorkout,
        ),
      ),
    ],
  );
}
```

**验证**: 
- 运动中显示两个小图标按钮（暂停/休息）
- 结束按钮视觉权重降低
- 暂停状态显示大继续按钮

**Commit**: `refactor: simplify exercising buttons to minimal icons`

---

#### Task 2.3: 重构休息中按钮布局
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildRestingButtons` 方法 (行 446-457)

**当前代码**:
```dart
Widget _buildRestingButtons(TrainingProvider training, AppThemeData theme) {
  return SizedBox(
    width: double.infinity,
    child: GlassButton(
      label: '跳过休息',
      icon: Icons.skip_next,
      color: theme.successColor,
      height: 56,
      onPressed: training.skipRest,
    ),
  );
}
```

**目标代码**:
```dart
Widget _buildRestingButtons(TrainingProvider training, AppThemeData theme) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildMinimalIconButton(
        icon: Icons.skip_next,
        onPressed: training.skipRest,
        color: theme.successColor,
      ),
    ],
  );
}
```

**验证**: 休息时只显示一个小跳过按钮  
**Commit**: `refactor: simplify resting skip button`

---

#### Task 2.4: 重构空闲状态按钮
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildIdleButtons` 方法 (行 276-344)

**修改要点**:
1. 保持休息时长设置卡片（功能必需）
2. 开始按钮保持较大（引导用户开始）

**当前代码基本保留**，仅调整：
- 开始按钮高度从 60 → 56
- 设置卡片视觉简化

**验证**: 空闲状态布局保持功能完整  
**Commit**: `refactor: minor idle buttons adjustment`

---

#### Task 2.5: 重构完成状态按钮
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildCompletedButtons` 方法 (行 459-498)

**当前布局**:
```
┌─────────────────────────────────────┐
│  [  保存记录  ] [  继续运动  ]       │
│  [           放弃           ]        │
└─────────────────────────────────────┘
```

**目标布局**:
```
┌─────────────────────────────────────┐
│  [       保存记录       ]            │  ← 主按钮，引导保存
│                                     │
│      [↻]     [×]                    │  ← 继续和放弃图标按钮
└─────────────────────────────────────┘
```

**修改代码**:
```dart
Widget _buildCompletedButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
  return Column(
    children: [
      // 主操作 - 保存记录
      SizedBox(
        width: double.infinity,
        child: GlassButton(
          label: '保存记录',
          icon: Icons.save,
          color: theme.primaryColor,
          height: 52,
          onPressed: () => _saveWorkout(context, training),
        ),
      ),
      const SizedBox(height: 24),
      // 辅助操作 - 极简图标
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMinimalIconButton(
            icon: Icons.replay,
            onPressed: training.resumeExercise,
            color: theme.successColor,
          ),
          const SizedBox(width: 32),
          _buildMinimalIconButton(
            icon: Icons.delete_outline,
            onPressed: training.resetWorkout,
            color: theme.warningColor,
          ),
        ],
      ),
    ],
  );
}
```

**验证**: 完成状态引导用户保存，辅助操作简化  
**Commit**: `refactor: simplify completed state buttons`

---

### Phase 3: 头部和间距优化 (预计 20 分钟)

#### Task 3.1: 简化 Header 视觉权重
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildHeader` 方法 (行 61-92)

**修改要点**:
- 减小标题字号
- 减少字母间距
- 考虑移除 "WORKOUT" 副标题

**目标代码**:
```dart
Widget _buildHeader(AppThemeData theme) {
  return Column(
    children: [
      ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: theme.timerGradientColors,
        ).createShader(bounds),
        child: Text(
          'TIMER',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 24,  // 从 32 减小
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 4,  // 从 8 减小
          ),
        ),
      ),
    ],
  );
}
```

**验证**: Header 不再抢夺计时器视觉焦点  
**Commit**: `refactor: reduce header visual weight`

---

#### Task 3.2: 调整整体间距
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `build` 方法主 Column (行 41-53)

**修改要点**:
- 减少各元素间距
- 让计时器更居中

**当前间距**:
```dart
SizedBox(height: 16),   // header前
SizedBox(height: 32),   // header后
SizedBox(height: 24),   // timer后
SizedBox(height: 32),   // status后
SizedBox(height: 32),   // buttons后
```

**目标间距**:
```dart
SizedBox(height: 8),    // header前
SizedBox(height: 24),   // header后
SizedBox(height: 20),   // timer后（状态标签已移除）
SizedBox(height: 24),   // buttons前
SizedBox(height: 24),   // buttons后
```

**验证**: 整体布局更紧凑，计时器更突出  
**Commit**: `refactor: tighten spacing for timer focus`

---

### Phase 4: 状态标签集成 (预计 15 分钟)

#### Task 4.1: 将状态标签移到计时器内部
**文件**: `lib/widgets/animated_timer_widget.dart`  
**位置**: `AnimatedTimerDisplay` build 方法

**当前**: 状态标签在计时器外部单独显示  
**目标**: 状态标签在计时器内部底部显示

**修改**: 在 `animated_timer_widget.dart` 的 Column children 中添加状态显示

```dart
// 在 AnimatedTimerDisplay 内部添加
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    AnimatedNumber(...),
    const SizedBox(height: 4),
    Text(label, ...),  // 现有标签
    // 新增：组数显示（如果需要）
    if (showSetInfo) ...[
      const SizedBox(height: 8),
      Text(
        '第 $currentSet 组',
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: size * 0.06,
          fontWeight: FontWeight.w500,
          color: theme.primaryColor,
        ),
      ),
    ],
  ],
)
```

**注意**: 需要给 `AnimatedTimerDisplay` 添加可选参数 `currentSet` 和 `showSetInfo`

**验证**: 组数信息在计时器内部显示  
**Commit**: `feat: integrate set counter into timer display`

---

#### Task 4.2: 移除外部状态徽章
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `build` 方法，移除 `_buildStatusBadge` 调用

**操作**:
1. 删除行 48: `_buildStatusBadge(training, theme),`
2. 删除行 49: `const SizedBox(height: 32),`

**验证**: 外部状态徽章已移除  
**Commit**: `refactor: remove external status badge`

---

### Phase 5: 动画和过渡 (预计 15 分钟)

#### Task 5.1: 添加按钮切换动画
**文件**: `lib/widgets/training_widget.dart`  
**位置**: `_buildButtons` 方法

**修改**: 使用 `AnimatedSwitcher` 包裹按钮区域

```dart
Widget _buildButtons(BuildContext context, TrainingProvider training, AppThemeData theme) {
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
    child: Container(
      key: ValueKey(training.state),
      child: _getButtonsForState(context, training, theme),
    ),
  );
}
```

**验证**: 状态切换时按钮平滑过渡  
**Commit**: `feat: add smooth button transition animations`

---

## 6. 测试和验证

### 6.1 功能测试清单

| 测试项 | 预期结果 | 通过 |
|--------|----------|------|
| 开始运动 | 计时器开始计数，显示大尺寸 | ☐ |
| 运动中暂停 | 显示继续按钮，小结束按钮 | ☐ |
| 暂停后继续 | 恢复运动状态 | ☐ |
| 开始休息 | 显示倒计时，小秒表在上方 | ☐ |
| 跳过休息 | 立即切换到下一组 | ☐ |
| 休息自动结束 | 自动切换到下一组 | ☐ |
| 结束运动 | 显示保存/继续/放弃 | ☐ |
| 保存记录 | 数据保存成功 | ☐ |
| 继续运动 | 恢复运动状态 | ☐ |
| 放弃 | 重置到空闲状态 | ☐ |
| 设置休息时长 | 滚轮选择器正常 | ☐ |

### 6.2 视觉验证

| 验证项 | 检查要点 |
|--------|----------|
| 计时器焦点 | 计时器是否明显比按钮更大更突出 |
| 按钮简化 | 辅助按钮是否足够低调 |
| 间距合理 | 元素间距是否舒适 |
| 动画流畅 | 状态切换是否平滑 |
| 多设备适配 | 在不同屏幕尺寸上测试 |

### 6.3 测试命令

```bash
# 运行应用
flutter run

# 运行测试
flutter test

# 静态分析
flutter analyze

# 检查格式
dart format --set-exit-if-changed lib/
```

---

## 7. 回滚计划

如果重构出现问题，可以通过以下命令回滚：

```bash
# 查看提交历史
git log --oneline -10

# 回滚到特定提交
git revert <commit-hash>

# 或硬回滚（谨慎使用）
git reset --hard <commit-hash>
```

---

## 8. 时间估算

| Phase | 预计时间 | 任务数 |
|-------|----------|--------|
| Phase 1: 布局重构 | 30 分钟 | 4 |
| Phase 2: 按钮简化 | 45 分钟 | 5 |
| Phase 3: 头部优化 | 20 分钟 | 2 |
| Phase 4: 状态集成 | 15 分钟 | 2 |
| Phase 5: 动画过渡 | 15 分钟 | 1 |
| **总计** | **125 分钟** | **14** |

---

## 9. 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 响应式尺寸在小屏设备异常 | 高 | 添加最小/最大尺寸约束 |
| 状态标签集成破坏现有逻辑 | 中 | 保留原有参数，新增可选参数 |
| 动画性能问题 | 低 | 使用 AnimatedSwitcher 而非复杂动画 |

---

## 10. 验收标准

- [ ] 圆形计时器占据屏幕 70-80% 宽度
- [ ] 辅助按钮使用极简图标样式
- [ ] Header 视觉权重降低
- [ ] 状态信息集成到计时器内部
- [ ] 所有原有功能正常工作
- [ ] `flutter analyze` 无错误
- [ ] 在至少 2 种屏幕尺寸上测试通过
