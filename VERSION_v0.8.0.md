# VERSION_v0.8.0

**Release Date**: 2026-02-14
**Commit**: 8bb9665
**Branch**: feature/digital-vitality-ui

---

## 🎨 New Features

### Theme System
- **3 Preset Themes**: Neon Tempus (dark tech), Arctic Flow (light clean), Electric Pulse (dark energy)
- **Theme Selection Screen**: Visual preview cards with color samples
- **Persistent Selection**: Theme saved to SharedPreferences
- **Dynamic Colors**: All screens automatically adapt to selected theme

### Interval Training Mode
- **Exercise Timer**: Forward counting timer (from 0)
- **Rest Timer**: Countdown timer with customizable duration
- **Auto-switch**: Automatically returns to exercise after rest
- **Status Display**: "正在进行第N组", "已完成N组，准备进行第N+1组"
- **Pause/Resume**: Full control during exercise
- **Save/Continue**: Save workout or continue after completion

### Duration Picker
- **Wheel Selector**: Cupertino-style picker
- **Minutes**: 0-5 minutes range
- **Seconds**: 00/10/20/30/40/50 (10-second intervals)
- **Minimum**: 10 seconds (validated)

### Statistics Page
- **Weekly/Monthly Toggle**: Tab-based switching
- **Summary Cards**: Total sets, total time, workout days
- **Trend Chart**: Bar chart showing daily/weekly trends
- **Personal Best**: Max sets, longest workout, longest streak

---

## 🔧 Improvements

### Gradle Configuration
- **AGP**: 8.5.2 → 8.6.0 (Flutter recommended)
- **Kotlin**: 2.0.21 → 2.1.0 (Flutter recommended)
- **Gradle**: 8.14 → 8.7 (stable)
- **China Mirrors**: Aliyun + Tencent cloud mirrors
- **Build Optimization**: Parallel build, caching enabled

### Code Quality
- **Provider Updates**: All screens use ThemeProvider
- **Test Fixes**: Widget tests updated for new providers
- **Integration Tests**: Updated for new app structure
- **LSP Clean**: Zero errors on all modified files

---

## 📁 Files Added

```
lib/theme/app_theme.dart              # Theme definitions (3 presets)
lib/theme/theme_provider.dart          # Theme state management
lib/bloc/training_provider.dart        # Training state machine
lib/screens/stats_screen.dart          # Statistics page
lib/screens/theme_selection_screen.dart # Theme picker
lib/widgets/duration_picker.dart       # Time wheel selector
lib/widgets/training_widget.dart       # Training UI
lib/utils/color_extension.dart         # Color helper extension
docs/plans/2026-02-13-feature-enhancement-design.md
```

## 📝 Files Modified

```
lib/main.dart              # Added ThemeProvider, TrainingProvider
lib/screens/timer_screen.dart   # Use TrainingWidget
lib/screens/settings_screen.dart # Theme selection entry
lib/screens/history_screen.dart  # Theme-aware styling
lib/widgets/timer_widget.dart    # Theme-aware styling
test/widget_test.dart       # Updated providers
integration_test/app_test.dart # Updated providers
android/settings.gradle.kts   # AGP 8.6.0, Kotlin 2.1.0
android/build.gradle.kts      # Mirror repositories
android/gradle.properties     # Build optimizations
android/gradle/wrapper/gradle-wrapper.properties # Gradle 8.7
```

---

## 📊 Stats

| Metric | Value |
|--------|-------|
| Files Changed | 26 |
| Lines Added | +3,302 |
| Lines Removed | -695 |
| New Files | 15 |
| Modified Files | 11 |

---

## 🔄 Rollback

```bash
git checkout v0.8.0
git reset --hard v0.8.0
```

---

## 📦 Release Assets

- **APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Size**: ~151 MB

---

## 🚀 Next Version Preview

Potential features for v0.9.0:
- Custom theme editor
- Sound effects for timer events
- Export workout data (CSV/JSON)
- Cloud sync for workout history
