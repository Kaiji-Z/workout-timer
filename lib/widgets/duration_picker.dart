import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

/// 时间选择器组件
/// 分钟滚轮：0-5 分钟
/// 秒滚轮：00/10/20/30/40/50（每10秒一格）
class DurationPicker extends StatefulWidget {
  final int initialDurationSeconds;
  final Function(int seconds) onDurationSelected;
  final String title;

  const DurationPicker({
    super.key,
    required this.initialDurationSeconds,
    required this.onDurationSelected,
    this.title = '设置休息时长',
  });

  /// 显示底部弹出的时间选择器
  static Future<void> show(
    BuildContext context, {
    required int initialDurationSeconds,
    required Function(int seconds) onDurationSelected,
    String title = '设置休息时长',
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DurationPicker(
        initialDurationSeconds: initialDurationSeconds,
        onDurationSelected: onDurationSelected,
        title: title,
      ),
    );
  }

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _minutes;
  late int _seconds;

  final List<int> _minuteOptions = [0, 1, 2, 3, 4, 5];
  final List<int> _secondOptions = [0, 10, 20, 30, 40, 50];

  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDurationSeconds ~/ 60;
    _seconds = widget.initialDurationSeconds % 60;

    // 找到最近的10秒刻度
    _seconds = (_seconds / 10).round() * 10;
    if (_seconds >= 60) _seconds = 50;

    _minuteController = FixedExtentScrollController(
      initialItem: _minuteOptions.indexOf(_minutes),
    );
    _secondController = FixedExtentScrollController(
      initialItem: _secondOptions.indexOf(_seconds),
    );
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  int get _totalSeconds => _minutes * 60 + _seconds;

  void _onConfirm() {
    if (_totalSeconds >= 10) {
      widget.onDurationSelected(_totalSeconds);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('休息时长至少需要10秒'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.borderColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                TextButton(
                  onPressed: _onConfirm,
                  child: Text(
                    '确定',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Picker
          Expanded(
            child: Row(
              children: [
                // Minutes picker
                Expanded(
                  child: _buildWheel(
                    controller: _minuteController,
                    items: _minuteOptions,
                    suffix: '分',
                    theme: theme,
                    onChanged: (index) {
                      setState(() {
                        _minutes = _minuteOptions[index];
                      });
                    },
                  ),
                ),
                // Seconds picker
                Expanded(
                  child: _buildWheel(
                    controller: _secondController,
                    items: _secondOptions,
                    suffix: '秒',
                    theme: theme,
                    onChanged: (index) {
                      setState(() {
                        _seconds = _secondOptions[index];
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '已选择: ${_formatDuration(_totalSeconds)}',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required List<int> items,
    required String suffix,
    required AppThemeData theme,
    required Function(int) onChanged,
  }) {
    return Stack(
      children: [
        // Selection indicator
        Center(
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        // Wheel
        CupertinoPicker(
          scrollController: controller,
          itemExtent: 40,
          onSelectedItemChanged: onChanged,
          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
            background: Colors.transparent,
          ),
          children: items.map((value) {
            return Center(
              child: Text(
                '$value$suffix',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: theme.textColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0 && remainingSeconds > 0) {
      return '$minutes分$remainingSeconds秒';
    } else if (minutes > 0) {
      return '$minutes分钟';
    } else {
      return '$remainingSeconds秒';
    }
  }
}
