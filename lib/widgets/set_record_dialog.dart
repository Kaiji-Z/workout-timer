import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/set_data.dart';
import '../models/exercise.dart';
import '../services/bodyweight_coefficient_service.dart';
import '../theme/theme_provider.dart';

/// 单组训练数据记录悬浮对话框 - Flat Vitality 设计风格
///
/// 在计划模式每次休息结束后弹出，记录当前组的次数和重量。
/// - 显示动作名称和组号
/// - CupertinoPicker 滑动选择次数
/// - TextField 手动输入重量
/// - 保存和跳过按钮
class SetRecordDialog extends StatefulWidget {
  final String exerciseName;
  final int setNumber;
  final int? initialReps;
  final double? initialWeight;
  final Exercise? exercise;

  const SetRecordDialog({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    this.initialReps = 12,
    this.initialWeight,
    this.exercise,
  });

  /// 显示对话框并返回记录的数据（null 表示跳过）
  static Future<SetData?> show(
    BuildContext context, {
    required String exerciseName,
    required int setNumber,
    int? initialReps,
    double? initialWeight,
    Exercise? exercise,
  }) {
    return showDialog<SetData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SetRecordDialog(
        exerciseName: exerciseName,
        setNumber: setNumber,
        initialReps: initialReps,
        initialWeight: initialWeight,
        exercise: exercise,
      ),
    );
  }

  @override
  State<SetRecordDialog> createState() => _SetRecordDialogState();
}

class _SetRecordDialogState extends State<SetRecordDialog> {
  late int _selectedReps;
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();
  double? _bodyWeight;
  bool _isBodyweight = false;
  double _coefficient = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedReps = widget.initialReps ?? 12;
    if (widget.initialWeight != null) {
      _weightController.text = widget.initialWeight.toString();
    }
    // Detect bodyweight exercise and load body weight
    _isBodyweight = BodyweightCoefficientService.isBodyweightExercise(
      widget.exercise,
    );
    if (_isBodyweight) {
      _coefficient = BodyweightCoefficientService.getCoefficient(
        widget.exercise,
      );
      BodyweightCoefficientService.loadBodyWeight().then((weight) {
        if (weight != null && weight > 0 && mounted) {
          setState(() {
            _bodyWeight = weight;
          });
        }
      });
    }
    // Auto-focus weight input after a short delay to allow UI to render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weightFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题：动作名称 + 组号
            Text(
              widget.exerciseName,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '第${widget.setNumber}组',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // 次数选择器
            Text(
              '次数',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedReps - 1,
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedReps = index + 1;
                  });
                },
                children: List.generate(50, (index) {
                  final reps = index + 1;
                  return Center(
                    child: Text(
                      '$reps 次',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: reps == _selectedReps
                            ? theme.textColor
                            : theme.secondaryTextColor,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // 自重动作参考信息
            if (_isBodyweight && _bodyWeight != null && _bodyWeight! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '体重 ${_bodyWeight!.toStringAsFixed(0)}kg × ${(_coefficient * 100).toStringAsFixed(0)}% = ${(_bodyWeight! * _coefficient).toStringAsFixed(1)}kg',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 重量输入
            Text(
              _isBodyweight ? '附加重量 (kg)' : '重量 (kg)',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: _isBodyweight ? '0 = 纯自重' : '0',
                hintStyle: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 16,
                  color: theme.secondaryTextColor.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.accentColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.textColor,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),

            // 按钮区域
            Row(
              children: [
                // 跳过按钮
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '跳过',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 保存按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '保存',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final additionalWeight = double.tryParse(_weightController.text) ?? 0.0;
    double weight;
    if (_isBodyweight && _bodyWeight != null && _bodyWeight! > 0) {
      weight = BodyweightCoefficientService.calculateEquivalentWeight(
        exercise: widget.exercise,
        bodyWeight: _bodyWeight!,
        additionalWeight: additionalWeight,
      );
    } else {
      weight = additionalWeight;
    }
    final setData = SetData(
      setNumber: widget.setNumber,
      reps: _selectedReps,
      weight: weight > 0 ? weight : null,
    );
    Navigator.of(context).pop(setData);
  }
}
