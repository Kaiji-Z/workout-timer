import 'package:flutter/material.dart';

/// [BuildContext] 上的非空文字样式快捷访问。
///
/// Flutter 3.47 的 `TextTheme` 成员仍为 `TextStyle?`，但在 MaterialApp
///（本项目全部页面都在其下）中它们恒非空。与其在数百个调用点重复
/// `Theme.of(context).textTheme.xxx!` 断言，不如收敛到这组 getter——
/// 本文件因此是全仓**唯一**允许出现 `textTheme.xxx!` 断言的地方。
///
/// 用法：`Theme.of(context).textTheme.bodyMedium!.copyWith(...)`
/// 写作 `context.bodyMedium.copyWith(...)`。
extension BuildContextTextStyles on BuildContext {
  TextStyle get displayLarge => Theme.of(this).textTheme.displayLarge!;
  TextStyle get displaySmall => Theme.of(this).textTheme.displaySmall!;
  TextStyle get headlineLarge => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get headlineMedium => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!;
  TextStyle get titleMedium => Theme.of(this).textTheme.titleMedium!;
  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;
  TextStyle get labelLarge => Theme.of(this).textTheme.labelLarge!;
}
