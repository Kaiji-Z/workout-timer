import 'package:flutter/material.dart';

/// 主题类型枚举 - iPhone 5c 色彩系列
enum AppThemeType {
  iphone5cBlue,
  iphone5cGreen,
  iphone5cYellow,
  iphone5cPink,
  iphone5cWhite,
}

/// 主题数据模型
class AppThemeData {
  final String name;
  final String nameZh;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final List<Color> timerGradientColors;
  final List<Color> decorativeCircleColors; // 装饰圆形颜色（半透明）

  const AppThemeData({
    required this.name,
    required this.nameZh,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.timerGradientColors,
    required this.decorativeCircleColors,
  });

  /// 转换为 Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // iPhone 5c 风格使用浅色主题
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: warningColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return null;
        }),
      ),
      iconTheme: IconThemeData(
        color: secondaryTextColor,
      ),
      textTheme: TextTheme(
        // iOS 26 Typography - Bolder weights, left-aligned
        displayLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: -0.1,
        ),
        bodySmall: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          letterSpacing: 0,
        ),
        labelSmall: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ============================================================================
// iPhone 5c Theme Series
// ============================================================================

/// Theme: iPhone 5c Blue - iPhone XR Blue inspired
/// 清新蓝色风格 - 统一的蓝色系色彩语言
const iphone5cBlueTheme = AppThemeData(
  name: 'iphone5cBlue',
  nameZh: 'iPhone Blue',
  description: '清新蓝色风格',
  icon: Icons.phone_iphone,
  // Background - very light blue tint
  backgroundColor: Color(0xFFF0F8FF),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - iPhone XR Blue
  primaryColor: Color(0xFF48AEE6),
  // Secondary - lighter blue
  secondaryColor: Color(0xFF7CC4F0),
  // Accent - deeper blue
  accentColor: Color(0xFF2196F3),
  // Success - teal green
  successColor: Color(0xFF4CAF50),
  // Warning - amber
  warningColor: Color(0xFFFFC107),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - blue tones
  timerGradientColors: [
    Color(0xFF48AEE6),
    Color(0xFF2196F3),
  ],
  // Decorative circles - semi-transparent blue
  decorativeCircleColors: [
    Color(0x3348AEE6), // 20% opacity
    Color(0x2248AEE6), // 13% opacity
    Color(0x1148AEE6), // 7% opacity
  ],
);

/// Theme: iPhone 5c Green - iPhone 11 Green inspired
/// 清新绿色风格 - 统一的绿色系色彩语言
const iphone5cGreenTheme = AppThemeData(
  name: 'iphone5cGreen',
  nameZh: 'iPhone Green',
  description: '清新绿色风格',
  icon: Icons.eco_rounded,
  // Background - very light green tint
  backgroundColor: Color(0xFFF0FFF4),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - iPhone 11 Green
  primaryColor: Color(0xFFAEE1CD),
  // Secondary - lighter green
  secondaryColor: Color(0xFFC8EBD9),
  // Accent - deeper green
  accentColor: Color(0xFF66BB6A),
  // Success - green
  successColor: Color(0xFF4CAF50),
  // Warning - amber
  warningColor: Color(0xFFFFC107),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - green tones
  timerGradientColors: [
    Color(0xFFAEE1CD),
    Color(0xFF66BB6A),
  ],
  // Decorative circles - semi-transparent green
  decorativeCircleColors: [
    Color(0x33AEE1CD),
    Color(0x22AEE1CD),
    Color(0x11AEE1CD),
  ],
);

/// Theme: iPhone 5c Yellow - iPhone 11 Yellow inspired
/// 明亮黄色风格 - 统一的黄色系色彩语言
const iphone5cYellowTheme = AppThemeData(
  name: 'iphone5cYellow',
  nameZh: 'iPhone Yellow',
  description: '明亮黄色风格',
  icon: Icons.wb_sunny_rounded,
  // Background - very light yellow tint
  backgroundColor: Color(0xFFFFFEF5),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - iPhone 11 Yellow
  primaryColor: Color(0xFFFFE681),
  // Secondary - lighter yellow
  secondaryColor: Color(0xFFFFF0A3),
  // Accent - deeper yellow/amber
  accentColor: Color(0xFFFFB300),
  // Success - green
  successColor: Color(0xFF4CAF50),
  // Warning - darker amber
  warningColor: Color(0xFFFF8F00),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - yellow tones
  timerGradientColors: [
    Color(0xFFFFE681),
    Color(0xFFFFB300),
  ],
  // Decorative circles - semi-transparent yellow
  decorativeCircleColors: [
    Color(0x33FFE681),
    Color(0x22FFE681),
    Color(0x11FFE681),
  ],
);

/// Theme: iPhone 5c Pink - iPhone XR Coral inspired
/// 活力粉色风格 - 统一的粉色系色彩语言
const iphone5cPinkTheme = AppThemeData(
  name: 'iphone5cPink',
  nameZh: 'iPhone Pink',
  description: '活力粉色风格',
  icon: Icons.favorite_rounded,
  // Background - very light pink tint
  backgroundColor: Color(0xFFFFF5F3),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - iPhone XR Coral
  primaryColor: Color(0xFFFF6E5A),
  // Secondary - lighter coral
  secondaryColor: Color(0xFFFF8A7A),
  // Accent - deeper pink
  accentColor: Color(0xFFE91E63),
  // Success - green
  successColor: Color(0xFF4CAF50),
  // Warning - amber
  warningColor: Color(0xFFFFC107),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - pink tones
  timerGradientColors: [
    Color(0xFFFF6E5A),
    Color(0xFFE91E63),
  ],
  // Decorative circles - semi-transparent pink
  decorativeCircleColors: [
    Color(0x33FF6E5A),
    Color(0x22FF6E5A),
    Color(0x11FF6E5A),
  ],
);

/// Theme: iPhone 5c White - Clean minimal style
/// 纯净白色风格 - 极简设计，深灰色为主色
const iphone5cWhiteTheme = AppThemeData(
  name: 'iphone5cWhite',
  nameZh: 'iPhone White',
  description: '纯净白色风格',
  icon: Icons.phone_iphone,
  // Background - light gray
  backgroundColor: Color(0xFFF3F3F3),
  // Surface - white for contrast
  surfaceColor: Color(0xFFFFFFFF),
  // Primary - dark gray for contrast on white
  primaryColor: Color(0xFF333333),
  // Secondary - medium gray
  secondaryColor: Color(0xFF666666),
  // Accent - iOS blue
  accentColor: Color(0xFF007AFF),
  // Success - green
  successColor: Color(0xFF4CAF50),
  // Warning - amber
  warningColor: Color(0xFFFFC107),
  // Text - dark for light background
  textColor: Color(0xFF1A1A1A),
  secondaryTextColor: Color(0xFF666666),
  borderColor: Color(0xFFE0E0E0),
  // Timer gradient - gray to blue
  timerGradientColors: [
    Color(0xFF333333),
    Color(0xFF007AFF),
  ],
  // Decorative circles - semi-transparent gray
  decorativeCircleColors: [
    Color(0x22333333),
    Color(0x11333333),
    Color(0x08333333),
  ],
);

/// 获取主题数据
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.iphone5cBlue:
      return iphone5cBlueTheme;
    case AppThemeType.iphone5cGreen:
      return iphone5cGreenTheme;
    case AppThemeType.iphone5cYellow:
      return iphone5cYellowTheme;
    case AppThemeType.iphone5cPink:
      return iphone5cPinkTheme;
    case AppThemeType.iphone5cWhite:
      return iphone5cWhiteTheme;
  }
}

/// 所有主题列表
const allThemes = [
  iphone5cWhiteTheme,   // Default - neutral choice
  iphone5cBlueTheme,
  iphone5cGreenTheme,
  iphone5cYellowTheme,
  iphone5cPinkTheme,
];
