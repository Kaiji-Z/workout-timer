# VitalFlow 2.0 UI Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform the workout timer app UI to a layered design with cyan/mint green color system, neon progress ring, frosted glass cards, and flat capsule buttons.

**Architecture:** 4-layer visual hierarchy - Background Layer (gradient + decorative halos) → Progress Ring Layer (neon glow effect) → Card Layer (frosted glass containers) → Content Layer (buttons, text, icons). Each layer is independently styled but visually cohesive.

**Tech Stack:** Flutter 3.10+, Dart 3.0+, existing glass_widgets.dart components

---

## Design System Reference

### Color Palette (Direction A - Cyan Vitality)
```
Primary:      #00f0ff (Cyan - main accent, progress ring, primary buttons)
Secondary:    #00ffaa (Mint Green - rest state, success, secondary actions)
Background:   #e6f7ff → #b3e0ff → #ffffff (Gradient: light blue to white)
Surface:      #ffffff (Card backgrounds)
Text Primary: #333333
Text Secondary: #666666
Border:       rgba(0,0,0,0.08)
```

### Layer Specifications
```
Layer 1 - Background:
  - Gradient: #e6f7ff → #b3e0ff → #ffffff (top to bottom)
  - Decorative halos: 2-3 circular gradients (cyan 10% alpha, mint 8% alpha)
  
Layer 2 - Progress Ring:
  - Stroke width: 6% of timer size
  - Gradient: #00f0ff → #00ffaa
  - Glow: blur 15px, alpha 40%
  - Outer halo: spread 30px, blur 50px, alpha 15%
  
Layer 3 - Cards (Frosted Glass):
  - Timer Card: Circular, blur 20px, opacity 92%, border 1px 30% white
  - Button Area: Rounded rect (16px), blur 15px, opacity 88%
  - Nav Bar: Capsule, blur 20px, opacity 85%, border 0.5px 50% white
  
Layer 4 - Content:
  - Buttons: Flat solid color, capsule shape, light shadow (8px blur, 20% alpha)
  - Text: SF Pro Display/Text, existing typography
```

---

## Task 1: Update Color System

**Files:**
- Modify: `lib/theme/app_theme.dart:203-230` (vitalFlowTheme definition)

**Step 1: Update primary and secondary colors**

Replace the vitalFlowTheme color values:

```dart
/// 主题 1: VitalFlow - 青绿活力风格 (推荐)
/// 基于参考图设计规范 - 青绿科技感
const vitalFlowTheme = AppThemeData(
  name: 'vitalFlow',
  nameZh: 'VitalFlow',
  description: '青绿活力风格',
  icon: Icons.water_drop_rounded,
  // 背景色 - 浅青到白渐变的基础色
  backgroundColor: Color(0xFFe6f7ff),
  // 卡片背景 - 纯白
  surfaceColor: Color(0xFFFFFFFF),
  // 主色调 - 青色 (更亮、更科技感)
  primaryColor: Color(0xFF00f0ff),
  // 辅助色 - 薄荷绿
  secondaryColor: Color(0xFF00ffaa),
  // 强调色 - 薄荷绿
  accentColor: Color(0xFF00ffaa),
  // 成功色 - 薄荷绿
  successColor: Color(0xFF00ffaa),
  // 警告色 - 保持橙色
  warningColor: Color(0xFFff9500),
  textColor: Color(0xFF333333),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0x14000000), // rgba(0,0,0,0.08)
  // 渐变色 - 青到绿
  timerGradientColors: [
    Color(0xFF00f0ff),
    Color(0xFF00ffaa),
  ],
  isDark: false,
);
```

**Step 2: Verify color changes**

Run: `flutter analyze lib/theme/app_theme.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/theme/app_theme.dart
git commit -m "feat(theme): update VitalFlow colors to cyan/mint green palette"
```

---

## Task 2: Redesign Background Layer with Decorative Halos

**Files:**
- Modify: `lib/screens/timer_screen.dart`
- Modify: `lib/widgets/training_widget.dart:33-65`

**Step 1: Create reusable background widget in timer_screen.dart**

Add a new widget at the end of the file (before the closing of the file):

```dart
import 'dart:ui';

// ... existing imports

/// VitalFlow 背景层 - 渐变 + 装饰性光晕
class VitalFlowBackground extends StatelessWidget {
  final Widget child;

  const VitalFlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFe6f7ff), // 浅青
            Color(0xFFb3e0ff), // 中青
            Color(0xFFf0faff), // 接近白
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 装饰性光晕 - 右上角 (青色)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00f0ff).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 装饰性光晕 - 左下角 (薄荷绿)
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00ffaa).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 装饰性光晕 - 中右 (青色，较小)
          Positioned(
            top: 200,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00f0ff).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 内容
          child,
        ],
      ),
    );
  }
}
```

**Step 2: Update TimerScreen to use VitalFlowBackground**

Replace the build method in TimerScreen:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: VitalFlowBackground(
      child: const SafeArea(
        child: TrainingWidget(),
      ),
    ),
  );
}
```

**Step 3: Update TrainingWidget to remove its own background gradient**

In `lib/widgets/training_widget.dart`, modify the `build` method. Find the Container with gradient decoration (around lines 33-44) and replace with:

```dart
return Consumer<TrainingProvider>(
  builder: (context, training, child) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ... rest of the code remains the same
```

Remove the outer Container with gradient - the background is now handled by VitalFlowBackground.

**Step 4: Verify background changes**

Run: `flutter analyze lib/screens/timer_screen.dart lib/widgets/training_widget.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/screens/timer_screen.dart lib/widgets/training_widget.dart
git commit -m "feat(ui): add VitalFlow background with gradient and decorative halos"
```

---

## Task 3: Redesign Progress Ring with Neon Glow Effect

**Files:**
- Modify: `lib/widgets/animated_timer_widget.dart:39-114` (AnimatedTimerDisplay)
- Modify: `lib/widgets/animated_timer_widget.dart:116-189` (_TimerProgressPainter)

**Step 1: Update AnimatedTimerDisplay build method**

Replace the build method with enhanced neon glow:

```dart
@override
Widget build(BuildContext context) {
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // 外层光晕 - 氛围效果 (Layer 2a)
        Container(
          width: size * 1.2,
          height: size * 1.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isCountdown ? theme.successColor : theme.primaryColor)
                    .withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // 内层发光 - 霓虹效果 (Layer 2b)
        Container(
          width: size * 0.95,
          height: size * 0.95,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isCountdown ? theme.successColor : theme.primaryColor)
                    .withValues(alpha: 0.35),
                spreadRadius: 15,
                blurRadius: 40,
              ),
            ],
          ),
        ),
        // Progress ring - 霓虹进度环
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _TimerProgressPainter(
              progress: progress,
              primaryColor: theme.primaryColor,
              secondaryColor: theme.successColor,
              backgroundColor: theme.borderColor,
              strokeWidth: size * 0.055, // 约16px for 300px
              isCountdown: isCountdown,
            ),
          ),
        ),
        // Timer Card - 毛玻璃圆形卡片 (Layer 3)
        _buildTimerCard(theme),
      ],
    ),
  );
}

/// 构建计时器毛玻璃卡片
Widget _buildTimerCard(AppThemeData theme) {
  return ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: size * 0.82,
        height: size * 0.82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.92),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedNumber(
                value: _formatTime(seconds),
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w300,
                  color: theme.textColor,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: size * 0.065,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryTextColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

**Step 2: Add import for dart:ui at the top of animated_timer_widget.dart**

```dart
import 'dart:ui';
import 'dart:math' as math;
```

**Step 3: Update _TimerProgressPainter for neon effect**

Replace the entire _TimerProgressPainter class:

```dart
class _TimerProgressPainter extends ChangeNotifier implements CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final double strokeWidth;
  final bool isCountdown;

  _TimerProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.isCountdown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    final activeColor = isCountdown ? secondaryColor : primaryColor;

    // 背景环 - 极淡
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 外发光层 - 霓虹光晕
    final outerGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.25)
      ..strokeWidth = strokeWidth * 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      outerGlowPaint,
    );

    // 进度环 - 渐变色 (青到绿)
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [
        primaryColor,
        isCountdown ? secondaryColor : primaryColor.withValues(alpha: 0.7),
        isCountdown ? primaryColor : secondaryColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 内发光 - 沿进度环
    final innerGlowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth * 0.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      innerGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isCountdown != isCountdown;
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
```

**Step 4: Verify progress ring changes**

Run: `flutter analyze lib/widgets/animated_timer_widget.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/widgets/animated_timer_widget.dart
git commit -m "feat(ui): add neon glow effect to progress ring with gradient"
```

---

## Task 4: Create Flat Capsule Button Component

**Files:**
- Modify: `lib/widgets/glass_widgets.dart:171-376` (LiquidButton and LiquidOutlineButton)

**Step 1: Create new FlatCapsuleButton widget**

Add after the existing LiquidButton class (around line 377):

```dart
// ============================================================================
// FLAT CAPSULE BUTTONS - VitalFlow 2.0 Design
// ============================================================================

/// 扁平化胶囊按钮 - VitalFlow 2.0 风格
/// 
/// 特点:
/// - 纯色填充 (无渐变)
/// - 胶囊形状
/// - 轻阴影
/// - 按下动态缩放
class FlatCapsuleButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isPrimary;
  final double height;
  final bool isLoading;

  const FlatCapsuleButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    required this.color,
    this.isPrimary = true,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  State<FlatCapsuleButton> createState() => _FlatCapsuleButtonState();
}

class _FlatCapsuleButtonState extends State<FlatCapsuleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.height / 2;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) {
        _controller.reverse();
        widget.onPressed?.call();
      } : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                // 主按钮: 纯色填充 | 次要按钮: 透明 + 边框
                color: widget.isPrimary ? widget.color : Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                border: widget.isPrimary
                    ? null
                    : Border.all(color: widget.color, width: 1.5),
                // 轻阴影 (仅主按钮)
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            widget.isPrimary ? Colors.white : widget.color,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.isPrimary ? Colors.white : widget.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: widget.isPrimary ? Colors.white : widget.color,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

**Step 2: Update SingleRowButtonArea to use FlatCapsuleButton**

Find the SingleRowButtonArea class (around line 1036) and update its build method:

```dart
@override
Widget build(BuildContext context) {
  if (buttons.isEmpty) return const SizedBox.shrink();
  
  return Row(
    children: buttons.asMap().entries.map((entry) {
      final index = entry.key;
      final button = entry.value;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: index < buttons.length - 1 ? gap : 0,
          ),
          child: FlatCapsuleButton(
            label: button.label,
            icon: button.icon,
            color: button.isDestructive 
                ? button.color 
                : (button.isPrimary ? button.color : button.color),
            height: height,
            onPressed: button.onPressed,
            isPrimary: button.isPrimary,
          ),
        ),
      );
    }).toList(),
  );
}
```

**Step 3: Verify button changes**

Run: `flutter analyze lib/widgets/glass_widgets.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/widgets/glass_widgets.dart
git commit -m "feat(ui): add FlatCapsuleButton for VitalFlow 2.0 design"
```

---

## Task 5: Create Button Area Card Container

**Files:**
- Modify: `lib/widgets/training_widget.dart:221-286` (_buildBottomSection, _buildSingleRowButtons)

**Step 1: Update _buildBottomSection to wrap buttons in frosted glass card**

Replace the _buildBottomSection method:

```dart
/// 底部区域：状态徽章 + 按钮区域卡片
Widget _buildBottomSection(BuildContext context, TrainingProvider training, AppThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // 状态徽章
        _buildStatusBadge(training, theme),
        const SizedBox(height: 16),
        // 按钮区域 - 毛玻璃卡片
        _buildButtonAreaCard(training, theme),
        const SizedBox(height: 16),
      ],
    ),
  );
}

/// 按钮区域毛玻璃卡片
Widget _buildButtonAreaCard(TrainingProvider training, AppThemeData theme) {
  final buttons = _getButtonsForState(context, training, theme);
  
  if (buttons.isEmpty) {
    return const SizedBox.shrink();
  }
  
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleRowButtonArea(
          buttons: buttons,
          height: 52,
          gap: 10,
        ),
      ),
    ),
  );
}
```

**Step 2: Add import for dart:ui at the top of training_widget.dart**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
// ... rest of imports
```

**Step 3: Verify button area changes**

Run: `flutter analyze lib/widgets/training_widget.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/widgets/training_widget.dart
git commit -m "feat(ui): wrap buttons in frosted glass card container"
```

---

## Task 6: Update Stopwatch Display (Small Timer)

**Files:**
- Modify: `lib/widgets/animated_timer_widget.dart:192-250` (AnimatedStopwatchDisplay)

**Step 1: Update AnimatedStopwatchDisplay with frosted glass style**

Replace the AnimatedStopwatchDisplay build method:

```dart
@override
Widget build(BuildContext context) {
  return ClipOval(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.85),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedNumber(
              value: _formatTime(seconds),
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: size * 0.22,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
                letterSpacing: -1,
              ),
            ),
            Text(
              '总时长',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: size * 0.12,
                fontWeight: FontWeight.w400,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Step 2: Verify stopwatch changes**

Run: `flutter analyze lib/widgets/animated_timer_widget.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/widgets/animated_timer_widget.dart
git commit -m "feat(ui): update stopwatch display with frosted glass style"
```

---

## Task 7: Update Duration Picker Design

**Files:**
- Modify: `lib/widgets/duration_picker.dart:246-313` (_buildBottomSection, _buildConfirmButton)

**Step 1: Update confirm button to use flat capsule style**

Replace _buildConfirmButton method:

```dart
Widget _buildConfirmButton(AppThemeData theme) {
  return GestureDetector(
    onTap: _onConfirm,
    child: Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '确认',
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
    ),
  );
}
```

**Step 2: Update wheel selection indicator to match new color system**

In _buildWheel method, update the selection indicator colors (around line 328-342):

```dart
// Selection indicator - iOS 26 风格
Center(
  child: Container(
    height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: theme.primaryColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.primaryColor.withValues(alpha: 0.25),
        width: 1,
      ),
    ),
  ),
),
```

**Step 3: Verify duration picker changes**

Run: `flutter analyze lib/widgets/duration_picker.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/widgets/duration_picker.dart
git commit -m "feat(ui): update duration picker with flat button style"
```

---

## Task 8: Update Completed State Display

**Files:**
- Modify: `lib/widgets/training_widget.dart:155-219` (_buildCompletedDisplay)

**Step 1: Update completed display with frosted glass card**

Replace _buildCompletedDisplay method:

```dart
/// 完成状态显示
Widget _buildCompletedDisplay(TrainingProvider training, AppThemeData theme) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // 完成卡片 - 毛玻璃圆形
      PulsingWidget(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                  color: theme.successColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.successColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(training.sessionDuration),
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: theme.textColor,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '总时长',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      // 统计徽章
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassBadge(
            text: '${training.currentSet} 组',
            color: theme.successColor,
            icon: Icons.repeat,
          ),
          const SizedBox(width: 12),
          GlassBadge(
            text: _formatTime(training.totalExerciseTime),
            color: theme.primaryColor,
            icon: Icons.timer,
          ),
        ],
      ),
    ],
  );
}
```

**Step 2: Verify completed display changes**

Run: `flutter analyze lib/widgets/training_widget.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/widgets/training_widget.dart
git commit -m "feat(ui): update completed display with frosted glass style"
```

---

## Task 9: Final Verification and Testing

**Step 1: Run full project analysis**

Run: `flutter analyze`
Expected: No errors (warnings acceptable)

**Step 2: Build and run the app**

Run: `flutter run`
Expected: App launches with new VitalFlow 2.0 design

**Step 3: Manual testing checklist**

- [ ] Background shows gradient with decorative halos
- [ ] Progress ring has neon glow effect
- [ ] Timer card is frosted glass circular
- [ ] Buttons are flat capsule style with dynamic press
- [ ] Button area is wrapped in frosted glass card
- [ ] Duration picker matches new style
- [ ] Completed state shows frosted glass card
- [ ] All states (idle, exercising, resting, paused, completed) display correctly

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat(ui): complete VitalFlow 2.0 UI redesign"
```

---

## Summary

This plan transforms the Workout Timer app UI with:

1. **New Color System** - Cyan (#00f0ff) and Mint Green (#00ffaa) palette
2. **Layered Background** - Gradient + decorative halos
3. **Neon Progress Ring** - Glowing gradient effect with outer halo
4. **Frosted Glass Cards** - Timer card, button area, completed display
5. **Flat Capsule Buttons** - Solid color, light shadow, dynamic press
6. **Unified Design Language** - All components follow the same visual system

Total: 9 tasks, ~30-40 minutes implementation time.
