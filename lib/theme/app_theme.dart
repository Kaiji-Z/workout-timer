import 'package:flutter/material.dart';

/// 主题类型枚举
enum AppThemeType {
  neonTempus,
  arcticFlow,
  electricPulse,
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
  final bool isDark;

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
    required this.isDark,
  });

  /// 转换为 Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: warningColor,
        onPrimary: isDark ? backgroundColor : Colors.white,
        onSecondary: isDark ? backgroundColor : Colors.white,
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
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? backgroundColor : Colors.white,
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

/// 主题 1: Neon Tempus v2 - 深色科技风格
const neonTempusTheme = AppThemeData(
  name: 'neonTempus',
  nameZh: 'Neon Tempus',
  description: '深色科技风格',
  icon: Icons.brightness_2_rounded,
  backgroundColor: Color(0xFF0a0a12),
  surfaceColor: Color(0xFF15151F),
  primaryColor: Color(0xFF00f0ff),
  secondaryColor: Color(0xFFbf00ff),
  accentColor: Color(0xFFff00aa),
  successColor: Color(0xFF00ff88),
  warningColor: Color(0xFFff00aa),
  textColor: Color(0xFFFFFFFF),
  secondaryTextColor: Color(0xFFb0b0c0),
  borderColor: Color(0x14ffffff),
  timerGradientColors: [
    Color(0xFF00f0ff),
    Color(0xFFbf00ff),
    Color(0xFFff00aa),
  ],
  isDark: true,
);

/// 主题 2: Arctic Flow - 浅色纯净风格
const arcticFlowTheme = AppThemeData(
  name: 'arcticFlow',
  nameZh: 'Arctic Flow',
  description: '浅色纯净风格',
  icon: Icons.ac_unit_rounded,
  backgroundColor: Color(0xFFF5F5F7),
  surfaceColor: Color(0xFFFFFFFF),
  primaryColor: Color(0xFF007AFF),
  secondaryColor: Color(0xFF34C759),
  accentColor: Color(0xFF5856D6),
  successColor: Color(0xFF34C759),
  warningColor: Color(0xFFFF9500),
  textColor: Color(0xFF1C1C1E),
  secondaryTextColor: Color(0xFF8E8E93),
  borderColor: Color(0xFFE5E5EA),
  timerGradientColors: [
    Color(0xFF007AFF),
    Color(0xFF5AC8FA),
    Color(0xFF34C759),
  ],
  isDark: false,
);

/// 主题 3: Electric Pulse - 深色能量风格
const electricPulseTheme = AppThemeData(
  name: 'electricPulse',
  nameZh: 'Electric Pulse',
  description: '深色能量风格',
  icon: Icons.flash_on_rounded,
  backgroundColor: Color(0xFF121212),
  surfaceColor: Color(0xFF1E1E1E),
  primaryColor: Color(0xFFFF6F20),
  secondaryColor: Color(0xFFFF4500),
  accentColor: Color(0xFFFFB300),
  successColor: Color(0xFF00C853),
  warningColor: Color(0xFFFFB300),
  textColor: Color(0xFFFAFAFA),
  secondaryTextColor: Color(0xFF9E9E9E),
  borderColor: Color(0xFF2D2D2D),
  timerGradientColors: [
    Color(0xFFFF6F20),
    Color(0xFFFF4500),
    Color(0xFFFFB300),
  ],
  isDark: true,
);

/// 获取主题数据
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.neonTempus:
      return neonTempusTheme;
    case AppThemeType.arcticFlow:
      return arcticFlowTheme;
    case AppThemeType.electricPulse:
      return electricPulseTheme;
  }
}

/// 所有主题列表
const allThemes = [
  neonTempusTheme,
  arcticFlowTheme,
  electricPulseTheme,
];
