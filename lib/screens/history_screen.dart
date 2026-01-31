import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../services/workout_repository.dart';

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
      return [];
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await _repository.deleteSession(id);
      setState(() {});
    } catch (e) {}
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a12),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00f0ff), Color(0xFFbf00ff)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'WORKOUT HISTORY',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00f0ff)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'LOAD FAILED',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  color: Colors.red,
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
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO RECORDS YET',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a workout and press FINISH',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final sessions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionCard(
                  session: session,
                  formatDate: _formatDate,
                  onDelete: () => _deleteSession(session.id),
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

  const _SessionCard({
    required this.session,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.transparent, Color(0xFFff0055)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF141423).withOpacity(0.8),
              const Color(0xFF1a1a2e).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00f0ff).withOpacity(0.05),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF00f0ff), Color(0xFF0078ff)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${session.totalSets}',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0a0a12),
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
                      fontFamily: 'Rajdhani',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(session.createdAt),
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
