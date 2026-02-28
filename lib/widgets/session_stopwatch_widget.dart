import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 小型会话计时器组件
/// 显示整个训练过程的总时长，从开始运动到结束运动持续计时
class SessionStopwatchWidget extends StatelessWidget {
  final int sessionDuration;
  final AppThemeData theme;
  final double size;
  final bool showLabel;

  const SessionStopwatchWidget({
    super.key,
    required this.sessionDuration,
    required this.theme,
    this.size = 80,
    this.showLabel = true,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(sessionDuration),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: size * 0.2,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
              shadows: [
                Shadow(
                  color: theme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Text(
              '总时长',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: size * 0.1,
                color: theme.secondaryTextColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
