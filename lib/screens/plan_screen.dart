import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';
import '../bloc/plan_provider.dart';
import '../models/workout_plan.dart';
import '../models/muscle_group.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/plan_card.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/exercise_selector.dart';
import 'plan_form_screen.dart';
import 'ai_plan_wizard_screen.dart';
import '../theme/app_theme.dart';
import '../animations/page_transitions.dart';
import '../main.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              '训练计划',
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                FadeUpPageRoute(
                  page: const AIPlanWizardScreen(),
                ),
              );
              if (result == true && mounted) {
                context.read<PlanProvider>().loadPlans();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.accentColor),
                const SizedBox(width: 4),
                Text(
                  'AI训练计划',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
    // 获取选中日期的计划
    final plansForDate = planProvider.getPlansForDate(_selectedDate);

    // 格式化日期显示
    final dateFormat = DateFormat('M月d日 E', 'zh_CN');
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
                isToday ? '今日计划' : '$dateStr 的计划',
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              if (plansForDate.isNotEmpty)
                TextButton(
                  onPressed: () => _showAddPlanToDateSheet(planProvider),
                  child: Text(
                    '+ 添加',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: theme.accentColor),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 当日计划列表
        if (plansForDate.isNotEmpty)
          ...plansForDate
              .map(
                (plan) => Dismissible(
                  key: ValueKey(plan.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: theme.errorColor,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXl,
                      ),
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
                        title: const Text('移除计划'),
                        content: Text(
                          '确定要从 ${_selectedDate.month}月${_selectedDate.day}日 移除「${plan.name}」吗？',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              '移除',
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
                          '已从${_selectedDate.month}月${_selectedDate.day}日移除「${plan.name}」',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: PlanCard(
                    plan: plan,
                    onTap: () => _showPlanDetail(plan),
                  ),
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
                '📚 我的计划库',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: theme.onAccentColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayPlan(AppThemeData theme) {
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
                  '添加今日计划',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
      builder: (context) => _PlanDetailSheet(
        plan: plan,
        onAddToDate: () => _addPlanToDate(context.read<PlanProvider>(), plan),
        onDelete: () => _confirmDeletePlan(context.read<PlanProvider>(), plan),
      ),
    );
  }

  void _showAddPlanToDateSheet(PlanProvider planProvider) {
    final allPlans = planProvider.plans;
    final theme = context.read<ThemeProvider>().currentTheme;

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
                    '选择计划添加到 ${_selectedDate.month}月${_selectedDate.day}日',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge!.copyWith(fontSize: 18),
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
                      label: const Text('创建新计划'),
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
                    '我的计划库',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge!.copyWith(fontSize: 18),
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
                                        label: Text('编辑'),
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
                                          '删除',
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
                      label: const Text('创建新计划'),
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
    try {
      await planProvider.assignPlanToDate(plan.id, _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已将「${plan.name}」添加到 ${_selectedDate.month}月${_selectedDate.day}日',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: theme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeletePlan(PlanProvider planProvider, WorkoutPlan plan) {
    final theme = context.read<ThemeProvider>().currentTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除计划'),
        content: Text('确定要删除「${plan.name}」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
                      content: Text('已删除「${plan.name}」'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('删除失败: $e'),
                      backgroundColor: theme.errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('删除', style: TextStyle(color: theme.errorColor)),
          ),
        ],
      ),
    );
  }
}

/// 计划详情底部弹窗
class _PlanDetailSheet extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onAddToDate;
  final VoidCallback? onDelete;

  const _PlanDetailSheet({
    required this.plan,
    required this.onAddToDate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxs),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 计划名称
            Text(
              plan.name,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            // 右上角删除按钮
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                  icon: Icon(Icons.delete_outline, color: theme.errorColor),
                  tooltip: '删除计划',
                ),
              ),
            const SizedBox(height: 8),

            // 目标部位
            Text(
              '目标部位：${plan.targetMusclesText}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
            ),
            const SizedBox(height: 8),

            // 统计
            Row(
              children: [
                _buildStatItem(context, '${plan.exerciseCount}', '个动作', theme),
                const SizedBox(width: 24),
                _buildStatItem(context, '${plan.totalSets}', '组', theme),
                const SizedBox(width: 24),
                _buildStatItem(
                  context,
                  '~${plan.estimatedDuration}',
                  '分钟',
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 动作列表
            Text('动作列表', style: Theme.of(context).textTheme.titleLarge!),
            const SizedBox(height: 12),
            ...plan.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final planExercise = entry.value;
              final hasDetails = planExercise.hasDetails;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasDetails && planExercise.exercise != null
                      ? () => ExerciseDetailSheet.show(
                          context,
                          exercise: planExercise.exercise!,
                          isSelected: false,
                          onToggle: () => Navigator.pop(context),
                          readOnly: true,
                        )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.textColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 缩略图或序号
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                hasDetails &&
                                    planExercise.exercise?.imageUrl != null
                                ? () {
                                    if (planExercise
                                        .exercise!
                                        .images
                                        .isNotEmpty) {
                                      FullscreenImageViewer.showCarousel(
                                        context,
                                        images: planExercise.exercise!.images,
                                        initialIndex: 0,
                                        title: planExercise.exercise!.name,
                                      );
                                    } else if (planExercise
                                            .exercise!
                                            .imageUrl !=
                                        null) {
                                      FullscreenImageViewer.show(
                                        context,
                                        imageUrl:
                                            planExercise.exercise!.imageUrl!,
                                        title: planExercise.exercise!.name,
                                      );
                                    }
                                  }
                                : null,
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hasDetails
                                    ? theme.accentColor.withValues(alpha: 0.1)
                                    : theme.textColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                                child:
                                    hasDetails &&
                                        planExercise.exercise?.imageUrl != null
                                    ? Hero(
                                        tag: planExercise.exercise!.imageUrl!,
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              planExercise.exercise!.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Icon(
                                            Icons.fitness_center,
                                            color: theme.accentColor.withValues(
                                              alpha: 0.5,
                                            ),
                                            size: 22,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.fitness_center,
                                                color: theme.accentColor
                                                    .withValues(alpha: 0.5),
                                                size: 22,
                                              ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: hasDetails
                                                    ? theme.accentColor
                                                    : theme.secondaryTextColor
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 动作名称
                              Text(
                                hasDetails
                                    ? planExercise.name
                                    : '${planExercise.name} (无详情)',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      fontSize: 15,
                                      color: hasDetails
                                          ? theme.textColor
                                          : theme.secondaryTextColor.withValues(
                                              alpha: 0.7,
                                            ),
                                      fontStyle: hasDetails
                                          ? null
                                          : FontStyle.italic,
                                    ),
                              ),
                              // 肌肉标签和器材信息
                              if (hasDetails &&
                                  planExercise.exercise != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.accentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        planExercise
                                            .exercise!
                                            .primaryMuscle
                                            .displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              fontSize: 11,
                                              color: theme.accentColor,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      planExercise
                                          .exercise!
                                          .equipmentDisplayName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall!,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${planExercise.effectiveSets}组',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: theme.secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddToDate,
                    icon: Icon(Icons.calendar_today, color: theme.accentColor),
                    label: Text(
                      '添加到日历',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: theme.accentColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<PlanProvider>().selectPlan(plan);
                      MainNavigation.switchToTab(2);
                    },
                    icon: Icon(Icons.play_arrow, color: theme.onAccentColor),
                    label: Text(
                      '开始训练',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: theme.onAccentColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    AppThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.accentColor,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall!),
      ],
    );
  }
}
