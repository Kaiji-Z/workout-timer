/// 用户配置文件
class UserProfile {
  final String goal; // muscle_building, fat_loss, strength, endurance
  final int weeklyFrequency; // 2-3, 4-5, 6+
  final int sessionDuration; // 30, 45, 60, 90
  final String experience; // beginner, intermediate, advanced
  final String equipment; // gym, home_dumbbell, bodyweight
  final List<String> focusAreas; // chest, back, shoulders, arms, legs, core
  final DateTime startDate;

  const UserProfile({
    required this.goal,
    required this.weeklyFrequency,
    required this.sessionDuration,
    required this.experience,
    required this.equipment,
    this.focusAreas = const [],
    required this.startDate,
  });

  /// 从数据库Map解析
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      goal: map['goal'] as String? ?? '',
      weeklyFrequency: map['weekly_frequency'] as int? ?? 3,
      sessionDuration: map['session_duration'] as int? ?? 45,
      experience: map['experience'] as String? ?? 'beginner',
      equipment: map['equipment'] as String? ?? 'bodyweight',
      focusAreas: map['focus_areas'] != null
          ? (map['focus_areas'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'goal': goal,
      'weekly_frequency': weeklyFrequency,
      'session_duration': sessionDuration,
      'experience': experience,
      'equipment': equipment,
      'focus_areas': focusAreas.join(','),
      'start_date': startDate.toIso8601String(),
    };
  }

  /// 复制并修改
  UserProfile copyWith({
    String? goal,
    int? weeklyFrequency,
    int? sessionDuration,
    String? experience,
    String? equipment,
    List<String>? focusAreas,
    DateTime? startDate,
  }) {
    return UserProfile(
      goal: goal ?? this.goal,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      experience: experience ?? this.experience,
      equipment: equipment ?? this.equipment,
      focusAreas: focusAreas ?? this.focusAreas,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.goal == goal &&
        other.weeklyFrequency == weeklyFrequency &&
        other.sessionDuration == sessionDuration &&
        other.experience == experience &&
        other.equipment == equipment &&
        _listEquals(other.focusAreas, focusAreas) &&
        other.startDate == startDate;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        goal,
        weeklyFrequency,
        sessionDuration,
        experience,
        equipment,
        Object.hashAll(focusAreas),
        startDate,
      );

  @override
  String toString() =>
      'UserProfile(goal: $goal, weeklyFrequency: $weeklyFrequency, sessionDuration: $sessionDuration, experience: $experience, equipment: $equipment, focusAreas: $focusAreas, startDate: $startDate)';
}
