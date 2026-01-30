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
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF050508),
                Color(0xFF0a0a12),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  _buildHeader(),

                  const SizedBox(height: 16),

                  _buildTimerDisplay(timer, context),

                  const SizedBox(height: 16),

                  _buildPresetChips(timer),

                  const SizedBox(height: 12),

                  _buildCompletedSets(timer),

                  const SizedBox(height: 24),

                  _buildControlButtons(timer),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'WORKOUT TIMER',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF00f0ff),
                  Color(0xFFbf00ff),
                ],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(TimerProvider timer, BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: timer.progress,
                isRunning: timer.isRunning,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(timer.remainingSeconds),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Color(0xFF00f0ff),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(timer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TimerProvider timer) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String text;

    if (timer.isRunning) {
      bgColor = const Color(0x1500ff88);
      borderColor = const Color(0x4000ff88);
      textColor = const Color(0xFF00ff88);
      text = 'ACTIVE';
    } else {
      bgColor = const Color(0x1000f0ff);
      borderColor = const Color(0x3000f0ff);
      textColor = const Color(0xFF00f0ff);
      text = 'READY';
    }

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
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPresetChips(TimerProvider timer) {
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompletedSets(TimerProvider timer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x33141423),
        border: Border.all(color: Colors.white10, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${timer.totalSets}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00f0ff),
              shadows: [
                const Shadow(
                  color: Color(0xFF00f0ff),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '完成组数',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(TimerProvider timer) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ControlButton(
          label: timer.isRunning ? 'PAUSE' : 'START',
          color: timer.isRunning ? const Color(0xFFffdd00) : const Color(0xFF00f0ff),
          gradient: timer.isRunning ? null : const LinearGradient(
            colors: [Color(0xFF00f0ff), Color(0xFF00a0aa)],
          ),
          onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
        ),
        _ControlButton(
          label: 'SKIP',
          color: const Color(0xFF00ff88),
          onPressed: timer.skipSet,
        ),
        _ControlButton(
          label: 'NEW',
          color: const Color(0xFF0078ff),
          onPressed: timer.newTimer,
        ),
        _ControlButton(
          label: 'RESET',
          color: const Color(0xFFff00aa),
          onPressed: timer.resetTimer,
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  _CircularProgressPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = const Color(0x0dffffff)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    final gradient = const LinearGradient(
      colors: [Color(0xFF00f0ff), Color(0xFFbf00ff), Color(0xFFff00aa)],
      stops: [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..color = const Color(0xFF00f0ff)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PresetChip extends StatelessWidget {
  final int seconds;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PresetChip({
    required this.seconds,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = seconds >= 120 ? '2min' : '${seconds}s';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1500f0ff) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF00f0ff) : const Color(0x14ffffff),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0x2000f0ff),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF00f0ff) : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final Color color;
  final LinearGradient? gradient;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.color,
    this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: gradient == null ? BorderSide(color: color.withOpacity(0.8), width: 2) : BorderSide.none,
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
          border: gradient != null
              ? null
              : Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: gradient != null ? const Color(0xFF050508) : color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
