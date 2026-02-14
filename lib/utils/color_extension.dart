import 'package:flutter/material.dart';

/// Color 扩展方法，提供更方便的透明度设置
extension ColorExtension on Color {
  /// 设置透明度（0.0-1.0）
  /// 替代已弃用的 withOpacity 方法
  Color withAlpha(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}
