import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

/// iOS 26 风格时间选择器
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

  /// 显示底部弹出的时间选择器 - iOS 26 风格
  static Future<void> show(
    BuildContext context, {
    required int initialDurationSeconds,
    required Function(int seconds) onDurationSelected,
    String title = '设置休息时长',
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
    final isDark = theme.isDark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.45,
      decoration: BoxDecoration(
        // iOS 26 风格：液态玻璃底部 sheet
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              // 半透明材质
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              // 边框
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // 顶部拖动条 - iOS 26 风格
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                // Header
                _buildHeader(theme),
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
                // Preview & Confirm Button
                _buildBottomSection(theme),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 取消按钮 - iOS 26 风格
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: theme.primaryColor,
              ),
            ),
          ),
          // 标题
          Text(
            widget.title,
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          // 确定按钮 - iOS 26 风格
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onConfirm,
            child: Text(
              '确定',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 预览
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '已选择: ${_formatDuration(_totalSeconds)}',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          // 确认按钮 - iOS 26 风格胶囊按钮
          _buildConfirmButton(theme),
        ],
      ),
    );
  }

Widget _buildConfirmButton(AppThemeData theme) {
    return GestureDetector(
      onTap: _onConfirm,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '确认',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
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
    final isDark = theme.isDark;
    
    return Stack(
      children: [
        // Selection indicator - iOS 26 风格
        Center(
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              // 液态玻璃选择器背景
              color: isDark
                  ? theme.primaryColor.withValues(alpha: 0.08)
                  : theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
        // Wheel
        CupertinoPicker(
          scrollController: controller,
          itemExtent: 44,
          onSelectedItemChanged: onChanged,
          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
            background: Colors.transparent,
          ),
          children: items.map((value) {
            return Center(
              child: Text(
                '$value$suffix',
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 22,
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
