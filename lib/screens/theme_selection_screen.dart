import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentTheme = themeProvider.currentTheme;
    
    return Scaffold(
      backgroundColor: currentTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: currentTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentTheme.timerGradientColors,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '选择主题',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: currentTheme.textColor,
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allThemes.length,
        itemBuilder: (context, index) {
          final theme = allThemes[index];
          final isSelected = themeProvider.currentThemeType.name == theme.name;
          
          return _ThemeCard(
            theme: theme,
            isSelected: isSelected,
            onTap: () {
              final themeType = AppThemeType.values.firstWhere(
                (t) => t.name == theme.name,
              );
              themeProvider.setTheme(themeType);
            },
          );
        },
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeData theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Icon(
                    theme.icon,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            theme.nameZh,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '当前',
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 13,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Color preview
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Primary color
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Secondary color
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Accent color
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Success color
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.successColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
