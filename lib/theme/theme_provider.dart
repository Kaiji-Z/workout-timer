import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// 主题状态管理 Provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppThemeType _currentThemeType = AppThemeType.neonTempus;
  AppThemeData _currentTheme = neonTempusTheme;
  
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
      case AppThemeType.neonTempus:
        return 'neonTempus';
      case AppThemeType.arcticFlow:
        return 'arcticFlow';
      case AppThemeType.electricPulse:
        return 'electricPulse';
    }
  }
  
  /// 主题名称转类型
  AppThemeType _themeNameToType(String name) {
    switch (name) {
      case 'arcticFlow':
        return AppThemeType.arcticFlow;
      case 'electricPulse':
        return AppThemeType.electricPulse;
      case 'neonTempus':
      default:
        return AppThemeType.neonTempus;
    }
  }
}
