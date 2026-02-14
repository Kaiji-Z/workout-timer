import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'bloc/timer_provider.dart';
import 'bloc/training_provider.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '健身计时器',
            theme: themeProvider.currentTheme.toThemeData(),
            home: const TimerScreen(),
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
