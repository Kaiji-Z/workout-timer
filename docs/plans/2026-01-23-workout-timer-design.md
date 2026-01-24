# Workout Timer App Design - 2026-01-23

## Overview
A cross-platform fitness timer app built with Flutter, targeting Android and iOS. Core functionality: timer for rest periods between workout sets, with preset time options, multi-channel notifications (sound + vibration + screen), and basic data recording (sets count, total rest time).

## Section 1: Overall Architecture and Tech Stack
Application uses Flutter for cross-platform development with Dart language, ensuring performance and modernity. Core architecture based on MVVM pattern:
- **Model**: Data layer, using SQLite via sqflite plugin for basic workout records
- **View**: UI layer, using Flutter Widgets for responsive interface with Material Design 3 style
- **ViewModel/BLoC**: Business logic layer, managing timer state and data operations

Tech Stack:
- Dart 3.0+: Modern syntax and async support
- Flutter 3.10+: Declarative UI, simplified layouts
- sqflite: Lightweight local database
- flutter_local_notifications: Notification handling
- permission_handler: Permission management
- Package name: com.workouttimer.simple, Target API 24+ (Android 7.0), supports landscape and dark mode.

## Section 2: UI Components and Screens
Adopts Flutter's Material Design with fitness-themed green color scheme (#4CAF50), supports auto dark mode.

Core Screens:
- **Main Timer Screen**: Full-screen layout with large countdown number (72pt font), circular progress bar showing remaining time percentage. Center play/pause/reset buttons (FAB style), bottom grid of preset time buttons (30s, 60s, 90s, 120s). Top-right menu for settings.
- **Settings Screen**: Notification options (sound on/off, vibration on/off, custom reminder message input), theme toggle (light/dark/system), data management (clear history).
- **History Screen**: List showing sets count, total rest time, and date for each workout. Supports swipe-to-delete individual records.

Key Components:
- TimerWidget: Custom countdown component using AnimationController for smooth animations
- NotificationCard: Notification preview component simulating end popup
- HistoryList: Scrollable list using ListView.builder for performance

UI design focuses on simplicity: Large readable fonts, intuitive buttons, no complex navigation. Auto-adapts to landscape (timer centered, buttons horizontal).

## Section 3: Data Flow and Storage
Uses unidirectional data flow pattern for predictable state:
- **User Action** → **BLoC** → **Repository** → **Local Database**
- **Database Change** → **Repository** → **BLoC** → **UI Update**

Data Models:
- WorkoutSession: Contains sessionId (UUID), totalSets (int), totalRestTime (Duration), date (DateTime)
- Automatically increments totalSets and accumulates totalRestTime when timer ends

Storage Implementation:
- SQLite database via sqflite
- Table: workout_sessions (id TEXT PRIMARY KEY, sets INTEGER, rest_time_ms INTEGER, created_at TEXT)
- Repository class encapsulates CRUD operations with async methods: saveSession(), getAllSessions(), deleteSession()
- Persistence: Auto-save current session on app close, restore unfinished timer on launch

Performance:
- History pagination (20 items per load) to avoid large list lag
- Data validation: Time not negative, sets count <=999
- Backup: Optional JSON export via share_plus plugin

## Section 4: Notification System
Uses flutter_local_notifications plugin for multi-channel alerts:
- **Sound Notification**: Play default system sound or custom audio (optional user choice)
- **Vibration Notification**: Trigger device vibration (500ms default) via Vibration plugin
- **Screen Notification**: Show local notification popup with title "Rest Over!" and custom message (e.g., "Start next set!"), tap to return to app

Implementation:
- Schedule background task on timer start (flutter_background_service or WorkManager)
- Trigger NotificationService.showNotification() on timer end
- Permissions: Request POST_NOTIFICATIONS (Android 13+), handle denial gracefully
- Custom messages: Stored in SharedPreferences, default "Ready for next set!"

UX Optimization:
- Do Not Disturb: When app in foreground, vibrate only without popup
- Emergency Stop: Notification shows "Skip" button to stop timer immediately
- Volume Control: Respects system volume settings

## Section 5: Error Handling and Edge Cases
Robust error handling for common exceptions:
- **Timer Interruption**: Save current state in SharedPreferences when app killed/restarted, prompt "Continue last timer?" on restore
- **Battery Optimization**: Detect low battery (<15%), show warning and suggest charging; use ignore_battery_optimizations permission
- **Permission Issues**: Guide to settings if notification/vibration denied; fallback to sound-only
- **Invalid Input**: Preset buttons limited to 10-300 seconds, prevent negative/overlong waits
- **Device Rotation**: Use OrientationBuilder for auto layout adjustment
- **Memory Management**: Timer uses Timer.periodic to avoid leaks; auto-clean history over 1000 records
- **Offline-First**: Pure local app, no network needed (reserved for future cloud sync)

User Feedback: Friendly Toast messages for errors, e.g., "Permission denied, please enable in settings", no app crashes.

## Section 6: Testing Strategy
Follows TDD principles for quality assurance:
- **Unit Tests**: flutter_test for business logic (TimerLogic, Repository methods). Coverage target 80%+.
- **Widget Tests**: flutter_test for UI component behavior (button clicks, progress animations).
- **Integration Tests**: flutter_driver for full flows (start timer → wait → check notifications/data).
- **Manual Tests**: Verify on multiple devices (Pixel, iPhone) for notifications, vibration, dark mode; test edge cases like low battery, permission denial.
- **CI/CD**: GitHub Actions for automated tests and reports; code quality via flutter analyze.

Test Data: Mock data for database and notifications to avoid external dependencies.

## Summary
This WorkoutTimer app is a simple, effective fitness tool with cross-platform Flutter development. Core features include preset rest timing, comprehensive notifications, and basic workout tracking. Architecture is clean, UI intuitive, data reliable, error-tolerant, and well-tested for future feature expansions.