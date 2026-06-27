import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/user_preferences_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();

  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;
  final TextEditingController _bodyWeightController = TextEditingController();

  // Stable value keys (locale-independent). Labels are resolved at build time.
  static const List<String> _goalValues = [
    'muscle_building',
    'fat_loss',
    'strength',
    'endurance',
  ];

  static const List<String> _experienceValues = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  static const List<String> _equipmentValues = [
    'gym',
    'home_dumbbell',
    'bodyweight',
  ];

  static const List<int> _frequencyValues = [3, 4, 5, 6];

  static const List<String> _focusAreaValues = [
    'chest',
    'back',
    'shoulders',
    'arms',
    'legs',
    'core',
  ];

  // Locale-aware label resolvers.
  String _goalLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'muscle_building':
        return l10n.prefGoalMuscleBuilding;
      case 'fat_loss':
        return l10n.prefGoalFatLoss;
      case 'strength':
        return l10n.prefGoalStrength;
      case 'endurance':
        return l10n.prefGoalEndurance;
      default:
        return value;
    }
  }

  String _experienceLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'beginner':
        return l10n.prefExperienceBeginner;
      case 'intermediate':
        return l10n.prefExperienceIntermediate;
      case 'advanced':
        return l10n.prefExperienceAdvanced;
      default:
        return value;
    }
  }

  String _equipmentLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'gym':
        return l10n.prefEquipmentGym;
      case 'home_dumbbell':
        return l10n.prefEquipmentHomeDumbbell;
      case 'bodyweight':
        return l10n.prefEquipmentBodyweight;
      default:
        return value;
    }
  }

  String _focusAreaLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'chest':
        return l10n.prefFocusAreaChest;
      case 'back':
        return l10n.prefFocusAreaBack;
      case 'shoulders':
        return l10n.prefFocusAreaShoulders;
      case 'arms':
        return l10n.prefFocusAreaArms;
      case 'legs':
        return l10n.prefFocusAreaLegs;
      case 'core':
        return l10n.prefFocusAreaCore;
      default:
        return value;
    }
  }

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
        if (prefs.bodyWeight > 0) {
          _bodyWeightController.text = prefs.bodyWeight.toStringAsFixed(1);
        }
      });
    }
  }

  Future<void> _savePreferences() async {
    await _preferencesService.savePreferences(_preferences);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.prefSaved),
            duration: const Duration(seconds: 1)),
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

  void _updateBodyWeight(double weight) {
    setState(() {
      _preferences = _preferences.copyWith(bodyWeight: weight);
    });
    _savePreferences();
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.prefCloseTooltip,
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
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
              ),
            ),
            Text(
              l10n.prefTitle,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
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
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Body Weight
                  _buildSectionHeader(l10n.prefBodyWeightSection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppDimensions.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.prefBodyWeightHint,
                            style: Theme.of(context).textTheme.bodySmall!,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bodyWeightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,1}'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: l10n.prefBodyWeightPlaceholder,
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: theme.secondaryTextColor
                                              .withValues(alpha: 0.5),
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: theme.borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: theme.borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusLg,
                                      ),
                                      borderSide: BorderSide(
                                        color: theme.accentColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    suffixText: 'kg',
                                    suffixStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: theme.secondaryTextColor,
                                        ),
                                  ),
                                  style: Theme.of(context).textTheme.bodyLarge!,
                                  onChanged: (value) {
                                    final weight = double.tryParse(value);
                                    _updateBodyWeight(weight ?? 0.0);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Training Goal
                  _buildSectionHeader(l10n.prefGoalSection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalValues.map((value) {
                          final isSelected =
                              _preferences.goal == value;
                          return _buildSelectionChip(
                            label: _goalLabel(value, l10n),
                            isSelected: isSelected,
                            onTap: () => _updateGoal(value),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 2: Experience Level
                  _buildSectionHeader(l10n.prefExperienceSection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _experienceValues.map((value) {
                          final isSelected =
                              _preferences.experience == value;
                          return _buildSelectionChip(
                            label: _experienceLabel(value, l10n),
                            isSelected: isSelected,
                            onTap: () =>
                                _updateExperience(value),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Available Equipment
                  _buildSectionHeader(l10n.prefEquipmentSection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _equipmentValues.map((value) {
                          final isSelected =
                              _preferences.equipment == value;
                          return _buildSelectionChip(
                            label: _equipmentLabel(value, l10n),
                            isSelected: isSelected,
                            onTap: () =>
                                _updateEquipment(value),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Weekly Frequency
                  _buildSectionHeader(l10n.prefFrequencySection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _frequencyValues.map((value) {
                          final isSelected =
                              _preferences.frequency == value;
                          return _buildSelectionChip(
                            label: l10n.prefFrequencyDays(value),
                            isSelected: isSelected,
                            onTap: () =>
                                _updateFrequency(value),
                            theme: theme,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 5: Focus Areas (Multi-select)
                  _buildSectionHeader(l10n.prefFocusAreaSection, theme),
                  _buildGlassCard(
                    theme: theme,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _focusAreaValues.map((value) {
                          final isSelected = _preferences.focusAreasList
                              .contains(value);
                          return _buildFilterChip(
                            label: _focusAreaLabel(value, l10n),
                            isSelected: isSelected,
                            onTap: () {
                              final currentAreas = _preferences.focusAreasList
                                  .toList();
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
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
    // 深色模式下使用更低的透明度
    final isDark = theme.isDark;
    final bgAlpha = isDark ? 0.08 : 0.12;
    final borderAlpha = isDark ? 0.20 : 0.30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: theme.surfaceColor.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: theme.surfaceColor.withValues(alpha: borderAlpha),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
            border: Border.all(
              color: isSelected
                  ? theme.accentColor
                  : theme.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: isSelected ? theme.surfaceColor : theme.accentColor,
            ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.15)
                : theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
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
                Icon(Icons.check, size: 16, color: theme.accentColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: theme.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
