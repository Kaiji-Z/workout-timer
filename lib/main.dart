import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'bloc/timer_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();

  try {
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
    // Continue without notifications - app can still function
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final timerProvider = context.read<TimerProvider>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Pause timer when app goes to background
        if (timerProvider.isRunning) {
          timerProvider.pauseTimer();
        }
        break;
      case AppLifecycleState.resumed:
        // Timer remains paused when returning to foreground
        // User can manually resume if desired
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        timerProvider.dispose();
        break;
    }
  }

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
