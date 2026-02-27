import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// 主题状态管理 Provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  // 默认使用琥珀金主题 (参考图风格)
  AppThemeType _currentThemeType = AppThemeType.amberGold;
  AppThemeData _currentTheme = amberGoldTheme;
  
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
      case AppThemeType.amberGold:
        return 'amberGold';
      case AppThemeType.coralOrange:
        return 'coralOrange';
      case AppThemeType.mintGreen:
        return 'mintGreen';
      case AppThemeType.rosePink:
        return 'rosePink';
      case AppThemeType.skyBlue:
        return 'skyBlue';
    }
  }
  
  /// 主题名称转类型
  AppThemeType _themeNameToType(String name) {
    switch (name) {
      case 'amberGold':
        return AppThemeType.amberGold;
      case 'coralOrange':
        return AppThemeType.coralOrange;
      case 'mintGreen':
        return AppThemeType.mintGreen;
      case 'rosePink':
        return AppThemeType.rosePink;
      case 'skyBlue':
        return AppThemeType.skyBlue;
      // Legacy theme names - map to new themes
      case 'vitalityYellow':
      case 'iphone5cYellow':
        return AppThemeType.amberGold;
      case 'vitalityOrange':
      case 'iphone5cOrange':
        return AppThemeType.coralOrange;
      case 'vitalityGreen':
      case 'iphone5cGreen':
        return AppThemeType.mintGreen;
      case 'vitalityPink':
      case 'iphone5cPink':
        return AppThemeType.rosePink;
      case 'vitalityBlue':
      case 'iphone5cBlue':
      case 'iphone5cWhite':
        return AppThemeType.skyBlue;
      case 'oceanFlow':
      case 'arcticFlow':
        return AppThemeType.skyBlue;
      case 'vitalFlow':
        return AppThemeType.mintGreen;
      case 'neonTempus':
      case 'electricPulse':
        return AppThemeType.skyBlue;
      default:
        return AppThemeType.amberGold;
    }
  }
}
