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
        // 更新预设时间：30秒/45秒/1分钟/1分30秒/2分钟
        final presetTimes = [30, 45, 60, 90, 120];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // 区域1：计时区域（最大）
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 倒计时数字
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatTime(timer.remainingSeconds),
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          color: timer.isRunning ? Colors.blue[600] : Colors.black87,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 进度条
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: timer.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: timer.isRunning ? Colors.blue[600] : Colors.grey[400],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 状态文本
                    Text(
                      timer.isRunning ? '休息中...' : '准备开始',
                      style: TextStyle(
                        fontSize: 14,
                        color: timer.isRunning ? Colors.blue[600] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 区域2：操作区（三个按钮垂直排列）
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 240, // 固定高度避免布局问题
                child: Column(
                  children: [
                    // 开始休息按钮
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _ActionButton(
                          onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
                          icon: timer.isRunning ? Icons.pause : Icons.play_arrow,
                          label: timer.isRunning ? '暂停休息' : '开始休息',
                          color: timer.isRunning ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),

                    // 跳过休息按钮
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _ActionButton(
                          onPressed: timer.skipToNextSet,
                          icon: Icons.skip_next,
                          label: '跳过休息',
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    // 重置休息按钮
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: _ActionButton(
                          onPressed: timer.resetTimer,
                          icon: Icons.refresh,
                          label: '重置休息',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 区域3：选择区（时间选择）
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '休息时间',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: presetTimes.map((seconds) {
                        final isSelected = timer.remainingSeconds == seconds && !timer.isRunning;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _TimeButton(
                              seconds: seconds,
                              isSelected: isSelected,
                              onPressed: () => timer.selectPreset(seconds),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 区域4：记录区（完成组数）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '已完成：${timer.totalSets} 组',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // 添加底部间距
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, double.infinity),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final int seconds;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TimeButton({
    required this.seconds,
    required this.onPressed,
    required this.isSelected,
  });

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}分钟';
      } else {
        return '${minutes}分${remainingSeconds}秒';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[50],
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _formatTime(seconds),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue[700] : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

