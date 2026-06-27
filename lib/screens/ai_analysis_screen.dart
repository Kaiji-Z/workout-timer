import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_record.dart';
import '../models/muscle_group.dart';
import '../services/stats_calculator_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';

/// Full-screen page for AI training analysis.
/// Generates a rich prompt from workout data and lets users copy it to external AI tools.
class AIAnalysisScreen extends StatefulWidget {
  final String periodType; // 'week' or 'month'
  final DateTime startDate;
  final DateTime endDate;
  final List<WorkoutRecord> records; // current period
  final List<WorkoutRecord>
  previousRecords; // previous period for trend comparison
  final List<WorkoutRecord> allRecords; // all records for recovery calculation

  const AIAnalysisScreen({
    super.key,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.records,
    required this.previousRecords,
    required this.allRecords,
  });

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  String? _generatedPrompt;
  bool _isPromptCopied = false;

  final StatsCalculatorService _statsCalc = StatsCalculatorService();

  // User preferences loaded asynchronously
  String _selectedGoal = 'muscle_building';
  String _selectedExperience = 'intermediate';
  String _selectedEquipment = 'gym';
  int _selectedFrequency = 4;
  final Set<String> _selectedFocusAreas = {};

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final prefs = await UserPreferencesService().loadPreferences().timeout(
        const Duration(seconds: 2),
      );
      if (!mounted) return;
      setState(() {
        _selectedGoal = prefs.goal;
        _selectedExperience = prefs.experience;
        _selectedEquipment = prefs.equipment;
        _selectedFrequency = prefs.frequency;
        _selectedFocusAreas.clear();
        _selectedFocusAreas.addAll(prefs.focusAreasList);
        _generatedPrompt = _generatePrompt(l10n);
      });
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      if (!mounted) return;
      setState(() {
        _generatedPrompt = _generatePrompt(l10n);
      });
    }
  }

  // ==================== Data Calculation ====================

  /// Calculate estimated 1RM trend with English exercise names for AI prompt.
  ///
  /// Same logic as [StatsCalculatorService.calculateEstimated1RMTrend] but keys
  /// by `nameEn` (falling back to `name` / `exerciseId`) so the generated prompt
  /// uses standard English exercise names that AI models recognise.
  Map<String, List<Estimated1RMPoint>> _calculate1RMTrendEn(
    List<WorkoutRecord> records,
  ) {
    final result = <String, List<Estimated1RMPoint>>{};

    for (final record in records) {
      final sessionBest = <String, Estimated1RMPoint>{};

      for (final recordedExercise in record.exercises) {
        final name = recordedExercise.nameEn.isNotEmpty
            ? recordedExercise.nameEn
            : (recordedExercise.name.isNotEmpty
                  ? recordedExercise.name
                  : recordedExercise.exerciseId);
        if (name.isEmpty) continue;

        final sets = recordedExercise.setsData;
        if (sets == null || sets.isEmpty) continue;

        for (final set in sets) {
          if (set.weight == null || set.weight! <= 0) continue;
          if (set.reps == null || set.reps! <= 0) continue;

          final e1RM = StatsCalculatorService.estimate1RM(
            set.weight!,
            set.reps!,
          );
          final current = sessionBest[name];
          if (current == null || e1RM > current.estimated1RM) {
            sessionBest[name] = Estimated1RMPoint(
              date: record.date,
              estimated1RM: e1RM,
              weight: set.weight!,
              reps: set.reps,
            );
          }
        }
      }

      for (final entry in sessionBest.entries) {
        result.putIfAbsent(entry.key, () => []);
        result[entry.key]!.add(entry.value);
      }
    }

    for (final points in result.values) {
      points.sort((a, b) => a.date.compareTo(b.date));
    }

    return result;
  }

  // ==================== Formatting Methods ====================

  /// Format muscle volume distribution (weighted by training volume)
  String _formatMuscleVolumeDistribution(AppLocalizations l10n) {
    final dist = _statsCalc.calculateMuscleVolumeDistribution(widget.records);
    if (dist.isEmpty) return l10n.anNoMuscleData;

    final sorted = dist.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);

    final buffer = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final pct = total > 0
          ? (entry.value / total * 100).toStringAsFixed(1)
          : '0.0';
      final volumeStr = entry.value >= 1000
          ? '${(entry.value / 1000).toStringAsFixed(1)}k'
          : entry.value.toStringAsFixed(0);
      buffer.writeln(
        l10n.anPromptMuscleDistLine(i + 1, entry.key.displayName, volumeStr, pct),
      );
    }
    return buffer.toString().trimRight();
  }

  /// Format volume trend (current vs previous period)
  String _formatVolumeTrend(AppLocalizations l10n) {
    final currentVolume = _statsCalc.calculateTotalVolume(widget.records);
    final previousVolume = _statsCalc.calculateTotalVolume(
      widget.previousRecords,
    );

    if (currentVolume == 0 && previousVolume == 0) return l10n.anNoTrendData;

    final buffer = StringBuffer();
    String fmtVol(double v) => v >= 1000
        ? '${(v / 1000).toStringAsFixed(1)}k kg'
        : '${v.toStringAsFixed(0)} kg';

    // Total volume trend
    if (previousVolume > 0) {
      final change = ((currentVolume - previousVolume) / previousVolume * 100)
          .round();
      final arrow = change > 0
          ? '↑'
          : change < 0
          ? '↓'
          : '→';
      buffer.writeln(
        l10n.anPromptVolumeTrendWithChange(
            fmtVol(currentVolume), change > 0 ? '+' : '', change, arrow),
      );
    } else {
      buffer.writeln(l10n.anPromptVolumeTrendNew(fmtVol(currentVolume)));
    }

    // Training frequency trend
    final currentDays = _countUniqueDays(widget.records);
    final previousDays = _countUniqueDays(widget.previousRecords);
    if (previousDays > 0) {
      final diff = currentDays - previousDays;
      final arrow = diff > 0
          ? '↑'
          : diff < 0
          ? '↓'
          : '→';
      buffer.writeln(l10n.anPromptFreqTrend(currentDays, diff, arrow));
    }

    // Per-muscle volume trend
    final currentMuscleVol = _statsCalc.calculateMuscleVolumeDistribution(
      widget.records,
    );
    final previousMuscleVol = _statsCalc.calculateMuscleVolumeDistribution(
      widget.previousRecords,
    );
    final allMuscles = {
      ...currentMuscleVol.keys,
      ...previousMuscleVol.keys,
    }.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

    for (final muscle in allMuscles) {
      final curr = currentMuscleVol[muscle] ?? 0;
      final prev = previousMuscleVol[muscle] ?? 0;
      if (prev > 0 && curr > 0) {
        final change = ((curr - prev) / prev * 100).round();
        if (change.abs() >= 10) {
          final arrow = change > 0 ? '↑' : '↓';
          buffer.writeln(
            l10n.anPromptMuscleTrend(
                muscle.displayName, change > 0 ? '+' : '', change, arrow),
          );
        }
      }
    }

    return buffer.toString().trimRight();
  }

  /// Format sets per muscle group with MEV reference
  String _formatSetsPerMuscleGroup(AppLocalizations l10n) {
    final setsPerMuscle = _statsCalc.calculateSetsPerMuscleGroup(
      widget.records,
    );
    if (setsPerMuscle.isEmpty) return l10n.anNoSetsData;

    final isWeek = widget.periodType == 'week';
    // MEV reference: 10 sets/week (Schoenfeld 2017)
    const weeklyMev = 10;
    final mevLabel = isWeek
        ? l10n.anMevWeekLabel(weeklyMev)
        : l10n.anMevMonthLabel(weeklyMev * 4);

    final sorted = setsPerMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer();
    buffer.writeln('  ($mevLabel)');
    for (final entry in sorted) {
      final sets = entry.value;
      final ratio = isWeek ? sets / weeklyMev : sets / (weeklyMev * 4);
      String status;
      if (ratio >= 1.0) {
        status = l10n.anStatusSufficient;
      } else if (ratio >= 0.5) {
        status = l10n.anStatusLow;
      } else {
        status = l10n.anStatusInsufficient;
      }
      buffer.writeln(
        l10n.anPromptSetsLine(entry.key.displayName, sets, status),
      );
    }
    return buffer.toString().trimRight();
  }

  /// Format estimated 1RM for top exercises (uses English names for AI)
  String _formatEstimated1RM(AppLocalizations l10n) {
    final trend = _calculate1RMTrendEn(widget.records);
    if (trend.isEmpty) return l10n.anNo1rmData;

    // Sort by estimated1RM descending (best session), take top 10
    final sorted = trend.entries.toList()
      ..sort(
        (a, b) =>
            b.value.last.estimated1RM.compareTo(a.value.last.estimated1RM),
      );

    final buffer = StringBuffer();
    buffer.writeln(l10n.anMayhewNote);
    for (final entry in sorted.take(10)) {
      final point = entry.value.last;
      final e1RM = point.estimated1RM.toStringAsFixed(1);
      final w = point.weight.toStringAsFixed(1);
      final r = point.reps ?? 0;
      buffer.writeln(l10n.anPrompt1rmLine(entry.key, e1RM, w, r));
    }
    return buffer.toString().trimRight();
  }

  /// Format 1RM progression trend (month view only)
  String _format1RMProgression(AppLocalizations l10n) {
    final trend = _calculate1RMTrendEn(widget.records);
    if (trend.isEmpty) return l10n.anNo1rmTrendData;

    // Filter to exercises with 2+ sessions, sort by change%
    final progressable = <MapEntry<String, List<Estimated1RMPoint>>>[];
    for (final entry in trend.entries) {
      if (entry.value.length >= 2) {
        progressable.add(entry);
      }
    }

    if (progressable.isEmpty) return l10n.anNoProgressData;

    progressable.sort((a, b) {
      final changeA =
          (a.value.last.estimated1RM - a.value.first.estimated1RM) /
          a.value.first.estimated1RM;
      final changeB =
          (b.value.last.estimated1RM - b.value.first.estimated1RM) /
          b.value.first.estimated1RM;
      return changeB.compareTo(changeA);
    });

    final buffer = StringBuffer();
    for (final entry in progressable.take(10)) {
      final first = entry.value.first;
      final last = entry.value.last;
      final change =
          ((last.estimated1RM - first.estimated1RM) / first.estimated1RM * 100);
      final weeks = last.date.difference(first.date).inDays / 7.0;
      final arrow = change > 0
          ? '↑'
          : change < 0
          ? '↓'
          : '→';
      final weeksStr = weeks > 0
          ? l10n.anPrompt1rmWeeksSuffix(weeks.toStringAsFixed(0))
          : '';
      buffer.writeln(
        l10n.anPrompt1rmProgressLine(
          entry.key,
          first.estimated1RM.toStringAsFixed(1),
          last.estimated1RM.toStringAsFixed(1),
          change > 0 ? '+' : '',
          change.toStringAsFixed(1),
          arrow,
          weeksStr,
        ),
      );
    }
    return buffer.toString().trimRight();
  }

  /// Format recovery management data (calculate rest days per muscle)
  String _formatRecoveryManagement(AppLocalizations l10n) {
    // Recovery is a global state (not period-specific)
    final records = widget.allRecords.isNotEmpty
        ? widget.allRecords
        : widget.records;
    if (records.isEmpty) return l10n.anNoRecoveryData;

    final Map<PrimaryMuscleGroup, DateTime> lastTrainedDates = {};
    for (final record in records) {
      final muscles = _getMusclesFromRecord(record);
      for (final muscle in muscles) {
        final existingDate = lastTrainedDates[muscle];
        if (existingDate == null || record.date.isAfter(existingDate)) {
          lastTrainedDates[muscle] = record.date;
        }
      }
    }

    if (lastTrainedDates.isEmpty) return l10n.anNoMuscleRecoveryData;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buffer = StringBuffer();

    final sortedEntries = lastTrainedDates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in sortedEntries) {
      final lastDate = DateTime(
        entry.value.year,
        entry.value.month,
        entry.value.day,
      );
      final restDays = today.difference(lastDate).inDays;
      String status;
      if (restDays >= 3) {
        status = l10n.anRecoveryTrainable;
      } else if (restDays >= 1) {
        status = l10n.anRecoveryRestMore(3 - restDays);
      } else {
        status = l10n.anRecoveryJustTrained;
      }
      buffer.writeln(
        l10n.anPromptRecoveryLine(entry.key.displayName, restDays, status),
      );
    }

    return buffer.toString().trimRight();
  }

  // ==================== Helpers ====================

  /// Count unique training days
  int _countUniqueDays(List<WorkoutRecord> records) {
    final days = <String>{};
    for (final r in records) {
      days.add('${r.date.year}-${r.date.month}-${r.date.day}');
    }
    return days.length;
  }

  /// Extract trained muscles from a record, using exercise.primaryMuscle when available.
  /// Falls back to record.trainedMuscles when no exercise detail is loaded.
  Set<PrimaryMuscleGroup> _getMusclesFromRecord(WorkoutRecord record) {
    final fromExercises = <PrimaryMuscleGroup>{};
    for (final e in record.exercises) {
      if (e.exercise != null) {
        fromExercises.add(e.exercise!.primaryMuscle);
      }
    }
    if (fromExercises.isNotEmpty) return fromExercises;
    return record.trainedMuscles.toSet();
  }

  // ==================== Prompt Generation ====================

  String _generatePrompt(AppLocalizations l10n) {
    final isWeek = widget.periodType == 'week';
    final periodLabel = isWeek ? l10n.anPeriodWeek : l10n.anPeriodMonth;
    final periodWord = isWeek ? l10n.anWeek : l10n.anMonth;
    final dateRange = l10n.anDateRange(widget.startDate.month,
        widget.startDate.day, widget.endDate.month, widget.endDate.day);

    String goalLabel(String code) {
      switch (code) {
        case 'muscle_building':
          return l10n.anGoalMuscleBuilding;
        case 'fat_loss':
          return l10n.anGoalFatLoss;
        case 'strength':
          return l10n.anGoalStrength;
        case 'endurance':
          return l10n.anGoalEndurance;
        default:
          return code;
      }
    }

    String experienceLabel(String code) {
      switch (code) {
        case 'beginner':
          return l10n.prefExperienceBeginner;
        case 'intermediate':
          return l10n.prefExperienceIntermediate;
        case 'advanced':
          return l10n.prefExperienceAdvanced;
        default:
          return code;
      }
    }

    String equipmentLabel(String code) {
      switch (code) {
        case 'gym':
          return l10n.prefEquipmentGym;
        case 'home_dumbbell':
          return l10n.prefEquipmentHomeDumbbell;
        case 'bodyweight':
          return l10n.prefEquipmentBodyweight;
        default:
          return code;
      }
    }

    String muscleLabel(String code) {
      switch (code) {
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
          return code;
      }
    }

    // Basic statistics
    final totalVolume = _statsCalc.calculateTotalVolume(widget.records);
    final density = _statsCalc.calculateDensity(widget.records);
    final sessionCount = widget.records.length;
    final workoutDays = _countUniqueDays(widget.records);
    String fmtVol(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

    final buffer = StringBuffer();

    // Opening — period-adaptive
    buffer.writeln(l10n.anPromptOpening);
    if (isWeek) {
      buffer.writeln(l10n.anPromptWeekNote);
    } else {
      buffer.writeln(l10n.anPromptMonthNote);
    }
    buffer.writeln();

    // Training data report
    buffer.writeln(l10n.anPromptReportHeader);
    buffer.writeln();

    // Basic info
    buffer.writeln(l10n.anPromptBasicInfoHeader);
    buffer.writeln(l10n.anPromptPeriod(periodLabel, dateRange));
    buffer.writeln(l10n.anPromptSessions(sessionCount, workoutDays));
    buffer.writeln(l10n.anPromptTotalVolume(fmtVol(totalVolume)));
    buffer.writeln(l10n.anPromptDensity(density.toStringAsFixed(1)));
    buffer.writeln();

    // Trend changes
    buffer.writeln(l10n.anPromptTrendHeader(periodWord));
    buffer.writeln(_formatVolumeTrend(l10n));
    buffer.writeln();

    // Muscle volume distribution
    buffer.writeln(l10n.anPromptMuscleDistHeader);
    buffer.writeln(_formatMuscleVolumeDistribution(l10n));
    buffer.writeln();

    // Sets per muscle group (NEW)
    buffer.writeln(l10n.anPromptSetsPerMuscleHeader);
    buffer.writeln(_formatSetsPerMuscleGroup(l10n));
    buffer.writeln();

    // Estimated 1RM (REPLACED from PR)
    buffer.writeln(l10n.anPrompt1rmHeader);
    buffer.writeln(_formatEstimated1RM(l10n));
    buffer.writeln();

    // 1RM progression — MONTH ONLY
    if (!isWeek) {
      buffer.writeln(l10n.anPrompt1rmProgressionHeader);
      buffer.writeln(_format1RMProgression(l10n));
      buffer.writeln();
    }

    // Recovery status
    buffer.writeln(l10n.anPromptRecoveryHeader);
    buffer.writeln(_formatRecoveryManagement(l10n));
    buffer.writeln();

    // User profile
    buffer.writeln(l10n.anPromptProfileHeader);
    buffer.writeln(l10n.anPromptGoal(goalLabel(_selectedGoal)));
    buffer.writeln(
      l10n.anPromptExperience(experienceLabel(_selectedExperience)),
    );
    buffer.writeln(l10n.anPromptFrequency(_selectedFrequency));
    buffer.writeln(
      l10n.anPromptEquipment(equipmentLabel(_selectedEquipment)),
    );
    if (_selectedFocusAreas.isNotEmpty) {
      buffer.writeln(
        l10n.anPromptFocusAreas(
          _selectedFocusAreas.map(muscleLabel).join(', '),
        ),
      );
    }
    buffer.writeln();

    // Output format
    buffer.writeln(l10n.anPromptOutputHeader);
    buffer.writeln(l10n.anPromptOutputIntro);
    buffer.writeln();
    buffer.writeln(l10n.anPromptOutputPart1);
    buffer.writeln();
    buffer.writeln(l10n.anPromptOutputPart1Detail);
    buffer.writeln(l10n.anPromptOutputSplit(workoutDays));
    buffer.writeln(l10n.anPromptOutputComparison);
    buffer.writeln(l10n.anPromptOutputSelection);
    buffer.writeln(l10n.anPromptOutputOverload);
    buffer.writeln();
    buffer.writeln(l10n.anPromptOutputPart2);
    buffer.writeln();
    buffer.writeln(l10n.anPromptOutputJson);
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "name": "...",');
    buffer.writeln('  "days": [');
    buffer.writeln('    {');
    buffer.writeln('      "dayOfWeek": 1,');
    buffer.writeln('      "targetMuscles": ["chest", "shoulders"],');
    buffer.writeln('      "exercises": [');
    buffer.writeln(
      '        {"exerciseName": "Barbell Bench Press", "targetSets": 4}',
    );
    buffer.writeln('      ]');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln(l10n.anPromptNamingHeader);
    buffer.writeln(l10n.anPromptNamingIntro);
    buffer.writeln(
      '- Barbell: Barbell Bench Press, Barbell Squat, Deadlift, Overhead Press, Barbell Row',
    );
    buffer.writeln(
      '- Dumbbell: Incline Dumbbell Press, Dumbbell Fly, Dumbbell Curl, Lateral Raise',
    );
    buffer.writeln('- Cable/Machine: Cable Fly, Cable Crossover, Lat Pulldown, Leg Press');
    buffer.writeln('- Bodyweight: Pull-up, Dip, Push-up, Bodyweight Squat');
    buffer.writeln(l10n.anPromptNamingClosing);
    buffer.writeln();
    buffer.writeln(l10n.anPromptClosing);

    return buffer.toString();
  }

  // ==================== UI Building ====================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final l10n = AppLocalizations.of(context)!;
    final isWeek = widget.periodType == 'week';

    return Scaffold(
      backgroundColor: theme.primaryColor,
      appBar: _buildAppBar(theme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Instructions
            _buildInstructionsBox(theme),
            const SizedBox(height: 24),

            // Section 2: Training Data Report
            _buildSectionHeader(l10n.anReportHeading, theme),
            const SizedBox(height: 12),

            // a) Basic Info
            _buildGlassCard(theme: theme, child: _buildBasicInfoSection(theme)),
            const SizedBox(height: 12),

            // b) Trend Changes
            _buildGlassCard(theme: theme, child: _buildTrendSection(theme)),
            const SizedBox(height: 12),

            // c) Muscle Volume Distribution
            _buildGlassCard(
              theme: theme,
              child: _buildMuscleDistributionSection(theme),
            ),
            const SizedBox(height: 12),

            // d) Sets Per Muscle Group (NEW)
            _buildGlassCard(
              theme: theme,
              child: _buildSetsPerMuscleSection(theme),
            ),
            const SizedBox(height: 12),

            // e) Estimated 1RM (REPLACED from PR)
            _buildGlassCard(
              theme: theme,
              child: _buildEstimated1RMSection(theme),
            ),
            const SizedBox(height: 12),

            // f) 1RM Progression — MONTH ONLY
            if (!isWeek) ...[
              _buildGlassCard(
                theme: theme,
                child: _build1RMProgressionSection(theme),
              ),
              const SizedBox(height: 12),
            ],

            // g) Recovery Status
            _buildGlassCard(theme: theme, child: _buildRecoverySection(theme)),
            const SizedBox(height: 12),

            const SizedBox(height: 24),

            // Section 3: Generated Prompt
            _buildSectionHeader(l10n.anPromptHeading, theme),
            const SizedBox(height: 12),
            _buildPromptContainer(theme),
            const SizedBox(height: 16),
            _buildCopyButton(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: l10n.anCloseTooltip,
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
          Icon(Icons.psychology, color: theme.accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            l10n.anTitle,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsBox(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                l10n.anInstructionsHeading,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(l10n.anInstruction1, theme),
          _buildInstructionStep(l10n.anInstruction2, theme),
          _buildInstructionStep(l10n.anInstruction3, theme),
          _buildInstructionStep(l10n.anInstruction4, theme),
          _buildInstructionStep(l10n.anInstruction5, theme),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGlassCard({required AppThemeData theme, required Widget child}) {
    final isDark = theme.isDark;
    final bgAlpha = isDark ? 0.08 : 0.12;
    final borderAlpha = isDark ? 0.20 : 0.30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
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

  Widget _buildBasicInfoSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final totalVolume = _statsCalc.calculateTotalVolume(widget.records);
    final density = _statsCalc.calculateDensity(widget.records);
    final totalDurationMin =
        widget.records.fold<int>(0, (sum, r) => sum + r.durationSeconds) ~/ 60;
    final sessionCount = widget.records.length;
    final workoutDays = _countUniqueDays(widget.records);
    final avgPerSession = sessionCount > 0
        ? totalDurationMin ~/ sessionCount
        : 0;
    final avgVolumePerSession = sessionCount > 0
        ? totalVolume / sessionCount
        : 0.0;
    String fmtVol(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(l10n.anBasicInfo, theme),
        _buildDataRow(l10n.anSessionCount,
            l10n.anSessionsAndDays(sessionCount, workoutDays), theme),
        _buildDataRow(l10n.anTotalVolume, '${fmtVol(totalVolume)} kg', theme),
        _buildDataRow(
            l10n.anDensity, l10n.anDensityValue(density.toStringAsFixed(1)), theme),
        if (sessionCount > 0)
          _buildDataRow(
            l10n.anAvgPerSession,
            l10n.anAvgPerSessionValue(fmtVol(avgVolumePerSession), avgPerSession),
            theme,
          ),
      ],
    );
  }

  Widget _buildTrendSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(
          widget.periodType == 'week' ? l10n.anTrendWeek : l10n.anTrendMonth,
          theme,
        ),
        Text(
          _formatVolumeTrend(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMuscleDistributionSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(l10n.anMuscleDistribution, theme),
        Text(
          _formatMuscleVolumeDistribution(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSetsPerMuscleSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(
          widget.periodType == 'week'
              ? l10n.anSetsPerMuscleWeek
              : l10n.anSetsPerMuscleMonth,
          theme,
        ),
        Text(
          _formatSetsPerMuscleGroup(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildEstimated1RMSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(l10n.anEstimated1rm, theme),
        Text(
          _formatEstimated1RM(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _build1RMProgressionSection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(l10n.an1rmProgression, theme),
        Text(
          _format1RMProgression(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildRecoverySection(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader(l10n.anRecovery, theme),
        Text(
          _formatRecoveryManagement(l10n),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptContainer(AppThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          _generatedPrompt ?? AppLocalizations.of(context)!.anGeneratingPrompt,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: theme.textColor, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildCopyButton(AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _generatedPrompt == null
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: _generatedPrompt!));
                setState(() => _isPromptCopied = true);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.anCopiedToast)));
              },
        icon: Icon(
          _isPromptCopied ? Icons.check : Icons.copy,
          size: 20,
          color: theme.surfaceColor,
        ),
        label: Text(
          _isPromptCopied ? l10n.anCopiedLabel : l10n.anCopyPrompt,
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: theme.surfaceColor),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
      ),
    );
  }
}
