import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../services/workout_repository.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutRepository _repository = WorkoutRepository();
  List<WorkoutSession> _allSessions = [];
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
      setState(() {
        _allSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<WorkoutSession> _filterByWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return _allSessions.where((s) {
      final date = DateTime.parse(s.createdAt);
      return date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek);
    }).toList();
  }

  List<WorkoutSession> _filterByMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return _allSessions.where((s) {
      final date = DateTime.parse(s.createdAt);
      return date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart);
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return {
        'totalSets': 0,
        'totalTime': 0,
        'workoutDays': 0,
        'avgSets': 0.0,
      };
    }

    final totalSets = sessions.fold<int>(0, (sum, s) => sum + s.totalSets);
    final totalTime = sessions.fold<int>(0, (sum, s) => sum + s.totalRestTimeMs);
    
    final uniqueDays = sessions.map((s) {
      final date = DateTime.parse(s.createdAt);
      return '${date.year}-${date.month}-${date.day}';
    }).toSet().length;

    return {
      'totalSets': totalSets,
      'totalTime': totalTime,
      'workoutDays': uniqueDays,
      'avgSets': sessions.isEmpty ? 0.0 : totalSets / sessions.length,
    };
  }

  Map<String, dynamic> _getPersonalBests() {
    if (_allSessions.isEmpty) {
      return {
        'maxSets': null,
        'maxSetsDate': null,
        'maxTime': null,
        'maxTimeDate': null,
        'longestStreak': 0,
      };
    }

    WorkoutSession? maxSetsSession;
    WorkoutSession? maxTimeSession;

    for (final session in _allSessions) {
      if (maxSetsSession == null || session.totalSets > maxSetsSession.totalSets) {
        maxSetsSession = session;
      }
      if (maxTimeSession == null || session.totalRestTimeMs > maxTimeSession.totalRestTimeMs) {
        maxTimeSession = session;
      }
    }

    // Calculate longest streak
    final dates = _allSessions.map((s) {
      final date = DateTime.parse(s.createdAt);
      return DateTime(date.year, date.month, date.day);
    }).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final date in dates) {
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final diff = lastDate.difference(date).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
          currentStreak = 1;
        }
      }
      lastDate = date;
    }
    longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;

    return {
      'maxSets': maxSetsSession?.totalSets,
      'maxSetsDate': maxSetsSession?.createdAt,
      'maxTime': maxTimeSession?.totalRestTimeMs,
      'maxTimeDate': maxTimeSession?.createdAt,
      'longestStreak': longestStreak,
    };
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    final date = DateTime.parse(isoString);
    return DateFormat('MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
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
              'STATISTICS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 2,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.secondaryTextColor,
          labelStyle: TextStyle(
            fontFamily: 'Rajdhani',
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

  Widget _buildStatsView(List<WorkoutSession> sessions, AppThemeData theme) {
    final stats = _calculateStats(sessions);
    final bests = _getPersonalBests();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummarySection(stats, theme),
          const SizedBox(height: 24),

          // Chart
          _buildChartSection(sessions, theme),
          const SizedBox(height: 24),

          // Personal Bests
          _buildPersonalBestSection(bests, theme),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> stats, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('概览', theme),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总组数',
                '${stats['totalSets']}',
                '组',
                Icons.fitness_center,
                theme.primaryColor,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '总时长',
                _formatDuration(stats['totalTime'] as int),
                '',
                Icons.timer,
                theme.secondaryColor,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '训练天数',
                '${stats['workoutDays']}',
                '天',
                Icons.calendar_today,
                theme.accentColor,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    AppThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              color: theme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<WorkoutSession> sessions, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('训练趋势', theme),
        const SizedBox(height: 12),
        Container(
          height: 180, // 减小高度以避免溢出
          padding: const EdgeInsets.all(12), // 减小内边距
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: sessions.isEmpty
              ? Center(
                  child: Text(
                    '暂无数据',
                    style: TextStyle(
                      color: theme.secondaryTextColor,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                )
              : _buildBarChart(sessions, theme),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<WorkoutSession> sessions, AppThemeData theme) {
    // Group by date
    final Map<String, int> dailyData = {};
    for (final session in sessions.take(7).toList()) {
      final date = _formatDate(session.createdAt);
      dailyData[date] = (dailyData[date] ?? 0) + session.totalSets;
    }

    final entries = dailyData.entries.toList();
    final maxSets = entries.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: entries.map((entry) {
        final height = maxSets > 0 ? (entry.value / maxSets) * 100 : 0.0; // 减小高度
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${entry.value}',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28, // 减小宽度
              height: height.clamp(4.0, 100.0), // 减小最大高度
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4), // 减小间距
            Text(
              entry.key,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 10,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPersonalBestSection(Map<String, dynamic> bests, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('个人最佳', theme),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            children: [
              _buildBestRow(
                '单次最多组数',
                bests['maxSets'] != null ? '${bests['maxSets']} 组' : '-',
                _formatDate(bests['maxSetsDate'] as String?),
                Icons.emoji_events,
                theme.accentColor,
                theme,
              ),
              Divider(color: theme.borderColor, height: 1),
              _buildBestRow(
                '单次最长训练',
                bests['maxTime'] != null ? _formatDuration(bests['maxTime'] as int) : '-',
                _formatDate(bests['maxTimeDate'] as String?),
                Icons.access_time,
                theme.primaryColor,
                theme,
              ),
              Divider(color: theme.borderColor, height: 1),
              _buildBestRow(
                '连续训练天数',
                '${bests['longestStreak']} 天',
                '',
                Icons.local_fire_department,
                theme.warningColor,
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestRow(
    String label,
    String value,
    String date,
    IconData icon,
    Color color,
    AppThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Text(
              date,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.secondaryTextColor,
        letterSpacing: 1,
      ),
    );
  }
}
