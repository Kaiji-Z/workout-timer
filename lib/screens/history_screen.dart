import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../models/workout_record.dart';
import '../services/workout_repository.dart';
import '../bloc/record_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../animations/list_animations.dart';
import 'record_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _repository = WorkoutRepository();

  Future<List<dynamic>> _loadAllRecords() async {
    // 加载旧记录
final oldSessions = await _repository.getAllSessions();
    
    if (!mounted) return [];
    
    // 获取新记录（从Provider中直接获取，需要先加载）
    final recordProvider = context.read<RecordProvider>();
    if (recordProvider.recordCount == 0) {
      await recordProvider.loadRecords();
    }
    final newRecords = recordProvider.records;
    
    // 按日期排序
    final allRecords = <dynamic>[...oldSessions, ...newRecords];
    allRecords.sort((a, b) {
      final dateA = a is WorkoutSession 
          ? DateTime.parse(a.createdAt) 
          : a.date;
      final dateB = b is WorkoutSession 
          ? DateTime.parse(b.createdAt) 
          : b.date;
      return dateB.compareTo(dateA);
    });
    
    return allRecords;
  }

  Future<void> _deleteSession(String id) async {
    try {
      await _repository.deleteSession(id);
      setState(() {});
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  Future<void> _deleteRecord(String id) async {
    try {
      await context.read<RecordProvider>().deleteRecord(id);
      setState(() {});
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  Future<void> _clearHistory() async {
    try {
      await _repository.clearAllSessions();
      setState(() {});
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  String _formatDate(dynamic record) {
    DateTime date;
    if (record is WorkoutSession) {
      date = DateTime.parse(record.createdAt);
    } else if (record is WorkoutRecord) {
      date = record.date;
    } else {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
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
                gradient: LinearGradient(
                  colors: theme.timerGradientColors,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'HISTORY',
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
        actions: [
          TextButton(
            onPressed: () => _showClearConfirmDialog(),
            child: Text(
              'Clear',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                color: theme.accentColor,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _loadAllRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'LOAD FAILED',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.accentColor,
                  letterSpacing: 2,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: theme.secondaryTextColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No record yet',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryTextColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'complete a workout to see results',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      color: theme.secondaryTextColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
return ListAnimation(
                  index: index,
                  child: record is WorkoutRecord
                      ? _RecordCard(
                          record: record,
                          formatDate: _formatDate,
                          onDelete: () => _deleteRecord(record.id),
                          onTap: () => _navigateToDetail(record),
                          theme: theme,
                        )
                      : _SessionCard(
                          session: record as WorkoutSession,
                          formatDate: _formatDate,
                          onDelete: () => _deleteSession(record.id),
                          theme: theme,
                        ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(WorkoutRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailScreen(record: record),
      ),
    );
  }
}

/// 新记录卡片 - 支持计划模式记录
class _RecordCard extends StatelessWidget {
  final WorkoutRecord record;
  final String Function(dynamic) formatDate;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final AppThemeData theme;

  const _RecordCard({
    required this.record,
    required this.formatDate,
    required this.onDelete,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, theme.accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: theme.textColor),
      ),
      onDismissed: (direction) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: record.isPlanMode
                      ? LinearGradient(
                          colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.8)],
                        )
                      : LinearGradient(
                          colors: [theme.primaryColor, theme.secondaryColor],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: record.isPlanMode
                      ? const Icon(Icons.playlist_add_check, color: Colors.white, size: 24)
                      : Text(
                          '${record.totalSets}',
                          style: const TextStyle(
                            fontFamily: '.SF Pro Display',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 计划名称或"自由训练"
                    Row(
                      children: [
                        if (record.isPlanMode) ...[
                          Flexible(
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: theme.accentColor.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Text(
                                 record.planName ?? '计划模式',
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                                 style: TextStyle(
                                   fontFamily: '.SF Pro Text',
                                   fontSize: 11,
                                   fontWeight: FontWeight.w600,
                                   color: theme.accentColor,
                                 ),
                               ),
                             ),
                           ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          record.dateText,
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 训练部位
                    if (record.trainedMuscles.isNotEmpty)
                      Text(
                        record.trainedMusclesText,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      )
                    else
                      Text(
                        '自由训练',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // 统计信息
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: theme.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          record.durationText,
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.repeat, size: 14, color: theme.secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          '${record.totalSets}组',
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        if (record.exerciseCount > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.fitness_center, size: 14, color: theme.secondaryTextColor),
                          const SizedBox(width: 4),
                          Text(
                            '${record.exerciseCount}动作',
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 12,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 箭头
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 旧记录卡片 - 保持兼容性
class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final String Function(dynamic) formatDate;
  final VoidCallback onDelete;
  final AppThemeData theme;

  const _SessionCard({
    required this.session,
    required this.formatDate,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, theme.accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: theme.textColor),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${session.totalSets}',
                  style: const TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETS COMPLETED',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(session),
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.borderColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
