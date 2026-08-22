import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../l10n/context_l10n.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../providers/plan_provider.dart';
import '../models/workout_plan.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/plan_card.dart';
import '../widgets/plan_detail_sheet.dart';
import 'plan_form_screen.dart';
import 'ai_plan_wizard_screen.dart';
import '../theme/app_theme.dart';
import '../animations/page_transitions.dart';
import '../theme/build_context_text_styles.dart';

/// 计划页面 - Flat Vitality 设计
///
/// 布局：上半部分日历 + 下半部分计划列表
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.planTitle,
          style: context.headlineLarge.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                FadeUpPageRoute(page: const AIPlanWizardScreen()),
              );
              if (result == true && context.mounted) {
                context.read<PlanProvider>().loadPlans();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  l10n.planAiButton,
                  style: context.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: AppDimensions.bottomPadding(context),
            ),
            child: Column(
              children: [
                // 日历
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CalendarWidget(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 当日计划列表 - 移除固定高度约束，让内容自适应
                _buildPlanList(planProvider, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanList(PlanProvider planProvider, AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    // 获取选中日期的计划
    final plansForDate = planProvider.getPlansForDate(_selectedDate);

    // 格式化日期显示（locale-aware pattern）
    final localeCode = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('MMM d EEE', localeCode);
    final dateStr = dateFormat.format(_selectedDate);
    final isToday = _isToday(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当日计划标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? l10n.planTodayPlans : l10n.plansForDate(dateStr),
                style: context.titleLarge,
              ),
              if (plansForDate.isNotEmpty)
                TextButton(
                  onPressed: () => _showAddPlanToDateSheet(planProvider),
                  child: Text(
                    l10n.planAddButton,
                    style: context.bodyMedium.copyWith(
                      color: theme.accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 当日计划列表
        if (plansForDate.isNotEmpty)
          ...plansForDate.map(
            (plan) => Dismissible(
              key: ValueKey(plan.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: theme.errorColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: theme.onAccentColor,
                  size: 24,
                ),
              ),
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.planRemoveTitle),
                    content: Text(
                      l10n.planRemoveFromDateConfirm(
                        _selectedDate.month,
                        _selectedDate.day,
                        plan.name,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.widgetCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          l10n.planRemoveAction,
                          style: TextStyle(color: theme.errorColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                planProvider.removePlanFromDate(plan.id, _selectedDate);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.planRemovedToast(
                        _selectedDate.month,
                        _selectedDate.day,
                        plan.name,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: PlanCard(plan: plan, onTap: () => _showPlanDetail(plan)),
            ),
          )
        else
          _buildEmptyDayPlan(theme),

        const SizedBox(height: 16),

        // 计划库按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPlanLibraryModal(planProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.planLibraryButton,
                style: context.titleLarge.copyWith(color: theme.onAccentColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayPlan(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddPlanToDateSheet(context.read<PlanProvider>()),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: theme.accentColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.planEmptyAddToday,
                  style: context.bodyMedium.copyWith(
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  void _navigateToCreatePlan() async {
    final result = await Navigator.push(
      context,
      FadeUpPageRoute(page: const PlanFormScreen()),
    );

    if (result == true) {
      // 刷新计划列表
      if (mounted) {
        context.read<PlanProvider>().loadPlans();
      }
    }
  }

  void _showPlanDetail(WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanDetailSheet(
        plan: plan,
        onAddToDate: () => _addPlanToDate(context.read<PlanProvider>(), plan),
        onDelete: () => _confirmDeletePlan(context.read<PlanProvider>(), plan),
      ),
    );
  }

  void _showAddPlanToDateSheet(PlanProvider planProvider) {
    final allPlans = planProvider.plans;
    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = context.l10n;

    if (allPlans.isEmpty) {
      _navigateToCreatePlan();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    l10n.planSelectToAddTitle(
                      _selectedDate.month,
                      _selectedDate.day,
                    ),
                    style: context.headlineLarge.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      itemCount: allPlans.length,
                      itemBuilder: (context, index) {
                        final plan = allPlans[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: theme.accentColor,
                            ),
                          ),
                          title: Text(plan.name),
                          subtitle: Text(plan.targetMusclesText),
                          onTap: () {
                            _addPlanToDate(planProvider, plan);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCreatePlan();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.planCreateNew),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.accentColor,
                        side: BorderSide(color: theme.accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPlanLibraryModal(PlanProvider planProvider) {
    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    l10n.planLibraryTitle,
                    style: context.headlineLarge.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Consumer<PlanProvider>(
                      builder: (context, provider, child) {
                        final allPlans = provider.plans;
                        return ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          itemCount: allPlans.length,
                          itemBuilder: (context, index) {
                            final plan = allPlans[index];
                            return Column(
                              children: [
                                InkWell(
                                  onTap: () => _showPlanDetail(plan),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: theme.accentColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusMd,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.fitness_center,
                                            color: theme.accentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // 计划名称 + 描述占满剩余宽度
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                plan.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge!
                                                    .copyWith(fontSize: 15),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                plan.targetMusclesText,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      fontSize: 13,
                                                      color: theme.accentColor
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // 编辑/删除按钮在列表项下方
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 68,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push<bool>(
                                            context,
                                            FadeUpPageRoute(
                                              page: PlanFormScreen(plan: plan),
                                            ),
                                          ).then((result) {
                                            if (result == true && mounted) {
                                              provider.loadPlans();
                                            }
                                          });
                                        },
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                        ),
                                        label: Text(l10n.planEdit),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _confirmDeletePlan(provider, plan),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: theme.errorColor,
                                        ),
                                        label: Text(
                                          l10n.planDelete,
                                          style: TextStyle(
                                            color: theme.errorColor,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToCreatePlan();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.planCreateNew),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.accentColor,
                        side: BorderSide(color: theme.accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addPlanToDate(PlanProvider planProvider, WorkoutPlan plan) async {
    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = context.l10n;
    try {
      await planProvider.assignPlanToDate(plan.id, _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.planAddedToDateToast(
                _selectedDate.month,
                _selectedDate.day,
                plan.name,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.planAddFailed(e.toString())),
            backgroundColor: theme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeletePlan(PlanProvider planProvider, WorkoutPlan plan) {
    final theme = context.read<ThemeProvider>().currentTheme;
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planDeleteTitle),
        content: Text(l10n.planDeleteConfirm(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.widgetCancel),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await planProvider.deletePlan(plan.id);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.planDeletedToast(plan.name)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.planDeleteFailed(e.toString())),
                      backgroundColor: theme.errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.planDelete,
              style: TextStyle(color: theme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// 计划详情底部弹窗
