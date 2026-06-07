# AGENTS.md - Theme System

**Updated:** 2026-06-07

## OVERVIEW

Flat Vitality theme system with 3 preset themes (amberGold, coralOrange, skyBlue) using warm gradients and deep indigo accents. Supports dark mode via `AppThemeData.dark` getter and `isDark` field. Implements AppThemeType enum with shared_preferences persistence. Legacy theme names (mintGreen, rosePink, vitalityGreen, etc.) are mapped to the 3 active themes for backward compatibility.

## FILES

| File | Lines | Purpose |
|------|-------|---------|
| `app_theme.dart` | ~410 | Theme data models, 3 theme definitions, dark mode getter, full TextTheme |
| `theme_provider.dart` | ~132 | Theme state management with dark mode persistence, legacy name mapping |

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Theme definitions | `app_theme.dart` (`amberGoldTheme`, `coralOrangeTheme`, `skyBlueTheme`) |
| Dark theme getter | `app_theme.dart` (`AppThemeData.dark`) |
| Theme type enum | `app_theme.dart` (`AppThemeType` — includes legacy values for compat) |
| ThemeData conversion | `app_theme.dart` (`toThemeData()` — full 10-level TextTheme) |
| All themes list | `app_theme.dart` (`allThemes` — 3 entries) |
| Theme data model | `app_theme.dart` (`AppThemeData` class with `isDark`, `onAccentColor`, `shadowColor`, `dragHandleColor`) |
| Theme getter | `app_theme.dart` (`getThemeData()` — maps legacy names to active themes) |
| Legacy name mapping | `theme_provider.dart` (`_typeToThemeName()`, `_themeNameToType()`) |
| Dark mode toggle | `theme_provider.dart` (`isDarkMode`, `setDarkMode()`) |

## THEMES

| Theme | Light Colors | Accent | Dark Mode |
|-------|--------------|--------|-----------|
| `amberGold` | #FFB74D → #FFA726 | #1A237E | Derived via `.dark` getter |
| `coralOrange` | #FF8A65 → #FF7043 | #1A237E | Derived via `.dark` getter |
| `skyBlue` | #64B5F6 → #42A5F5 | #0D47A1 | Derived via `.dark` getter |

**Legacy mapping**: `mintGreen` → `amberGold`, `rosePink` → `coralOrange`, `vitalityGreen`/`iphone5cGreen`/`vitalFlow` → `skyBlue`, `vitalityPink`/`iphone5cPink` → `coralOrange`.

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

Dark mode uses `HSLColor.fromAHSL()` to darken primary/secondary while preserving hue. The `toThemeData()` method auto-detects dark mode via the `isDark` boolean field.

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
| `Colors.white` / `Colors.black` | Breaks dark mode | Use `theme.surfaceColor` / `theme.textColor` / `theme.onAccentColor` |
| Hardcoded dark colors | Wrong in light mode | Use `ThemeProvider.currentTheme` |
| Ignoring accent consistency | Confusing UI | Always use accentColor for interactive elements |
| Wrong alpha values | Inconsistent transparency | Use established alpha patterns (0.15, 0.3, 0.4, 0.5) |
| Checking `Theme.of(context).brightness` | Fragile | Use `theme.isDark` boolean field |
| Hardcoded `fontFamily: '.SF Pro'` | Bypasses TextTheme | Use `Theme.of(context).textTheme.*` levels |
| Hardcoded `BorderRadius.circular(n)` | Inconsistent radii | Use `AppDimensions.radiusXxx` tokens |
| Hardcoded `EdgeInsets.all(16)` | Magic number | Use `AppDimensions.screenPadding` |
