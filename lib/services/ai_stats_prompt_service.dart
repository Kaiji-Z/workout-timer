import 'package:intl/intl.dart';
import '../models/muscle_group.dart';

/// Service for generating AI prompts from workout statistics
class AIStatsPromptService {
  /// Generate a statistics export prompt for AI analysis
  String generateStatsPrompt({
    required String periodType, // 'week' or 'month'
    required DateTime startDate,
    required DateTime endDate,
    required List<dynamic> records,
    required String goal,
    required List<String> focusMuscles,
  }) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final periodLabel = periodType == 'week' ? '本周' : '本月';
    
    // Calculate basic stats
    final sessionCount = records.length;
    final uniqueDays = <String>{};
    int totalSets = 0;
    int totalDuration = 0;
    final muscleFrequency = <PrimaryMuscleGroup, int>{};
    
    for (final record in records) {
      // Get date
      DateTime date;
      if (record.createdAt != null) {
        date = DateTime.parse(record.createdAt);
      } else if (record.date != null) {
        date = record.date;
      } else {
        continue;
      }
      uniqueDays.add('${date.year}-${date.month}-${date.day}');
      
      // Get sets
      if (record.totalSets != null) {
        totalSets += record.totalSets as int;
      }
      
      // Get duration
      if (record.totalRestTimeMs != null) {
        totalDuration += (record.totalRestTimeMs as int) ~/ 1000;
      } else if (record.durationSeconds != null) {
        totalDuration += record.durationSeconds as int;
      }
      
      // Get muscle frequency
      if (record.trainedMuscles != null) {
        for (final muscle in record.trainedMuscles) {
          muscleFrequency[muscle] = (muscleFrequency[muscle] ?? 0) + 1;
        }
      }
    }
    
    final workoutDays = uniqueDays.length;
    final totalMinutes = totalDuration ~/ 60;
    
    // Format goal
    final goalLabel = _formatGoal(goal);
    
    // Format focus muscles
    final focusLabel = focusMuscles.isEmpty ? '无特定重点' : focusMuscles.map(_formatMuscle).join('、');
    
    // Build muscle distribution table
    final muscleRows = StringBuffer();
    if (muscleFrequency.isNotEmpty) {
      final sortedMuscles = muscleFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedMuscles) {
        muscleRows.writeln('| ${entry.key.displayName} | ${entry.value} | ${entry.value} |');
      }
    } else {
      muscleRows.writeln('| 暂无数据 | - | - |');
    }
    
    return '''## 训练数据统计

### 训练周期
- 类型: $periodLabel
- 日期范围: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}

### 基础统计
- 训练次数: $sessionCount 次
- 训练天数: $workoutDays 天
- 总组数: $totalSets 组
- 总时长: $totalMinutes 分钟

### 各部位训练分布
| 部位 | 训练次数 | 组数 |
|------|---------|------|
$muscleRows
### 用户目标
- 主要目标: $goalLabel
- 重点加强: $focusLabel

## 输出格式

Output ONLY valid JSON:
{
  "name": "Plan Name",
  "days": [
    {
      "dayOfWeek": 1,
      "targetMuscles": ["chest"],
      "exercises": [
        {"exerciseName": "Barbell Bench Press", "targetSets": 4}
      ]
    }
  ]
}

## 规则

1. `dayOfWeek`: 1=周一 ... 7=周日
2. `targetMuscles`: chest, back, shoulders, arms, legs, core
3. `targetSets`: 3-5 per exercise
4. 根据用户的训练数据和目标，生成个性化的训练计划
5. 对于训练不足的部位（$focusLabel），增加训练频率
6. 保持合理的训练与休息平衡

请根据以上训练数据生成训练计划。JSON only:''';
  }
  
  /// Format goal string for display
  String _formatGoal(String goal) {
    switch (goal) {
      case 'muscle_building':
        return '增肌';
      case 'fat_loss':
        return '减脂';
      case 'strength':
        return '力量';
      case 'endurance':
        return '耐力';
      default:
        return goal;
    }
  }
  
  /// Format muscle group for display
  String _formatMuscle(String muscle) {
    const muscleMap = {
      'chest': '胸部',
      'back': '背部',
      'shoulders': '肩部',
      'arms': '手臂',
      'legs': '腿部',
      'core': '核心',
    };
    return muscleMap[muscle] ?? muscle;
  }
}
