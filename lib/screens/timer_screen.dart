import 'package:flutter/material.dart';
import '../widgets/timer_widget.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健身计时器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: const Center(
        child: TimerWidget(),
      ),
    );
  }
}