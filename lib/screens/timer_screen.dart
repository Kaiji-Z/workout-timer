import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/training_widget.dart';
import '../theme/theme_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bar_chart_outlined,
              color: theme.secondaryTextColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/stats');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.history_outlined,
              color: theme.secondaryTextColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: theme.secondaryTextColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: const TrainingWidget(),
    );
  }
}
