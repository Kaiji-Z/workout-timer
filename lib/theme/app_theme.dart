import 'package:flutter/material.dart';

/// 主题类型枚举 - Flat Vitality 设计系统
enum AppThemeType {
  amberGold,
  coralOrange,
  mintGreen,
  rosePink,
  skyBlue,
}

/// 主题数据模型
/// Flat Vitality 设计系统 - 完全基于参考图
/// 
/// 设计原则:
/// - 温暖纯色/渐变背景 (琥珀/橙色系)
/// - 深蓝色强调色 (#1A237E) - 粗进度环
/// - 白色圆形按钮 + 深色图标
/// - 扁平设计，无发光、无玻璃效果
/// - 8-10px 粗线条进度环
class AppThemeData {
  final String name;
  final String nameZh;
  final String description;
  final IconData icon;
  
  // 核心颜色
  final Color primaryColor;      // 背景色
  final Color secondaryColor;    // 渐变结束色
  final Color accentColor;       // 深蓝色强调色 (进度环、图标)
  
  // 表面
  final Color surfaceColor;      // 卡片背景 (白色)
  final Color cardColor;         // 按钮背景 (白色)
  
  // 文字
  final Color textColor;
  final Color secondaryTextColor;
  
  // 进度环
  final Color progressRingColor; // 进度环颜色 (深蓝)
  final Color progressBgColor;   // 进度环背景 (浅色)
  final double progressStrokeWidth; // 进度环线条粗细
  
  // 装饰
  final List<Color> decorativeCircleColors;

  const AppThemeData({
    required this.name,
    required this.nameZh,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.progressRingColor,
    required this.progressBgColor,
    this.progressStrokeWidth = 10.0,
    required this.decorativeCircleColors,
  });

  // 兼容性 getter
  Color get backgroundColor => primaryColor;
  Color get backgroundGradientEnd => secondaryColor;
  Color get borderColor => progressRingColor.withValues(alpha: 0.3);
  List<Color> get timerGradientColors => [progressRingColor, progressRingColor.withValues(alpha: 0.7)];

  /// 转换为 Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: const Color(0xFFE53935),
        onPrimary: textColor,
        onSecondary: Colors.white,
        onSurface: textColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          foregroundColor: accentColor,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      iconTheme: IconThemeData(
        color: accentColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodySmall: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
        ),
        labelLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

// ============================================================================
// Flat Vitality Theme Series - 参考图精确风格
// 
// 核心设计规范:
// - 背景: 温暖渐变 (琥珀/橙色系)
// - 进度环: 深靛蓝 #1A237E, 10px粗线条
// - 按钮: 白色圆形 (#FFFFFF) + 深色图标
// - 文字: 深色 (#212121)
// - 扁平设计: 无发光、无玻璃效果
// ============================================================================

/// 统一强调色 - 深靛蓝色 (参考图核心颜色)
const Color _kProgressRingColor = Color(0xFF1A237E); // Indigo 900

/// Theme: Amber Gold (参考图主色)
/// 温暖的琥珀金色 - 深蓝强调
const amberGoldTheme = AppThemeData(
  name: 'amberGold',
  nameZh: '琥珀金',
  description: '温暖明亮',
  icon: Icons.wb_sunny_rounded,
  // Background - 琥珀金渐变
  primaryColor: Color(0xFFFFB74D),
  secondaryColor: Color(0xFFFFA726),
  // Accent - 深靛蓝
  accentColor: _kProgressRingColor,
  // Surface
  surfaceColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFFFFFFF),
  // Text
  textColor: Color(0xFF212121),
  secondaryTextColor: Color(0xFF757575),
  // Progress ring
  progressRingColor: _kProgressRingColor,
  progressBgColor: Color(0x33FFFFFF),
  progressStrokeWidth: 10.0,
  // Decorative
  decorativeCircleColors: [
    Color(0x40FFFFFF),
    Color(0x30FFFFFF),
    Color(0x20FFFFFF),
  ],
);

/// Theme: Coral Orange
/// 珊瑚橙色 - 深蓝强调
const coralOrangeTheme = AppThemeData(
  name: 'coralOrange',
  nameZh: '珊瑚橙',
  description: '热情活力',
  icon: Icons.local_fire_department_rounded,
  // Background
  primaryColor: Color(0xFFFF8A65),
  secondaryColor: Color(0xFFFF7043),
  // Accent
  accentColor: _kProgressRingColor,
  // Surface
  surfaceColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFFFFFFF),
  // Text
  textColor: Color(0xFF212121),
  secondaryTextColor: Color(0xFF757575),
  // Progress
  progressRingColor: _kProgressRingColor,
  progressBgColor: Color(0x33FFFFFF),
  progressStrokeWidth: 10.0,
  // Decorative
  decorativeCircleColors: [
    Color(0x40FFFFFF),
    Color(0x30FFFFFF),
    Color(0x20FFFFFF),
  ],
);

/// Theme: Mint Green
/// 薄荷绿 - 深蓝强调
const mintGreenTheme = AppThemeData(
  name: 'mintGreen',
  nameZh: '薄荷绿',
  description: '清新自然',
  icon: Icons.eco_rounded,
  // Background
  primaryColor: Color(0xFF81C784),
  secondaryColor: Color(0xFF66BB6A),
  // Accent
  accentColor: _kProgressRingColor,
  // Surface
  surfaceColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFFFFFFF),
  // Text
  textColor: Color(0xFF212121),
  secondaryTextColor: Color(0xFF757575),
  // Progress
  progressRingColor: _kProgressRingColor,
  progressBgColor: Color(0x33FFFFFF),
  progressStrokeWidth: 10.0,
  // Decorative
  decorativeCircleColors: [
    Color(0x40FFFFFF),
    Color(0x30FFFFFF),
    Color(0x20FFFFFF),
  ],
);

/// Theme: Rose Pink
/// 玫瑰粉 - 深蓝强调
const rosePinkTheme = AppThemeData(
  name: 'rosePink',
  nameZh: '玫瑰粉',
  description: '甜美活力',
  icon: Icons.favorite_rounded,
  // Background
  primaryColor: Color(0xFFF48FB1),
  secondaryColor: Color(0xFFEC407A),
  // Accent
  accentColor: _kProgressRingColor,
  // Surface
  surfaceColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFFFFFFF),
  // Text
  textColor: Color(0xFF212121),
  secondaryTextColor: Color(0xFF757575),
  // Progress
  progressRingColor: _kProgressRingColor,
  progressBgColor: Color(0x33FFFFFF),
  progressStrokeWidth: 10.0,
  // Decorative
  decorativeCircleColors: [
    Color(0x40FFFFFF),
    Color(0x30FFFFFF),
    Color(0x20FFFFFF),
  ],
);

/// Theme: Sky Blue
/// 天空蓝 - 更深的蓝强调
const skyBlueTheme = AppThemeData(
  name: 'skyBlue',
  nameZh: '天空蓝',
  description: '清新宁静',
  icon: Icons.water_drop_rounded,
  // Background
  primaryColor: Color(0xFF64B5F6),
  secondaryColor: Color(0xFF42A5F5),
  // Accent - 稍微深一点的蓝
  accentColor: Color(0xFF0D47A1),
  // Surface
  surfaceColor: Color(0xFFFFFFFF),
  cardColor: Color(0xFFFFFFFF),
  // Text
  textColor: Color(0xFF212121),
  secondaryTextColor: Color(0xFF757575),
  // Progress
  progressRingColor: Color(0xFF0D47A1),
  progressBgColor: Color(0x33FFFFFF),
  progressStrokeWidth: 10.0,
  // Decorative
  decorativeCircleColors: [
    Color(0x40FFFFFF),
    Color(0x30FFFFFF),
    Color(0x20FFFFFF),
  ],
);

/// 获取主题数据
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.amberGold:
      return amberGoldTheme;
    case AppThemeType.coralOrange:
      return coralOrangeTheme;
    case AppThemeType.mintGreen:
      return mintGreenTheme;
    case AppThemeType.rosePink:
      return rosePinkTheme;
    case AppThemeType.skyBlue:
      return skyBlueTheme;
  }
}

/// 所有主题列表
const allThemes = [
  amberGoldTheme,  // Default - 参考图风格
  coralOrangeTheme,
  mintGreenTheme,
  rosePinkTheme,
  skyBlueTheme,
];
