# AGENTS.md - Theme System

**Generated:** 2026-02-28

## OVERVIEW

Flat Vitality theme system with 5 preset themes using warm gradients and deep indigo accents. Implements AppThemeType enum with shared_preferences persistence.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `app_theme.dart` | 383 | Theme data models, 5 theme definitions |
| `theme_provider.dart` | - | Theme state management with persistence |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Theme definitions | `app_theme.dart:212-358` (5 preset themes) |
| Theme type enum | `app_theme.dart:4-10` (`AppThemeType`) |
| ThemeData conversion | `app_theme.dart:73-193` (`toThemeData()`) |
| All themes list | `app_theme.dart:377-383` (`allThemes`) |
| Theme data model | `app_theme.dart:21-64` (`AppThemeData` class) |
| Theme getter | `app_theme.dart:361-374` (`getThemeData()`) |

## THEMES

| Theme | Colors | Accent | Notes |
|-------|--------|--------|-------|
| `amberGold` | #FFB74D → #FFA726 | #1A237E (Indigo 900) | Default, warm amber |
| `coralOrange` | #FF8A65 → #FF7043 | #1A237E | Coral orange |
| `mintGreen` | #81C784 → #66BB6A | #1A237E | Fresh mint |
| `rosePink` | #F48FB1 → #EC407A | #1A237E | Sweet pink |
| `skyBlue` | #64B5F6 → #42A5F5 | #0D47A1 | Sky blue (slightly deeper accent) |

## CONVENTIONS

**Flat Vitality Design System**:
- Warm gradient backgrounds: primaryColor → secondaryColor
- Deep indigo accent (#1A237E) for progress rings, icons, active states
- White surfaces: surfaceColor, cardColor = #FFFFFF
- 10px progress ring stroke width
- Flat design: no glow, no glass effects
- High contrast text: #212121 primary, #757575 secondary
- `.SF Pro Display/Text` fonts with proper weight hierarchy

**Color Usage**:
- Progress rings: accentColor (deep indigo)
- Icons: accentColor
- Active state indicators: accentColor.withValues(alpha: 0.15)
- Borders: accentColor.withValues(alpha: 0.3-0.4)
- Decorative circles: white with varying alpha (0x40, 0x30, 0x20)

**Material 3 Integration**:
- Theme converted via `toThemeData()` method
- Custom cardTheme, appBarTheme, switchTheme, iconTheme
- TextTheme with display/body/title/label hierarchy
- useMaterial3: true, Brightness.light for all themes

## ANTI-PATTERNS

| Pattern | Why Bad | Instead |
|---------|---------|---------|
| Direct color usage | Breaks theming | Use AppThemeData fields |
| Ignoring accent consistency | Confusing UI | Always use accentColor for interactive elements |
| Wrong alpha values | Inconsistent transparency | Use established alpha patterns (0.15, 0.3, 0.4, 0.5) |
