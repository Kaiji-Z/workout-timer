import 'package:flutter/material.dart';

/// 主题类型枚举 - Flat Vitality 设计系统
enum AppThemeType { amberGold, coralOrange, mintGreen, rosePink, skyBlue }

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
  final Color primaryColor; // 背景色
  final Color secondaryColor; // 渐变结束色
  final Color accentColor; // 深蓝色强调色 (进度环、图标)

  // 表面
  final Color surfaceColor; // 卡片背景 (白色)
  final Color cardColor; // 按钮背景 (白色)

  // 文字
  final Color textColor;
  final Color secondaryTextColor;

  // 进度环
  final Color progressRingColor; // 进度环颜色 (深蓝)
  final Color progressBgColor; // 进度环背景 (浅色)
  final double progressStrokeWidth; // 进度环线条粗细

  // 装饰
  final List<Color> decorativeCircleColors;

  // 语义色
  final Color errorColor; // 错误/危险
  final Color successColor; // 成功
  final Color errorBackgroundColor; // 错误背景
  final Color dividerColor; // 分割线

  // 表面层级系统 (3-tier depth system)
  final Color surfaceColorRaised; // Level 1: raised cards, list items
  final Color surfaceColorOverlay; // Level 2: dialogs, bottom sheets, floating
  final Color scrimColor; // Modal scrim/overlay

  // 扩展语义色
  final Color warningColor; // 警告状态 (amber)
  final Color infoColor; // 信息状态 (blue)

  // 高亮色 - pressed/active 状态
  final Color highlightColor; // Subtle accent tint for pressed states

  /// Whether this theme is a dark variant.
  /// Replaces fragile `surfaceColor == Color(0xFF1E1E2E)` checks.
  final bool isDark;

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
    this.errorColor = const Color(0xFFE53935),
    this.successColor = const Color(0xFF4CAF50),
    this.errorBackgroundColor = const Color(0xFFF5E6E6),
    this.dividerColor = const Color(0xFFE0E0E0),
    required this.surfaceColorRaised,
    required this.surfaceColorOverlay,
    required this.scrimColor,
    this.warningColor = const Color(0xFFFF9800),
    this.infoColor = const Color(0xFF2196F3),
    this.highlightColor = const Color(0x1A1A237E), // accentColor at ~10% alpha
    this.isDark = false,
  });

  // ── Design-system convenience getters ──────────────────────────────────
  /// Color painted ON TOP of accentColor (icons/text inside accent buttons).
  /// Always white — the deep indigo accent is dark enough in both modes.
  Color get onAccentColor => Colors.white;

  /// Soft shadow color for cards and floating elements.
  Color get shadowColor => textColor.withValues(alpha: 0.12);

  /// Drag-handle / chip background color (derived from divider).
  Color get dragHandleColor => dividerColor;

  // 兼容性 getter
  Color get backgroundColor => primaryColor;
  Color get backgroundGradientEnd => secondaryColor;
  Color get borderColor => progressRingColor.withValues(alpha: 0.3);
  List<Color> get timerGradientColors => [
    progressRingColor,
    progressRingColor.withValues(alpha: 0.7),
  ];

  /// 生成深色模式变体
  /// 保持原有色调，调整亮度和对比度以适应深色背景
  AppThemeData get dark {
    // 从主色提取色相，保持主题特色
    final hsl = HSLColor.fromColor(primaryColor);
    final hue = hsl.hue;

    // 深色背景：保持色相，大幅降低亮度，适当降低饱和度
    final darkPrimary = HSLColor.fromAHSL(1.0, hue, 0.25, 0.12).toColor();
    final darkSecondary = HSLColor.fromAHSL(1.0, hue, 0.30, 0.15).toColor();

    return AppThemeData(
      name: name,
      nameZh: nameZh,
      description: description,
      icon: icon,
      // 深色背景 - 保持原有色调
      primaryColor: darkPrimary,
      secondaryColor: darkSecondary,
      // 强调色 - 浅化靛蓝以确保 WCAG 对比度 (#1A237E 在深色背景上约 1.1:1 失败)
      accentColor: const Color(0xFF7986CB), // Indigo 300 — text/icons on dark
      // 表面颜色 - 中性深色（不使用主题色调，保持卡片可读性）
      surfaceColor: const Color(0xFF1E1E2E),
      cardColor: const Color(0xFF2A2A3C),
      // 文字颜色 - 浅色
      textColor: const Color(0xFFE8E8E8),
      secondaryTextColor: const Color(0xFF9E9E9E),
      // 进度环 - 使用更鲜艳的 Indigo Accent 400 以保证可见度
      progressRingColor: const Color(0xFF536DFE),
      progressBgColor: const Color(0x40FFFFFF),
      progressStrokeWidth: progressStrokeWidth,
      // 装饰圆圈 - 保持白色半透明
      decorativeCircleColors: decorativeCircleColors,
      // 语义色 - 深色背景下使用更亮的颜色
      errorColor: const Color(0xFFEF5350),
      successColor: const Color(0xFF66BB6A),
      errorBackgroundColor: const Color(0xFF3E2723),
      dividerColor: const Color(0xFF3A3A4A),
      // 表面层级系统 - 深色模式
      surfaceColorRaised: const Color(0xFF2A2A3C), // 原 cardColor 值
      surfaceColorOverlay: const Color(0xFF33334A), // 更亮的层级用于对话框
      scrimColor: const Color(0xB0000000), // 更不透明的 scrim 用于深色
      // 扩展语义色 - 深色背景下使用更亮的颜色
      warningColor: const Color(0xFFFFB74D), // 更浅的琥珀
      infoColor: const Color(0xFF64B5F6), // 更浅的蓝
      highlightColor: const Color(0x337986CB), // 更浅的强调色调
      isDark: true,
    );
  }

  /// 转换为 Flutter ThemeData
  ThemeData toThemeData() {
    // Use the explicit isDark field instead of fragile color comparison
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          // NOTE: 不再在全局主题硬设 foregroundColor。项目里所有 ElevatedButton
          // 都是"深靛蓝底 + 白字"的主操作按钮,各自通过 styleFrom(foregroundColor)
          // 控制;全局这里硬设 accentColor 会在 M3 下与局部 style 的 label 文字色
          // 冲突,导致白字按钮渲染成深色文字不可读(见 set_record_dialog /
          // exercise_selection 等多处)。移除后局部 style 正常生效。
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
      iconTheme: IconThemeData(color: accentColor),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displayMedium: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displaySmall: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineLarge: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
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
          fontFeatures: const [FontFeature.tabularFigures()],
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
  // Surface hierarchy (3-tier depth system)
  surfaceColorRaised: Color(0xFFF5F5F5),
  surfaceColorOverlay: Color(0xFFFFFFFF),
  scrimColor: Color(0x80000000),
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
  // Surface hierarchy (3-tier depth system)
  surfaceColorRaised: Color(0xFFF5F5F5),
  surfaceColorOverlay: Color(0xFFFFFFFF),
  scrimColor: Color(0x80000000),
);

// NOTE: mintGreen and rosePink themes were removed (reduced from 5 to 3).
// Users who had these selected are auto-mapped via theme_provider.dart:
//   mintGreen → amberGold, rosePink → coralOrange

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
  // Surface hierarchy (3-tier depth system)
  surfaceColorRaised: Color(0xFFF5F5F5),
  surfaceColorOverlay: Color(0xFFFFFFFF),
  scrimColor: Color(0x80000000),
);

/// 获取主题数据
AppThemeData getThemeData(AppThemeType type) {
  switch (type) {
    case AppThemeType.amberGold:
      return amberGoldTheme;
    case AppThemeType.coralOrange:
      return coralOrangeTheme;
    case AppThemeType.mintGreen:
      return amberGoldTheme; // Legacy: mintGreen mapped to amberGold
    case AppThemeType.rosePink:
      return coralOrangeTheme; // Legacy: rosePink mapped to coralOrange
    case AppThemeType.skyBlue:
      return skyBlueTheme;
  }
}

/// 所有主题列表
const allThemes = [
  amberGoldTheme, // Default - 参考图风格
  coralOrangeTheme,
  skyBlueTheme,
];

/// Okabe-Ito colorblind-safe palette for data visualization
///
/// 适用于色盲用户的图表配色方案 (Okabe-Ito 2008)。
/// 涵盖 7 种高对比度颜色，对红绿色盲、蓝黄色盲均友好。
class ChartPalette {
  ChartPalette._();

  static const List<Color> colors = [
    Color(0xFFE69F00), // orange
    Color(0xFF56B4E9), // sky blue
    Color(0xFF009E73), // bluish green
    Color(0xFFF0E442), // yellow
    Color(0xFF0072B2), // blue
    Color(0xFFD55E00), // vermilion
    Color(0xFFCC79A7), // reddish purple
  ];

  /// 按索引获取颜色（自动循环以支持任意数量的数据点）
  static Color byIndex(int index) => colors[index % colors.length];
}
