import '../models/workout_record.dart';
import 'stats_calculator_service.dart';

/// 动作史检索单条结果：某次训练中的某个动作。
///
/// 回答"上次这个动作我练了多少"——按动作名跨训练回看原始记录。
class ExerciseHistoryEntry {
  final WorkoutRecord record;
  final RecordedExercise recordedExercise;

  /// 展示名（中文名优先，缺省回退英文名）
  final String exerciseName;

  /// 当次最佳组（按估算 1RM 最高者）；无有效组数据时为 null
  final double? bestWeight;
  final int? bestReps;
  final double? bestE1RM;

  const ExerciseHistoryEntry({
    required this.record,
    required this.recordedExercise,
    required this.exerciseName,
    this.bestWeight,
    this.bestReps,
    this.bestE1RM,
  });
}

/// 按动作名检索历史记录。
///
/// 大小写不敏感的包含匹配（中文名 + 英文名）；动作引用未加载的记录
/// 无法识别，跳过。结果按训练日期降序。查询为空时返回空列表。
/// 纯函数，无 IO。
List<ExerciseHistoryEntry> searchExerciseHistory(
  List<WorkoutRecord> records,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final results = <ExerciseHistoryEntry>[];
  for (final record in records) {
    for (final recordedExercise in record.exercises) {
      final exercise = recordedExercise.exercise;
      if (exercise == null) continue;

      final name = exercise.name.toLowerCase();
      final nameEn = exercise.nameEn.toLowerCase();
      if (!name.contains(q) && !nameEn.contains(q)) continue;

      // 当次最佳组：与 calculateEstimated1RMTrend 同语义（e1RM 最高）
      double? bestE1RM;
      double? bestWeight;
      int? bestReps;
      final sets = recordedExercise.setsData;
      if (sets != null) {
        for (final set in sets) {
          final weight = set.weight;
          final reps = set.reps;
          if (weight == null || weight <= 0) continue;
          if (reps == null || reps <= 0) continue;
          final e1RM = StatsCalculatorService.estimate1RM(weight, reps);
          if (bestE1RM == null || e1RM > bestE1RM) {
            bestE1RM = e1RM;
            bestWeight = weight;
            bestReps = reps;
          }
        }
      }

      results.add(ExerciseHistoryEntry(
        record: record,
        recordedExercise: recordedExercise,
        exerciseName: exercise.name.isNotEmpty ? exercise.name : exercise.nameEn,
        bestWeight: bestWeight,
        bestReps: bestReps,
        bestE1RM: bestE1RM,
      ));
    }
  }

  results.sort((a, b) => b.record.date.compareTo(a.record.date));
  return results;
}
