import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_session.dart';
import '../services/workout_repository.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _repository = WorkoutRepository();

  Future<List<WorkoutSession>> _loadSessions() async {
    try {
      return await _repository.getAllSessions();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await _repository.deleteSession(id);
      setState(() {});
    } catch (e) {
      debugPrint('Error deleting session: $e');
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

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
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
                gradient: LinearGradient(
                  colors: theme.timerGradientColors,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'WORKout History',
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
      ),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _loadSessions(),
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
                  color: theme.warningColor,
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
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _clearHistory,
                    child: Text(
                      'Clear all history',
                      style: TextStyle(
                        color: theme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final sessions = snapshot.data!;
            return AnimatedList(
              padding: const EdgeInsets.all(16),
              initialItemCount: sessions.length,
              itemBuilder: (context, index, animation) {
                final session = sessions[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: _SessionCard(
                    session: session,
                    formatDate: _formatDate,
                    onDelete: () => _deleteSession(session.id),
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
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;
  final String Function(String) formatDate;
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
            colors: [Colors.transparent, theme.warningColor],
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
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.1),
              theme.secondaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.05),
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
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.isDark ? theme.backgroundColor : theme.surfaceColor,
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
                      color: theme.textColor.withValues(alpha: 0.9),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(session.createdAt),
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