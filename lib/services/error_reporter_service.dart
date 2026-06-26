import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../l10n/app_localizations.dart';

/// Severity of a reported failure, controlling how it surfaces to the user.
enum ErrorSeverity {
  /// Logged via [debugPrint] only — invisible to the user.
  ///
  /// Use for non-critical failures the UI already handles (e.g. a Provider
  /// exposes an `error` field the screen renders), or for best-effort side
  /// effects like firing a notification.
  devOnly,

  /// Logged AND shown to the user as a transient [SnackBar].
  ///
  /// Use for failures that may lose user data (saving a workout, importing a
  /// plan) so the user knows something went wrong and can retry.
  userWarning,
}

/// Centralized error reporting so data-loss failures are no longer silent.
///
/// Before this, every catch block only called `debugPrint`, leaving the user
/// with no feedback when, e.g., a completed workout failed to save. Now those
/// critical paths call [report] with [ErrorSeverity.userWarning], which also
/// surfaces a SnackBar via the global [scaffoldMessengerKey] wired in `main`.
///
/// Non-critical failures continue to use [ErrorSeverity.devOnly].
class ErrorReporter {
  ErrorReporter();

  /// Global key attached to [MaterialApp.scaffoldMessengerKey]. Set from
  /// `main()` so [report] can show SnackBars without a BuildContext.
  GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Resolve the current [AppLocalizations] for service-layer use (no
  /// BuildContext available). Falls back to Chinese if not registered yet.
  AppLocalizations _currentLocalizations() {
    try {
      final locale = ServiceLocator.get<ValueNotifier<Locale>>().value;
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('zh'));
    }
  }

  /// Report [error] at the given [severity].
  ///
  /// Always logs via [debugPrint] (preserving prior behavior). For
  /// [ErrorSeverity.userWarning], also shows a SnackBar if a
  /// [scaffoldMessengerKey] is attached and has a current state.
  ///
  /// Pass [stackTrace] when available so the log is diagnosable.
  void report(
    Object error, {
    ErrorSeverity severity = ErrorSeverity.devOnly,
    StackTrace? stackTrace,
    String? message,
  }) {
    final label = severity == ErrorSeverity.userWarning ? 'WARNING' : 'ERROR';
    debugPrint('[$label] $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }

    if (severity == ErrorSeverity.userWarning) {
      final msg = message ?? _currentLocalizations().errorGeneric;
      _showSnackBar(msg);
    }
  }

  void _showSnackBar(String message) {
    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) {
      // No UI available (e.g. during startup or in tests) — log and bail.
      debugPrint(
        'ErrorReporter: no ScaffoldMessenger available to show: $message',
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
