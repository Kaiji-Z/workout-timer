import 'package:intl/intl.dart';

/// 日历计划关联
class CalendarPlan {
  final String id;
  final DateTime date;
  final String planId;
  final DateTime createdAt;

  const CalendarPlan({
    required this.id,
    required this.date,
    required this.planId,
    required this.createdAt,
  });

  /// 获取日期键（格式：yyyy-MM-dd）
  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  /// 获取格式化的日期文本
  String get dateText => DateFormat('yyyy年MM月dd日').format(date);

  /// 从JSON解析
  factory CalendarPlan.fromJson(Map<String, dynamic> json) {
    return CalendarPlan(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      planId: json['planId'] as String? ?? json['plan_id'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'planId': planId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 从数据库Map解析
  factory CalendarPlan.fromMap(Map<String, dynamic> map) {
    return CalendarPlan(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      planId: map['plan_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'plan_id': planId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  CalendarPlan copyWith({
    String? id,
    DateTime? date,
    String? planId,
    DateTime? createdAt,
  }) {
    return CalendarPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      planId: planId ?? this.planId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CalendarPlan(id: $id, date: $dateKey, planId: $planId)';
}
