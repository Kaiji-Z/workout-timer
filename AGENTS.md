# AGENTS.md - WorkoutTimer Flutter App

This file contains guidelines for agentic coding assistants working on the WorkoutTimer Flutter application. It provides build/test commands, code style guidelines, and project conventions to ensure consistent development.

## Project Overview

WorkoutTimer is a cross-platform Flutter app for workout rest timing. It features:
- Timer functionality with preset durations (30s, 60s, 90s, 120s)
- Multi-channel notifications (sound, vibration, screen popup)
- Basic workout data recording (sets, rest time)
- Settings and history screens
- Local SQLite storage with Provider state management

**Architecture**: MVVM pattern with Provider, services layer for business logic, and local database.

**Tech Stack**: Flutter/Dart, sqflite, provider, flutter_local_notifications, vibration, shared_preferences, intl.

## Build/Lint/Test Commands

### Flutter Commands
```bash
# Install dependencies (use domestic mirrors for faster download in China)
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get

# Run app on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build for iOS (requires macOS)
flutter build ios
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/widget_test.dart

# Run tests matching a pattern
flutter test --name="App loads"

# Run integration tests (if any)
flutter test integration_test/
```

### Analysis and Linting
```bash
# Static analysis (recommended before commits)
flutter analyze

# Format code
dart format lib/ test/

# Fix auto-fixable issues
dart fix --apply

# Check for outdated dependencies
flutter pub outdated
```

### Single Test Execution
To run a specific test method:
```bash
flutter test --name="exact test name"
```

Example:
```bash
flutter test --name="App loads and shows timer screen"
```

## Code Style Guidelines

### General Principles
- Follow Dart style guide: https://dart.dev/guides/language/effective-dart
- Use `flutter_lints` package for consistent linting
- Prefer functional programming where appropriate
- Keep methods small and focused (single responsibility)
- Use meaningful variable/function names
- Avoid magic numbers; use named constants

### Imports and File Organization
```dart
// Correct import order:
import 'dart:async';           // Dart SDK imports
import 'package:flutter/material.dart';  // Flutter SDK
import 'package:provider/provider.dart'; // Third-party packages
import '../models/workout_session.dart'; // Relative imports (prefer relative)
import 'database_helper.dart';          // Local imports
```

**Rules**:
- Use relative imports within the same package
- Group imports: Dart SDK, Flutter SDK, third-party, local
- Avoid wildcard imports (`import 'package:foo.dart' show Bar;`)
- No unused imports (dart fix will remove them)

### Naming Conventions
```dart
// Classes: PascalCase
class TimerProvider extends ChangeNotifier {}

// Methods/Functions: camelCase
void startTimer() {}
Future<void> saveSession() async {}

// Variables: camelCase
int remainingSeconds = 60;
final String customMessage;

// Constants: UPPER_SNAKE_CASE
const String TABLE_NAME = 'workout_sessions';

// Private members: prefix with underscore
int _counter = 0;
void _tick(Timer timer) {}

// Enums: PascalCase
enum TimerState { running, paused, stopped }
```

### Types and Null Safety
- Enable sound null safety (Dart 2.12+)
- Use `late` for lazy initialization when appropriate
- Prefer `final` for immutable variables
- Use nullable types explicitly: `String? name`
- Avoid `!` operator; use null checks instead

```dart
// Good
final String? message = prefs.getString('message');
if (message != null) {
  // Use message
}

// Avoid
final String message = prefs.getString('message')!;
```

### Async Programming
- Use `async`/`await` for readability
- Handle errors with try-catch in async methods
- Avoid `Future.delayed` for simple delays; use proper async patterns

```dart
// Good
Future<void> loadData() async {
  try {
    final data = await repository.getData();
    // Process data
  } catch (e) {
    print('Error loading data: $e');
    rethrow;
  }
}

// Avoid blocking UI with async operations in initState
@override
void initState() {
  super.initState();
  _loadData(); // Call async method
}

Future<void> _loadData() async { /* ... */ }
```

### Error Handling
- Use try-catch for expected errors (network, database)
- Log errors with meaningful messages
- Re-throw exceptions to let callers handle them
- Avoid empty catch blocks

```dart
// Good
try {
  await database.insert(session);
} catch (e) {
  print('Database error: $e');
  rethrow;
}

// Avoid
try {
  await riskyOperation();
} catch (e) {} // Silent failure
```

### Widget Patterns
- Use `const` constructors when possible
- Prefer StatelessWidget for simple widgets
- Use keys for dynamic lists: `Key(session.id)`
- Follow Material Design guidelines
- Use meaningful widget names

```dart
// Good
class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) => Column(/* ... */),
    );
  }
}
```

### State Management (Provider Pattern)
- Use ChangeNotifier for reactive state
- Notify listeners only when state changes
- Keep providers focused on specific domains
- Use context.read() for actions, context.watch() for reactive UI

```dart
class TimerProvider extends ChangeNotifier {
  void startTimer() {
    _isRunning = true;
    notifyListeners(); // Only call when state changes
  }
}

// In widgets
void _onPressed() {
  context.read<TimerProvider>().startTimer();
}

Text(timer.isRunning ? 'Running' : 'Stopped'); // Auto-updates via watch
```

### Database and Data Models
- Use immutable data models with copyWith
- Separate database logic into repository layer
- Use transactions for multi-step operations
- Validate data before saving

```dart
class WorkoutSession {
  final String id;
  final int totalSets;

  WorkoutSession copyWith({String? id, int? totalSets}) {
    return WorkoutSession(
      id: id ?? this.id,
      totalSets: totalSets ?? this.totalSets,
    );
  }
}
```

### Testing Guidelines
- Write tests for business logic and UI interactions
- Use descriptive test names
- Mock external dependencies
- Test error scenarios

```dart
testWidgets('Timer starts correctly', (tester) async {
  await tester.pumpWidget(/* app */);
  await tester.tap(find.text('Start'));
  await tester.pump();
  expect(find.text('Running'), findsOneWidget);
});
```

## Architecture Patterns

### File Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── workout_session.dart
├── screens/                  # UI screens/pages
│   ├── timer_screen.dart
│   ├── settings_screen.dart
│   └── history_screen.dart
├── widgets/                  # Reusable UI components
│   └── timer_widget.dart
├── bloc/                     # State management (Providers)
│   └── timer_provider.dart
├── services/                 # Business logic & external services
│   ├── notification_service.dart
│   ├── workout_repository.dart
│   └── database_helper.dart
└── utils/                    # Utilities (if needed)
```

### Dependency Injection
- Use Provider for dependency injection
- Inject services at app level
- Avoid singleton patterns; use Provider scope

### Navigation
- Use named routes for consistency
- Pass minimal data through routes
- Handle back navigation properly

```dart
// In main.dart
routes: {
  '/settings': (context) => const SettingsScreen(),
}

// Navigation
Navigator.pushNamed(context, '/settings');
```

## Specific Rules for This Project

### Notification Handling
- Always request permissions on first app launch
- Check vibration capability before vibrating
- Use shared_preferences for user notification preferences
- Handle notification failures gracefully

### Database Operations
- Use transactions for complex operations
- Close database connections properly
- Migrate schema versions carefully
- Limit history records to prevent bloat (max 1000)

### Timer Logic
- Use Timer.periodic for countdown
- Cancel timers in dispose()
- Handle app background/foreground transitions
- Save state on interruption

### UI/UX Considerations
- Support both portrait and landscape
- Use Material 3 design system
- Provide visual feedback for all actions
- Handle loading states appropriately

### Security
- Store sensitive data securely (use encrypted storage if needed)
- Validate user inputs
- Avoid logging sensitive information

## Commit Guidelines
- Use conventional commits: `feat: add timer presets`
- Write clear commit messages
- Commit related changes together
- Run tests and analysis before committing

## CI/CD Integration
- Use GitHub Actions for automated testing
- Run flutter analyze and flutter test on PRs
- Build APKs for releases
- Monitor code coverage

## Performance Tips
- Use const widgets when possible
- Optimize list views with keys
- Minimize rebuilds with proper Provider usage
- Profile with Flutter DevTools

This document should be updated as the project evolves. Always refer to the current design document in `docs/plans/` for feature-specific guidelines.