import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'circular_progress_painter.dart';

/// 休息倒计时组件
/// 大型圆形进度显示，用于休息期间倒计时
class RestTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final AppThemeData theme;
  final double size;
  final String label;

  const RestTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.theme,
    this.size = 240,
    this.label = '休息倒计时',
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: progress,
                gradientColors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.5)],
                backgroundColor: theme.borderColor,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(remainingSeconds),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  color: theme.textColor,
                  shadows: [
                    Shadow(
                      color: theme.accentColor,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: size * 0.05,
                  color: theme.secondaryTextColor,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
