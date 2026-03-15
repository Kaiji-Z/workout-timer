import 'dart:convert';

/// Represents a single set in a workout exercise.
/// 
/// Tracks the set number, reps completed, and weight used.
/// Supports serialization for database storage.
class SetData {
  final int setNumber;
  final int? reps;
  final double? weight;

  const SetData({
    required this.setNumber,
    this.reps,
    this.weight,
  });

  /// Converts the set data to a map for database storage.
  Map<String, dynamic> toMap() => {
        'set_number': setNumber,
        'reps': reps,
        'weight': weight,
      };

  /// Creates a SetData from a map (database row).
  factory SetData.fromMap(Map<String, dynamic> map) => SetData(
        setNumber: map['set_number'] as int? ?? 1,
        reps: map['reps'] as int?,
        weight: (map['weight'] as num?)?.toDouble(),
      );

  /// Converts the set data to a JSON string.
  String toJson() => jsonEncode(toMap());

  /// Creates a SetData from a JSON string.
  factory SetData.fromJson(String jsonString) =>
      SetData.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);

  /// Returns a user-friendly display string for the set.
  /// 
  /// Examples:
  /// - Both null: "Set 3"
  /// - Only reps: "12 reps"
  /// - Only weight: "45.0kg"
  /// - Both: "12 × 45.0kg"
  String get displayText {
    if (reps == null && weight == null) return 'Set $setNumber';
    if (weight == null) return '$reps reps';
    if (reps == null) return '${weight!.toStringAsFixed(1)}kg';
    return '$reps × ${weight!.toStringAsFixed(1)}kg';
  }

  /// Calculates the volume (reps × weight) for this set.
  /// Returns 0 if either reps or weight is null.
  double get volume => (reps ?? 0) * (weight ?? 0);

  /// Creates a copy of this SetData with optionally overridden fields.
  SetData copyWith({
    int? setNumber,
    int? reps,
    double? weight,
  }) =>
      SetData(
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
      );

  @override
  String toString() => 'SetData(setNumber: $setNumber, reps: $reps, weight: $weight)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetData &&
          setNumber == other.setNumber &&
          reps == other.reps &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(setNumber, reps, weight);
}
