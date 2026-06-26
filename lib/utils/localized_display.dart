import 'package:flutter/widgets.dart';

import '../models/exercise.dart';
import '../models/muscle_group.dart';

/// Locale-aware display-name helpers for data-layer models.
///
/// The models store language-neutral data (enum values, the original English
/// exercise name from free-exercise-db). The UI layer calls these helpers to
/// pick the right display string for the active locale. No DB schema change —
/// [Exercise.nameEn] and the muscle-group `nameEn` getters already exist.
class LocalizedDisplay {
  LocalizedDisplay._();

  /// Whether the active locale should show English.
  static bool _isEn(Locale locale) => locale.languageCode == 'en';

  /// Primary muscle group display name.
  static String primaryMuscle(PrimaryMuscleGroup m, Locale locale) =>
      _isEn(locale) ? m.nameEn : m.displayName;

  /// Secondary muscle group display name.
  static String secondaryMuscle(SecondaryMuscleGroup m, Locale locale) =>
      _isEn(locale) ? m.nameEn : m.displayName;

  /// Exercise display name. English locale prefers [Exercise.nameEn]; falls
  /// back to [Exercise.name] when the English name is unavailable.
  static String exerciseName(Exercise e, Locale locale) {
    if (_isEn(locale) && e.nameEn.isNotEmpty) return e.nameEn;
    return e.name;
  }
}
