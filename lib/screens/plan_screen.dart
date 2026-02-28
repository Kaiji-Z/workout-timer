import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../bloc/plan_provider.dart';
import '../models/workout_plan.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/plan_card.dart';
import 'plan_form_screen.dart';
import '../theme/app_theme.dart';

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 标题
            _buildHeader(theme),
            
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
            
            // 当日计划列表
            Expanded(
              child: _buildPlanList(planProvider, theme),
            ),
            
            // 底部导航栏空间
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '训练计划',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          // 今天按钮
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            child: Text(
              '今天',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(PlanProvider planProvider, AppThemeData theme) {
    // 获取选中日期的计划
    final plansForDate = planProvider.getPlansForDate(_selectedDate);
    final allPlans = planProvider.plans;
    
    // 格式化日期显示
    final dateFormat = DateFormat('M月d日 E', 'zh_CN');
    final dateStr = dateFormat.format(_selectedDate);
    final isToday = _isToday(_selectedDate);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                if (plansForDate.isNotEmpty)
                  TextButton(
                    onPressed: () => _showAddPlanToDateSheet(planProvider),
                    child: Text(
                      '+ 添加',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
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
            ...plansForDate.map((plan) => PlanCard(
                  plan: plan,
                  onStart: () => _startPlan(plan),
                  onEdit: () => _navigateToEditPlan(plan),
                  onDelete: () => _confirmDeletePlanFromDay(planProvider, plan),
                ))
          else
            _buildEmptyDayPlan(theme),
          
          const SizedBox(height: 24),
          
          // 计划库标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📚 我的计划库',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToCreatePlan(),
                  child: Text(
                    '+ 新建',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      color: theme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 计划库列表
          if (allPlans.isNotEmpty)
            ...allPlans.map((plan) => CompactPlanCard(
                  plan: plan,
                  onTap: () => _showPlanDetail(plan),
                ))
          else
            EmptyPlanCard(
              onTap: () => _navigateToCreatePlan(),
              title: '还没有计划',
              subtitle: '点击创建你的第一个训练计划',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayPlan(AppThemeData theme) {
    return GestureDetector(
      onTap: () => _showAddPlanToDateSheet(context.read<PlanProvider>()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  void _navigateToCreatePlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanFormScreen(),
      ),
    );
    
    if (result == true) {
      // 刷新计划列表
      if (mounted) {
        context.read<PlanProvider>().loadPlans();
      }
    }
  }

  void _navigateToEditPlan(WorkoutPlan plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanFormScreen(plan: plan),
      ),
    );
    
    if (result == true) {
      if (mounted) {
        context.read<PlanProvider>().loadPlans();
      }
    }
  }

  void _startPlan(WorkoutPlan plan) {
    // TODO: Navigate to timer with plan mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始计划：${plan.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlanDetail(WorkoutPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanDetailSheet(
        plan: plan,
        onAddToDate: () => _addPlanToDate(context.read<PlanProvider>(), plan),
      ),
    );
  }

  void _showAddPlanToDateSheet(PlanProvider planProvider) {
    final allPlans = planProvider.plans;
    
    if (allPlans.isEmpty) {
      _navigateToCreatePlan();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '选择计划添加到 ${_selectedDate.month}月${_selectedDate.day}日',
                style: const TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: allPlans.length,
                  itemBuilder: (context, index) {
                    final plan = allPlans[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).primaryColor,
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
            ],
          ),
        );
      },
    );
  }

  void _addPlanToDate(PlanProvider planProvider, WorkoutPlan plan) async {
    try {
      await planProvider.assignPlanToDate(plan.id, _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已将「${plan.name}」添加到 ${_selectedDate.month}月${_selectedDate.day}日'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeletePlanFromDay(PlanProvider planProvider, WorkoutPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除计划'),
        content: Text('确定要从 ${_selectedDate.month}月${_selectedDate.day}日 移除「${plan.name}」吗？'),
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
                await planProvider.removePlanFromDate(plan.id, _selectedDate);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('已移除'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('移除失败: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
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

  const _PlanDetailSheet({
    required this.plan,
    required this.onAddToDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 计划名称
            Text(
              plan.name,
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // 目标部位
            Text(
              '目标部位：${plan.targetMusclesText}',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // 统计
            Row(
              children: [
                _buildStatItem('${plan.exerciseCount}', '个动作', theme),
                const SizedBox(width: 24),
                _buildStatItem('${plan.totalSets}', '组', theme),
                const SizedBox(width: 24),
                _buildStatItem('~${plan.estimatedDuration}', '分钟', theme),
              ],
            ),
            const SizedBox(height: 24),
            
            // 动作列表
            Text(
              '动作列表',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.textColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 15,
                          color: theme.textColor,
                        ),
                      ),
                    ),
                    Text(
                      '${exercise.effectiveSets}组',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
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
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        color: theme.accentColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Start plan
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      '开始训练',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildStatItem(String value, String label, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: '.SF Pro Display',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.accentColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
