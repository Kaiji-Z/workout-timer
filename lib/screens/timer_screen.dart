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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.backgroundColor,
              theme.backgroundColor.withValues(alpha: 0.95),
              theme.surfaceColor,
            ],
          ),
        ),
        child: const SafeArea(
          child: TrainingWidget(),
        ),
      ),
    );
  }
}
