import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/timer_provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

/// Warm Vitality 风格计时器组件
/// 
/// 设计特点:
/// - 粗线条进度环 (10px) - 深蓝色
/// - 白色背景按钮 + 深色图标/文字
/// - 扁平设计，无发光效果
/// - 温暖渐变背景
class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.backgroundColor,
                theme.backgroundGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  _buildTimerDisplay(timer, context, theme),
                  const SizedBox(height: 16),
                  _buildPresetChips(timer, theme),
                  const SizedBox(height: 12),
                  _buildCompletedSets(timer, theme),
                  const SizedBox(height: 24),
                  _buildControlButtons(timer, theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'WORKOUT TIMER',
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(TimerProvider timer, BuildContext context, AppThemeData theme) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度环
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: timer.progress,
                isRunning: timer.isRunning,
                accentColor: theme.accentColor,
                backgroundColor: theme.borderColor,
              ),
            ),
          ),
          // 中心内容
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(timer.remainingSeconds),
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(timer, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TimerProvider timer, AppThemeData theme) {
    final isRunning = timer.isRunning;
    final bgColor = isRunning 
        ? theme.accentColor.withValues(alpha: 0.15)
        : theme.textColor.withValues(alpha: 0.08);
    final borderColor = isRunning 
        ? theme.accentColor.withValues(alpha: 0.4)
        : theme.textColor.withValues(alpha: 0.2);
    final textColor = isRunning ? theme.accentColor : theme.textColor;
    final text = isRunning ? 'ACTIVE' : 'READY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPresetChips(TimerProvider timer, AppThemeData theme) {
    final presets = [30, 60, 90, 120];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: presets.asMap().entries.map((entry) {
        final seconds = entry.value;
        final index = entry.key;
        final isSelected = timer.selectedPresetIndex == index && !timer.isRunning;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PresetChip(
            seconds: seconds,
            isSelected: isSelected,
            onPressed: () => timer.selectPreset(index),
            theme: theme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedSets(TimerProvider timer, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${timer.totalSets}',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '完成组数',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textColor.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(TimerProvider timer, AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 重置按钮 (圆形白色背景)
        _CircleControlButton(
          icon: Icons.refresh_rounded,
          onPressed: timer.resetTimer,
          theme: theme,
        ),
        // 主按钮 (开始/暂停)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _PrimaryControlButton(
              label: timer.isRunning ? 'PAUSE' : 'START',
              icon: timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
              theme: theme,
            ),
          ),
        ),
        // 跳过按钮 (圆形白色背景)
        _CircleControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: timer.skipSet,
          theme: theme,
        ),
      ],
    );
  }
}

/// 粗线条进度环 - Warm Vitality 风格
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final Color accentColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.isRunning,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // 背景环 - 浅色
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度环 - 深蓝色，粗线条
    final progressPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.accentColor != accentColor;
  }
}

/// 预设时间选择器 - Warm Vitality 风格
class _PresetChip extends StatelessWidget {
  final int seconds;
  final bool isSelected;
  final VoidCallback onPressed;
  final AppThemeData theme;

  const _PresetChip({
    required this.seconds,
    required this.isSelected,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final label = seconds >= 120 ? '2min' : '${seconds}s';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.accentColor 
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : theme.textColor,
          ),
        ),
      ),
    );
  }
}

/// 圆形控制按钮 - 参考图风格
class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final AppThemeData theme;

  const _CircleControlButton({
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: theme.accentColor,
          size: 24,
        ),
      ),
    );
  }
}

/// 主控制按钮 - 参考图风格
class _PrimaryControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final AppThemeData theme;

  const _PrimaryControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.accentColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
