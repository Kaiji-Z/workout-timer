import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 全屏图片查看器
/// 
/// 点击图片显示全屏大图，再点击任意位置退出
/// 支持单图和多图自动轮播模式
class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final List<String>? images; // 多图模式
  final int initialIndex; // 多图模式初始索引
  final String? title;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.images,
    this.initialIndex = 0,
    this.title,
  });

  /// 显示全屏单图
  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? title,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        barrierLabel: '关闭',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, _, __) => FullscreenImageViewer(
          imageUrl: imageUrl,
          title: title,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// 显示全屏多图轮播（自动播放，交叉渐隐）
  static Future<void> showCarousel(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
    String? title,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        barrierLabel: '关闭',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, _, __) => FullscreenImageViewer(
          imageUrl: images.isNotEmpty ? images.first : '',
          images: images,
          initialIndex: initialIndex,
          title: title,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  Timer? _autoPlayTimer;
  static const _autoPlayDuration = Duration(seconds: 3);
  static const _fadeDuration = Duration(milliseconds: 500);

  bool get _isCarouselMode => widget.images != null && widget.images!.length > 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_isCarouselMode) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (widget.images != null && widget.images!.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images!.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCarouselMode) {
      return _buildCarouselMode(context);
    }
    return _buildSingleMode(context);
  }

  /// 单图模式
  Widget _buildSingleMode(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 点击区域 - 点击任意位置关闭
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),
            // 图片
            Center(
              child: Hero(
                tag: widget.imageUrl,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '图片加载失败',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 标题
            if (widget.title != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            // 关闭提示
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '点击任意位置关闭',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 多图轮播模式（自动播放，交叉渐隐）
  Widget _buildCarouselMode(BuildContext context) {
    final images = widget.images!;
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 背景
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),
            // 图片轮播 - 交叉渐隐
            Center(
              child: AnimatedSwitcher(
                duration: _fadeDuration,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: InteractiveViewer(
                  key: ValueKey<int>(_currentIndex),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: images[_currentIndex],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.title ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${images.length}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _currentIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index 
                                ? Colors.white 
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }
}
