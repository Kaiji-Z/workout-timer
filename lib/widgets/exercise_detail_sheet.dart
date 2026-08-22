// 动作详情弹窗与全屏图片画廊（从 exercise_selector.dart 拆分）。
import 'dart:async';
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dimensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/build_context_text_styles.dart';

/// 全屏图片画廊背景色。刻意纯黑（照片浏览器底衬，非主题表面），
/// 与 FullscreenImageViewer 同类用途。
const Color _galleryBackground = Color(0xFF000000);

class ExerciseDetailSheet extends StatefulWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onToggle;
  final Function(int)? onSetsChanged;
  final bool readOnly;

  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onToggle,
    this.onSetsChanged,
    this.readOnly = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    bool isSelected = false,
    required VoidCallback onToggle,
    Function(int)? onSetsChanged,
    bool readOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(
        exercise: exercise,
        isSelected: isSelected,
        onToggle: onToggle,
        onSetsChanged: onSetsChanged,
        readOnly: readOnly,
      ),
    );
  }

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  static const _autoPlayDuration = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (widget.exercise.images.isNotEmpty) {
        setState(() {
          _currentPage = (_currentPage + 1) % widget.exercise.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final hasImages = widget.exercise.images.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              // 拖动条
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
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

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 动作名称
                      Text(
                        widget.exercise.name,
                        style: context.headlineLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.nameEn,
                        style: context.bodyMedium.copyWith(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 标签
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTag(
                            widget.exercise.primaryMuscle.displayName,
                            Icons.fitness_center,
                            theme,
                          ),
                          _buildTag(
                            widget.exercise.equipmentDisplayName(l10n),
                            Icons.sports_gymnastics,
                            theme,
                          ),
                          _buildTag(
                            widget.exercise.levelDisplayName(l10n),
                            Icons.signal_cellular_alt,
                            theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 图片轮播
                      if (hasImages) _buildImageCarousel(theme),

                      // 动作指导
                      if (widget.exercise.instructions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInstructions(theme),
                      ],

                      const SizedBox(height: 24),

                      // 推荐配置
                      _buildRecommendation(theme),

                      const SizedBox(height: 24),

                      // 次要肌肉部位
                      if (widget.exercise.secondaryMuscles.isNotEmpty) ...[
                        Text(
                          l10n.widgetInvolvedMuscles,
                          style: context.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.exercise.secondaryMuscles.map((
                            muscle,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surfaceColor,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXl,
                                ),
                                border: Border.all(
                                  color: theme.textColor.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                muscle.displayName,
                                style: context.bodyMedium.copyWith(
                                  fontSize: 13,
                                  color: theme.textColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 操作按钮
                      if (!widget.readOnly)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onToggle();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isSelected
                                  ? theme.errorColor
                                  : theme.accentColor,
                              foregroundColor: theme.onAccentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLg,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.isSelected
                                  ? l10n.widgetRemoveFromPlan
                                  : l10n.widgetAddToPlan,
                              style: context.titleLarge.copyWith(
                                color: theme.onAccentColor,
                              ),
                            ),
                          ),
                        ),
                      if (!widget.readOnly) const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 图片轮播组件（交叉渐隐自动轮播）
  Widget _buildImageCarousel(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final images = widget.exercise.images;

    return Column(
      children: [
        // 轮播图片 - 使用 AnimatedSwitcher 实现交叉渐隐
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showFullscreenImage(_currentPage),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: SizedBox(
              height: 200,
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  key: ValueKey<int>(_currentPage),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: Hero(
                      tag: 'exercise_image_$_currentPage',
                      child: CachedNetworkImage(
                        imageUrl: images[_currentPage],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.accentColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.accentColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 页面指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _currentPage = index);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.accentColor
                        : theme.textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // 图片说明
        Text(
          l10n.widgetImageStepIndicator(_currentPage + 1, images.length),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 动作指导组件
  Widget _buildInstructions(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, size: 20, color: theme.accentColor),
            const SizedBox(width: 8),
            Text(
              l10n.widgetExerciseInstructions,
              style: context.titleLarge.copyWith(color: theme.textColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.exercise.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 步骤编号
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: context.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.onAccentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 步骤内容
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    child: Text(
                      instruction,
                      style: context.bodyMedium.copyWith(
                        height: 1.5,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 推荐配置组件
  Widget _buildRecommendation(AppThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.widgetRecommendedConfig,
            style: context.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  l10n.widgetRecommendedSetsValue(
                    widget.exercise.recommendation.recommendedSets,
                  ),
                  l10n.widgetRecommendedSets,
                  Icons.repeat,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  widget.exercise.recommendation.repsRangeText(l10n),
                  l10n.widgetRepsRangeLabel,
                  Icons.filter_list,
                  theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  widget.exercise.recommendation.restText(l10n),
                  l10n.widgetRestLabel,
                  Icons.timer,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon, AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.accentColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: context.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    AppThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.accentColor),
        const SizedBox(height: 4),
        Text(value, style: context.titleLarge.copyWith(color: theme.textColor)),
        Text(label, style: context.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  void _showFullscreenImage(int initialIndex) {
    // 使用全屏查看器显示所有图片
    showDialog(
      context: context,
      builder: (context) => _FullscreenImageGallery(
        images: widget.exercise.images,
        initialIndex: initialIndex,
        title: widget.exercise.name,
      ),
    );
  }
}

/// 全屏图片画廊查看器（自动轮播 + 交叉渐隐）
class _FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _FullscreenImageGallery({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullscreenImageGallery> createState() =>
      _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<_FullscreenImageGallery>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  Timer? _autoPlayTimer;
  static const _autoPlayDuration = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (widget.images.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: _galleryBackground,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 图片轮播 - 交叉渐隐
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: AnimatedSwitcher(
                  duration: _fadeDuration,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: InteractiveViewer(
                    key: ValueKey<int>(_currentIndex),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[_currentIndex],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.onAccentColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: theme.onAccentColor.withValues(alpha: 0.54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 顶部栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.widgetClose,
                      icon: Icon(Icons.close, color: theme.onAccentColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: context.headlineMedium.copyWith(
                          color: theme.onAccentColor,
                        ),
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: context.bodyMedium.copyWith(
                        color: theme.onAccentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部指示器
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.screenPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _currentIndex = index);
                        },
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? theme.onAccentColor
                                : theme.onAccentColor.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
