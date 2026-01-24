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
    return await _repository.getAllSessions();
  }

  Future<void> _deleteSession(String id) async {
    await _repository.deleteSession(id);
    setState(() {}); // Refresh
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes分$seconds秒';
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('锻炼历史')),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _loadSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无锻炼记录'));
          } else {
            final sessions = snapshot.data!;
            return ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Dismissible(
                  key: Key(session.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteSession(session.id),
                  child: ListTile(
                    title: Text('组数: ${session.totalSets}'),
                    subtitle: Text('休息时间: ${_formatDuration(session.totalRestTimeMs)}\n${_formatDate(session.createdAt)}'),
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