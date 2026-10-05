import 'package:flutter/material.dart';

/// 首次启动轮播引导页（RED 阶段桩：仅保证测试可编译，
/// 完整实现在同序列的 feat 提交中）。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
