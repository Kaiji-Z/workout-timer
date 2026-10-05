import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/context_l10n.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../theme/build_context_text_styles.dart';
import '../theme/theme_provider.dart';
import '../utils/dimensions.dart';

/// 首次启动三页轮播引导：计时器 → 计划 → 每组记录。
///
/// 跳过、完成、系统返回都会置位 `onboarding_done`，只出现一次；
/// CTA 额外把用户送到计划页开始建第一个计划。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final PageController _controller = PageController();
  int _page = 0;
  bool _completing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete({bool goToPlans = false}) async {
    if (_completing) return;
    _completing = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (goToPlans) MainNavigation.switchToTab(0);
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _complete(goToPlans: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final l10n = context.l10n;
    final isLast = _page == _pageCount - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _complete();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.backgroundColor, theme.backgroundGradientEnd],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // 跳过
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(
                        l10n.onboardingSkip,
                        style: context.labelLarge.copyWith(
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        _buildPage(
                          theme,
                          icon: Icons.timer_outlined,
                          title: l10n.onboardingPage1Title,
                          body: l10n.onboardingPage1Body,
                        ),
                        _buildPage(
                          theme,
                          icon: Icons.playlist_add_check,
                          title: l10n.onboardingPage2Title,
                          body: l10n.onboardingPage2Body,
                        ),
                        _buildPage(
                          theme,
                          icon: Icons.emoji_events_outlined,
                          title: l10n.onboardingPage3Title,
                          body: l10n.onboardingPage3Body,
                        ),
                      ],
                    ),
                  ),
                  // 页指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final active = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.accentColor
                              : theme.accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusPill,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // 主按钮：末页是 CTA，其余是下一步
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                      ),
                      child: Text(
                        isLast ? l10n.onboardingCta : l10n.onboardingNext,
                        style: context.titleLarge.copyWith(
                          color: theme.onAccentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    AppThemeData theme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 48, color: theme.accentColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.headlineLarge.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.bodyLarge.copyWith(
              color: theme.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
