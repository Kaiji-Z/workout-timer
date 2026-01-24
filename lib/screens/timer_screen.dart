import 'package:flutter/material.dart';
import '../widgets/timer_widget.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '健身计时器',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black54,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.history_outlined,
              color: Colors.black54,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: TimerWidget(),
      ),
    );
  }
}