---
target: lib/screens/stats_screen.dart
date: 2026-06-24
round: 2 (post visual-refresh)
total_score: 31
p0_count: 0
p1_count: 0
p2_count: 1
---

# Critique: stats_screen.dart (Round 2, post-refresh)

## Score: 21 → 27 → 31/40. Ship verdict: 改到位.

## Round-2 changes verified
- **Hero differentiation RESOLVED**: `_buildHeroVolume` now solid indigo fill + white 40px number + translucent-white badge. Lone solid surface among 15%-tint subordinates → unambiguous visual center.
- **Month-grid selection RESOLVED**: was warm brand gradient + WCAG fail (white on amber ≈1.6:1); now solid `accentColor` + `onAccentColor` white text. Matches week "today" pill for calendar consistency.
- Charts: all data viz now Okabe-Ito (ChartPalette), varied hue per series (orange=duration, bluish-green=common-exercises, blue=heatmap). No brand-color data viz remains.
- 15% tint rule uniform. tabular-nums on all dense numbers. CountUp honors reduced-motion. Gradient title stripe removed.

## Remaining (non-blocking)
- P2: week-selector "today" worked-day count uses `primaryColor` while month-grid uses Okabe-Ito `heatBlue` — two slightly different "worked" semantics across calendars. Cosmetic.

## Trend
21 → 27 → 31. No P0/P1 remaining. Ship.
