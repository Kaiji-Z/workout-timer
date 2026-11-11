import 'package:flutter/material.dart';

/// 单个入场动画包装器
/// 用于单个组件的淡入上滑效果
class FadeInItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<FadeInItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// 列表项入场动画包装器
/// 简单的淡入上滑动画效果
class ListAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const ListAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    // 入场 stagger 封顶：长列表（如历史记录）深处的条目不再需要
    // 等待 index*50ms 才淡入，避免第 40 条空白 2 秒的可感知延迟。
    final cappedIndex = index < 20 ? index : 20;
    return FadeInItem(
      delay: delay + Duration(milliseconds: cappedIndex * 50),
      duration: duration,
      child: child,
    );
  }
}
