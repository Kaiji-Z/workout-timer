class WorkoutSession {
  final String id;
  final int totalSets;
  final int totalRestTimeMs;
  final String createdAt;

  WorkoutSession({
    required this.id,
    required this.totalSets,
    required this.totalRestTimeMs,
    required this.createdAt,
  });

  // From map (for database)
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      totalSets: map['sets'],
      totalRestTimeMs: map['rest_time_ms'],
      createdAt: map['created_at'],
    );
  }

  // To map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sets': totalSets,
      'rest_time_ms': totalRestTimeMs,
      'created_at': createdAt,
    };
  }

  // Copy with
  WorkoutSession copyWith({
    String? id,
    int? totalSets,
    int? totalRestTimeMs,
    String? createdAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      totalSets: totalSets ?? this.totalSets,
      totalRestTimeMs: totalRestTimeMs ?? this.totalRestTimeMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}