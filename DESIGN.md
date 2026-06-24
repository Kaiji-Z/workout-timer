---
name: 撸铁计时器 (WorkoutTimer)
description: 组间休息,精准掌控 — Flat Vitality 设计系统
colors:
  # 暖背景族 (Amber Gold 默认主题) — 承载"汗水"温度
  amber-primary: "#FFB74D"
  amber-secondary: "#FFA726"
  coral-primary: "#FF8A65"
  coral-secondary: "#FF7043"
  sky-primary: "#64B5F6"
  sky-secondary: "#42A5F5"
  # 深靛蓝强调族 — 承载"冷静"纪律 (默认 amber/coral 主题用 Indigo 900)
  accent-indigo-deep: "#1A237E"
  accent-indigo-sky: "#0D47A1"
  accent-indigo-dark: "#536DFE"
  accent-indigo-dark-text: "#7986CB"
  # 中性表面族 (Light)
  surface-base: "#FFFFFF"
  surface-raised: "#F5F5F5"
  # 中性表面族 (Dark)
  surface-base-dark: "#1E1E2E"
  surface-card-dark: "#2A2A3C"
  surface-overlay-dark: "#33334A"
  # 文字
  text-primary: "#212121"
  text-secondary: "#757575"
  text-primary-dark: "#E8E8E8"
  text-secondary-dark: "#9E9E9E"
  # 分隔/边界
  divider: "#E0E0E0"
  divider-dark: "#3A3A4A"
  # 语义
  semantic-error: "#E53935"
  semantic-error-dark: "#EF5350"
  semantic-success: "#4CAF50"
  semantic-success-dark: "#66BB6A"
  semantic-warning: "#FF9800"
  semantic-warning-dark: "#FFB74D"
  semantic-info: "#2196F3"
  semantic-info-dark: "#64B5F6"
  semantic-error-bg: "#F5E6E6"
  semantic-error-bg-dark: "#3E2723"
typography:
  display:
    fontFamily: ".SF Pro Display, -apple-system, system-ui, sans-serif"
    fontWeight: 700
    letterSpacing: -1
    fontFeature: "tabular-nums"
  display-medium:
    fontFamily: ".SF Pro Display, -apple-system, system-ui, sans-serif"
    fontWeight: 700
    letterSpacing: -0.5
    fontFeature: "tabular-nums"
  headline:
    fontFamily: ".SF Pro Display, -apple-system, system-ui, sans-serif"
    fontWeight: 600
  title:
    fontFamily: ".SF Pro Text, -apple-system, system-ui, sans-serif"
    fontWeight: 600
    fontFeature: "tabular-nums"
  body:
    fontFamily: ".SF Pro Text, -apple-system, system-ui, sans-serif"
    fontWeight: 400
  body-small:
    fontFamily: ".SF Pro Text, -apple-system, system-ui, sans-serif"
    fontWeight: 400
  label:
    fontFamily: ".SF Pro Text, -apple-system, system-ui, sans-serif"
    fontWeight: 500
    fontFeature: "tabular-nums"
  # 计时器专用字体 — 不在 Material TextTheme 中,独立使用
  timer-display:
    fontFamily: "Orbitron, Rajdhani, monospace"
    fontWeight: 700
    fontFeature: "tabular-nums"
rounded:
  xxs: "3px"
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  chip: "20px"
  sheet: "24px"
  pill: "28px"
  navbar: "25px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  xxxl: "48px"
  screen: "16px"
components:
  button-circular:
    backgroundColor: "{colors.surface-base}"
    textColor: "{colors.text-primary}"
    rounded: "9999px"
    size: "56px"
  button-primary:
    backgroundColor: "{colors.accent-indigo-deep}"
    textColor: "#FFFFFF"
    rounded: "{rounded.pill}"
    height: "56px"
  button-primary-destructive:
    backgroundColor: "{colors.semantic-error}"
    textColor: "#FFFFFF"
    rounded: "{rounded.pill}"
    height: "56px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.accent-indigo-deep}"
    rounded: "{rounded.pill}"
    height: "56px"
  card-flat:
    backgroundColor: "{colors.surface-raised}"
    rounded: "{rounded.xl}"
    padding: "16px"
  badge-flat:
    backgroundColor: "{colors.accent-indigo-deep}"
    textColor: "{colors.accent-indigo-deep}"
    rounded: "{rounded.chip}"
    padding: "14px 8px"
  badge-status:
    rounded: "{rounded.chip}"
    padding: "16px 8px"
  chip-preset:
    backgroundColor: "{colors.surface-base}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.pill}"
---

# Design System: 撸铁计时器 (WorkoutTimer)

## 1. Overview

**Creative North Star: "汗水与冷静"**

撸铁计时器的视觉系统是一场温度的对决:背景是**汗水**——温暖的渐变(琥珀金/珊瑚橙/天际蓝),传递"运动值得,坚持值得"的活力;强调色是**冷静**——深靛蓝 (#1A237E) 像纪律一样压在暖背景上,给整个界面重量、方向、可读性。一个负责燃烧,一个负责专注。缺了任何一个,系统就塌了:只有暖色会轻浮喧闹,只有深蓝会冰冷无情。

这是一个**扁平**系统。没有玻璃模糊、没有发光辉光、没有装饰性渐变文字。深度由三层 elevation(resting / raised / floating)通过克制的阴影传达,而非堆叠视觉特效。圆角是温柔的(卡片 16px,芯片 20px,胶囊 28px),按钮是实在的(白色圆形 + 深色图标,按下时缩到 92%)。一切都在说:"我帮你自律,我不烦你。"

计时器是绝对的视觉中心。当倒计时数字出现,其他一切退后。这是产品存在的理由,设计系统服务于它。

**显式拒绝(来自 PRODUCT.md 反例):**
- 广告堆满的健身 App — 计时器界面永不出现推销元素
- 冷冰冰的临床记录器 — 温度由背景对决承载,不是纯数据灰
- 过度玻璃/动画堆砌 — Flat 是承诺,每个动画都有目的
- 千篇一律的 SaaS 仪表盘 — 深蓝 + 暖橙的对决是记忆点,不是通用工具外观

**Key Characteristics:**
- **温度对决**:暖背景 vs 深靛蓝,缺一不可
- **彻底扁平**:无发光、无玻璃、无渐变文字
- **大号可扫读**:计时器数字是绝对中心,其他退后
- **温柔圆角 + 实在按钮**:16–28px 圆角,白色圆形按钮按下缩放
- **三层 elevation**:resting / raised / floating,克制阴影
- **色盲安全**:数据可视化用 Okabe-Ito 调色板

## 2. Colors: 汗水与冷静的对决

整个调色板围绕一组对立:**暖背景族**(汗水)与**深靛蓝强调族**(冷静)。中性表面保持纯净白(浅色)或近黑(深色),不向任何一方偏色,以免破坏对决的纯粹。

### Primary(暖背景族 — 汗水)

三个主题各是一组暖渐变,默认 amberGold:

- **琥珀金主色 (Amber Gold)** (#FFB74D → #FFA726):默认主题。温暖明亮,健身房灯光下的活力。背景渐变起止色。
- **珊瑚橙主色 (Coral Orange)** (#FF8A65 → #FF7043):热情活力,更饱和的暖。背景渐变起止色。
- **天际蓝主色 (Sky Blue)** (#64B5F6 → #42A5F5):清新宁静——注意它仍是"背景暖色"角色,只是色相偏冷。背景渐变起止色。

### Secondary(深靛蓝强调族 — 冷静)

纪律的颜色,压在暖背景之上:

- **深靛蓝 (Indigo 900)** (#1A237E):amberGold 与 coralOrange 主题的进度环、强调图标、主操作按钮背景。这是"冷静"的核心。
- **深蓝 (Blue 900)** (#0D47A1):skyBlue 主题专用强调色(因为背景已是蓝,强调色需更深以保持对决)。
- **靛蓝亮 (Indigo Accent 400)** (#536DFE):深色模式下的进度环——浅化以保证可见度。
- **靛蓝文字 (Indigo 300)** (#7986CB):深色模式下的强调文字/图标。#1A237E 在深色背景上对比度失败(~1.1:1),必须浅化。

### Neutral(中性表面)

刻意保持中性,不参与对决:

- **纯白基底** (#FFFFFF):浅色模式卡片、按钮背景。
- **浅灰浮起** (#F5F5F5):浅色模式 raised 卡片层级。
- **近黑基底** (#1E1E2E):深色模式背景。保留暖色微调(非纯黑),与暖主题呼应。
- **深灰卡片** (#2A2A3C):深色模式卡片层级。
- **更深浮起** (#33334A):深色模式对话框/浮层。

### Text

- **主文字** (#212121 浅 / #E8E8E8 深):高对比正文。
- **次要文字** (#757575 浅 / #9E9E9E 深):辅助说明。注意深色模式次要文字 #9E9E9E 在 #1E1E2E 上对比度约 7:1,达标。

### 语义色

错误 #E53935(深 #EF5350)、成功 #4CAF50(深 #66BB6A)、警告 #FF9800(深 #FFB74D)、信息 #2196F3(深 #64B5F6)、错误背景 #F5E6E6(深 #3E2723)。分隔线 #E0E0E0(深 #3A3A4A)。深色模式统一浅化一档。

### 数据可视化(Okabe-Ito 色盲安全)

独立于品牌色:`ChartPalette.colors` = [#E69F00 橙, #56B4E9 天蓝, #009E73 蓝绿, #F0E442 黄, #0072B2 蓝, #D55E00 朱, #CC79A7 紫红]。**任何图表、肌群分布环、趋势线都用这套**,不用品牌深靛蓝,因为色盲用户无法区分。

### Named Rules

**The Duality Rule.** 暖背景与深靛蓝强调必须同时在场。一个屏幕不能只有暖色(轻浮),也不能只有深蓝(冰冷)。进度环 = 深靛蓝,背景 = 暖渐变,这是产品的人格签名。

**The 15% Tint Rule.** 强调色作为"激活态"背景时,一律用 `accentColor.withValues(alpha: 0.15)`——flat badge、pressed 高亮、激活芯片。15% 是甜点:够看见,不喧宾夺主。

**The Sky-Blue Exception Rule.** skyBlue 主题背景已是蓝色,强调色改用更深的 #0D47A1 而非 #1A237E,否则背景与强调色融成一片失去对决。每个主题的强调色必须能"压住"自己的背景。

## 3. Typography

**Display Font:** .SF Pro Display(系统字体,fallback `-apple-system, system-ui, sans-serif`)
**Body Font:** .SF Pro Text(系统字体,同 fallback)
**Timer Font:** Orbitron / Rajdhani(独立打包于 `fonts/`,仅用于计时器倒计时数字)

**Character:** 系统字体保证原生质感与性能;计时器专用等宽几何字体让数字有"机器般的精准感"——这是产品核心,值得一个专属字体。所有数字角色(display / display-medium / title / label)启用 `tabular-nums`(等宽数字),防止倒计时跳动时数字宽度变化。

### Hierarchy(对应 Flutter `textTheme`)

- **Display Large** (w700, 48px, letterSpacing -1, tabular-nums):最大级标题,极少使用。
- **Display Medium** (w700, 36px, letterSpacing -0.5, tabular-nums):屏幕主标题。
- **Display Small** (w600, 28px, letterSpacing -0.3):大标题。
- **Headline Large** (w600, 24px):章节标题。
- **Headline Medium** (w600, 18px):小节标题。
- **Title Large** (w600, 16px, tabular-nums):卡片标题、列表项标题。`SectionHeader` 默认用此。
- **Body Large** (w400, 16px):正文。
- **Body Medium** (w400, 14px):辅助正文。
- **Body Small** (w400, 12px, secondaryTextColor):最小文字,仅次要信息。
- **Label Large** (w500, 14px, tabular-nums):按钮文字、徽章、芯片。`PrimaryActionButton` 文字用此 + letterSpacing 0.5。

### 计时器专属(不在 TextTheme)

- **Timer Display** (Orbitron, w700, tabular-nums):倒计时大号数字。响应式尺寸 `screenWidth × 0.9` clamp(280, 400)。这是全屏视觉中心。

### Named Rules

**The Tabular-Numbers Rule.** 任何会变化的数字(倒计时、组数、重量、统计值)必须用 `FontFeature.tabularFigures()`。等宽数字防止跳动,这是计时器可读性的底线。

**The One Display Font Rule.** Orbitron/Rajdhani **只**用于计时器倒计时数字,不用于标题、按钮、正文。它的稀缺性正是它的力量——出现在哪里,哪里就是视觉中心。

## 4. Elevation

**彻底扁平是默认。** 这个系统不用阴影制造装饰,只用它传达状态。三层 elevation 通过 `AppElevation` 类集中定义,任何散落的 `BoxShadow` 字面量都是违规。

阴影颜色统一为 `theme.shadowColor = textColor.withValues(alpha: 0.12)`——半透明的文字色,而非纯黑,保证在暖背景上自然。

### Shadow Vocabulary

- **Resting** (`0 2px 8px rgba(text,0.12)`):卡片静止时的微妙阴影。让卡片"浮"一点,不抢戏。
- **Raised** (`0 4px 16px rgba(text,0.12)` + `0 2px 10px transparent`):激活/提升卡片、`CircularControlButton`、`PrimaryActionButton`。明显的提升感,按下时配合 0.92 缩放。
- **Floating** (`0 8px 24px rgba(text,0.12)` + `0 4px 16px transparent`):FAB、对话框、底部弹层。最大阴影,用于打断层级的元素。

### Named Rules

**The Flat-By-Default Rule.** 表面静止时是平的。阴影只在状态改变时出现(提升、悬浮、聚焦)。一个永远有重阴影的卡片是装饰过度。

**The No-Glow Rule.** 禁止发光效果(glow、外辉光、彩色光晕)。进度环画家 `CircularProgressPainter` 用了 `MaskFilter.blur(BlurStyle.normal, 8)`,这是**唯一**允许的轻微模糊,用于进度环边缘柔化——但它不是发光装饰,是抗锯齿级的柔化。任何新元素想加发光,先问:这是 Flat Vitality 吗?答案永远是否。

## 5. Components

### 圆形控制按钮 (CircularControlButton) — 签名组件

计时器周围的操作按钮,参考图核心样式。

- **Shape:** 完整圆形(`BoxShape.circle`),尺寸 56px(可配,中心计时按钮 70px)。
- **Fill:** `theme.cardColor`(浅色=纯白 #FFFFFF,深色=#2A2A3C)。
- **Icon:** 深色图标(`theme.textColor`),尺寸 = 按钮尺寸 × 0.45。
- **Shadow:** `AppElevation.raised`。
- **Press:** `PressableMixin`,按下缩放到 0.92(easeOut, 100ms)。
- **A11y:** `Semantics(button: true, label: ...)`,所有实例必须传 `semanticLabel`。

### 主操作按钮 (PrimaryActionButton) — 胶囊形

深靛蓝实心,承载主操作("开始训练""保存")。

- **Shape:** 完整胶囊(`height / 2` 圆角),高度 56px(可配)。
- **Fill:** `theme.accentColor`(#1A237E),`isDestructive` 时用 `theme.errorColor`。
- **Content:** 白色文字(`theme.onAccentColor`)+ 可选白色图标,水平内边距 24px,图标-文字间距 8px。
- **Text:** `titleLarge` + `letterSpacing 0.5` + 白色。
- **Shadow:** `AppElevation.raised`,阴影色用强调色 30% 透明(彩色阴影增强归属感)。
- **Press:** `PressableMixin` 默认 0.95 缩放。

### 次要按钮 (_SecondaryButton) — 描边胶囊

透明背景 + 强调色描边 + 强调色文字,用于次要操作("取消""查看全部")。

- **Shape:** 胶囊,高度 56px。
- **Fill:** `Colors.transparent`。
- **Border:** `color.withValues(alpha: 0.5)`,width 2。
- **Text:** 强调色,`titleLarge` fontSize 15。
- **Icon:** 强调色,20px。

### 扁平卡片 (FlatCard)

列表项、信息块的标准容器。

- **Corner:** `radiusXl` (16px)。
- **Fill:** `theme.surfaceColorRaised`(浅=#F5F5F5,深=#2A2A3C)——注意用 raised 层级,比 base 稍深,制造层级。
- **Padding:** 默认 `screenPadding` (16px)。
- **Shadow:** `AppElevation.raised`。
- **Border:** 无。

### 扁平徽章 (FlatBadge) / 状态徽章 (StatusBadge)

胶囊形标签。

- **FlatBadge Fill:** `accentColor.withValues(alpha: 0.15)`(The 15% Tint Rule),文字强调色。padding `14px 8px`,圆角 `radiusChip` (20px)。
- **StatusBadge:** 任意 color,fill `color.withValues(alpha: 0.15)`,border `color.withValues(alpha: 0.3)` width 1。用于状态标记(完成/进行中/休息)。

### 预设芯片 (PresetChip)

30s/60s/90s/120s 快速选择。

- **Shape:** 完整胶囊。
- **Unselected:** 白色背景 + 深色文字。
- **Selected:** 强调色背景 + 白色文字。

### 底部导航栏 (Floating NavBar)

浮动设计,`extendBody: true`。

- **Container:** 70px 高,底部 16px 外边距,4 角圆角 25px(`radiusNavbar`),白色(浅)/深灰(深)背景。
- **Center Timer Button:** 70×70 圆形,渐变填充,底部对齐突出——5 个按钮里它是视觉锚点。
- **Icons:** 未选中次要色,选中强调色。

### 弹层 (Bottom Sheet)

- **Drag Handle:** 40×4 小条,`dragHandleColor`(= divider 色),圆角 3px。
- **Shape:** 顶部圆角 `radiusSheet` (24px)。

### 进度环 (CircularProgressPainter) — 签名组件

计时器的核心视觉。

- **Stroke:** 10px(`progressStrokeWidth`),`StrokeCap.round`。
- **Background Track:** `progressBgColor`(白色 20% 透明)。
- **Progress Arc:** 深靛蓝渐变(`timerGradientColors` = [accent, accent@70%]),起始角 -π/2(顶部)。
- **Edge:** `MaskFilter.blur(BlurStyle.normal, 8)` 唯一允许的柔化。

## 6. Do's and Don'ts

### Do:

- **Do** 保持暖背景与深靛蓝强调同时在场(The Duality Rule)。每个主要屏幕都要有这场对决。
- **Do** 用 `AppThemeData` 字段取色,永不硬编码 `Colors.white`/`Colors.black`——深色模式会崩。
- **Do** 让计时器倒计时数字用 Orbitron 并占据视觉中心(The One Display Font Rule)。
- **Do** 给所有会变化的数字加 `FontFeature.tabularFigures()`(The Tabular-Numbers Rule)。
- **Do** 用 `AppElevation.resting/raised/floating` 三层阴影,不写散落的 `BoxShadow` 字面量。
- **Do** 用 `AppDimensions` 的 8 级圆角 token(xxs→pill),不发明新圆角值。
- **Do** 激活态背景统一用 `accentColor.withValues(alpha: 0.15)`(The 15% Tint Rule)。
- **Do** 所有可交互元素 ≥ 48dp 触控目标(`AppDimensions.minTouchTarget`),健身房手汗场景宁大勿小。
- **Do** 图表用 `ChartPalette`(Okabe-Ito),不用品牌深靛蓝——色盲安全优先。
- **Do** 所有 `CircularControlButton` 传 `semanticLabel`。

### Don't:

- **Don't** 做成"广告堆满的健身 App"——计时器界面永不出现横幅、付费墙、社交噪音(PRODUCT.md 反例)。
- **Don't** 做成"冷冰冰的临床记录器"——温度由暖背景对决承载,不是纯数据灰(PRODUCT.md 反例)。
- **Don't** 用 glassmorphism / 毛玻璃作为默认装饰(The No-Glow Rule,PRODUCT.md 反例"过度玻璃/动画堆砌")。
- **Don't** 加发光效果(glow、彩色光晕、外辉光)。进度环的 `MaskFilter.blur(8)` 是唯一例外且仅用于抗锯齿柔化。
- **Don't** 用 `background-clip: text` 渐变文字——用单色,强调靠字重或字号。
- **Don't** 做成"千篇一律的 SaaS 仪表盘"——英雄数字大卡片、企业中性灰是反例(PRODUCT.md)。
- **Don't** 用 `border-left`/`border-right` > 1px 做彩色侧条——用完整边框、背景色块或前导图标代替。
- **Don't** 在卡片上同时堆 `1px border` + `宽软阴影`——选其一(单一实色边框,或不超过 8px blur 的阴影)。
- **Don't** 卡片圆角超过 16px——`radiusXl` 是卡片上限,24px+ 留给弹层,28px 留给胶囊。
- **Don't** 在浅色模式硬编码深色值,或反之——永远走 `ThemeProvider.currentTheme`。
- **Don't** 让 Orbitron 出现在标题、按钮或正文——它只属于计时器倒计时(The One Display Font Rule)。
