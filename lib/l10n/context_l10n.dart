import 'package:flutter/widgets.dart';

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
