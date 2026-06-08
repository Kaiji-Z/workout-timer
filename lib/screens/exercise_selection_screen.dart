import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout_plan.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import '../bloc/plan_provider.dart';
import '../widgets/exercise_selector.dart'; // 复用 ExerciseDetailSheet
import '../widgets/fullscreen_image_viewer.dart';
import '../services/exercise_favorites_service.dart';
import '../services/database_helper.dart';
import '../animations/page_transitions.dart';
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
      FadeUpPageRoute(
        page: ExerciseSelectionScreen(
          selectedMuscles: selectedMuscles,
          initialExercises: initialExercises ?? [],
        ),
      ),
    );
  }

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  List<PlanExercise> _selectedExercises = [];
  PrimaryMuscleGroup? _filterMuscle;
  String? _filterEquipment; // 器械类型筛选
  String _searchQuery = '';
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  bool _showFavoritesOnly = false;
  Set<String> _favoriteIds = {};
  late ExerciseFavoritesService _favoritesService;

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

    // 初始化收藏服务并加载收藏列表
    _initFavorites();
  }

  Future<void> _initFavorites() async {
    final db = await DatabaseHelper.instance.database;
    _favoritesService = ExerciseFavoritesService(database: db);
    _favoriteIds = await _favoritesService.getFavoriteIds();
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(String exerciseId) async {
    await _favoritesService.toggleFavorite(exerciseId);
    _favoriteIds = await _favoritesService.getFavoriteIds();
    if (mounted) setState(() {});
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

              // 收藏筛选标签
              _buildFavoritesFilterChip(theme),
              if (_showFavoritesOnly || _filterEquipment != null)
                const SizedBox(height: 12),

              // 动作列表
              Expanded(child: _buildExerciseList(planProvider, theme)),

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
        tooltip: '返回',
        icon: Icon(Icons.arrow_back, color: theme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '选择训练动作',
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.textColor,
        ),
      ),
      actions: [
        if (_selectedExercises.isNotEmpty)
          TextButton(
            onPressed: _clearSelection,
            child: Text(
              '清空',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: theme.accentColor),
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
          color: theme.surfaceColorRaised,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: AppElevation.resting(theme.shadowColor),
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
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: theme.secondaryTextColor),
            prefixIcon: Icon(Icons.search, color: theme.secondaryTextColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: '清除搜索',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: theme.textColor),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterMuscle = null),
              borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _filterMuscle == null
                      ? theme.accentColor
                      : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                  border: Border.all(
                    color: _filterMuscle == null
                        ? theme.accentColor
                        : theme.textColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '全部',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: _filterMuscle == null
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _filterMuscle == null
                        ? theme.onAccentColor
                        : theme.textColor,
                  ),
                ),
              ),
            ),
          ),
          // 各肌肉部位
          ...widget.selectedMuscles.map((muscle) {
            final isSelected = _filterMuscle == muscle;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _filterMuscle = muscle),
                borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.accentColor : theme.surfaceColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusChip,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? theme.accentColor
                          : theme.textColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    muscle.displayName,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? theme.onAccentColor : theme.textColor,
                    ),
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
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _filterEquipment = item['key']),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : theme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  border: Border.all(
                    color: isSelected
                        ? theme.accentColor
                        : theme.textColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  item['label']!,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? theme.onAccentColor : theme.textColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 收藏筛选标签
  Widget _buildFavoritesFilterChip(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showFavoritesOnly
                  ? theme.accentColor
                  : theme.surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: _showFavoritesOnly
                    ? theme.accentColor
                    : theme.textColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: _showFavoritesOnly
                      ? theme.onAccentColor
                      : theme.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '收藏',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontSize: 13,
                    fontWeight: _showFavoritesOnly
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _showFavoritesOnly
                        ? theme.onAccentColor
                        : theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList(PlanProvider planProvider, AppThemeData theme) {
    // 获取所有动作
    List<Exercise> exercises = planProvider.exercises;

    // 按肌肉部位筛选
    if (_filterMuscle != null) {
      exercises = exercises
          .where((e) => e.primaryMuscle == _filterMuscle)
          .toList();
    }

    // 按器械类型筛选
    if (_filterEquipment != null) {
      exercises = exercises
          .where((e) => e.equipment == _filterEquipment)
          .toList();
    }

    // 按收藏筛选
    if (_showFavoritesOnly) {
      exercises = exercises.where((e) => _favoriteIds.contains(e.id)).toList();
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
        return keywords.every(
          (keyword) =>
              name.contains(keyword) ||
              nameEn.contains(keyword) ||
              equipmentName.contains(keyword) ||
              equipmentEn.contains(keyword),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(color: theme.secondaryTextColor),
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
        final isSelected = _selectedExercises.any(
          (e) => e.exerciseId == exercise.id,
        );
        return _ExerciseListItem(
          exercise: exercise,
          isSelected: isSelected,
          isFavorite: _favoriteIds.contains(exercise.id),
          onTap: () => _toggleExercise(exercise),
          onLongPress: () => _showDetailSheet(exercise, isSelected),
          onToggleFavorite: () => _toggleFavorite(exercise.id),
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
        color: theme.surfaceColorRaised,
        boxShadow: AppElevation.raised(theme.shadowColor),
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
                  color: hasSelection
                      ? theme.accentColor
                      : theme.textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Center(
                  child: Text(
                    '${_selectedExercises.length}',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hasSelection
                          ? theme.onAccentColor
                          : theme.secondaryTextColor,
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
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                  disabledBackgroundColor: theme.textColor.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: theme.onAccentColor,
                  disabledForegroundColor: theme.secondaryTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '确认',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontSize: 15),
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
        children:
            _selectedExercises.take(3).map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _removeExerciseById(exercise.exerciseId),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXl,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(fontSize: 13, color: theme.textColor),
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
                ),
              );
            }).toList()..addAll(
              _selectedExercises.length > 3
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '+${_selectedExercises.length - 3}',
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
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
      final existingIndex = _selectedExercises.indexWhere(
        (e) => e.exerciseId == exercise.id,
      );

      if (existingIndex >= 0) {
        _selectedExercises.removeAt(existingIndex);
      } else {
        _selectedExercises.add(
          PlanExercise(
            exerciseId: exercise.id,
            exercise: exercise,
            targetSets: exercise.recommendation.recommendedSets,
            order: _selectedExercises.length,
          ),
        );
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
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;
  final AppThemeData theme;

  const _ExerciseListItem({
    required this.exercise,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
    required this.theme,
  });

  @override
  State<_ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<_ExerciseListItem> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.theme.accentColor.withValues(alpha: 0.1)
                : widget.theme.surfaceColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: widget.isSelected
                  ? widget.theme.accentColor
                  : Colors.transparent,
              width: widget.isSelected ? 1.5 : 0,
            ),
            boxShadow: AppElevation.resting(widget.theme.shadowColor),
          ),
          child: ListTile(
            leading: Material(
              color: Colors.transparent,
              child: InkWell(
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
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.theme.accentColor
                        : widget.theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: widget.exercise.imageUrl != null
                        ? Hero(
                            tag: widget.exercise.imageUrl!,
                            child: CachedNetworkImage(
                              imageUrl: widget.exercise.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.fitness_center,
                                color: widget.isSelected
                                    ? widget.theme.onAccentColor
                                    : widget.theme.accentColor,
                                size: 22,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.fitness_center,
                                color: widget.isSelected
                                    ? widget.theme.onAccentColor
                                    : widget.theme.accentColor,
                                size: 22,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fitness_center,
                            color: widget.isSelected
                                ? widget.theme.onAccentColor
                                : widget.theme.accentColor,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
            title: Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 15,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: widget.theme.textColor,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    widget.exercise.primaryMuscle.displayName,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      color: widget.theme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.exercise.equipmentDisplayName,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: widget.theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 收藏切换按钮
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onToggleFavorite,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        widget.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isFavorite
                            ? widget.theme.accentColor
                            : widget.theme.secondaryTextColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // 选中/添加按钮
                widget.isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: widget.theme.accentColor,
                        size: 24,
                      )
                    : Icon(
                        Icons.add_circle_outline,
                        color: widget.theme.secondaryTextColor,
                        size: 24,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
