import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/plan_screen.dart';
import 'bloc/timer_provider.dart';
import 'bloc/training_provider.dart';
import 'bloc/plan_provider.dart';
import 'bloc/record_provider.dart';
import 'bloc/training_progress_provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/exercise_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Chinese locale
  await initializeDateFormatting('zh_CN', null);

  // Load exercise data from assets
  try {
    await ExerciseService.loadExercises();
    debugPrint('Loaded ${ExerciseService.exercises.length} exercises');
  } catch (e) {
    debugPrint('Failed to load exercises: $e');
    // Continue with fallback built-in exercises
  }

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Skip notification initialization on web
  if (!kIsWeb) {
    final notificationService = NotificationService();

    try {
      await notificationService.initialize();
      await notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      // Continue without notifications - app can still function
    }
  }

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => TrainingProvider()),
        // 健身计划相关Providers
        ChangeNotifierProvider(create: (_) => PlanProvider()..loadPlans()),
        ChangeNotifierProvider(create: (_) => RecordProvider()..loadRecords()),
        ChangeNotifierProvider(create: (_) => TrainingProgressProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '撸铁计时器',
            theme: themeProvider.currentTheme.toThemeData(),
            home: const MainNavigation(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/history': (context) => const HistoryScreen(),
              '/stats': (context) => const StatsScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Decorative background circles - iPhone 5c style
class DecorativeCircles extends StatelessWidget {
  final List<Color> colors;
  
  const DecorativeCircles({super.key, required this.colors});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right circle
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.isNotEmpty ? colors[0] : const Color(0x00000000),
            ),
          ),
        ),
        // Bottom-left circle
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.length > 1 ? colors[1] : const Color(0x00000000),
            ),
          ),
        ),
        // Center-right small circle
        Positioned(
          top: 300,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.length > 2 ? colors[2] : const Color(0x00000000),
            ),
          ),
        ),
      ],
    );
  }
}

/// iOS 26 风格主导航 - 悬浮药丸导航栏
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    TimerScreen(),
    PlanScreen(),
    HistoryScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      // 使用半透明背景
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 渐变背景 - Warm Vitality 风格
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appTheme.backgroundColor,
                  appTheme.backgroundGradientEnd,
                ],
              ),
            ),
          ),
          // Decorative circles
          DecorativeCircles(colors: appTheme.decorativeCircleColors),
          // Content
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                );
              },
              child: _screens[_currentIndex],
            ),
          ),
        ],
      ),
      // iOS 26 风格悬浮导航栏 - 统一毛玻璃效果
      // 扁平导航栏 - Flat Vitality 风格
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.timer_outlined, Icons.timer, '计时器', appTheme),
              _buildNavItem(1, Icons.fitness_center_outlined, Icons.fitness_center, '计划', appTheme),
              _buildNavItem(2, Icons.history_outlined, Icons.history, '历史', appTheme),
              _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, '统计', appTheme),
              _buildNavItem(4, Icons.settings_outlined, Icons.settings, '设置', appTheme),
            ],
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, AppThemeData appTheme) {
    // 使用 accentColor (深色) 确保可见性
    final activeColor = appTheme.accentColor;
    final inactiveColor = appTheme.textColor.withValues(alpha: 0.5);
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
