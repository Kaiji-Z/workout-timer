import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/set_data.dart';
import '../theme/theme_provider.dart';
import 'glass_widgets.dart';

/// 重量输入对话框 - Flat Vitality 设计风格
/// 
/// 特点:
/// - 白色背景对话框
/// - 深色文字和图标
/// - 圆形按钮
/// - 简洁阴影
class WeightInputDialog extends StatefulWidget {
  final String exerciseName;
  final int setNumber;
  
  const WeightInputDialog({
    super.key,
    required this.exerciseName,
    required this.setNumber,
  });
  
  @override
  State<WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weightFocus.requestFocus();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Text(
                  '第${widget.setNumber}组 - ${widget.exerciseName}',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 重量输入
            TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '重量(kg)',
                labelStyle: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  color: theme.secondaryTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.accentColor,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.textColor,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _repsFocus.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            
            // 次数输入
            TextField(
              controller: _repsController,
              focusNode: _repsFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '次数',
                labelStyle: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  color: theme.secondaryTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.accentColor,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.textColor,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            
            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 跳过按钮
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 确认按钮
                CircularControlButton(
                  icon: Icons.check,
                  onPressed: () {
                    final weight = double.tryParse(_weightController.text);
                    final reps = int.tryParse(_repsController.text);
                    
                    if (weight != null && reps != null) {
                      final setData = SetData(
                        setNumber: widget.setNumber,
                        weight: weight,
                        reps: reps,
                      );
                      Navigator.of(context).pop(setData);
                    } else {
                      // 简单验证
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入有效的重量和次数'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}