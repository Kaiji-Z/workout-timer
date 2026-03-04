import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../bloc/plan_provider.dart';
import '../widgets/exercise_selector.dart'; // 复用 ExerciseDetailSheet
import '../widgets/fullscreen_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 独立的动作选择页面
/// 
/// 从 PlanFormScreen Step 2 进入，用户可以：
/// - 搜索动作
/// - 按肌肉部位筛选
/// - 点击选中/取消
/// - 长按查看详情
/// - 底部栏显示已选并确认
class ExerciseSelectionScreen extends StatefulWidget {
  /// 从 Step 1 选择的肌肉部位
  final List<PrimaryMuscleGroup> selectedMuscles;
  
  /// 编辑模式时传入的已选动作
  final List<PlanExercise> initialExercises;
  
  const ExerciseSelectionScreen({
    super.key,
    required this.selectedMuscles,
    this.initialExercises = const [],
  });
  
  /// 打开选择页面的静态方法
  static Future<List<PlanExercise>?> show(
    BuildContext context, {
    required List<PrimaryMuscleGroup> selectedMuscles,
    List<PlanExercise>? initialExercises,
  }) {
    return Navigator.push<List<PlanExercise>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSelectionScreen(
          selectedMuscles: selectedMuscles,
          initialExercises: initialExercises ?? [],
        ),
        fullscreenDialog: false,
      ),
    );
  }
  
  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  List<PlanExercise> _selectedExercises = [];
  PrimaryMuscleGroup? _filterMuscle;
  String? _filterEquipment; // 器械类型筛选
  String _searchQuery = '';
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _selectedExercises = List.from(widget.initialExercises);
    // 默认筛选第一个选中的肌肉部位
    if (widget.selectedMuscles.isNotEmpty) {
      _filterMuscle = widget.selectedMuscles.first;
    }
    
    // 搜索控制器
    _searchController = TextEditingController();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final planProvider = context.watch<PlanProvider>();
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(theme),
      body: Stack(
        children: [
          // 主内容区
          Column(
            children: [
              // 搜索框
              _buildSearchBar(theme),
              const SizedBox(height: 12),
              
              // 肌肉部位筛选标签
              if (widget.selectedMuscles.isNotEmpty) ...[
                _buildMuscleFilterChips(theme),
                const SizedBox(height: 12),
              ],
              
              // 器械类型筛选标签
              _buildEquipmentFilterChips(theme),
              const SizedBox(height: 12),
              
              // 动作列表
              Expanded(
                child: _buildExerciseList(planProvider, theme),
              ),
              
              // 底部留白，避免被固定栏遮挡
              const SizedBox(height: 88),
            ],
          ),
          
          // 底部固定栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(theme),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(AppThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '选择训练动作',
        style: TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
      actions: [
        if (_selectedExercises.isNotEmpty)
          TextButton(
            onPressed: _clearSelection,
            child: Text(
              '清空',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                color: theme.accentColor,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildSearchBar(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: '搜索动作...',
            hintStyle: TextStyle(
              fontFamily: '.SF Pro Text',
              color: theme.secondaryTextColor,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: theme.secondaryTextColor,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: theme.secondaryTextColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            color: theme.textColor,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMuscleFilterChips(AppThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // "全部" 选项
          GestureDetector(
            onTap: () => setState(() => _filterMuscle = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _filterMuscle == null ? theme.accentColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filterMuscle == null 
                      ? theme.accentColor 
                      : theme.textColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '全部',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 14,
                  fontWeight: _filterMuscle == null ? FontWeight.w600 : FontWeight.w500,
                  color: _filterMuscle == null ? Colors.white : theme.textColor,
                ),
              ),
            ),
          ),
          // 各肌肉部位
          ...widget.selectedMuscles.map((muscle) {
            final isSelected = _filterMuscle == muscle;
            return GestureDetector(
              onTap: () => setState(() => _filterMuscle = muscle),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.accentColor : theme.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  muscle.displayName,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.textColor,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 器械类型筛选标签
  Widget _buildEquipmentFilterChips(AppThemeData theme) {
    // 器械类型列表（中文名称）
    final equipmentTypes = [
      {'key': null, 'label': '全部'},
      {'key': 'dumbbell', 'label': '哑铃'},
      {'key': 'barbell', 'label': '杠铃'},
      {'key': 'cable', 'label': '绳索'},
      {'key': 'machine', 'label': '器械'},
      {'key': 'kettlebells', 'label': '壶铃'},
      {'key': 'body only', 'label': '自重'},
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: equipmentTypes.map((item) {
          final isSelected = _filterEquipment == item['key'];
          return GestureDetector(
            onTap: () => setState(() => _filterEquipment = item['key']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.accentColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? theme.accentColor 
                      : theme.textColor.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                item['label']!,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildExerciseList(PlanProvider planProvider, AppThemeData theme) {
    // 获取所有动作
    List<Exercise> exercises = planProvider.exercises;
    
    // 按肌肉部位筛选
    if (_filterMuscle != null) {
      exercises = exercises.where((e) => e.primaryMuscle == _filterMuscle).toList();
    }
    
    // 按器械类型筛选
    if (_filterEquipment != null) {
      exercises = exercises.where((e) => e.equipment == _filterEquipment).toList();
    }
    
    // 搜索筛选（增强版：支持名称、英文名、器械类型模糊搜索）
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      exercises = exercises.where((e) {
        final name = e.name.toLowerCase();
        final nameEn = e.nameEn.toLowerCase();
        final equipmentName = e.equipmentDisplayName.toLowerCase();
        final equipmentEn = e.equipment.toLowerCase();
        
        // 支持多个关键词搜索（空格分隔）
        final keywords = query.split(RegExp(r'\s+'));
        
        // 所有关键词都必须匹配
        return keywords.every((keyword) =>
          name.contains(keyword) ||
          nameEn.contains(keyword) ||
          equipmentName.contains(keyword) ||
          equipmentEn.contains(keyword)
        );
      }).toList();
    }
    
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到动作',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = _selectedExercises.any((e) => e.exerciseId == exercise.id);
        return _ExerciseListItem(
          exercise: exercise,
          isSelected: isSelected,
          onTap: () => _toggleExercise(exercise),
          onLongPress: () => _showDetailSheet(exercise, isSelected),
          theme: theme,
        );
      },
    );
  }
  
  Widget _buildBottomBar(AppThemeData theme) {
    final hasSelection = _selectedExercises.isNotEmpty;
    
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 数量徽章
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasSelection ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${_selectedExercises.length}',
                    style: TextStyle(
                      fontFamily: '.SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: hasSelection ? Colors.white : theme.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 已选动作预览
              Expanded(
                child: hasSelection
                    ? _buildSelectedChipsPreview(theme)
                    : Text(
                        '点击动作卡片选择',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 14,
                          color: theme.secondaryTextColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              
              // 确认按钮
              ElevatedButton(
                onPressed: hasSelection ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  disabledBackgroundColor: theme.textColor.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: theme.secondaryTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '确认',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedChipsPreview(AppThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _selectedExercises.take(3).map((exercise) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _removeExerciseById(exercise.exerciseId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 13,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close,
                      size: 14,
                      color: theme.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList()
          ..addAll(
            _selectedExercises.length > 3
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '+${_selectedExercises.length - 3}',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 13,
                          color: theme.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]
                : [],
          ),
      ),
    );
  }
  
  // ==================== 操作方法 ====================
  
  void _toggleExercise(Exercise exercise) {
    HapticFeedback.lightImpact();
    setState(() {
      final existingIndex = _selectedExercises.indexWhere((e) => e.exerciseId == exercise.id);
      
      if (existingIndex >= 0) {
        _selectedExercises.removeAt(existingIndex);
      } else {
        _selectedExercises.add(PlanExercise(
          exerciseId: exercise.id,
          exercise: exercise,
          targetSets: exercise.recommendation.recommendedSets,
          order: _selectedExercises.length,
        ));
      }
    });
  }
  
  void _removeExerciseById(String exerciseId) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedExercises.removeWhere((e) => e.exerciseId == exerciseId);
    });
  }
  
  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedExercises.clear();
    });
  }
  
  void _showDetailSheet(Exercise exercise, bool isSelected) {
    HapticFeedback.mediumImpact();
    ExerciseDetailSheet.show(
      context,
      exercise: exercise,
      isSelected: isSelected,
      onToggle: () => _toggleExercise(exercise),
    );
  }
  
  void _confirmSelection() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _selectedExercises);
  }
}


/// 动作列表项（支持长按）
class _ExerciseListItem extends StatefulWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final AppThemeData theme;
  
  const _ExerciseListItem({
    required this.exercise,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.theme,
  });
  
  @override
  State<_ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<_ExerciseListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }
  
  void _onTapCancel() {
    _scaleController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? widget.theme.accentColor.withValues(alpha: 0.1) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected 
                  ? widget.theme.accentColor 
                  : Colors.transparent,
              width: widget.isSelected ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            leading: GestureDetector(
              onTap: () {
                // 如果有多张图片，使用轮播模式
                if (widget.exercise.images.isNotEmpty) {
                  FullscreenImageViewer.showCarousel(
                    context,
                    images: widget.exercise.images,
                    title: widget.exercise.name,
                    heroTag: widget.exercise.imageUrl, // 传递 Hero 标签
                  );
                } else if (widget.exercise.imageUrl != null) {
                  FullscreenImageViewer.show(
                    context,
                    imageUrl: widget.exercise.imageUrl!,
                    title: widget.exercise.name,
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isSelected 
                      ? widget.theme.accentColor 
                      : widget.theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.exercise.imageUrl != null
                      ? Hero(
                          tag: widget.exercise.imageUrl!,
                          child: CachedNetworkImage(
                            imageUrl: widget.exercise.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              Icons.fitness_center,
                              color: widget.isSelected 
                                  ? Colors.white 
                                  : widget.theme.accentColor,
                              size: 22,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.fitness_center,
                              color: widget.isSelected 
                                  ? Colors.white 
                                  : widget.theme.accentColor,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: widget.isSelected 
                              ? Colors.white 
                              : widget.theme.accentColor,
                          size: 22,
                        ),
                ),
              ),
            ),
            title: Text(
              widget.exercise.name,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 15,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.theme.textColor,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.exercise.primaryMuscle.displayName,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 11,
                      color: widget.theme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.exercise.equipmentDisplayName,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 12,
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
            trailing: widget.isSelected
                ? Icon(Icons.check_circle, color: widget.theme.accentColor, size: 24)
                : Icon(Icons.add_circle_outline, color: widget.theme.secondaryTextColor, size: 24),
          ),
        ),
      ),
    );
  }
}
