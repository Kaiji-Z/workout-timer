import 'package:flutter/material.dart';

/// 主题类型枚举
enum AppThemeType {
  vitalFlow,
  neonTempus,
  arcticFlow,
  electricPulse,
  oceanFlow,
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

/// 主题 1: VitalFlow - 清新健康风格 (推荐)
/// 基于现代健康应用设计趋势 - 简约、清新、和谐
/// 主色调: 青绿色系 (Teal) - 传达健康、活力、现代感
const vitalFlowTheme = AppThemeData(
  name: 'vitalFlow',
  nameZh: 'VitalFlow',
  description: '清新健康风格',
  icon: Icons.eco_rounded,
  // 背景色 - 深青色 (配合模糊背景图)
  backgroundColor: Color(0xFF1A3A3A),
  // 卡片背景 - 毛玻璃效果白色
  surfaceColor: Color(0xE6FFFFFF), // 90% white
  // 主色调 - 清新青绿 (Fresh Teal)
  primaryColor: Color(0xFF4DB6AC),
  // 辅助色 - 浅青绿
  secondaryColor: Color(0xFF80CBC4),
  // 强调色 - 珊瑚橙 (能量感)
  accentColor: Color(0xFFFF8A65),
  // 成功色 - 活力绿
  successColor: Color(0xFF66BB6A),
  // 警告色 - 暖琥珀
  warningColor: Color(0xFFFFA726),
  // 文字色 - 深色 (在毛玻璃上)
  textColor: Color(0xFF263238),
  secondaryTextColor: Color(0xFF546E7A),
  borderColor: Color(0x33FFFFFF), // rgba(255,255,255,0.2)
  // 渐变色 - 青绿渐变
  timerGradientColors: [
    Color(0xFF4DB6AC),
    Color(0xFF26A69A),
  ],
  isDark: true,
);

/// 主题 2: Neon Tempus - 深色科技风格
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

/// 主题 3: Arctic Flow - 浅色纯净风格
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

/// 主题 4: Electric Pulse - 深色能量风格
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

/// 主题 5: Ocean Flow - 浅色极简风格 (新增)
/// 基于蓝色邻近色系 - 传达专业、信任、现代感
const oceanFlowTheme = AppThemeData(
  name: 'oceanFlow',
  nameZh: 'Ocean Flow',
  description: '浅色极简风格',
  icon: Icons.water_drop_rounded,
  // 背景色 - 极浅灰白
  backgroundColor: Color(0xFFFAFBFC),
  // 卡片背景 - 纯白
  surfaceColor: Color(0xFFFFFFFF),
  // 主色调 - 深海蓝
  primaryColor: Color(0xFF0066CC),
  // 次要色 - 天际青
  secondaryColor: Color(0xFF00A8B5),
  // 强调色 - 绿松石
  accentColor: Color(0xFF00C9B7),
  // 成功色 - 翡翠绿
  successColor: Color(0xFF10B981),
  // 警告色 - 琥珀黄
  warningColor: Color(0xFFF59E0B),
  // 文字色 - 深蓝灰
  textColor: Color(0xFF1A2B3C),
  secondaryTextColor: Color(0xFF6B7280),
  borderColor: Color(0xFFE5E7EB),
  // 渐变色 - 蓝色邻近色渐变
  timerGradientColors: [
    Color(0xFF0066CC),
    Color(0xFF00A8B5),
    Color(0xFF00C9B7),
  ],
  isDark: false,
);

/// 获取主题数据
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.vitalFlow:
      return vitalFlowTheme;
    case AppThemeType.neonTempus:
      return neonTempusTheme;
    case AppThemeType.arcticFlow:
      return arcticFlowTheme;
    case AppThemeType.electricPulse:
      return electricPulseTheme;
    case AppThemeType.oceanFlow:
      return oceanFlowTheme;
  }
}

/// 所有主题列表
const allThemes = [
  oceanFlowTheme,     // 新默认主题
  vitalFlowTheme,     // 原默认主题
  neonTempusTheme,    // 旧版
  arcticFlowTheme,    // 旧版
  electricPulseTheme, // 旧版
];
