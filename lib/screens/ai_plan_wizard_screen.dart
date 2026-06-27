import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan_import.dart';
import '../services/ai_prompt_service.dart';
import '../services/exercise_matcher_service.dart';
import '../services/exercise_service.dart';
import '../services/user_preferences_service.dart';
import '../providers/plan_provider.dart';
import '../utils/dimensions.dart';
import '../widgets/glass_widgets.dart';

/// Tries to extract a valid workout plan JSON from arbitrary text.
///
/// Strategy (in order):
/// 1. Direct `jsonDecode` — works for pure JSON input.
/// 2. Markdown code block — `` ```json {...} ``` `` or `` ``` {...} ``` ``.
/// 3. Brace matching — finds the largest balanced `{...}` substring.
///
/// Each candidate is validated by checking for the required `days` key.
/// Returns `null` if no valid JSON with `days` is found.
Map<String, dynamic>? _extractJsonFromText(String text) {
  // 1. Direct parse
  try {
    final result = jsonDecode(text);
    if (result is Map<String, dynamic> && result.containsKey('days')) {
      return result;
    }
  } catch (_) {}

  // 2. Markdown code blocks (```json ... ``` or ``` ... ```)
  final codeBlockPattern = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?\s*```');
  for (final match in codeBlockPattern.allMatches(text)) {
    final blockContent = match.group(1)?.trim();
    if (blockContent == null) continue;
    try {
      final result = jsonDecode(blockContent);
      if (result is Map<String, dynamic> && result.containsKey('days')) {
        return result;
      }
    } catch (_) {}
  }

  // 3. Brace matching — scan for the outermost balanced { ... } that contains "days"
  int searchFrom = 0;
  while (true) {
    final startIndex = text.indexOf('{', searchFrom);
    if (startIndex == -1) break;

    int depth = 0;
    bool inString = false;
    bool escape = false;

    for (int i = startIndex; i < text.length; i++) {
      final ch = text[i];

      if (escape) {
        escape = false;
        continue;
      }
      if (ch == r'\') {
        escape = true;
        continue;
      }
      if (ch == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          // Found a complete top-level object
          final candidate = text.substring(startIndex, i + 1);
          try {
            final result = jsonDecode(candidate);
            if (result is Map<String, dynamic> &&
                result.containsKey('days')) {
              return result;
            }
          } catch (_) {}
          break; // Stop scanning from this startIndex
        }
      }
    }

    searchFrom = startIndex + 1;
  }

  return null;
}

class AIPlanWizardScreen extends StatefulWidget {
  const AIPlanWizardScreen({super.key});

  @override
  State<AIPlanWizardScreen> createState() => _AIPlanWizardScreenState();
}

class _AIPlanWizardScreenState extends State<AIPlanWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _jsonController = TextEditingController();

  int _currentStep = 0;
  int _activeTab = 0; // 0 = 新建计划, 1 = 导入分析

  // Step 1 state (新建计划)
  String _goal = 'muscle_building';
  int _weeklyFrequency = 4;
  int _sessionDuration = 60;
  String _experience = 'intermediate';
  String _equipment = 'gym';
  List<String> _focusAreas = [];

  // Step 2 state
  DateTime _startDate = _nextMonday();
  String? _generatedPrompt;

  // Step 3 state (import analysis)
  String? _parseError;
  bool _isParsing = false;

  // Step 4 state (preview + import)
  WeeklyPlanImport? _parsedPlan;
  bool _isImporting = false;
  final Map<String, int> _editableSets = {};

  // Pre-matching state: key = "day{dayOfWeek}-{exerciseName}"
  final Map<String, MatchResult> _matchResults = {};
  final Map<String, Exercise> _manualSelections = {};
  bool _isMatching = false;

  bool _preferencesLoaded = false;

  static DateTime _nextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final service = UserPreferencesService();
      final prefs = await service.loadPreferences().timeout(
        const Duration(seconds: 2),
      );
      if (mounted) {
        setState(() {
          _goal = prefs.goal;
          _weeklyFrequency = prefs.frequency;
          _experience = prefs.experience;
          _equipment = prefs.equipment;
          _focusAreas = prefs.focusAreasList;
          _preferencesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences, using defaults: $e');
      if (mounted) {
        setState(() => _preferencesLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.aiCloseTooltip,
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
              l10n.aiTitle,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                l10n.aiPreviousStep,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: theme.accentColor),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _activeTab == 1
                  ? [
                      // Import analysis flow: 2 pages
                      _buildStep1(theme), // Contains the tab with import form
                      _buildStep4(theme), // Preview + import
                    ]
                  : [
                      // New plan flow: 4 pages (existing)
                      _buildStep1(theme), // Contains the tab with new plan form
                      _buildStep2(theme),
                      _buildStep3(theme),
                      _buildStep4(theme),
                    ],
            ),
          ),
          _buildBottomButton(theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isImport = _activeTab == 1;
    final stepLabels = isImport
        ? [l10n.aiStepImportAnalysis, l10n.aiStepPreviewImport]
        : [
            l10n.aiStepProfile,
            l10n.aiStepGeneratePrompt,
            l10n.aiStepPasteJson,
            l10n.aiStepPreviewImport,
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < stepLabels.length; i++) ...[
            if (i > 0) _buildStepLine(_currentStep >= i, theme),
            _buildStepItem(i + 1, stepLabels[i], _currentStep >= i, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(
    int number,
    String label,
    bool isActive,
    AppThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? theme.accentColor
                : theme.textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > number - 1
                ? Icon(Icons.check, color: theme.onAccentColor, size: 18)
                : Text(
                    '$number',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? theme.onAccentColor
                          : theme.secondaryTextColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: isActive ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, AppThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? theme.accentColor
            : theme.textColor.withValues(alpha: 0.1),
      ),
    );
  }

  // ==================== 第1步：Tab切换（新建计划 / 导入分析） ====================
  Widget _buildStep1(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(
            children: [
              _buildTab(l10n.aiTabNewPlan, 0, theme),
              _buildTab(l10n.aiTabImportAnalysis, 1, theme),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: _activeTab == 0
              ? _buildNewPlanForm(theme)
              : _buildImportAnalysisForm(theme),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index, AppThemeData theme) {
    final isActive = _activeTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = index;
              _currentStep = 0;
              _pageController.jumpToPage(0);
            });
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? theme.accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive ? theme.onAccentColor : theme.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 新建计划表单（原Step1内容） ====================
  Widget _buildNewPlanForm(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (!_preferencesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiNewPlanHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiNewPlanSubheading,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),

          _buildSingleSelectQuestion(
            l10n.prefGoalSection,
            _goal,
            {
              l10n.prefGoalMuscleBuilding: 'muscle_building',
              l10n.prefGoalFatLoss: 'fat_loss',
              l10n.prefGoalStrength: 'strength',
              l10n.prefGoalEndurance: 'endurance',
            },
            (value) => setState(() => _goal = value),
            theme,
          ),
          const SizedBox(height: 16),

          _buildSingleSelectQuestion(
            l10n.aiQuestionFrequency,
            '$_weeklyFrequency',
            {
              l10n.prefFrequencyDays(3): '3',
              l10n.prefFrequencyDays(4): '4',
              l10n.prefFrequencyDays(5): '5',
              l10n.prefFrequencyDays(6): '6',
            },
            (value) => setState(() => _weeklyFrequency = int.parse(value)),
            theme,
          ),
          const SizedBox(height: 16),

          _buildSingleSelectQuestion(
            l10n.aiQuestionDuration,
            '$_sessionDuration',
            {
              l10n.aiDurationMinutes(45): '45',
              l10n.aiDurationMinutes(60): '60',
              l10n.aiDurationMinutes(75): '75',
              l10n.aiDurationMinutes(90): '90',
            },
            (value) => setState(() => _sessionDuration = int.parse(value)),
            theme,
          ),
          const SizedBox(height: 16),

          _buildSingleSelectQuestion(
            l10n.prefExperienceSection,
            _experience,
            {
              l10n.prefExperienceBeginner: 'beginner',
              l10n.prefExperienceIntermediate: 'intermediate',
              l10n.prefExperienceAdvanced: 'advanced',
            },
            (value) => setState(() => _experience = value),
            theme,
          ),
          const SizedBox(height: 16),

          _buildSingleSelectQuestion(
            l10n.aiQuestionEquipment,
            _equipment,
            {
              l10n.prefEquipmentGym: 'gym',
              l10n.prefEquipmentHomeDumbbell: 'home_dumbbell',
              l10n.prefEquipmentBodyweight: 'bodyweight',
            },
            (value) => setState(() => _equipment = value),
            theme,
          ),
          const SizedBox(height: 16),

          _buildMultiSelectQuestion(
            l10n.prefFocusAreaSection,
            _focusAreas,
            {
              l10n.prefFocusAreaChest: 'chest',
              l10n.prefFocusAreaBack: 'back',
              l10n.prefFocusAreaShoulders: 'shoulders',
              l10n.prefFocusAreaArms: 'arms',
              l10n.prefFocusAreaLegs: 'legs',
              l10n.prefFocusAreaCore: 'core',
            },
            (value) => setState(() => _focusAreas = value),
            theme,
          ),
        ],
      ),
    );
  }

  // ==================== 导入分析表单（新增） ====================
  Widget _buildImportAnalysisForm(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiImportHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiImportSubheading,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _jsonController,
            maxLines: 10,
            minLines: 6,
            decoration: InputDecoration(
              labelText: l10n.aiJsonLabel,
              labelStyle: TextStyle(color: theme.textColor),
              border: const OutlineInputBorder(),
              errorText: _parseError,
              helperText: l10n.aiJsonHelper,
              helperMaxLines: 2,
            ),
            onChanged: (_) {
              if (_parseError != null) {
                setState(() => _parseError = null);
              }
            },
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: _isParsing ? l10n.aiParsing : l10n.aiParseJson,
            onPressed: _isParsing ? null : _parseJsonForImport,
            height: 56,
          ),
          if (_parseError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.errorBackgroundColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: theme.errorColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: theme.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: theme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Run pre-matching against the exercise database after JSON is parsed.
  /// Populates _matchResults so the preview UI can show status badges.
  Future<void> _runPreMatching() async {
    if (_parsedPlan == null) return;

    setState(() => _isMatching = true);

    try {
      if (!ExerciseService.isLoaded) {
        await ExerciseService.loadExercises();
      }
      final matcher = ExerciseMatcherService(
        exercises: ExerciseService.exercises,
      );

      _matchResults.clear();

      for (final day in _parsedPlan!.days) {
        for (final exercise in day.exercises) {
          final key = 'day${day.dayOfWeek}-${exercise.exerciseName}';
          final result = await matcher.matchExercise(exercise.exerciseName);
          _matchResults[key] = result;
        }
      }
    } catch (e) {
      debugPrint('Pre-matching failed: $e');
    } finally {
      if (mounted) setState(() => _isMatching = false);
    }
  }

  /// Parse JSON for import analysis tab - goes directly to preview
  void _parseJsonForImport() async {
    final l10n = AppLocalizations.of(context)!;
    if (_jsonController.text.isEmpty) {
      setState(() => _parseError = l10n.aiErrorEmptyJson);
      return;
    }

    setState(() {
      _isParsing = true;
      _parseError = null;
    });

    try {
      final jsonMap = _extractJsonFromText(_jsonController.text);
      if (jsonMap == null) {
        setState(() {
          _isParsing = false;
          _parseError = l10n.aiErrorInvalidJson;
        });
        return;
      }
      final parsedPlan = WeeklyPlanImport.fromJson(jsonMap);
      setState(() {
        _isParsing = false;
        _parsedPlan = parsedPlan;
        _matchResults.clear();
        _manualSelections.clear();
        _currentStep = 1; // Go to preview step (step 2 in import mode)
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      // Run pre-matching after navigation so UI shows progress immediately
      _runPreMatching();
    } catch (e) {
      setState(() {
        _isParsing = false;
        _parseError = l10n.aiErrorParseFailed(e.toString());
      });
    }
  }

  Widget _buildSingleSelectQuestion(
    String title,
    String currentValue,
    Map<String, String> options,
    ValueChanged<String> onChanged,
    AppThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final isSelected = entry.value == currentValue;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(entry.value),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusChip,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor
                          : theme.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.onAccentColor
                          : theme.accentColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectQuestion(
    String title,
    List<String> selectedValues,
    Map<String, String> options,
    ValueChanged<List<String>> onChanged,
    AppThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final label = entry.key;
            final code = entry.value;
            final isSelected = selectedValues.contains(code);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final newValues = List<String>.from(selectedValues);
                  if (isSelected) {
                    newValues.remove(code);
                  } else {
                    newValues.add(code);
                  }
                  onChanged(newValues);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accentColor
                        : theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusChip,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor
                          : theme.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.onAccentColor
                          : theme.accentColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== 第2步：日期 + 生成提示词 ====================
  Widget _buildStep2(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiGeneratePromptHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiGeneratePromptSubheading,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),

          Text(
            l10n.aiStartDateLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData(
                        useMaterial3: true,
                        colorScheme: ColorScheme.light(
                          primary: theme.accentColor,
                          onPrimary: theme.onAccentColor,
                          secondary: theme.accentColor,
                          surface: theme.surfaceColor,
                          onSurface: theme.textColor,
                          error: theme.errorColor,
                          onError: theme.onAccentColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceColorRaised,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: AppElevation.resting(theme.shadowColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.aiDateDisplay(
                          _startDate.year, _startDate.month, _startDate.day),
                      style: Theme.of(context).textTheme.bodyLarge!,
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: theme.accentColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          PrimaryActionButton(
            label: l10n.aiGeneratePromptButton,
            onPressed: _generatePrompt,
            height: 56,
          ),
          const SizedBox(height: 24),

          if (_generatedPrompt != null) ...[
            Text(
              l10n.aiGeneratedPromptLabel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              decoration: BoxDecoration(
                color: theme.surfaceColorRaised,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: AppElevation.resting(theme.shadowColor),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _generatedPrompt!,
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
              ),
            ),
            const SizedBox(height: 16),

            PrimaryActionButton(
              label: l10n.aiCopyToClipboard,
              onPressed: _copyToClipboard,
              height: 56,
            ),
            const SizedBox(height: 16),

            Text(
              l10n.aiCopyHint,
              style: Theme.of(context).textTheme.bodySmall!,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _generatePrompt() {
    final aiPromptService = AIPromptService();
    final userProfile = UserProfile(
      goal: _goal,
      weeklyFrequency: _weeklyFrequency,
      sessionDuration: _sessionDuration,
      experience: _experience,
      equipment: _equipment,
      focusAreas: _focusAreas,
      startDate: _startDate,
    );
    final prompt = aiPromptService.generatePrompt(userProfile);
    setState(() => _generatedPrompt = prompt);
  }

  Future<void> _copyToClipboard() async {
    if (_generatedPrompt != null) {
      await Clipboard.setData(ClipboardData(text: _generatedPrompt!));
      if (mounted) {
        final theme = context.read<ThemeProvider>().currentTheme;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiCopiedToast),
            backgroundColor: theme.successColor,
          ),
        );
      }
    }
  }

  // ==================== 第3步：粘贴JSON ====================
  Widget _buildStep3(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiPasteJsonHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiPasteJsonSubheading,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _jsonController,
            maxLines: 10,
            minLines: 6,
            decoration: InputDecoration(
              labelText: l10n.aiJsonLabel,
              labelStyle: TextStyle(color: theme.textColor),
              border: const OutlineInputBorder(),
              errorText: _parseError,
              helperText: l10n.aiJsonHelper,
              helperMaxLines: 2,
            ),
            onChanged: (_) {
              if (_parseError != null) {
                setState(() => _parseError = null);
              }
            },
          ),

          const SizedBox(height: 16),

          PrimaryActionButton(
            label: _isParsing ? l10n.aiParsing : l10n.aiParseJson,
            onPressed: _isParsing ? null : _parseJson,
            height: 56,
          ),

          if (_parseError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.errorBackgroundColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: theme.errorColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: theme.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: theme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _parseJson() async {
    final l10n = AppLocalizations.of(context)!;
    if (_jsonController.text.isEmpty) {
      setState(() => _parseError = l10n.aiErrorEmptyJson);
      return;
    }

    setState(() {
      _isParsing = true;
      _parseError = null;
    });

    try {
      final jsonMap = _extractJsonFromText(_jsonController.text);
      if (jsonMap == null) {
        setState(() {
          _isParsing = false;
          _parseError = l10n.aiErrorInvalidJson;
        });
        return;
      }
      final parsedPlan = WeeklyPlanImport.fromJson(jsonMap);
      setState(() {
        _isParsing = false;
        _parsedPlan = parsedPlan;
        _matchResults.clear();
        _manualSelections.clear();
      });

      if (_currentStep < 3) {
        setState(() => _currentStep = 3);
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      // Run pre-matching after navigation so UI shows progress immediately
      _runPreMatching();
    } catch (e) {
      setState(() {
        _isParsing = false;
        _parseError = l10n.aiErrorParseFailed(e.toString());
      });
    }
  }

  // ==================== 第4步：预览 + 导入 ====================
  Widget _buildStep4(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_parsedPlan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: theme.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              l10n.aiPreviewEmpty,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: theme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiPreviewHeading,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiPlanNameLabel(_parsedPlan!.name),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Match summary header
                if (!_isMatching && _matchResults.isNotEmpty) ...[
                  _buildMatchSummary(theme),
                  const SizedBox(height: 16),
                ],

                ..._parsedPlan!.days.map((day) => _buildDayCard(day, theme)),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: PrimaryActionButton(
            label: _isImporting ? l10n.aiImporting : l10n.aiConfirmImport,
            onPressed: _isImporting ? null : _importPlan,
            height: 56,
          ),
        ),
      ],
    );
  }

  /// Build match summary banner showing matched/candidate/unmatched counts.
  Widget _buildMatchSummary(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    int matched = 0;
    int candidates = 0;
    int unmatched = 0;

    for (final day in _parsedPlan!.days) {
      for (final exercise in day.exercises) {
        final key = 'day${day.dayOfWeek}-${exercise.exerciseName}';
        final hasManual = _manualSelections.containsKey(key);
        final result = _matchResults[key];

        if (hasManual || (result?.isSuccess ?? false)) {
          matched++;
        } else if (result != null && result.candidates.isNotEmpty) {
          candidates++;
        } else {
          unmatched++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.aiMatchSummary(matched, candidates, unmatched),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Locale-aware weekday name (1=Mon..7=Sun).
  String _dayName(int dayOfWeek, AppLocalizations l10n) {
    switch (dayOfWeek) {
      case 1:
        return l10n.aiDayNameMon;
      case 2:
        return l10n.aiDayNameTue;
      case 3:
        return l10n.aiDayNameWed;
      case 4:
        return l10n.aiDayNameThu;
      case 5:
        return l10n.aiDayNameFri;
      case 6:
        return l10n.aiDayNameSat;
      case 7:
        return l10n.aiDayNameSun;
      default:
        return '';
    }
  }

  Widget _buildDayCard(DailyPlanImport day, AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final dayName = _dayName(day.dayOfWeek, l10n);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.aiDayTitle(day.dayOfWeek, dayName),
                  style: Theme.of(context).textTheme.titleLarge!,
                ),
                Text(
                  day.exercises.isEmpty
                      ? l10n.aiRestDay
                      : l10n.aiExerciseCountSuffix(day.exercises.length),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
            if (day.targetMuscles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.aiTargetMusclesLabel(day.targetMuscles.join(', ')),
                style: Theme.of(context).textTheme.bodySmall!,
              ),
            ],
            const SizedBox(height: 12),
            ...day.exercises.map(
              (exercise) => _buildExerciseRow(exercise, day.dayOfWeek, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(
    ExerciseEntryImport exercise,
    int dayOfWeek,
    AppThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final exerciseKey = 'day$dayOfWeek-${exercise.exerciseName}';
    final currentSets = _editableSets[exerciseKey] ?? exercise.targetSets;

    // --- Match status ---
    final matchResult = _matchResults[exerciseKey];
    final hasManualSelection = _manualSelections.containsKey(exerciseKey);
    final isMatched =
        hasManualSelection || (matchResult?.isSuccess ?? false);

    // Display name: manual selection > auto-match > original
    final displayName = hasManualSelection
        ? _manualSelections[exerciseKey]!.name
        : (matchResult?.isSuccess == true && matchResult?.exercise != null
              ? matchResult!.exercise!.name
              : exercise.exerciseName);

    // Build status badge widget
    Widget? statusBadge;
    if (_isMatching) {
      statusBadge = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.accentColor,
        ),
      );
    } else if (isMatched) {
      statusBadge = Icon(
        Icons.check_circle,
        color: theme.successColor,
        size: 20,
      );
    } else if (matchResult != null && matchResult.candidates.isNotEmpty) {
      statusBadge = GestureDetector(
        onTap: () => _showCandidateSelection(
          exerciseKey,
          exercise.exerciseName,
          matchResult,
          theme,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.warningColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(
              color: theme.warningColor.withValues(alpha: 0.4),
            ),
          ),
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 14, color: theme.warningColor),
              const SizedBox(width: 4),
              Text(
                l10n.aiCandidatesBadge(matchResult.candidates.length),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(
                  fontSize: 11,
                  color: theme.warningColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      statusBadge = Icon(
        Icons.help_outline,
        color: theme.secondaryTextColor,
        size: 20,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
                if (displayName != exercise.exerciseName)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.aiOriginalLabel(exercise.exerciseName),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(
                        color: theme.secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: statusBadge,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.aiDecreaseSets,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: theme.accentColor,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    final newSets = currentSets - 1;
                    if (newSets >= 1) {
                      _editableSets[exerciseKey] = newSets;
                    }
                  });
                },
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '$currentSets',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: l10n.aiIncreaseSets,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: theme.accentColor,
                  size: 20,
                ),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _editableSets[exerciseKey] = currentSets + 1;
                  });
                },
              ),
              const SizedBox(width: 4),
              Text(l10n.aiSetsUnit, style: Theme.of(context).textTheme.bodySmall!),
            ],
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet for user to select a matching exercise from candidates.
  void _showCandidateSelection(
    String matchKey,
    String originalName,
    MatchResult matchResult,
    AppThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXxs,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.aiSelectMatchTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.aiSelectMatchSubtitle(
                          originalName, matchResult.candidates.length),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Candidate list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: matchResult.candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = matchResult.candidates[index];
                    final isSelected =
                        _manualSelections[matchKey]?.id == candidate.id;
                    final l10n = AppLocalizations.of(context)!;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.accentColor
                              : theme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check
                              : Icons.fitness_center,
                          color: isSelected
                              ? theme.onAccentColor
                              : theme.accentColor,
                          size: 20,
                        ),
                      ),
                      title: Text(candidate.name),
                      subtitle: Text(
                        '${candidate.primaryMuscle.displayName}'
                        ' · ${candidate.equipmentDisplayName(l10n)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.accentColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _manualSelections[matchKey] = candidate;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              // Keep as unmatched option
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _manualSelections.remove(matchKey);
                      });
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: theme.secondaryTextColor,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.aiKeepUnmatched,
                      style: TextStyle(color: theme.secondaryTextColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importPlan() async {
    if (_parsedPlan == null) return;

    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiImportConfirmTitle),
        content: Text(l10n.aiImportConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.widgetCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.widgetConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isImporting = true);

    try {
      final planProvider = context.read<PlanProvider>();
      await planProvider.importWeeklyPlanWithMatches(
        _parsedPlan!,
        _startDate,
        _manualSelections,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiImportSuccessToast),
            backgroundColor: theme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiImportFailedToast(e.toString())),
            backgroundColor: theme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  // ==================== 底部按钮 ====================
  Widget _buildBottomButton(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    String buttonText;
    bool isEnabled;
    VoidCallback? onPressed;

    if (_activeTab == 1) {
      // Import analysis flow
      switch (_currentStep) {
        case 0:
          buttonText = l10n.aiNextPreviewImport;
          isEnabled = _parsedPlan != null;
          onPressed = isEnabled
              ? () {
                  setState(() => _currentStep = 1);
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null;
          break;
        case 1:
          buttonText = l10n.aiComplete;
          isEnabled = _parsedPlan != null && !_isImporting;
          onPressed = isEnabled ? _importPlan : null;
          break;
        default:
          buttonText = '';
          isEnabled = false;
          onPressed = null;
      }
    } else {
      // New plan flow (existing logic)
      switch (_currentStep) {
        case 0:
          buttonText = l10n.aiNextGeneratePrompt;
          isEnabled = true;
          onPressed = _nextStep;
          break;
        case 1:
          buttonText = l10n.aiNextPasteJson;
          isEnabled = _generatedPrompt != null;
          onPressed = isEnabled ? _nextStep : null;
          break;
        case 2:
          buttonText = l10n.aiNextPreviewImport;
          isEnabled = _parsedPlan != null;
          onPressed = isEnabled ? _nextStep : null;
          break;
        case 3:
          buttonText = l10n.aiComplete;
          isEnabled = _parsedPlan != null && !_isImporting;
          onPressed = isEnabled ? _importPlan : null;
          break;
        default:
          buttonText = '';
          isEnabled = false;
          onPressed = null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? theme.accentColor
                  : theme.textColor.withValues(alpha: 0.1),
              foregroundColor: theme.onAccentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Text(
              buttonText,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: isEnabled
                    ? theme.onAccentColor
                    : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    final maxStep = _activeTab == 1 ? 1 : 3;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
