import 'package:flutter/material.dart';
import '../widgets/training_widget.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用主题背景，移除自定义背景
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: TrainingWidget(),
      ),
    );
  }
}