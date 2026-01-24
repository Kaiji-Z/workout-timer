import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/timer_provider.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Countdown display
            Text(
              _formatTime(timer.remainingSeconds),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            // Progress bar
            SizedBox(
              width: 200,
              height: 10,
              child: LinearProgressIndicator(
                value: timer.progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 40),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
                  child: Text(timer.isRunning ? '暂停' : '开始'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: timer.resetTimer,
                  child: const Text('重置'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: timer.skipToNextSet,
                  child: const Text('跳过'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Preset buttons
            Wrap(
              spacing: 10,
              children: timer.presetTimes.map((seconds) {
                return ElevatedButton(
                  onPressed: () => timer.selectPreset(seconds),
                  child: Text('${seconds ~/ 60} 分'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Sets counter
            Text(
              '已完成组数: ${timer.totalSets}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        );
      },
    );
  }
}