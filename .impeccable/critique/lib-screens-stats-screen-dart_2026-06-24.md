---
target: lib/screens/stats_screen.dart
date: 2026-06-24
total_score: 21
p0_count: 2
p1_count: 2
p2_count: 2
---

# Critique: stats_screen.dart

## Design Health Score: 21/40 (Acceptable, lower end)

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Spinner→full; count-up re-fires each refresh, masking real values |
| 2 | Match System / Real World | 3 | Jargon raw: 1RM, MEV, Mayhew with no gloss |
| 3 | User Control & Freedom | 2 | Recovery (primary stat) hidden behind collapsed ExpansionTile |
| 4 | Consistency & Standards | 2 | Two chart-color systems; tint alphas drift 0.08–0.20 |
| 5 | Error Prevention | 3 | Future-date clamping good; no guard for partial-week misleading 周均 |
| 6 | Recognition over Recall | 2 | MEV/1RM/Mayhew + dual-axis legend need prior knowledge |
| 7 | Flexibility & Efficiency | 2 | No custom date range, no filter, no export |
| 8 | Aesthetic & Minimalist | 1 | 25+ numbers, all equal weight, no visual center |
| 9 | Error Recovery | 1 | Load errors swallowed to debugPrint; no retry CTA |
| 10 | Help & Documentation | 1 | Most jargon-dense screen, zero inline explanation |

## Anti-Patterns Verdict: MODERATE-HIGH slop

Structurally the literal "千篇一律的 SaaS 仪表盘" anti-ref. Equal-weight metric-card grid (5×), gradient bars on every chart, decorative gradient title-stripe, count-up theater. No gradient-text/glassmorphism/glow (credit), but composition is generic.

## Priority Issues

- **P0** Equal-weight metric card grid — promote single hero (period total volume + vs上期 delta), demote rest.
- **P0** Charts use brand warm/indigo not ChartPalette (Okabe-Ito) — colorblind-a11y violation; lines 1080/1221/1273/1455 + volume_trend_charts.dart.
- **P1** 15% tint rule broken — drift to 0.08/0.10 at lines 470/538/1706/1745/1747.
- **P1** Count-up ungated on reduced-motion — animation_primitives.dart:214-230.
- **P2** tabular-nums missing on bodySmall/bodyMedium numbers.
- **P2** Decorative gradient title stripe line 271-279.

## Persona Red Flags
- Casey: ~9 numbers首屏 no anchor; nav in top corners outside thumb zone.
- Alex: 1RM "趋势" is text arrow not sparkline; hard caps on top-10/top-5.
- 撸铁者: recovery buried in collapsed tile; 10% tint washes out under glare; day-cells 36px < 48 minTouchTarget.
