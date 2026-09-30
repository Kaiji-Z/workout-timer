import 'package:flutter/widgets.dart';

import '../models/muscle_group.dart';
import 'app_localizations.dart';

/// Single choke-point for localized-string lookups.
///
/// `context.l10n` asserts that the nearest MaterialApp wraps
/// the given context with the app's localization delegates — a guarantee every
/// screen in this app relies on. Keeping the assertion here lets call sites
/// read `context.l10n.someKey` without scattering force-unwraps across the
/// codebase (same ratified pattern as `BuildContextTextStyles` in
/// lib/theme/build_context_text_styles.dart for textTheme).
extension ContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// 主肌群的本地化名称（复用偏好页 prefFocusArea* 键，zh/en 双语完整）。
///
/// 统计四区组件共用；不要在 UI 里直接用 `muscle.displayName`
/// （那是中文硬编码，英文环境会漏出中文）。
String localizedMuscleGroup(BuildContext context, PrimaryMuscleGroup muscle) {
  final l10n = context.l10n;
  switch (muscle) {
    case PrimaryMuscleGroup.chest:
      return l10n.prefFocusAreaChest;
    case PrimaryMuscleGroup.back:
      return l10n.prefFocusAreaBack;
    case PrimaryMuscleGroup.shoulders:
      return l10n.prefFocusAreaShoulders;
    case PrimaryMuscleGroup.arms:
      return l10n.prefFocusAreaArms;
    case PrimaryMuscleGroup.legs:
      return l10n.prefFocusAreaLegs;
    case PrimaryMuscleGroup.core:
      return l10n.prefFocusAreaCore;
  }
}
