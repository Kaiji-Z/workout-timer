// #TB|import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/workout_session.dart';
import '../services/workout_repository.dart';
import '../animations/list_animations.dart';
import 'dart:ui' as ui;

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
      if (maxSetsSession == null || session.totalSets > (maxSetsSession?.totalSets ?? 0)) {
        maxSetsSession = session;
      }
      if (maxTimeSession == null || session.totalRestTimeMs > (maxTimeSession?.totalRestTimeMs ?? 0)) {
        maxTimeSession = session;
      }
      if (maxTimeSession == null || session.totalRestTimeMs > (maxTimeSession?.totalRestTimeMs ?? 0)) {
        maxTimeSession = session;
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
                gradient: LinearGradient(colors: [theme.primaryColor, theme.secondaryColor])
              ),
            ),
            Text(
              'STATISTICS',
              style: TextStyle(
                fontFamily: '.SF Pro Display'
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
          labelStyle: TextStyle(
            fontFamily: '.SF Pro Text'
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards - 毛玻璃卡片
          _buildGlassSection('概览', [
            Row(
              children: [
                FadeInItem(
                  child: _buildGlassStatCard('总组数', '${stats['totalSets']}', '组', Icons.fitness_center, theme.primaryColor),
                  delay: const Duration(milliseconds: 100),
                ),
                FadeInItem(
                  child: _buildGlassStatCard('总时长', _formatDuration(stats['totalTime'] as int), '', Icons.timer, theme.timerGradientColors[1]),
                  delay: const Duration(milliseconds: 200),
                ),
                FadeInItem(
                  child: _buildGlassStatCard('训练天数', '${stats['workoutDays']}', '天', Icons.calendar_today, theme.successColor),
                  delay: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

          // Chart Section
          _buildGlassSection('训练趋势', [
            _buildGlassChart(sessions, theme),
          ]),
          const SizedBox(height: 24),

          // Personal Bests
          _buildGlassSection('个人最佳', [
            FadeInItem(
              child: _buildGlassBestRow('单次最多组数', bests['maxSets'] != null ? '${bests['maxSets']} 组' : '-', '', Icons.emoji_events, theme.warningColor),
              delay: const Duration(milliseconds: 400),
            ),
            FadeInItem(
              child: _buildGlassBestRow('单次最长训练', bests['maxTime'] != null ? _formatDuration(bests['maxTime'] as int) : '-', '', Icons.access_time, theme.primaryColor),
              delay: const Duration(milliseconds: 500),
            ),
            FadeInItem(
              child: _buildGlassBestRow('连续训练天数', '${bests['longestStreak']} 天', '', Icons.local_fire_department, theme.accentColor),
              delay: const Duration(milliseconds: 600),
            ),
          ]),
        ],
      ),
    );
  }

  // 毛玻璃 Section Header
  Widget _buildGlassSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: '.SF Pro Text'
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 毛玻璃 Stat Card
  Widget _buildGlassStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: '.SF Pro Display'
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text'
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // 毛玻璃 Chart
  Widget _buildGlassChart(List<WorkoutSession> sessions, AppThemeData theme) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: '.SF Pro Text'
          ),
        ),
      );
    }

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
        final height = maxSets > 0 ? (entry.value / maxSets) * 100 : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${entry.value}',
              style: TextStyle(
                fontFamily: '.SF Pro Display'
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: height.clamp(4.0, 100.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [theme.primaryColor, theme.secondaryColor]
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.key,
              style: TextStyle(
                fontFamily: '.SF Pro Text'
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 毛玻璃 Best Row
  Widget _buildGlassBestRow(String label, String value, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text'
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: '.SF Pro Display'
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Text(
              date,
              style: TextStyle(
                fontFamily: '.SF Pro Text'
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}
