import 'package:flutter/material.dart';

/// 统一尺寸规范 - Flat Vitality 设计系统
class AppDimensions {
  AppDimensions._();

  // 导航栏
  static const double navBarHeight = 70.0;
  static const double navBarBottomMargin = 16.0;
  static const double navBarTotalHeight = 86.0;
  static const double navBarRadius = 25.0;
  static const double navCenterButtonSize = 70.0;

  /// 计算底部留白（导航栏 + 系统安全区）
  static double bottomPadding(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + navBarTotalHeight;

  // 圆角
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusSheet = 24.0;

  // 间距
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;
  static const double spacingXxxl = 48.0;

  // 触摸目标
  static const double minTouchTarget = 44.0;

  // 计时器尺寸（响应式基准）
  static double timerSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.6).clamp(200.0, 320.0);
  }

  static double timerSmallSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth * 0.18).clamp(60.0, 90.0);
  }
}
