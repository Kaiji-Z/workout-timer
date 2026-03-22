import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_preferences_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();
  
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;

  // Options for each section
  static const List<Map<String, String>> _goalOptions = [
    {'value': 'muscle_building', 'label': '增肌'},
    {'value': 'fat_loss', 'label': '减脂'},
    {'value': 'strength', 'label': '力量'},
    {'value': 'endurance', 'label': '耐力'},
  ];

  static const List<Map<String, String>> _experienceOptions = [
    {'value': 'beginner', 'label': '初学者'},
    {'value': 'intermediate', 'label': '中级'},
    {'value': 'advanced', 'label': '高级'},
  ];

  static const List<Map<String, String>> _equipmentOptions = [
    {'value': 'gym', 'label': '健身房'},
    {'value': 'home_dumbbell', 'label': '家用哑铃'},
    {'value': 'bodyweight', 'label': '徒手'},
  ];

  static const List<Map<String, dynamic>> _frequencyOptions = [
    {'value': 3, 'label': '3天'},
    {'value': 4, 'label': '4天'},
    {'value': 5, 'label': '5天'},
    {'value': 6, 'label': '6天'},
  ];

  static const List<Map<String, String>> _focusAreaOptions = [
    {'value': 'chest', 'label': '胸部'},
    {'value': 'back', 'label': '背部'},
    {'value': 'shoulders', 'label': '肩部'},
    {'value': 'arms', 'label': '手臂'},
    {'value': 'legs', 'label': '腿部'},
    {'value': 'core', 'label': '核心'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _preferencesService.loadPreferences();
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    await _preferencesService.savePreferences(_preferences);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('偏好已保存'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _updateGoal(String goal) {
    setState(() {
      _preferences = _preferences.copyWith(goal: goal);
    });
    _savePreferences();
  }

  void _updateExperience(String experience) {
    setState(() {
      _preferences = _preferences.copyWith(experience: experience);
    });
    _savePreferences();
  }

  void _updateEquipment(String equipment) {
    setState(() {
      _preferences = _preferences.copyWith(equipment: equipment);
    });
    _savePreferences();
  }

  void _updateFrequency(int frequency) {
    setState(() {
      _preferences = _preferences.copyWith(frequency: frequency);
    });
    _savePreferences();
  }

  void _updateFocusAreas(List<String> focusAreas) {
    setState(() {
      _preferences = _preferences.copyWith(focusAreas: focusAreas.join(','));
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.timerGradientColors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '训练偏好',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Training Goal
                  _buildSectionHeader('训练目标', theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalOptions.map((option) {
                          final isSelected = _preferences.goal == option['value'];
                          return _buildSelectionChip(
                            label: option['label'] ?? '',
                            isSelected: isSelected,
                            onTap: () => _updateGoal(option['value'] ?? ''),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Experience Level
                  _buildSectionHeader('经验水平', theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _experienceOptions.map((option) {
                          final isSelected = _preferences.experience == option['value'];
                          return _buildSelectionChip(
                            label: option['label'] ?? '',
                            isSelected: isSelected,
                            onTap: () => _updateExperience(option['value'] ?? ''),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Available Equipment
                  _buildSectionHeader('可用设备', theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _equipmentOptions.map((option) {
                          final isSelected = _preferences.equipment == option['value'];
                          return _buildSelectionChip(
                            label: option['label'] ?? '',
                            isSelected: isSelected,
                            onTap: () => _updateEquipment(option['value'] ?? ''),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Weekly Frequency
                  _buildSectionHeader('每周频率', theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _frequencyOptions.map((option) {
                          final isSelected = _preferences.frequency == option['value'];
                          return _buildSelectionChip(
                            label: option['label'] ?? '',
                            isSelected: isSelected,
                            onTap: () => _updateFrequency(option['value'] as int),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 5: Focus Areas (Multi-select)
                  _buildSectionHeader('重点部位', theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _focusAreaOptions.map((option) {
                          final value = option['value'] ?? '';
                          final isSelected = _preferences.focusAreasList.contains(value);
                          return _buildFilterChip(
                            label: option['label'] ?? '',
                            isSelected: isSelected,
                            onTap: () {
                              final currentAreas = _preferences.focusAreasList.toList();
                              if (isSelected) {
                                currentAreas.remove(value);
                              } else {
                                currentAreas.add(value);
                              }
                              _updateFocusAreas(currentAreas);
                            },
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: '.SF Pro Text',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.secondaryTextColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required AppThemeData theme,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor
              : theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : theme.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor.withValues(alpha: 0.15)
              : theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.5)
                : theme.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 16,
                color: theme.accentColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
