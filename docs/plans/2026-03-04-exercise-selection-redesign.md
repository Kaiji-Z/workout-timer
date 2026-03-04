# Exercise Selection Redesign - Design Document

**Date:** 2026-03-04
**Status:** Approved
**Author:** AI Agent + User

## Problem Statement

Current `ExerciseSelector` widget embedded in `PlanFormScreen` Step 2 has UX issues:
- Selected exercises preview obscures the selection area
- Keyboard popup further compresses the visible area
- Poor mobile interaction experience

## Solution

Redesign as a standalone full-screen selection page with bottom fixed bar for selected items.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Selected items display | Bottom fixed bar | Like shopping cart, always visible, doesn't obscure |
| Navigation | Full-screen page + back button | Consistent with existing flow, easy to extend |
| Detail viewing | Long press to view, tap to select | Primary action (select) is faster, details are secondary |
| Confirmation | Bottom bar confirm button | Unified with bottom bar design, clear affordance |

## Page Structure

```
ExerciseSelectionScreen (New Page)
├── AppBar
│   ├── Back button (←)
│   ├── Title: "选择训练动作"
│   └── Clear button (when items selected)
│
├── Body
│   ├── Search bar (fixed top)
│   ├── Muscle filter chips (horizontal scroll)
│   └── Exercise list (ListView)
│
└── Bottom Fixed Bar (Stack + Positioned)
    ├── Selected count badge
    ├── Selected exercises horizontal preview
    └── Confirm button
```

## Navigation Flow

```
PlanFormScreen (Step 2)
    │
    │ Tap "选择动作" button
    ▼
ExerciseSelectionScreen (Full-screen)
    │
    │ Tap "确认"
    ▼
Return to PlanFormScreen (Step 2)
    └── Auto-display selected exercises summary
```

## Bottom Bar Design

```
┌─────────────────────────────────────────────────┐
│  ┌────┐                                         │
│  │ 3  │ 已选: 卧推、深蹲、硬拉...  [查看全部]   [确认] │
│  └────┘                                         │
└─────────────────────────────────────────────────┘
```

- Unselected: gray badge, disabled button
- 1-3 selected: show all chips
- 4+ selected: show first 2 + "等 N 个" text
- Tap chip × to remove

## List Item Interaction

- **Tap**: Toggle selection
- **Long press**: Show detail sheet (reuse `ExerciseDetailSheet`)
- **Visual feedback**: Scale animation on tap, haptic on long press

## PlanFormScreen Step 2 Redesign

**Before (embedded ExerciseSelector):**
- Search, filters, list, preview all in one scrollable area
- Preview obscures selection when keyboard appears

**After (summary + entry button):**
- Compact summary card showing selected count and names
- Large "选择训练动作" button to open selection page
- Quick recommendations section

## File Changes

| File | Action | Lines |
|------|--------|-------|
| `lib/screens/exercise_selection_screen.dart` | New | ~400 |
| `lib/screens/plan_form_screen.dart` | Modify Step 2 | ~100 |

## Implementation Steps

1. Create `ExerciseSelectionScreen` page skeleton
2. Implement search + muscle filter + exercise list
3. Implement bottom fixed bar
4. Implement long-press detail (reuse `ExerciseDetailSheet`)
5. Modify `PlanFormScreen._buildStep2()`
6. Test complete flow
