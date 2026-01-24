import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'bloc/timer_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: MaterialApp(
        title: '健身计时器',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const TimerScreen(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
