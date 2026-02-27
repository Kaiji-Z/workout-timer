# Ocean Flow UI/UX 优化实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 全面优化 WorkoutTimer 应用的 UI/UX，新增 Ocean Flow 浅色主题，统一设计语言，增强动画效果。

**Architecture:** 双轨主题策略（浅色 + 暗色），基于现有 Liquid Glass 组件系统扩展，使用 Flutter 动画框架实现丰富的过渡和反馈效果。

**Tech Stack:** Flutter 3.10+, Dart 3.10+, Provider, SF Pro 字体, Material 3

---

## Phase 1: 设计系统基础

### Task 1: 新增 Ocean Flow 主题配置

**Files:**
- Modify: `lib/theme/app_theme.dart:5-10, 308-329`

**Step 1: 添加 Ocean Flow 主题类型**

在 `AppThemeType` 枚举中添加新主题：

```dart
enum AppThemeType {
  vitalFlow,
  neonTempus,
  arcticFlow,
  electricPulse,
  oceanFlow,  // 新增
}
```

**Step 2: 定义 Ocean Flow 主题数据**

在 `electricPulseTheme` 后添加：

```dart
/// 主题 5: Ocean Flow - 浅色极简风格 (新增)
/// 基于蓝色邻近色系 - 传达专业、信任、现代感
const oceanFlowTheme = AppThemeData(
  name: 'oceanFlow',
  nameZh: 'Ocean Flow',
  description: '浅色极简风格',
  icon: Icons.water_drop_rounded,
  // 背景色 - 极浅灰白
  backgroundColor: Color(0xFFFAFBFC),
  // 卡片背景 - 纯白
  surfaceColor: Color(0xFFFFFFFF),
  // 主色调 - 深海蓝
  primaryColor: Color(0xFF0066CC),
  // 次要色 - 天际青
  secondaryColor: Color(0xFF00A8B5),
  // 强调色 - 绿松石
  accentColor: Color(0xFF00C9B7),
  // 成功色 - 翡翠绿
  successColor: Color(0xFF10B981),
  // 警告色 - 琥珀黄
  warningColor: Color(0xFFF59E0B),
  // 文字色 - 深蓝灰
  textColor: Color(0xFF1A2B3C),
  secondaryTextColor: Color(0xFF6B7280),
  borderColor: Color(0xFFE5E7EB),
  // 渐变色 - 蓝色邻近色渐变
  timerGradientColors: [
    Color(0xFF0066CC),
    Color(0xFF00A8B5),
    Color(0xFF00C9B7),
  ],
  isDark: false,
);
```

**Step 3: 更新主题获取函数**

修改 `getThemeData` 函数：

```dart
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.vitalFlow:
      return vitalFlowTheme;
    case AppThemeType.neonTempus:
      return neonTempusTheme;
    case AppThemeType.arcticFlow:
      return arcticFlowTheme;
    case AppThemeType.electricPulse:
      return electricPulseTheme;
    case AppThemeType.oceanFlow:
      return oceanFlowTheme;
  }
}
```

**Step 4: 更新主题列表**

修改 `allThemes` 列表：

```dart
const allThemes = [
  oceanFlowTheme,     // 新默认主题
  vitalFlowTheme,     // 原默认主题
  neonTempusTheme,    // 旧版
  arcticFlowTheme,    // 旧版
  electricPulseTheme, // 旧版
];
```

**Step 5: 验证编译**

Run: `flutter analyze lib/theme/app_theme.dart`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat(theme): add Ocean Flow light theme configuration"
```

---

### Task 2: 更新 ThemeProvider 支持新主题

**Files:**
- Modify: `lib/theme/theme_provider.dart`

**Step 1: 检查 ThemeProvider 实现**

Run: `cat lib/theme/theme_provider.dart`

确保 `_themeType` 默认值可以切换到 `AppThemeType.oceanFlow`

**Step 2: 更新默认主题（可选）**

如果需要 Ocean Flow 作为默认主题，修改初始化逻辑：

```dart
AppThemeType _themeType = AppThemeType.oceanFlow;
```

**Step 3: 验证主题切换**

Run: `flutter analyze lib/theme/`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/theme/theme_provider.dart
git commit -m "feat(theme): set Ocean Flow as default theme"
```

---

### Task 3: 创建页面过渡动画组件

**Files:**
- Create: `lib/animations/page_transitions.dart`

**Step 1: 创建淡入上滑过渡动画**

```dart
import 'package:flutter/material.dart';

/// 淡入上滑页面过渡动画
class FadeUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.02);
            const end = Offset.zero;
            const curve = Curves.easeOut;
            
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

/// 淡入淡出过渡动画
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}
```

**Step 2: 验证编译**

Run: `flutter analyze lib/animations/page_transitions.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/animations/page_transitions.dart
git commit -m "feat(animations): add page transition animations"
```

---

### Task 4: 创建列表入场动画组件

**Files:**
- Create: `lib/animations/list_animations.dart`

**Step 1: 创建 staggered 列表动画组件**

```dart
import 'package:flutter/material.dart';

/// Staggered 列表入场动画
class StaggeredListView extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final EdgeInsetsGeometry? padding;

  const StaggeredListView({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.padding,
  });

  @override
  State<StaggeredListView> createState() => _StaggeredListViewState();
}

class _StaggeredListViewState extends State<StaggeredListView>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.itemDuration + 
          widget.staggerDelay * (widget.children.length - 1),
      vsync: this,
    );
    
    _animations = List.generate(widget.children.length, (index) {
      final start = index * widget.staggerDelay.inMilliseconds /
          _controller.duration!.inMilliseconds;
      final end = (start * _controller.duration!.inMilliseconds +
              widget.itemDuration.inMilliseconds) /
          _controller.duration!.inMilliseconds;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
              curve: Curves.easeOut),
        ),
      );
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: widget.padding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _animations[index].value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _animations[index].value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}

/// 单个入场动画包装器
class FadeInItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<FadeInItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
```

**Step 2: 验证编译**

Run: `flutter analyze lib/animations/list_animations.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/animations/list_animations.dart
git commit -m "feat(animations): add staggered list entry animations"
```

---

## Phase 2: 屏幕优化

### Task 5: 优化 SettingsScreen

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Step 1: 统一字体**

将所有 `Orbitron` 和 `Rajdhani` 替换为 `.SF Pro Display` 和 `.SF Pro Text`：

```dart
// 标题部分
Text(
  'SETTINGS',
  style: TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: theme.textColor,
  ),
),

// Section Header
Text(
  title,
  style: TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: theme.secondaryTextColor,
    letterSpacing: 0,
  ),
),
```

**Step 2: 使用主题颜色**

移除硬编码颜色，使用 theme 变量：

```dart
// 替换
color: const Color(0xFF4DB6AC)
// 为
color: theme.primaryColor
```

**Step 3: 复用 LiquidCard**

导入并使用 LiquidCard：

```dart
import '../widgets/glass_widgets.dart';

// 替换 _buildGlassCard 为 LiquidCard
Widget _buildSettingsCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return LiquidCard(
    padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
    child: child,
  );
}
```

**Step 4: 添加主题切换选项**

在设置中添加主题选择器：

```dart
// 在 _buildSectionHeader('外观设置') 后添加
_buildSettingsCard(
  child: Column(
    children: [
      ListTile(
        title: Text('主题', style: TextStyle(color: theme.textColor)),
        subtitle: Text(
          themeProvider.currentTheme.nameZh,
          style: TextStyle(color: theme.secondaryTextColor),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.secondaryTextColor),
        onTap: () => _showThemeSelector(context, themeProvider),
      ),
    ],
  ),
),

// 添加主题选择方法
void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
  showModalBottomSheet(
    context: context,
    builder: (context) => LiquidGlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: allThemes.map((theme) {
          final isSelected = themeProvider.currentTheme.name == theme.name;
          return ListTile(
            leading: Icon(theme.icon, color: theme.primaryColor),
            title: Text(theme.nameZh),
            subtitle: Text(theme.description),
            trailing: isSelected 
              ? Icon(Icons.check, color: themeProvider.currentTheme.primaryColor)
              : null,
            onTap: () {
              themeProvider.setTheme(
                AppThemeType.values.firstWhere((t) => 
                  getThemeData(t).name == theme.name
                ),
              );
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}
```

**Step 5: 验证编译**

Run: `flutter analyze lib/screens/settings_screen.dart`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "refactor(settings): unify fonts and add theme selector"
```

---

### Task 6: 优化 HistoryScreen

**Files:**
- Modify: `lib/screens/history_screen.dart`

**Step 1: 统一字体**

替换字体为 SF Pro 系列

**Step 2: 使用主题颜色**

移除硬编码颜色

**Step 3: 添加列表入场动画**

```dart
import '../animations/list_animations.dart';

// 在 ListView.builder 中使用 StaggeredListView 或添加 FadeInItem
```

**Step 4: 验证编译**

Run: `flutter analyze lib/screens/history_screen.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/screens/history_screen.dart
git commit -m "refactor(history): unify fonts and add entry animations"
```

---

### Task 7: 优化 StatsScreen

**Files:**
- Modify: `lib/screens/stats_screen.dart`

**Step 1: 统一字体**

**Step 2: 使用主题颜色**

**Step 3: 添加图表动画**

为柱状图添加入场动画

**Step 4: 验证编译**

Run: `flutter analyze lib/screens/stats_screen.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/screens/stats_screen.dart
git commit -m "refactor(stats): unify fonts and add chart animations"
```

---

## Phase 3: 动画增强

### Task 8: 增强计时器氛围动画

**Files:**
- Modify: `lib/widgets/animated_timer_widget.dart`

**Step 1: 添加呼吸光晕效果**

为 AnimatedTimerDisplay 添加呼吸动画

**Step 2: 验证编译**

Run: `flutter analyze lib/widgets/animated_timer_widget.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/widgets/animated_timer_widget.dart
git commit -m "feat(timer): enhance ambient animation effects"
```

---

### Task 9: 应用页面过渡动画

**Files:**
- Modify: `lib/main.dart`

**Step 1: 在导航中使用 FadeUpPageRoute**

```dart
import 'animations/page_transitions.dart';

// 在路由中使用自定义过渡
```

**Step 2: 验证编译**

Run: `flutter analyze lib/main.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(navigation): apply page transition animations"
```

---

## Phase 4: 验证与发布

### Task 10: 全面测试

**Step 1: 运行静态分析**

Run: `flutter analyze`
Expected: No issues found

**Step 2: 运行测试**

Run: `flutter test`
Expected: All tests pass

**Step 3: 手动测试**

- 切换主题验证
- 页面过渡动画
- 列表入场动画
- 计时器动画

**Step 4: 构建验证**

Run: `flutter build apk --debug`
Expected: Build successful

**Step 5: 最终提交**

```bash
git add .
git commit -m "feat(ui): complete Ocean Flow UI/UX optimization"
```

---

## 文件变更汇总

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/theme/app_theme.dart` | 修改 | 新增 Ocean Flow 主题 |
| `lib/theme/theme_provider.dart` | 修改 | 更新默认主题 |
| `lib/animations/page_transitions.dart` | 新建 | 页面过渡动画 |
| `lib/animations/list_animations.dart` | 新建 | 列表入场动画 |
| `lib/screens/settings_screen.dart` | 重构 | 统一字体、添加主题切换 |
| `lib/screens/history_screen.dart` | 重构 | 统一字体、添加动画 |
| `lib/screens/stats_screen.dart` | 重构 | 统一字体、添加动画 |
| `lib/widgets/animated_timer_widget.dart` | 增强 | 氛围动画 |
| `lib/main.dart` | 修改 | 应用页面过渡 |

---

## 注意事项

1. **字体兼容性**：SF Pro 在 iOS/macOS 原生支持，Android 需要使用 fallback 字体或加载自定义字体
2. **动画性能**：在低端设备上测试动画性能
3. **主题切换**：确保切换主题时所有颜色正确更新
4. **无障碍**：保持足够的颜色对比度
