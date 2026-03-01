import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/workout_repository.dart';
import '../bloc/record_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutRepository _repository = WorkoutRepository();
  List<WorkoutSession> _oldSessions = [];
  List<WorkoutRecord> _newRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;
      final records = context.read<RecordProvider>().records;
      setState(() {
        _oldSessions = sessions;
        _newRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 获取所有记录（合并旧记录和新记录）
  List<dynamic> _getAllRecords() {
    return [..._oldSessions, ..._newRecords];
  }

  /// 按周筛选
  List<dynamic> _filterByWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return _getAllRecords().where((record) {
      DateTime date;
      if (record is WorkoutSession) {
        date = DateTime.parse(record.createdAt);
      } else if (record is WorkoutRecord) {
        date = record.date;
      } else {
        return false;
      }
      return date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek);
    }).toList();
  }

  /// 按月筛选
  List<dynamic> _filterByMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return _getAllRecords().where((record) {
      DateTime date;
      if (record is WorkoutSession) {
        date = DateTime.parse(record.createdAt);
      } else if (record is WorkoutRecord) {
        date = record.date;
      } else {
        return false;
      }
      return date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart);
    }).toList();
  }

  /// 获取记录日期
  DateTime _getRecordDate(dynamic record) {
    if (record is WorkoutSession) {
      return DateTime.parse(record.createdAt);
    } else if (record is WorkoutRecord) {
      return record.date;
    }
    return DateTime.now();
  }

  /// 获取记录组数
  int _getRecordSets(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalSets;
    } else if (record is WorkoutRecord) {
      return record.totalSets;
    }
    return 0;
  }

  /// 获取记录时长（秒）
  int _getRecordDuration(dynamic record) {
    if (record is WorkoutSession) {
      return record.totalRestTimeMs ~/ 1000;
    } else if (record is WorkoutRecord) {
      return record.durationSeconds;
    }
    return 0;
  }

  /// 计算训练频率统计
  Map<String, dynamic> _calculateFrequencyStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'sessionCount': 0,
        'workoutDays': 0,
        'avgSessionsPerWeek': 0.0,
        'muscleFrequency': <PrimaryMuscleGroup, int>{},
      };
    }

    final uniqueDays = <String>{};
    final muscleFrequency = <PrimaryMuscleGroup, int>{};

    for (final record in records) {
      final date = _getRecordDate(record);
      uniqueDays.add('${date.year}-${date.month}-${date.day}');
      
      if (record is WorkoutRecord && record.trainedMuscles.isNotEmpty) {
        for (final muscle in record.trainedMuscles) {
          muscleFrequency[muscle] = (muscleFrequency[muscle] ?? 0) + 1;
        }
      }
    }

    return {
      'sessionCount': records.length,
      'workoutDays': uniqueDays.length,
      'avgSessionsPerWeek': records.length / (uniqueDays.length > 0 ? uniqueDays.length / 7 : 1),
      'muscleFrequency': muscleFrequency,
    };
  }

  /// 计算训练量统计
  Map<String, dynamic> _calculateVolumeStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'totalSets': 0,
        'totalDuration': 0,
        'avgSetsPerSession': 0.0,
        'avgDurationPerSession': 0,
      };
    }

    int totalSets = 0;
    int totalDuration = 0;

    for (final record in records) {
      totalSets += _getRecordSets(record);
      totalDuration += _getRecordDuration(record);
    }

    return {
      'totalSets': totalSets,
      'totalDuration': totalDuration,
      'avgSetsPerSession': totalSets / records.length,
      'avgDurationPerSession': totalDuration ~/ records.length,
    };
  }

  /// 计算渐进超负荷指标
  Map<String, dynamic> _calculateProgressionStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'weeklyTrend': <String, int>{},
        'isImproving': false,
        'improvementPercent': 0.0,
      };
    }

    // 按周分组
    final weeklyData = <int, int>{};
    for (final record in records) {
      final date = _getRecordDate(record);
      final weekNumber = _getWeekNumber(date);
      weeklyData[weekNumber] = (weeklyData[weekNumber] ?? 0) + _getRecordSets(record);
    }

    // 计算趋势
    final sortedWeeks = weeklyData.keys.toList()..sort();
    final weeklyTrend = <String, int>{};
    for (final week in sortedWeeks.take(8)) {
      weeklyTrend['W$week'] = weeklyData[week] ?? 0;
    }

    // 判断是否在进步
    bool isImproving = false;
    double improvementPercent = 0.0;
    if (sortedWeeks.length >= 2) {
      final recentWeek = weeklyData[sortedWeeks.last] ?? 0;
      final previousWeek = weeklyData[sortedWeeks[sortedWeeks.length - 2]] ?? 0;
      if (previousWeek > 0) {
        improvementPercent = ((recentWeek - previousWeek) / previousWeek * 100);
        isImproving = recentWeek > previousWeek;
      }
    }

    return {
      'weeklyTrend': weeklyTrend,
      'isImproving': isImproving,
      'improvementPercent': improvementPercent,
    };
  }

  /// 计算恢复指标
  Map<String, dynamic> _calculateRecoveryStats(List<dynamic> records) {
    if (records.isEmpty) {
      return {
        'muscleRestDays': <PrimaryMuscleGroup, int>{},
        'avgRestDays': 0,
        'overtrainedMuscles': <PrimaryMuscleGroup>[],
      };
    }

    // 按部位记录最后训练日期
    final muscleLastTrained = <PrimaryMuscleGroup, DateTime>{};
    final muscleRestDays = <PrimaryMuscleGroup, int>{};
    final now = DateTime.now();

    // 从新记录中获取部位信息
    for (final record in records) {
      if (record is WorkoutRecord && record.trainedMuscles.isNotEmpty) {
        final date = record.date;
        for (final muscle in record.trainedMuscles) {
          if (!muscleLastTrained.containsKey(muscle) || 
              date.isAfter(muscleLastTrained[muscle]!)) {
            muscleLastTrained[muscle] = date;
          }
        }
      }
    }

    // 计算每个部位的休息天数
    for (final entry in muscleLastTrained.entries) {
      final days = now.difference(entry.value).inDays;
      muscleRestDays[entry.key] = days;
    }

    // 识别过度训练的部位（休息少于2天且训练频率高）
    final overtrainedMuscles = muscleRestDays.entries
        .where((e) => e.value < 2)
        .map((e) => e.key)
        .toList();

    final avgRestDays = muscleRestDays.isEmpty 
        ? 0 
        : muscleRestDays.values.reduce((a, b) => a + b) / muscleRestDays.length;

    return {
      'muscleRestDays': muscleRestDays,
      'avgRestDays': avgRestDays.round(),
      'overtrainedMuscles': overtrainedMuscles,
    };
  }

  /// 获取周数
  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) ~/ 7);
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.timerGradientColors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'TRAINING STATS',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 2,
          labelColor: theme.textColor,
          unselectedLabelColor: theme.secondaryTextColor,
          labelStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: '本周'),
            Tab(text: '本月'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatsView(_filterByWeek(), theme),
                _buildStatsView(_filterByMonth(), theme),
              ],
            ),
    );
  }

  Widget _buildStatsView(List<dynamic> records, AppThemeData theme) {
    final frequencyStats = _calculateFrequencyStats(records);
    final volumeStats = _calculateVolumeStats(records);
    final progressionStats = _calculateProgressionStats(records);
    final recoveryStats = _calculateRecoveryStats(records);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 训练频率概览
          _buildSection('训练频率', theme, [
            _buildFrequencyOverview(frequencyStats, theme),
          ]),
          const SizedBox(height: 20),

          // 2. 训练量统计
          _buildSection('训练量', theme, [
            _buildVolumeOverview(volumeStats, theme),
          ]),
          const SizedBox(height: 20),

          // 3. 渐进超负荷趋势
          _buildSection('渐进趋势', theme, [
            _buildProgressionChart(progressionStats, theme),
          ]),
          const SizedBox(height: 20),

          // 4. 恢复指标
          if ((recoveryStats['muscleRestDays'] as Map).isNotEmpty) ...[
            _buildSection('恢复状态', theme, [
              _buildRecoveryOverview(recoveryStats, theme),
            ]),
            const SizedBox(height: 20),
          ],

          // 5. 各部位训练频率
          if ((frequencyStats['muscleFrequency'] as Map).isNotEmpty) ...[
            _buildSection('部位训练频率', theme, [
              _buildMuscleFrequencyChart(frequencyStats['muscleFrequency'] as Map<PrimaryMuscleGroup, int>, theme),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, AppThemeData theme, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.secondaryTextColor,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  /// 训练频率概览
  Widget _buildFrequencyOverview(Map<String, dynamic> stats, AppThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            '训练次数',
            '${stats['sessionCount']}',
            '次',
            Icons.fitness_center,
            theme.primaryColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '训练天数',
            '${stats['workoutDays']}',
            '天',
            Icons.calendar_today,
            theme.secondaryColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            '周均训练',
            '${(stats['avgSessionsPerWeek'] as double).toStringAsFixed(1)}',
            '次',
            Icons.trending_up,
            theme.accentColor,
            theme,
          ),
        ),
      ],
    );
  }

  /// 训练量概览
  Widget _buildVolumeOverview(Map<String, dynamic> stats, AppThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '总组数',
                '${stats['totalSets']}',
                '组',
                Icons.repeat,
                theme.primaryColor,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '总时长',
                formatDuration(stats['totalDuration'] as int),
                '',
                Icons.timer,
                theme.secondaryColor,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubMetric('平均组数/次', '${(stats['avgSetsPerSession'] as double).toStringAsFixed(1)} 组', theme),
              Container(width: 1, height: 30, color: theme.textColor.withValues(alpha: 0.1)),
              _buildSubMetric('平均时长/次', formatDuration(stats['avgDurationPerSession'] as int), theme),
            ],
          ),
        ),
      ],
    );
  }

  /// 渐进趋势图表
  Widget _buildProgressionChart(Map<String, dynamic> stats, AppThemeData theme) {
    final weeklyTrend = stats['weeklyTrend'] as Map<String, int>;
    final isImproving = stats['isImproving'] as bool;
    final improvementPercent = stats['improvementPercent'] as double;

    if (weeklyTrend.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无数据',
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      );
    }

    final entries = weeklyTrend.entries.toList();
    final maxValue = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return Column(
      children: [
        // 趋势指示器
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isImproving 
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isImproving ? Icons.trending_up : Icons.trending_down,
                color: isImproving ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isImproving 
                    ? '训练量上升 ${improvementPercent.toStringAsFixed(1)}%'
                    : '训练量下降 ${improvementPercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isImproving ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 周趋势图
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((entry) {
              final height = maxValue > 0 ? (entry.value / maxValue) * 70 : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 11,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: height.clamp(8.0, 70.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [theme.primaryColor, theme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 10,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 恢复状态概览
  Widget _buildRecoveryOverview(Map<String, dynamic> stats, AppThemeData theme) {
    final muscleRestDays = stats['muscleRestDays'] as Map<PrimaryMuscleGroup, int>;
    final avgRestDays = stats['avgRestDays'] as int;
    // 识别过度训练的部位（休息少于2天）
    // final overtrainedMuscles = stats['overtrainedMuscles'] as List<PrimaryMuscleGroup>;

    final sortedMuscles = muscleRestDays.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 平均休息天数
        Row(
          children: [
            Icon(Icons.bedtime, color: theme.accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '平均休息：$avgRestDays 天',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 各部位休息状态
        ...sortedMuscles.map((entry) {
          final muscle = entry.key;
          final days = entry.value;
          final isOvertrained = days < 2;
          final isWellRested = days >= 3;
          
          Color statusColor;
          String statusText;
          if (isOvertrained) {
            statusColor = Colors.red;
            statusText = '需休息';
          } else if (isWellRested) {
            statusColor = Colors.green;
            statusText = '状态良好';
          } else {
            statusColor = Colors.orange;
            statusText = '可训练';
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _getMuscleIcon(muscle),
                  size: 18,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    muscle.displayName,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$days天 · $statusText',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 各部位训练频率图表
  Widget _buildMuscleFrequencyChart(Map<PrimaryMuscleGroup, int> frequency, AppThemeData theme) {
    final sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxFreq = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1;

    return Column(
      children: sortedEntries.map((entry) {
        final percentage = maxFreq > 0 ? entry.value / maxFreq : 0.0;
        
        // 根据训练量判断状态
        Color barColor;
        if (entry.value >= 3) {
          barColor = Colors.green; // 充足
        } else if (entry.value >= 2) {
          barColor = theme.accentColor; // 适中
        } else {
          barColor = Colors.orange; // 不足
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getMuscleIcon(entry.key), size: 16, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.displayName,
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value}次/周',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 13,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: theme.textColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon, Color color, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 10,
              color: theme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 11,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  IconData _getMuscleIcon(PrimaryMuscleGroup muscle) {
    switch (muscle) {
      case PrimaryMuscleGroup.chest:
        return Icons.fitness_center_rounded;
      case PrimaryMuscleGroup.back:
        return Icons.accessibility_new_rounded;
      case PrimaryMuscleGroup.shoulders:
        return Icons.arrow_upward_rounded;
      case PrimaryMuscleGroup.arms:
        return Icons.back_hand_rounded;
      case PrimaryMuscleGroup.legs:
        return Icons.directions_walk_rounded;
      case PrimaryMuscleGroup.core:
        return Icons.circle_rounded;
    }
  }
}
