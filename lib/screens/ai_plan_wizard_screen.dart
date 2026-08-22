import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan_import.dart';
import '../services/ai_prompt_service.dart';
import '../services/exercise_matcher_service.dart';
import '../services/exercise_service.dart';
import '../services/user_preferences_service.dart';
import '../providers/plan_provider.dart';
import '../utils/dimensions.dart';
import '../widgets/ai_wizard_components.dart';
import '../widgets/ai_wizard_preview.dart';
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
            if (result is Map<String, dynamic> && result.containsKey('days')) {
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

  // Start-week selection (import flow): null = not chosen, true = this week,
  // false = next week. Drives _startDate at import time.
  bool? _startFromThisWeek;

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

  /// The Monday of the current week. If today is Monday, returns today.
  /// Used when the user picks "this week" in the import flow — note this may
  /// land in the past (e.g. on Wednesday, Monday was 2 days ago), which is the
  /// documented behavior: exercises whose dayOfWeek maps to a past date will
  /// be scheduled to that past date.
  static DateTime _thisWeeksMonday() {
    final now = DateTime.now();
    final daysSinceMonday = (now.weekday - DateTime.monday + 7) % 7;
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysSinceMonday));
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

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
        title: Text(
          l10n.aiTitle,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
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
          aiWizardStepIndicator(
            context,
            currentStep: _currentStep,
            isImportTab: _activeTab == 1,
            theme: theme,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _activeTab == 1
                  ? [
                      // Import analysis flow: 3 pages
                      _buildStep1(theme), // Contains the tab with import form
                      aiWizardStartWeekStep(
                        context,
                        startFromThisWeek: _startFromThisWeek,
                        onSelectionChanged: (v) =>
                            setState(() => _startFromThisWeek = v),
                        theme: theme,
                      ), // Start-week selection
                      _buildStep4(theme), // Preview + import
                    ]
                  : [
                      // New plan flow: 4 pages (existing)
                      _buildStep1(theme), // Contains the tab with new plan form
                      aiWizardPromptStep(
                        context,
                        startDate: _startDate,
                        generatedPrompt: _generatedPrompt,
                        onGeneratePrompt: _generatePrompt,
                        onCopyToClipboard: _copyToClipboard,
                        onStartDateChanged: (date) =>
                            setState(() => _startDate = date),
                        theme: theme,
                      ),
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

  // ==================== 第1步：Tab切换（新建计划 / 导入分析） ====================
  Widget _buildStep1(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
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

          aiWizardMultiSelectQuestion(
            context,
            title: l10n.prefFocusAreaSection,
            selectedValues: _focusAreas,
            options: {
              l10n.prefFocusAreaChest: 'chest',
              l10n.prefFocusAreaBack: 'back',
              l10n.prefFocusAreaShoulders: 'shoulders',
              l10n.prefFocusAreaArms: 'arms',
              l10n.prefFocusAreaLegs: 'legs',
              l10n.prefFocusAreaCore: 'core',
            },
            onChanged: (value) => setState(() => _focusAreas = value),
            theme: theme,
          ),
        ],
      ),
    );
  }

  // ==================== 导入分析表单（新增） ====================
  Widget _buildImportAnalysisForm(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final parseError = _parseError;
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
          if (parseError != null) ...[
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
                      parseError,
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
    final parsedPlan = _parsedPlan;
    if (parsedPlan == null) return;

    setState(() => _isMatching = true);

    try {
      if (!ExerciseService.isLoaded) {
        await ExerciseService.loadExercises();
      }
      final matcher = ExerciseMatcherService(
        exercises: ExerciseService.exercises,
      );

      _matchResults.clear();

      for (final day in parsedPlan.days) {
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
        // Reset start-week choice: re-parsing is a new plan, force user to
        // explicitly pick this/next week again before preview.
        _startFromThisWeek = null;
        _currentStep = 1; // Go to start-week selection (step 2 in import mode)
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
    final prompt = _generatedPrompt;
    if (prompt != null) {
      await Clipboard.setData(ClipboardData(text: prompt));
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final parseError = _parseError;
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

          if (parseError != null) ...[
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
                      parseError,
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final parsedPlan = _parsedPlan;
    if (parsedPlan == null) {
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
                  l10n.aiPlanNameLabel(parsedPlan.name),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Match summary header
                if (!_isMatching && _matchResults.isNotEmpty) ...[
                  aiWizardMatchSummary(
                    context,
                    parsedPlan: parsedPlan,
                    matchResults: _matchResults,
                    manualSelections: _manualSelections,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                ],

                ...parsedPlan.days.map(
                  (day) => aiWizardDayCard(
                    context,
                    day: day,
                    editableSets: _editableSets,
                    matchResults: _matchResults,
                    manualSelections: _manualSelections,
                    isMatching: _isMatching,
                    setState: setState,
                    onShowCandidates:
                        (key, originalName, result, candidateTheme) =>
                            aiWizardCandidateSheet(
                              context,
                              matchKey: key,
                              originalName: originalName,
                              matchResult: result,
                              manualSelections: _manualSelections,
                              setState: setState,
                              theme: candidateTheme,
                            ),
                    theme: theme,
                  ),
                ),
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

  Future<void> _importPlan() async {
    final parsedPlan = _parsedPlan;
    if (parsedPlan == null) return;

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
    setState(() {
      _isImporting = true;
      // Resolve start date from the user's this/next-week choice.
      // _startFromThisWeek is guaranteed non-null here because the bottom
      // button for step 1 is disabled until a choice is made.
      _startDate = _startFromThisWeek == true
          ? _thisWeeksMonday()
          : _nextMonday();
    });

    try {
      final planProvider = context.read<PlanProvider>();
      await planProvider.importWeeklyPlanWithMatches(
        parsedPlan,
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    String buttonText;
    bool isEnabled;
    VoidCallback? onPressed;

    if (_activeTab == 1) {
      // Import analysis flow: 3 steps (JSON → start-week → preview)
      switch (_currentStep) {
        case 0:
          buttonText = l10n.aiNextStartWeek;
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
          buttonText = l10n.aiNextPreviewImport;
          // Force the user to pick this/next week before continuing.
          isEnabled = _parsedPlan != null && _startFromThisWeek != null;
          onPressed = isEnabled
              ? () {
                  setState(() => _currentStep = 2);
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              : null;
          break;
        case 2:
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
    final maxStep = _activeTab == 1 ? 2 : 3;
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
