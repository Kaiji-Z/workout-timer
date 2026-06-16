import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/set_data.dart';
import '../models/exercise.dart';
import '../services/bodyweight_coefficient_service.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
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
  final Exercise? exercise;

  const WeightInputDialog({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    this.exercise,
  });

  @override
  State<WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<WeightInputDialog> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();
  double? _bodyWeight;
  bool _isBodyweight = false;
  double _coefficient = 0.0;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: theme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSheet),
      ),
      child: SingleChildScrollView(
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
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 自重动作参考信息
            if (_isBodyweight && _bodyWeight != null && _bodyWeight! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
            TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isBodyweight
                    ? AppLocalizations.of(context)!.recAddedWeightKg
                    : AppLocalizations.of(context)!.recWeightKg,
                labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: theme.secondaryTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: theme.accentColor, width: 2),
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: theme.textColor),
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
                labelText: AppLocalizations.of(context)!.recReps,
                labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: theme.secondaryTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: theme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: theme.accentColor, width: 2),
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: theme.textColor),
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
                    AppLocalizations.of(context)!.recSkip,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
                      double finalWeight = weight;
                      if (_isBodyweight &&
                          _bodyWeight != null &&
                          _bodyWeight! > 0) {
                        finalWeight =
                            BodyweightCoefficientService.calculateEquivalentWeight(
                              exercise: widget.exercise,
                              bodyWeight: _bodyWeight!,
                              additionalWeight: weight,
                            );
                      }
                      final setData = SetData(
                        setNumber: widget.setNumber,
                        weight: finalWeight,
                        reps: reps,
                      );
                      Navigator.of(context).pop(setData);
                    } else {
                      // 简单验证
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.recInvalidInput,
                          ),
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
