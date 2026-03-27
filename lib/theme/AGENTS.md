# AGENTS.md - Theme System

**Updated:** 2026-03-27

## OVERVIEW

Flat Vitality theme system with 5 preset themes using warm gradients and deep indigo accents. Supports dark mode via `AppThemeData.dark` getter. Implements AppThemeType enum with shared_preferences persistence.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `app_theme.dart` | 383 | Theme data models, 5 theme definitions, dark mode getter |
| `theme_provider.dart` | - | Theme state management with dark mode persistence |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Theme definitions | `app_theme.dart:212-358` (5 preset themes) |
| Dark theme getter | `app_theme.dart:79-118` (`AppThemeData.dark`) |
| Theme type enum | `app_theme.dart:4-10` (`AppThemeType`) |
| ThemeData conversion | `app_theme.dart:73-193` (`toThemeData()`) |
| All themes list | `app_theme.dart:377-383` (`allThemes`) |
| Theme data model | `app_theme.dart:21-64` (`AppThemeData` class) |
| Theme getter | `app_theme.dart:361-374` (`getThemeData()`) |
| Dark mode toggle | `theme_provider.dart` (`isDarkMode`, `setDarkMode()`) |

## THEMES

| Theme | Light Colors | Accent | Dark Mode |
|-------|--------------|--------|-----------|
| `amberGold` | #FFB74D → #FFA726 | #1A237E | Derived via `.dark` getter |
| `coralOrange` | #FF8A65 → #FF7043 | #1A237E | Derived via `.dark` getter |
| `mintGreen` | #81C784 → #66BB6A | #1A237E | Derived via `.dark` getter |
| `rosePink` | #F48FB1 → #EC407A | #1A237E | Derived via `.dark` getter |
| `skyBlue` | #64B5F6 → #42A5F5 | #0D47A1 | Derived via `.dark` getter |

## DARK MODE COLORS

| Element | Light | Dark |
|---------|-------|------|
| Background | Primary → Secondary gradient | Darkened gradient (HSL darkening) |
| Surface | #FFFFFF | #1E1E2E |
| Card | #FFFFFF | #2A2A3C |
| Text primary | #212121 | #E8E8E8 |
| Text secondary | #757575 | #9E9E9E |
| Error | #E53935 | #EF5350 |
| Success | #4CAF50 | #66BB6A |
| Error background | #F5E6E6 | #3E2723 |
| Divider | #E0E0E0 | #3A3A4A |
| Accent | #1A237E | #1A237E (unchanged) |

Dark mode uses `HSLColor.fromAHSL()` to darken primary/secondary while preserving hue. The `toThemeData()` method auto-detects dark mode via `surfaceColor == Color(0xFF1E1E2E)`.

## CONVENTIONS

**Flat Vitality Design System**:
- Warm gradient backgrounds: primaryColor → secondaryColor
- Deep indigo accent (#1A237E) for progress rings, icons, active states
- White surfaces (light) / #1E1E2E dark surfaces (dark)
- 10px progress ring stroke width
- Flat design: no glow, no glass effects
- High contrast text: #212121/#E8E8E8 primary, #757575/#9E9E9E secondary
- `.SF Pro Display/Text` fonts with proper weight hierarchy

**Color Usage**:
- Progress rings: accentColor (deep indigo)
- Icons: accentColor
- Active state indicators: accentColor.withValues(alpha: 0.15)
- Borders: accentColor.withValues(alpha: 0.3-0.4)
- Decorative circles: white with varying alpha (0x40, 0x30, 0x20)

**Dark Mode**:
- Access via `context.watch<ThemeProvider>().currentTheme`
- Dark variant created by `AppThemeData.dark` getter
- Never hardcode `Colors.white` or `Colors.black` — use theme fields
- `toThemeData()` auto-detects dark mode for proper Brightness

**Material 3 Integration**:
- Theme converted via `toThemeData()` method
- Custom cardTheme, appBarTheme, switchTheme, iconTheme
- TextTheme with display/body/title/label hierarchy
- useMaterial3: true, Brightness.light/dark auto-detected

## ANTI-PATTERNS

| Pattern | Why Bad | Instead |
|---------|---------|---------|
| Direct color usage | Breaks theming | Use AppThemeData fields |
| `Colors.white` / `Colors.black` | Breaks dark mode | Use `theme.surfaceColor` / `theme.textColor` |
| Hardcoded dark colors | Wrong in light mode | Use `ThemeProvider.currentTheme` |
| Ignoring accent consistency | Confusing UI | Always use accentColor for interactive elements |
| Wrong alpha values | Inconsistent transparency | Use established alpha patterns (0.15, 0.3, 0.4, 0.5) |
| Checking `Theme.of(context).brightness` | Fragile | Use `theme.surfaceColor == Color(0xFF1E1E2E)` |
