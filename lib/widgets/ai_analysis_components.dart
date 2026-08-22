// AI 分析页的通用展示组件（从 ai_analysis_screen.dart 拆分）。
import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/context_l10n.dart';
import '../theme/app_theme.dart';
import '../theme/build_context_text_styles.dart';
import '../utils/dimensions.dart';

/// 使用说明卡片（info 图标 + 五条步骤）。
Widget buildAnalysisInstructionsBox(BuildContext context, AppThemeData theme) {
  final l10n = context.l10n;
  return Container(
    padding: const EdgeInsets.all(AppDimensions.screenPadding),
    decoration: BoxDecoration(
      color: theme.accentColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      border: Border.all(
        color: theme.accentColor.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.accentColor),
            const SizedBox(width: 8),
            Text(
              l10n.anInstructionsHeading,
              style: context.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInstructionStep(context, l10n.anInstruction1, theme),
        _buildInstructionStep(context, l10n.anInstruction2, theme),
        _buildInstructionStep(context, l10n.anInstruction3, theme),
        _buildInstructionStep(context, l10n.anInstruction4, theme),
        _buildInstructionStep(context, l10n.anInstruction5, theme),
      ],
    ),
  );
}

Widget _buildInstructionStep(
  BuildContext context,
  String text,
  AppThemeData theme,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: context.bodySmall.copyWith(fontSize: 13)),
  );
}

/// 报告区块大标题。
Widget buildAnalysisSectionHeader(
  BuildContext context,
  String title,
  AppThemeData theme,
) {
  return Text(
    title,
    style: context.headlineLarge.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// 区块内小标题。
Widget buildAnalysisSubsectionHeader(
  BuildContext context,
  String title,
  AppThemeData theme,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: context.labelLarge.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

/// 毛玻璃卡片容器（BackdropFilter 模糊 + 半透明表面）。
Widget buildAnalysisGlassCard({
  required AppThemeData theme,
  required Widget child,
}) {
  final isDark = theme.isDark;
  final bgAlpha = isDark ? 0.08 : 0.12;
  final borderAlpha = isDark ? 0.20 : 0.30;

  return ClipRRect(
    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(
            color: theme.surfaceColor.withValues(alpha: borderAlpha),
            width: 1,
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// 「label: value」数据行。
Widget buildAnalysisDataRow(
  BuildContext context,
  String label,
  String value,
  AppThemeData theme,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: context.bodySmall.copyWith(fontSize: 13)),
        Expanded(
          child: Text(value, style: context.bodyMedium.copyWith(fontSize: 13)),
        ),
      ],
    ),
  );
}
