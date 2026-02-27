# iPhone 5c Theme System Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor the WorkoutTimer theme system to use iPhone 5c-inspired color schemes with unified glass effects and pure color backgrounds with decorative circles.

**Architecture:** Replace 5 existing themes with iPhone 5c color variants (Blue, Green, Yellow, Pink, White), remove `isDark` property, unify all glass effects to use dark-mode settings (blur: 20, background: white 12%, border: white 30%), and transform background from LinearGradient to solid color + decorative circles.

**Tech Stack:** Flutter 3.10+, Dart 3.0+, Provider, existing theme infrastructure

---

## Overview

### Current State
- 5 themes: VitalFlow, Neon Tempus, Arctic Flow, Electric Pulse, Ocean Flow
- Each theme has `isDark` property for dark/light mode distinction
- Glass effects use conditional rendering based on `isDark`
- Background uses `LinearGradient` with `backgroundGradientColors`

### Target State
- 5 themes: iPhone 5c Blue, Green, Yellow, Pink, White
- No `isDark` property - each theme is a single color identity
- All glass effects unified: `white 12%` background, `white 30%` border
- Background: solid `backgroundColor` + semi-transparent decorative circles

### iPhone 5c Color Palette

| Theme | Primary Color | Color Code |
|-------|---------------|------------|
| Blue | #48AEE6 | iPhone XR Blue |
| Green | #AEE1CD | iPhone 11 Green |
| Yellow | #FFE681 | iPhone 11 Yellow |
| Pink | #FF6E5A | iPhone XR Coral |
| White | #F3F3F3 | Clean White |

---

## Phase 1: Theme Data Model Refactor (app_theme.dart)

### Task 1.1: Remove isDark Property from AppThemeData

**Files:**
- Modify: `lib/theme/app_theme.dart:30,49`

**Step 1: Remove isDark property declaration**

Remove line 30:
```dart
final bool isDark;
```

**Step 2: Remove isDark from constructor**

Remove `required this.isDark,` from constructor (line 49).

**Expected:** Compilation errors in multiple files (expected - will fix in later tasks).

---

### Task 1.2: Update toThemeData() Method

**Files:**
- Modify: `lib/theme/app_theme.dart:53-203`

**Step 1: Simplify brightness handling**

Replace conditional brightness with `Brightness.dark`:

```dart
ThemeData toThemeData() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: warningColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
    ),
```

**Step 2: Update cardTheme elevation**

Replace line 76:
```dart
elevation: 0,
```

**Step 3: Update elevatedButtonTheme foregroundColor**

Replace line 85:
```dart
foregroundColor: Colors.white,
```

---

### Task 1.3: Create iPhone 5c Color Utility Functions

**Files:**
- Modify: `lib/theme/app_theme.dart` (add after AppThemeData class)

**Step 1: Add color manipulation helpers**

```dart
/// Lightens a color by the given amount [amount] (0.0 to 1.0)
Color _lightenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// Darkens a color by the given amount [amount] (0.0 to 1.0)
Color _darkenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// Creates a very light background variant from primary color
Color _createBackgroundVariant(Color primary) {
  final hsl = HSLColor.fromColor(primary);
  // Make it very light but maintain some color tint
  return hsl.withLightness(0.95).withSaturation(hsl.saturation * 0.3).toColor();
}
```

---

### Task 1.4: Define iPhone 5c Blue Theme

**Files:**
- Modify: `lib/theme/app_theme.dart` (replace vitalFlowTheme, lines 206-244)

**Step 1: Create iPhone5cBlue theme**

```dart
/// Theme: iPhone 5c Blue - iPhone XR Blue inspired
const iphone5cBlueTheme = AppThemeData(
  name: 'iphone5cBlue',
  nameZh: 'iPhone Blue',
  description: '清新蓝色风格',
  icon: Icons.phone_iphone,
  // Background - very light blue
  backgroundColor: Color(0xFFF0F8FF),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - iPhone XR Blue
  primaryColor: Color(0xFF48AEE6),
  // Secondary - lighter blue
  secondaryColor: Color(0xFF7CC4F0),
  // Accent - deeper blue
  accentColor: Color(0xFF2196F3),
  // Success - teal
  successColor: Color(0xFF4CAF50),
  // Warning - amber
  warningColor: Color(0xFFFFC107),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - blue tones
  timerGradientColors: [
    Color(0xFF48AEE6),
    Color(0xFF2196F3),
  ],
  // Background decoration colors
  backgroundGradientColors: [
    Color(0x3348AEE6), // Semi-transparent blue for circles
    Color(0x2248AEE6),
    Color(0x1148AEE6),
  ],
);
```

---

### Task 1.5: Define iPhone 5c Green Theme

**Files:**
- Modify: `lib/theme/app_theme.dart` (replace neonTempusTheme, lines 246-274)

**Step 1: Create iPhone5cGreen theme**

```dart
/// Theme: iPhone 5c Green - iPhone 11 Green inspired
const iphone5cGreenTheme = AppThemeData(
  name: 'iphone5cGreen',
  nameZh: 'iPhone Green',
  description: '清新绿色风格',
  icon: Icons.eco_rounded,
  backgroundColor: Color(0xFFF0FFF4),
  surfaceColor: Color(0xFFFFFFFF),
  primaryColor: Color(0xFFAEE1CD),
  secondaryColor: Color(0xFFC8EBD9),
  accentColor: Color(0xFF66BB6A),
  successColor: Color(0xFF4CAF50),
  warningColor: Color(0xFFFFC107),
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  timerGradientColors: [
    Color(0xFFAEE1CD),
    Color(0xFF66BB6A),
  ],
  backgroundGradientColors: [
    Color(0x33AEE1CD),
    Color(0x22AEE1CD),
    Color(0x11AEE1CD),
  ],
);
```

---

### Task 1.6: Define iPhone 5c Yellow Theme

**Files:**
- Modify: `lib/theme/app_theme.dart` (replace arcticFlowTheme, lines 276-304)

**Step 1: Create iPhone5cYellow theme**

```dart
/// Theme: iPhone 5c Yellow - iPhone 11 Yellow inspired
const iphone5cYellowTheme = AppThemeData(
  name: 'iphone5cYellow',
  nameZh: 'iPhone Yellow',
  description: '明亮黄色风格',
  icon: Icons.wb_sunny_rounded,
  backgroundColor: Color(0xFFFFFEF5),
  surfaceColor: Color(0xFFFFFFFF),
  primaryColor: Color(0xFFFFE681),
  secondaryColor: Color(0xFFFFF0A3),
  accentColor: Color(0xFFFFB300),
  successColor: Color(0xFF4CAF50),
  warningColor: Color(0xFFFF8F00),
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  timerGradientColors: [
    Color(0xFFFFE681),
    Color(0xFFFFB300),
  ],
  backgroundGradientColors: [
    Color(0x33FFE681),
    Color(0x22FFE681),
    Color(0x11FFE681),
  ],
);
```

---

### Task 1.7: Define iPhone 5c Pink Theme

**Files:**
- Modify: `lib/theme/app_theme.dart` (replace electricPulseTheme, lines 306-334)

**Step 1: Create iPhone5cPink theme**

```dart
/// Theme: iPhone 5c Pink - iPhone XR Coral inspired
const iphone5cPinkTheme = AppThemeData(
  name: 'iphone5cPink',
  nameZh: 'iPhone Pink',
  description: '活力粉色风格',
  icon: Icons.favorite_rounded,
  backgroundColor: Color(0xFFFFF5F3),
  surfaceColor: Color(0xFFFFFFFF),
  primaryColor: Color(0xFFFF6E5A),
  secondaryColor: Color(0xFFFF8A7A),
  accentColor: Color(0xFFE91E63),
  successColor: Color(0xFF4CAF50),
  warningColor: Color(0xFFFFC107),
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  timerGradientColors: [
    Color(0xFFFF6E5A),
    Color(0xFFE91E63),
  ],
  backgroundGradientColors: [
    Color(0x33FF6E5A),
    Color(0x22FF6E5A),
    Color(0x11FF6E5A),
  ],
);
```

---

### Task 1.8: Define iPhone 5c White Theme

**Files:**
- Modify: `lib/theme/app_theme.dart` (replace oceanFlowTheme, lines 336-374)

**Step 1: Create iPhone5cWhite theme**

```dart
/// Theme: iPhone 5c White - Clean minimal style
const iphone5cWhiteTheme = AppThemeData(
  name: 'iphone5cWhite',
  nameZh: 'iPhone White',
  description: '纯净白色风格',
  icon: Icons.phone_iphone,
  backgroundColor: Color(0xFFF3F3F3),
  surfaceColor: Color(0xFFFFFFFF),
  primaryColor: Color(0xFF333333),
  secondaryColor: Color(0xFF666666),
  accentColor: Color(0xFF007AFF),
  successColor: Color(0xFF4CAF50),
  warningColor: Color(0xFFFFC107),
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  timerGradientColors: [
    Color(0xFF333333),
    Color(0xFF007AFF),
  ],
  backgroundGradientColors: [
    Color(0x22333333),
    Color(0x11333333),
    Color(0x08333333),
  ],
);
```

---

### Task 1.9: Update AppThemeType Enum

**Files:**
- Modify: `lib/theme/app_theme.dart:4-10`

**Step 1: Replace enum values**

```dart
enum AppThemeType {
  iphone5cBlue,
  iphone5cGreen,
  iphone5cYellow,
  iphone5cPink,
  iphone5cWhite,
}
```

---

### Task 1.10: Update getThemeData Function

**Files:**
- Modify: `lib/theme/app_theme.dart:377-390`

**Step 1: Update switch cases**

```dart
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.iphone5cBlue:
      return iphone5cBlueTheme;
    case AppThemeType.iphone5cGreen:
      return iphone5cGreenTheme;
    case AppThemeType.iphone5cYellow:
      return iphone5cYellowTheme;
    case AppThemeType.iphone5cPink:
      return iphone5cPinkTheme;
    case AppThemeType.iphone5cWhite:
      return iphone5cWhiteTheme;
  }
}
```

---

### Task 1.11: Update allThemes List

**Files:**
- Modify: `lib/theme/app_theme.dart:393-399`

**Step 1: Replace theme list**

```dart
const allThemes = [
  iphone5cWhiteTheme,   // Default
  iphone5cBlueTheme,
  iphone5cGreenTheme,
  iphone5cYellowTheme,
  iphone5cPinkTheme,
];
```

---

## Phase 2: Theme Provider Update (theme_provider.dart)

### Task 2.1: Update Default Theme

**Files:**
- Modify: `lib/theme/theme_provider.dart:10-11`

**Step 1: Change default to iPhone5cWhite**

```dart
AppThemeType _currentThemeType = AppThemeType.iphone5cWhite;
AppThemeData _currentTheme = iphone5cWhiteTheme;
```

---

### Task 2.2: Update Theme Name Mappings

**Files:**
- Modify: `lib/theme/theme_provider.dart:50-63,66-81`

**Step 1: Update _typeToThemeName method**

```dart
String _typeToThemeName(AppThemeType type) {
  switch (type) {
    case AppThemeType.iphone5cBlue:
      return 'iphone5cBlue';
    case AppThemeType.iphone5cGreen:
      return 'iphone5cGreen';
    case AppThemeType.iphone5cYellow:
      return 'iphone5cYellow';
    case AppThemeType.iphone5cPink:
      return 'iphone5cPink';
    case AppThemeType.iphone5cWhite:
      return 'iphone5cWhite';
  }
}
```

**Step 2: Update _themeNameToType method**

```dart
AppThemeType _themeNameToType(String name) {
  switch (name) {
    case 'iphone5cWhite':
      return AppThemeType.iphone5cWhite;
    case 'iphone5cBlue':
      return AppThemeType.iphone5cBlue;
    case 'iphone5cGreen':
      return AppThemeType.iphone5cGreen;
    case 'iphone5cYellow':
      return AppThemeType.iphone5cYellow;
    case 'iphone5cPink':
      return AppThemeType.iphone5cPink;
    default:
      return AppThemeType.iphone5cWhite;
  }
}
```

---

## Phase 3: Background Decorative Circles (main.dart)

### Task 3.1: Create Decorative Circles Widget

**Files:**
- Modify: `lib/main.dart` (add before _MainNavigationState class)

**Step 1: Add DecorativeCircles widget**

```dart
/// Decorative background circles - iPhone 5c style
class DecorativeCircles extends StatelessWidget {
  final List<Color> colors;
  
  const DecorativeCircles({super.key, required this.colors});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right circle
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.isNotEmpty ? colors[0] : Colors.transparent,
            ),
          ),
        ),
        // Bottom-left circle
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.length > 1 ? colors[1] : Colors.transparent,
            ),
          ),
        ),
        // Center-right small circle
        Positioned(
          top: 300,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.length > 2 ? colors[2] : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

### Task 3.2: Update Body Background

**Files:**
- Modify: `lib/main.dart:96-103`

**Step 1: Replace LinearGradient with solid color + circles**

Replace:
```dart
body: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: appTheme.backgroundGradientColors,
    ),
  ),
```

With:
```dart
body: Stack(
  children: [
    // Solid background color
    Container(
      color: appTheme.backgroundColor,
    ),
    // Decorative circles
    DecorativeCircles(colors: appTheme.backgroundGradientColors),
    // Content
    SafeArea(
```

**Step 2: Close the SafeArea and Stack properly**

The structure becomes:
```dart
body: Stack(
  children: [
    Container(color: appTheme.backgroundColor),
    DecorativeCircles(colors: appTheme.backgroundGradientColors),
    SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        // ... existing AnimatedSwitcher code
      ),
    ),
  ],
),
```

---

### Task 3.3: Remove isDark Reference in Navigation

**Files:**
- Modify: `lib/main.dart:90`

**Step 1: Remove isDark variable**

Delete:
```dart
final isDark = appTheme.isDark;
```

---

### Task 3.4: Unify Navigation Bar Glass Effect

**Files:**
- Modify: `lib/main.dart:138-147`

**Step 1: Remove isDark conditionals in glass effect**

Replace:
```dart
color: isDark 
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.white.withValues(alpha: 0.60),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.12),
```

Replace:
```dart
color: isDark 
    ? Colors.white.withValues(alpha: 0.30)
    : Colors.white.withValues(alpha: 0.80),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.30),
```

---

### Task 3.5: Unify Navigation Item Colors

**Files:**
- Modify: `lib/main.dart:169-171`

**Step 1: Remove isDark from inactiveColor**

Replace:
```dart
final inactiveColor = appTheme.isDark 
    ? appTheme.textColor.withValues(alpha: 0.5)
    : appTheme.textColor.withValues(alpha: 0.4);
```

With:
```dart
final inactiveColor = appTheme.textColor.withValues(alpha: 0.5);
```

---

## Phase 4: Unify Glass Effects (training_widget.dart)

### Task 4.1: Unify Completed Display Glass Effect

**Files:**
- Modify: `lib/widgets/training_widget.dart:158-165`

**Step 1: Remove isDark conditionals**

Replace:
```dart
color: theme.isDark 
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.white.withValues(alpha: 0.60),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.12),
```

Replace:
```dart
color: theme.isDark 
    ? Colors.white.withValues(alpha: 0.30)
    : Colors.white.withValues(alpha: 0.80),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.30),
```

---

### Task 4.2: Unify Button Area Glass Effect

**Files:**
- Modify: `lib/widgets/training_widget.dart:257,267-275`

**Step 1: Remove isDark variable**

Delete line 257:
```dart
final isDark = theme.isDark;
```

**Step 2: Replace isDark references**

Replace:
```dart
color: isDark 
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.white.withValues(alpha: 0.60),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.12),
```

Replace:
```dart
color: isDark 
    ? Colors.white.withValues(alpha: 0.30)
    : Colors.white.withValues(alpha: 0.80),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.30),
```

---

## Phase 5: Unify Glass Effects (stats_screen.dart)

### Task 5.1: Unify Glass Section Effect

**Files:**
- Modify: `lib/screens/stats_screen.dart:328-336`

**Step 1: Remove isDark conditionals**

Replace:
```dart
color: theme.isDark 
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.white.withValues(alpha: 0.60),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.12),
```

Replace:
```dart
color: theme.isDark 
    ? Colors.white.withValues(alpha: 0.30)
    : Colors.white.withValues(alpha: 0.80),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.30),
```

---

## Phase 6: Unify Glass Effects (settings_screen.dart)

### Task 6.1: Unify _buildGlassCard Effect

**Files:**
- Modify: `lib/screens/settings_screen.dart:243-251`

**Step 1: Remove isDark conditionals**

Replace:
```dart
color: theme.isDark 
    ? Colors.white.withValues(alpha: 0.12)
    : Colors.white.withValues(alpha: 0.60),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.12),
```

Replace:
```dart
color: theme.isDark
    ? Colors.white.withValues(alpha: 0.30)
    : Colors.white.withValues(alpha: 0.80),
```

With:
```dart
color: Colors.white.withValues(alpha: 0.30),
```

---

## Phase 7: Update history_screen.dart

### Task 7.1: Remove isDark Reference

**Files:**
- Modify: `lib/screens/history_screen.dart:249`

**Step 1: Simplify text color**

Replace:
```dart
color: theme.isDark ? theme.backgroundColor : theme.surfaceColor,
```

With:
```dart
color: Colors.white,
```

---

## Phase 8: Update glass_widgets.dart (Optional Enhancement)

### Task 8.1: Simplify Glass Widgets (Recommended)

**Files:**
- Modify: `lib/widgets/glass_widgets.dart`

**Note:** The `glass_widgets.dart` file uses `Theme.of(context).brightness` for `isDark` detection. Since our themes now always use `Brightness.dark`, these will automatically use the dark-mode values. However, for clarity and consistency, we can optionally simplify these to use the unified values directly.

**Decision Point:** Skip this task if glass_widgets.dart works correctly with the new theme system, or update for explicit clarity.

---

## Phase 9: Verification & Testing

### Task 9.1: Run Flutter Analyze

**Step 1: Check for compilation errors**

Run: `flutter analyze`

Expected: No errors related to `isDark` or theme types.

---

### Task 9.2: Run Application

**Step 1: Start the app**

Run: `flutter run`

**Step 2: Verify each theme**

1. Open Settings screen
2. Select each theme:
   - iPhone White - Verify white background with gray decorative circles
   - iPhone Blue - Verify light blue background with blue circles
   - iPhone Green - Verify light green background with green circles
   - iPhone Yellow - Verify light yellow background with yellow circles
   - iPhone Pink - Verify light pink background with pink circles
3. Check glass effects are consistent (dark-mode style)
4. Verify text contrast on all backgrounds

---

### Task 9.3: Test All Screens

**Step 1: Navigate through all screens**

- Timer Screen: Verify decorative circles visible, glass effects work
- History Screen: Verify cards display correctly
- Stats Screen: Verify glass cards render properly
- Settings Screen: Verify theme selector shows new themes

---

### Task 9.4: Test Theme Persistence

**Step 1: Test theme save/restore**

1. Select iPhone Blue theme
2. Close and restart app
3. Verify iPhone Blue is still selected

---

## Task Summary

| Phase | Tasks | Files Modified | Can Run in Parallel |
|-------|-------|----------------|---------------------|
| Phase 1 | 1.1-1.11 | app_theme.dart | No (sequential) |
| Phase 2 | 2.1-2.2 | theme_provider.dart | After Phase 1 |
| Phase 3 | 3.1-3.5 | main.dart | After Phase 1 |
| Phase 4 | 4.1-4.2 | training_widget.dart | After Phase 1 |
| Phase 5 | 5.1 | stats_screen.dart | After Phase 1 |
| Phase 6 | 6.1 | settings_screen.dart | After Phase 1 |
| Phase 7 | 7.1 | history_screen.dart | After Phase 1 |
| Phase 8 | 8.1 | glass_widgets.dart | Optional |
| Phase 9 | 9.1-9.4 | N/A | After all phases |

---

## Parallel Execution Groups

**Group A (After Phase 1 Complete):**
- Phase 2: theme_provider.dart
- Phase 3: main.dart
- Phase 4: training_widget.dart
- Phase 5: stats_screen.dart
- Phase 6: settings_screen.dart
- Phase 7: history_screen.dart

**Group B (After All Code Changes):**
- Phase 9: Verification & Testing

---

## Color Reference

### iPhone 5c Palette with Generated Variants

```
iPhone Blue (#48AEE6):
- Background: #F0F8FF (very light blue)
- Primary: #48AEE6
- Secondary: #7CC4F0
- Accent: #2196F3
- Circle colors: #48AEE6 @ 20%, 13%, 7% opacity

iPhone Green (#AEE1CD):
- Background: #F0FFF4
- Primary: #AEE1CD
- Secondary: #C8EBD9
- Accent: #66BB6A
- Circle colors: #AEE1CD @ 20%, 13%, 7% opacity

iPhone Yellow (#FFE681):
- Background: #FFFEF5
- Primary: #FFE681
- Secondary: #FFF0A3
- Accent: #FFB300
- Circle colors: #FFE681 @ 20%, 13%, 7% opacity

iPhone Pink (#FF6E5A):
- Background: #FFF5F3
- Primary: #FF6E5A
- Secondary: #FF8A7A
- Accent: #E91E63
- Circle colors: #FF6E5A @ 20%, 13%, 7% opacity

iPhone White (#F3F3F3):
- Background: #F3F3F3
- Primary: #333333 (dark gray for contrast)
- Secondary: #666666
- Accent: #007AFF (iOS blue)
- Circle colors: #333333 @ 13%, 7%, 3% opacity
```

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Text contrast on light backgrounds | All text uses dark colors (#1A1A1A) |
| Glass effects too dark on light bg | This is intentional - maintains visual consistency |
| Existing users lose their theme | Default to iPhone White (neutral choice) |
| Background circles overlap content | Positioned outside safe areas |

---

## Rollback Plan

If issues arise:
1. Revert `app_theme.dart` to restore original themes
2. Revert `theme_provider.dart` to original mappings
3. Revert other files to restore isDark conditionals
4. Run `git checkout -- lib/` to revert all changes
