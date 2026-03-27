import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
            home: MainNavigation(key: MainNavigation.globalKey),
          );
        },
      ),
    );
  }
}

/// Decorative background circles - iPhone 5c style
/// Uses LayoutBuilder for responsive positioning based on screen size
class DecorativeCircles extends StatelessWidget {
  final List<Color> colors;

  const DecorativeCircles({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Top-right circle
            Positioned(
              top: -constraints.maxHeight * 0.12,
              right: -constraints.maxWidth * 0.1,
              child: Container(
                width: constraints.maxWidth * 0.6,
                height: constraints.maxWidth * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.isNotEmpty
                      ? colors[0]
                      : const Color(0x00000000),
                ),
              ),
            ),
            // Bottom-left circle
            Positioned(
              bottom: -constraints.maxHeight * 0.1,
              left: -constraints.maxWidth * 0.05,
              child: Container(
                width: constraints.maxWidth * 0.5,
                height: constraints.maxWidth * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.length > 1
                      ? colors[1]
                      : const Color(0x00000000),
                ),
              ),
            ),
            // Center-right small circle
            Positioned(
              top: constraints.maxHeight * 0.3,
              right: -constraints.maxWidth * 0.08,
              child: Container(
                width: constraints.maxWidth * 0.3,
                height: constraints.maxWidth * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.length > 2
                      ? colors[2]
                      : const Color(0x00000000),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// iOS 26 风格主导航 - 悬浮药丸导航栏
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Global key to access MainNavigation state for tab switching
  static final GlobalKey<_MainNavigationState> globalKey =
      GlobalKey<_MainNavigationState>();

  /// Switch to a specific tab by index
  static void switchToTab(int index) {
    globalKey.currentState?.setCurrentIndex(index);
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2;

  /// Allow external code to change the current tab
  void setCurrentIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    PlanScreen(),
    HistoryScreen(),
    TimerScreen(),
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
          // Content without bottom padding - nav bar floats over content
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.0, 0.02),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
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
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Nav bar with all-corner radius
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25), // All 4 corners
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
                  _buildNavItem(
                    0,
                    Icons.fitness_center_outlined,
                    Icons.fitness_center,
                    appTheme,
                    '训练计划',
                  ),
                  _buildNavItem(
                    1,
                    Icons.history_outlined,
                    Icons.history,
                    appTheme,
                    '历史记录',
                  ),
                  _buildNavItem(
                    2,
                    Icons.sports_gymnastics_outlined,
                    Icons.sports_gymnastics,
                    appTheme,
                    '计时器',
                  ),
                  _buildNavItem(
                    3,
                    Icons.bar_chart_outlined,
                    Icons.bar_chart,
                    appTheme,
                    '训练统计',
                  ),
                  _buildNavItem(
                    4,
                    Icons.settings_outlined,
                    Icons.settings,
                    appTheme,
                    '设置',
                  ),
                ],
              ),
            ),
            // Center button aligned at bottom
            Positioned(
              bottom: 0, // Bottom of circle aligns with bottom of nav bar
              child: _buildCenterTimerButton(appTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    AppThemeData appTheme,
    String label,
  ) {
    // 使用 accentColor (深色) 确保可见性
    final activeColor = appTheme.accentColor;
    final inactiveColor = appTheme.textColor.withValues(alpha: 0.5);
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _currentIndex = index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterTimerButton(AppThemeData appTheme) {
    final activeColor = appTheme.accentColor;
    final isSelected = _currentIndex == 2;

    return Semantics(
      label: '训练计时器',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = 2),
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSelected
                    ? [activeColor, activeColor.withValues(alpha: 0.7)]
                    : [
                        activeColor.withValues(alpha: 0.5),
                        activeColor.withValues(alpha: 0.35),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.timer, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
