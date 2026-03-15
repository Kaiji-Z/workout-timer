# WorkoutTimer UI Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 4 UI issues in the Flutter WorkoutTimer app: calendar replacement, timer title accent bar removal, plan screen header conversion, and bottom navigation redesign.

**Architecture:** Maintain consistency with existing Flat Vitality design system, use Provider state management, ensure responsive layouts across all screen sizes.

**Tech Stack:** Flutter 3.10+, Dart 3.10.7, Provider, Material Design 3, SQLite

---

## Issue 1: Plan Screen Calendar - Show Full Month but More Compact

### Task 1: Replace CompactCalendar with CalendarWidget

**Files:**
- Modify: `lib/screens/plan_screen.dart:47`

**Step 1: Replace the CompactCalendar widget with CalendarWidget**
```dart
// Current code at line 47
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: CompactCalendar(
    selectedDate: _selectedDate,
    onDateSelected: (date) {
      setState(() {
        _selectedDate = date;
      });
    },
  ),
),

// Replace with
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: CalendarWidget(
    selectedDate: _selectedDate,
    onDateSelected: (date) {
      setState(() {
        _selectedDate = date;
      });
    },
  ),
),
```

**Step 2: Verify the change works**
- Run: `flutter run -d chrome`
- Expected: Full month calendar displayed with reduced spacing

---

## Issue 2: Timer Title - Remove Accent Bar, Keep Centered

### Task 2: Remove accent bar from timer title

**Files:**
- Modify: `lib/widgets/training_widget.dart:129-140`

**Step 1: Remove the accent bar Container widget**
```dart
// Current code at lines 129-140
Expanded(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 4,
        height: 20,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: theme.timerGradientColors),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Text(
        'WORKOUT TIMER',
        style: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: theme.textColor,
        ),
      ),
    ],
  ),
),

// Replace with
Expanded(
  child: Text(
    'WORKOUT TIMER',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: '.SF Pro Display',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: theme.textColor,
    ),
  ),
),
```

**Step 2: Verify the change works**
- Run: `flutter run -d chrome`
- Expected: Title centered without accent bar

---

## Issue 3: Plan Screen Header Alignment - Mismatch with History/Stats/Settings

### Task 3: Convert Plan screen to use AppBar like other pages

**Files:**
- Modify: `lib/screens/plan_screen.dart:42, 69-135`

**Step 1: Remove the custom _buildHeader method and replace with AppBar**
```dart
// Remove the _buildHeader method (lines 69-135)
// Remove the call to _buildHeader at line 42

// Replace the Scaffold body with AppBar
return Scaffold(
  backgroundColor: Colors.transparent,
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 4,
          height: 20,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: theme.timerGradientColors),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'WORKOUT PLANS',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.textColor,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AIPlanWizardScreen(),
            ),
          );
          if (result == true && mounted) {
            context.read<PlanProvider>().loadPlans();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 18,
              color: theme.accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              'AI训练计划',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  body: SafeArea(
    bottom: false,
    child: Column(
      children: [
        // Calendar widget (already exists)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CalendarWidget(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Plan list (already exists)
        SizedBox(
          height: 200,
          child: _buildPlanList(planProvider, theme),
        ),
      ],
    ),
  ),
);
```

**Step 2: Verify the change works**
- Run: `flutter run -d chrome`
- Expected: Plan screen now uses AppBar like other pages with consistent header styling

---

## Issue 4: Bottom Navigation Redesign - Match Reference Design

### Task 4: Redesign bottom navigation to match reference design

**Files:**
- Modify: `lib/main.dart:235-302`

**Step 1: Remove text labels from navigation items**
```dart
// Current code at lines 235-302
 Expanded(
  child: GestureDetector(
    onTap: () => setState(() => _currentIndex = index),
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    ),
  ),
),

// Replace with
 Expanded(
  child: GestureDetector(
    onTap: () => setState(() => _currentIndex = index),
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? activeColor : inactiveColor,
        size: 24,
      ),
    ),
  ),
),
```

**Step 2: Adjust the center timer button styling**
```dart
// Current code at lines 304-340
Widget _buildCenterTimerButton(AppThemeData appTheme) {
  final activeColor = appTheme.accentColor;

  return GestureDetector(
    onTap: () => setState(() => _currentIndex = 2),
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            activeColor,
            activeColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.timer,
          color: Colors.white,
          size: 32,
        ),
      ),
    ),
  );
}

// Keep as is, but ensure it's prominent
```

**Step 3: Verify the change works**
- Run: `flutter run -d chrome`
- Expected: Bottom navigation shows only icons, no text labels, with simple selected state

---

## Testing and Verification

**Run all tests:**
```bash
flutter test
```

**Expected results:**
- All tests should pass
- UI changes should be visible and functional
- No layout breaks or styling inconsistencies

**Manual testing:**
- Navigate through all screens
- Verify calendar displays correctly
- Check timer title styling
- Confirm AppBar consistency across screens
- Test bottom navigation functionality

---

## Commit Strategy

**Commit each change separately:**
```bash
git add lib/screens/plan_screen.dart
git commit -m "feat: replace compact calendar with full month calendar"

git add lib/widgets/training_widget.dart
git commit -m "feat: remove accent bar from timer title"

git add lib/screens/plan_screen.dart
git commit -m "feat: convert plan screen to use AppBar"

git add lib/main.dart
git commit -m "feat: redesign bottom navigation with icons only"
```

**Push changes:**
```bash
git push origin master
```