import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// 主题状态管理 Provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  // 默认使用 iPhone White 主题
  AppThemeType _currentThemeType = AppThemeType.iphone5cWhite;
  AppThemeData _currentTheme = iphone5cWhiteTheme;
  
  AppThemeType get currentThemeType => _currentThemeType;
  AppThemeData get currentTheme => _currentTheme;
  
  /// 初始化主题（从存储加载）
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);
      
      if (themeName != null) {
        _currentThemeType = _themeNameToType(themeName);
        _currentTheme = getThemeData(_currentThemeType);
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
    notifyListeners();
  }
  
  /// 切换主题
  Future<void> setTheme(AppThemeType type) async {
    if (_currentThemeType == type) return;
    
    _currentThemeType = type;
    _currentTheme = getThemeData(type);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _typeToThemeName(type));
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
    
    notifyListeners();
  }
  
  /// 主题类型转名称
  String _typeToThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.iphone5cBlue:
        return 'iphone5cBlue';
      case AppThemeType.iphone5cGreen:
        return 'iphone5cGreen';
      case AppThemeType.iphone5cYellow:
        return 'iphone5cYellow';
      case AppThemeType.iphone5cPink:
        return 'iphone5cPink';
      case AppThemeType.iphone5cWhite:
        return 'iphone5cWhite';
    }
  }
  
  /// 主题名称转类型
  AppThemeType _themeNameToType(String name) {
    switch (name) {
      case 'iphone5cWhite':
        return AppThemeType.iphone5cWhite;
      case 'iphone5cBlue':
        return AppThemeType.iphone5cBlue;
      case 'iphone5cGreen':
        return AppThemeType.iphone5cGreen;
      case 'iphone5cYellow':
        return AppThemeType.iphone5cYellow;
      case 'iphone5cPink':
        return AppThemeType.iphone5cPink;
      // Legacy theme names - map to closest new theme
      case 'oceanFlow':
      case 'arcticFlow':
        return AppThemeType.iphone5cWhite;
      case 'vitalFlow':
        return AppThemeType.iphone5cGreen;
      case 'neonTempus':
      case 'electricPulse':
        return AppThemeType.iphone5cBlue;
      default:
        return AppThemeType.iphone5cWhite;
    }
  }
}
