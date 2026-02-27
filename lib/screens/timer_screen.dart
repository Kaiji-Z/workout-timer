import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/training_widget.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VitalFlowBackground(
        child: const SafeArea(
          child: TrainingWidget(),
        ),
      ),
    );
  }
}

/// VitalFlow 背景层 - 全局模糊背景，突出前景
/// 模拟长焦镜头大光圈效果，背景虚化
const double _blurSigma = 12.0; // 模糊强度

class VitalFlowBackground extends StatelessWidget {
  final Widget child;

  const VitalFlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 模糊背景层
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blurSigma,
              sigmaY: _blurSigma,
              tileMode: TileMode.decal, // 边缘无缝
            ),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        // 轻微渐变叠加增加层次感
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.white.withValues(alpha: 0.08),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // 前景内容
        child,
      ],
    );
  }
}