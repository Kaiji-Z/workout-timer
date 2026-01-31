# PROJECT_UPDATE_LOG.md - WorkoutTimer Flutter App

**Last Updated**: 2026-01-31
**Current Branch**: feature/digital-vitality-ui
**Latest Commit**: a1ffdc7

---

## Version Summary (v0.5.0) - Background Timer Fix

### What Was Done

**Fixed: Background timer stops after ~10 seconds on some phones**

**Root Cause**: Android background restrictions (省电策略) kill background processes
- Xiaomi MIUI, Huawei, OPPO, Vivo have aggressive battery optimization
- App gets killed when screen off or app in background

**Solution**: Added Foreground Service
- Timer runs as a foreground service with persistent notification
- System won't kill foreground services as aggressively
- Shows real-time countdown in notification

### Changes Summary

| File | Change |
|------|--------|
| `android/app/src/main/AndroidManifest.xml` | Added FOREGROUND_SERVICE, BOOT_COMPLETED permissions |
| `android/app/.../TimerService.kt` | Created foreground service with notification |
| `android/app/.../MainActivity.kt` | Added MethodChannel to control service |
| `lib/services/timer_service.dart` | Flutter-Kotlin bridge |
| `lib/bloc/timer_provider.dart` | Start/stop service with timer |

---

## Previous Versions

### v0.4.0 - Notification Fix
**Commit**: 1d8fa8d

**Changes**:
- Added notification channel for sound/vibration
- Fixed vibrationPattern for native notification vibration
- Tested on device successfully

### v0.3.0 - Post-Dependency Cleanup
**Commit**: 8d2c0ee

**Changes**:
- Removed `vibration` package
- Added `android.enableSymlinks=true`
- Created `build.gradle.kts`

### v0.2.0 - Cyberpunk UI
**Commit**: e674919

**Features**:
- Complete cyberpunk UI with neon glow
- Custom circular progress ring
- 4 control buttons, preset selection
- Orbitron and Rajdhani fonts

### v0.1.0 - Initial Setup
**Commit**: c2c27e0

**Features**:
- Initial project structure
- MVVM architecture
- Timer, history, settings screens

---

## Current Status (v0.5.0)

### ✅ Working Features
- [x] Timer countdown with circular progress
- [x] Preset selection (30s/60s/90s/120s)
- [x] 4 control buttons
- [x] Completed sets counter
- [x] Neon glow UI
- [x] Dark theme
- [x] Notifications with sound/vibration
- [x] Background timer (foreground service)
- [x] Settings (sound/vibration toggles)
- [x] Android APK builds

### ⏳ Pending Tasks
- [ ] Database persistence (sqflite)
- [ ] History screen data integration
- [ ] Settings persistence
- [ ] IDE LSP issues

---

## Build Commands

```bash
# Run on Android
flutter run -d V2068A

# Build debug APK
flutter build apk --debug

#回滚到当前版本
git reset --hard a1ffdc7
```

---

## Architecture

```
lib/
├── bloc/timer_provider.dart       # Timer logic + service control
├── services/
│   ├── notification_service.dart  # Push notifications
│   └── timer_service.dart         # Foreground service bridge
└── ...
android/app/.../TimerService.kt    # Foreground service
```

---

## Environment

- **Platform**: Windows 11
- **Target**: Android (V2068A), Web (Chrome)
