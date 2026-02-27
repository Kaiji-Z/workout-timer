# Ocean Flow UI/UX 全面优化设计方案

**Created:** 2026-02-27
**Status:** Approved
**Author:** Design Discussion with User

---

## 概述

本方案旨在全面优化 WorkoutTimer 应用的 UI/UX，实现品牌差异化，打造极简主义/专业高端的视觉风格，同时增强动画交互体验。

### 设计目标

- **品牌差异化**：独特的视觉风格，在健身应用市场中脱颖而出
- **极简主义**：简洁、现代、精致的界面
- **专业高端**：传达品质感和信任感
- **目标用户**：健身新手（友好易懂）

---

## 设计系统

### 双轨主题策略

| 主题 | 风格 | 适用场景 |
|------|------|---------|
| **Ocean Flow** (新增) | 浅色极简、蓝色系 | 白天使用、清爽感觉 |
| **VitalFlow** (优化) | 暗色毛玻璃、青绿色 | 夜间使用、沉浸体验 |

---

## Ocean Flow 浅色主题

### 配色方案

**主色调渐变（邻近色）**
```
深海蓝 #0066CC → 天际青 #00A8B5 → 绿松石 #00C9B7
```

**完整色板**

| 用途 | 名称 | 色值 | 用例 |
|------|------|------|------|
| 背景 | 极浅灰白 | `#FAFBFC` | 页面背景 |
| 卡片背景 | 纯白 | `#FFFFFF` | 卡片、按钮 |
| 次要背景 | 浅灰 | `#F5F7F9` | 分隔区域 |
| 主色 | 深海蓝 | `#0066CC` | 主按钮、强调 |
| 次要色 | 天际青 | `#00A8B5` | 次要元素 |
| 强调色 | 绿松石 | `#00C9B7` | 进度、成功 |
| 成功 | 翡翠绿 | `#10B981` | 完成状态 |
| 警告 | 琥珀黄 | `#F59E0B` | 提醒、暂停 |
| 错误 | 珊瑚红 | `#EF4444` | 错误状态 |
| 主文字 | 深蓝灰 | `#1A2B3C` | 标题、正文 |
| 次要文字 | 中灰 | `#6B7280` | 说明文字 |
| 禁用文字 | 浅灰 | `#D1D5DB` | 禁用状态 |

**特殊效果色**

| 名称 | 色值 | 用途 |
|------|------|------|
| 涟漪蓝 | `rgba(0, 168, 181, 0.15)` | 水波纹效果 |
| 光晕青 | `rgba(0, 201, 183, 0.1)` | 光晕效果 |
| 水波纹 | `rgba(0, 102, 204, 0.08)` | 点击反馈 |

### 字体系统

**字体家族：SF Pro (iOS 26 Typography)**

```dart
// 标题字体 - SF Pro Display
displayLarge: SF Pro Display, 34px, Bold (w700)
displayMedium: SF Pro Display, 28px, Bold (w700)
displaySmall: SF Pro Display, 22px, Semibold (w600)

// 正文字体 - SF Pro Text
bodyLarge: SF Pro Text, 17px, Regular (w400)
bodyMedium: SF Pro Text, 15px, Regular (w400)
bodySmall: SF Pro Text, 13px, Regular (w400)

// 标签字体
labelLarge: SF Pro Text, 14px, Medium (w500)
labelMedium: SF Pro Text, 12px, Medium (w500)
labelSmall: SF Pro Text, 11px, Medium (w500)
```

**计时器数字**
- 字体：SF Pro Display
- 特性：`tabularFigures` (等宽数字)
- 大数字：96px, Light (w300)

---

## VitalFlow 暗色主题优化

### 现有配色（保留）

```
背景色：深青色 #1A3A3A
主色调：清新青绿 #4DB6AC
辅助色：浅青绿 #80CBC4
强调色：珊瑚橙 #FF8A65
```

### 优化项

1. **字体统一**：所有屏幕使用 SF Pro 系列
2. **颜色变量化**：移除硬编码颜色
3. **组件复用**：使用 LiquidCard 等现有组件

---

## 动画系统

### 1. 过渡动画 (Transition Animations)

| 场景 | 动画效果 | 时长 | 曲线 |
|------|---------|------|------|
| 页面切换 | 淡入淡出 + 轻微上滑 | 300ms | easeOut |
| Tab 切换 | 交叉淡入淡出 | 200ms | easeInOut |
| 模态弹窗 | 从底部滑入 + 背景模糊 | 250ms | easeOutCubic |
| 卡片展开 | 高度展开 + 淡入 | 200ms | easeOut |

### 2. 反馈动画 (Feedback Animations)

| 场景 | 动画效果 | 时长 | 曲线 |
|------|---------|------|------|
| 按钮点击 | 缩放 0.96 → 1.0 + 轻微下压 | 150ms | easeOut |
| 开关切换 | 弹性过渡 | 200ms | easeOutBack |
| 成功操作 | 打勾图标弹出 | 300ms | easeOutBack |
| 错误提示 | 抖动效果 | 400ms | easeInOut |

### 3. 氛围动画 (Ambient Animations)

| 场景 | 动画效果 | 时长 | 曲线 |
|------|---------|------|------|
| 计时器背景 | 轻柔光晕呼吸效果 | 3000ms | easeInOut (循环) |
| 空闲状态 | 粒子缓慢漂浮 (可选) | 10000ms | linear (循环) |
| 完成状态 | 脉冲光环 + 粒子扩散 | 1500ms | easeOut |
| 进度环 | 头部光点闪烁 | 2000ms | easeInOut (循环) |

### 4. 数据可视化动画 (Data Visualization)

| 场景 | 动画效果 | 时长 | 曲线 |
|------|---------|------|------|
| 进度环 | 平滑进度变化 + 头部光点 | 500ms | easeOutCubic |
| 数字变化 | 数字翻转/滑动过渡 | 300ms | easeOut |
| 图表柱状 | 从底部弹起 (staggered) | 600ms | easeOutBack |
| 统计卡片 | 数值计数动画 | 800ms | easeOut |

---

## 优化任务清单

### 设计系统优化

- [ ] **新增 Ocean Flow 主题**
  - 创建 `oceanFlowTheme` 配置
  - 定义浅色配色方案
  - 添加到主题选择器

- [ ] **统一字体**
  - SettingsScreen: Orbitron/Rajdhani → SF Pro
  - HistoryScreen: Orbitron/Rajdhani → SF Pro
  - StatsScreen: Orbitron/Rajdhani → SF Pro

- [ ] **移除硬编码颜色**
  - 审查所有 `Color(0xFF...)` 直接使用
  - 替换为 `theme.primaryColor` 等变量

- [ ] **复用毛玻璃组件**
  - SettingsScreen: 使用 LiquidCard
  - StatsScreen: 使用 LiquidCard

### 动画增强

- [ ] **页面过渡动画**
  - 创建 `FadeUpPageRoute` 自定义路由
  - 应用到所有页面切换

- [ ] **列表入场动画**
  - HistoryScreen: staggered 入场
  - StatsScreen: 图表动画

- [ ] **计时器氛围动画**
  - 增强 AnimatedTimerDisplay 呼吸效果
  - 添加空闲状态粒子效果 (可选)

- [ ] **按钮反馈优化**
  - 统一 LiquidButton 动画时长
  - 添加触觉反馈 (可选)

### 屏幕优化

- [ ] **TimerScreen**
  - 微调计时器动画
  - 优化状态切换过渡

- [ ] **SettingsScreen**
  - 统一字体
  - 复用 LiquidCard
  - 添加主题切换预览

- [ ] **HistoryScreen**
  - 统一字体
  - 添加列表入场动画
  - 优化空状态显示

- [ ] **StatsScreen**
  - 统一字体
  - 添加图表入场动画
  - 优化统计卡片布局

---

## 技术实现备注

### 文件修改清单

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `lib/theme/app_theme.dart` | 修改 | 新增 Ocean Flow 主题 |
| `lib/theme/theme_provider.dart` | 修改 | 添加主题切换支持 |
| `lib/screens/settings_screen.dart` | 重构 | 统一字体、复用组件 |
| `lib/screens/history_screen.dart` | 重构 | 统一字体、添加动画 |
| `lib/screens/stats_screen.dart` | 重构 | 统一字体、添加动画 |
| `lib/widgets/glass_widgets.dart` | 增强 | 添加动画支持 |
| `lib/main.dart` | 修改 | 添加页面过渡动画 |

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/animations/page_transitions.dart` | 页面过渡动画 |
| `lib/animations/list_animations.dart` | 列表入场动画 |
| `lib/widgets/ambient_effects.dart` | 氛围效果组件 |

---

## 预期效果

1. **视觉一致性**：所有屏幕统一使用 SF Pro 字体和主题颜色
2. **品牌识别**：Ocean Flow 蓝色系配色独特且专业
3. **交互流畅**：丰富的动画效果提升用户体验
4. **主题灵活**：用户可在浅色/暗色主题间切换

---

## 后续迭代

- [ ] 添加更多主题选项
- [ ] 实现主题自定义功能
- [ ] 优化动画性能
- [ ] 添加无障碍支持
