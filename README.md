<div align="center">

# 🏋️ 撸铁计时器

**组间休息，精准掌控**

🌐 **简体中文** | [English](README_EN.md)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Kaiji-Z/workout-timer?include_prereleases)](https://github.com/Kaiji-Z/workout-timer/releases)

免费 · 开源 · 无广告 · 无会员 · 数据不上传

[下载 APK](https://github.com/Kaiji-Z/workout-timer/releases) · [功能](#-功能) · [截图](#-界面) · [构建](#-从源码构建) · [技术栈](#-技术栈)

</div>

---

| 🏋️ 按计划训练 | 📊 训练统计 | 🤖 AI 计划与统计 |
|:---:|:---:|:---:|
| <img src="docs/screenshots/demo-training.gif" width="240" alt="按计划训练演示（加速播放）"> | <img src="docs/screenshots/demo-stats.gif" width="240" alt="训练统计演示（加速播放）"> | <img src="docs/screenshots/demo-ai.gif" width="240" alt="AI 计划与统计演示（加速播放）"> |
| 动作引导 + 每组记录 | 恢复 · 剂量 · 进步 · 习惯 | 免费 AI，零 API Key |

| 📚 动作库 | 🗂️ 训练历史 | ⚙️ 训练偏好 |
|:---:|:---:|:---:|
| <img src="docs/screenshots/demo-exercises.gif" width="240" alt="动作库演示（加速播放）"> | <img src="docs/screenshots/demo-history.gif" width="240" alt="训练历史演示（加速播放）"> | <img src="docs/screenshots/demo-preferences.gif" width="240" alt="训练偏好演示（加速播放）"> |
| 870+ 动作，双语搜索 | 每组数据完整留档 | AI 自动读取你的画像 |

## 这是什么？

一个**只做一件事**的健身 App：帮你管好组间休息。

你一定经历过——做完一组卧推，拿起手机，刷了 15 分钟短视频，身体凉了，训练状态全没了。撸铁计时器就是为解决这个问题而生。

按下开始，倒计时。时间到了，声音+振动提醒你。就这么简单。

但如果你需要更多——训练计划、动作库、每组重量记录、数据统计——它也能做到。

---

## ✨ 功能

### 🤖 AI 计划，不花一分钱

**不需要 API Key，不需要订阅，不需要任何内置大模型**——这就是本 App 的 AI 玩法：

1. 填一份问卷（目标 / 频率 / 时长 / 经验 / 器械），App 生成一份**专业级训练提示词**
2. 复制提示词，粘贴给你手头**任意免费 AI**（ChatGPT / 豆包 / Kimi / 通义千问…）
3. 把 AI 返回的 JSON 计划贴回来，预览后一键导入日历

AI 训练复盘同理：App 把你的训练数据整理成报告，交给免费 AI 分析，返回建议与下周计划。**你的数据 + 任意免费 AI = 私人教练，成本为零。**

### ⏱️ 计时器

| | |
|---|---|
| 预设休息 | 30秒 / 60秒 / 90秒 / 120秒，一键切换 |
| 大号倒计时 | 训练中不用眯眼看屏幕 |
| 后台计时 | 锁屏后继续倒计时，不中断 |
| 多重提醒 | 声音 + 振动 + 通知弹窗 |
| 组数统计 | 自动记录完成了几组 |
| 完成动画 | 训练结束时圆环变奖牌 |

### 📚 动作库

- **870+ 专业动作**，覆盖胸/背/腿/肩/臂/核心全部肌群
- 每个动作附分步示范图片 + 动作指导
- **中英文双语搜索**，模糊匹配（中文界面也能搜英文动作名）
- 按肌群、器械筛选，收藏常用动作

### 📋 训练计划

- **AI 生成计划**：提示词 → 免费 AI → 一键导入（见上）
- 手动创建：选肌群 → 挑动作 → 自定义组数，三步完成
- 日历视图安排每日训练，当天计划在计时页一键开练
- 执行计划时逐个动作引导，组间自动衔接

### 📊 训练记录与统计

- 每组记录**重量 × 次数**，精确追踪进步
- 自重动作自动计算训练量（生物力学系数）
- **今日状态卡**：肌群恢复时长 + 急慢性负荷比（护栏参考）
- **剂量监控**：滚动 7 天每肌群组数，对照 MEV/MRV 参考带
- **进步追踪**：e1RM 估算趋势 + 最近 PR + 6 周滚动容量
- **习惯热力图**：全年打卡 + 连续达标周
- AI 训练分析报告（配合免费 AI 使用，见上）

### 🌍 界面

- **中英双语**，应用内一键切换
- **3 种主题**：琥珀金 / 珊瑚橙 / 天空蓝，各配自动深色变体
- Flat Vitality 设计系统 — 温暖渐变 + 深蓝强调色
- 全面无障碍支持（Tooltip、语义标注、实时播报）

### 🔒 隐私

- **所有数据只存你手机上**（SQLite 本地数据库）
- 没有账号注册，没有云同步，没有数据上传
- 不收集任何个人信息
- 支持导出 / 导入全部数据（JSON 格式）

---

## 📸 界面

| 计时器 | 训练计划 | 历史记录 |
|:---:|:---:|:---:|
| <img src="docs/screenshots/timer.jpg" width="240" alt="计时器"> | <img src="docs/screenshots/plan-calendar.jpg" width="240" alt="训练计划"> | <img src="docs/screenshots/history.jpg" width="240" alt="历史记录"> |
| 今日计划 + 大号倒计时 | 日历排期 + 计划卡片 | 按月归档的训练史 |

| 统计 · 今日状态 | 统计 · 进步与习惯 | AI 分析 |
|:---:|:---:|:---:|
| <img src="docs/screenshots/stats-overview.jpg" width="240" alt="统计今日状态"> | <img src="docs/screenshots/stats-detail.jpg" width="240" alt="统计进步与习惯"> | <img src="docs/screenshots/ai-analysis.jpg" width="240" alt="AI 分析"> |
| 恢复 chips + 剂量监控 | e1RM 趋势 + 全年热力图 | 数据报告 → 免费 AI 复盘 |

| AI 向导 | 动作库 | 动作详情 |
|:---:|:---:|:---:|
| <img src="docs/screenshots/ai-wizard.jpg" width="240" alt="AI 向导"> | <img src="docs/screenshots/exercise-list.jpg" width="240" alt="动作库"> | <img src="docs/screenshots/exercise-detail.jpg" width="240" alt="动作详情"> |
| 问卷 → 提示词 → 导入 | 870+ 动作搜索筛选 | 分步图解 + 动作指导 |

| 设置 |
|:---:|
| <img src="docs/screenshots/settings.jpg" width="240" alt="设置"> |
| 通知 · 深色模式 · 主题 · 语言 · 数据管理 |

---

## 🚀 快速开始

### 下载安装

直接下载最新 APK 安装即可：

👉 [**GitHub Releases**](https://github.com/Kaiji-Z/workout-timer/releases)

👉 [**Gitee 镜像**](https://gitee.com/kaiji1126/workout-timer/releases)

### 从源码构建

```bash
git clone https://github.com/Kaiji-Z/workout-timer.git
cd workout-timer
flutter pub get
flutter run

# 构建 release APK
flutter build apk --release --no-tree-shake-icons
```

<details>
<summary>🇨🇳 国内镜像</summary>

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```
</details>

---

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| Flutter 3.10+ / Dart 3.10+ | 跨平台 UI |
| Provider (ChangeNotifier) | 状态管理 |
| SQLite (sqflite) | 本地数据库，5 版增量迁移 |
| fl_chart | 数据可视化 |
| flutter_local_notifications | 通知提醒 |
| flutter_localizations (gen-l10n) | 中英双语 |
| Rajdhani | 计时器专用字体 |

---

## 📁 项目结构

```
lib/
├── main.dart                 # 入口，MultiProvider，底部导航
├── providers/                # 状态管理 (ChangeNotifier × 7)
│   ├── timer_provider.dart   # 倒计时 + 组数
│   ├── training_provider.dart # 训练状态机
│   ├── plan_provider.dart    # 计划 CRUD
│   ├── record_provider.dart  # 训练记录 + 统计
│   ├── training_progress_provider.dart # 实时训练进度
│   └── locale_provider.dart  # 中英文切换
├── models/                   # 数据模型 (fromMap/toMap/copyWith)
├── screens/                  # 12 个页面
├── widgets/                  # 可复用组件 (30+)
├── theme/                    # Flat Vitality 主题系统
│   ├── app_theme.dart        # 3 主题 + 深色变体
│   └── theme_provider.dart   # 主题状态 + 持久化
├── animations/               # 动画原语
├── services/                 # 数据库、通知、AI 提示词、统计
│   ├── database_helper.dart  # SQLite v5，增量迁移
│   ├── ai_prompt_service.dart    # AI 计划提示词生成
│   ├── stats_calculator_service.dart # e1RM / 容量 / 剂量
│   └── data_transfer_service.dart    # 数据导出/导入
├── utils/
│   └── dimensions.dart       # AppDimensions 设计 token
└── data/                     # 870+ 动作静态 JSON
```

---

## 🤝 贡献

欢迎提 Issue 和 PR。

1. Fork → 2. 创建分支 → 3. 提交 → 4. Push → 5. 创建 Pull Request

---

## 📄 许可证

[MIT License](LICENSE)

---

## 🙏 致谢

| 资源 | 来源 |
|------|------|
| 健身动作数据库 | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) (CC0) |
| Rajdhani 字体 | [Google Fonts](https://fonts.google.com/specimen/Rajdhani) (SIL OFL) |

---

<div align="center">

**觉得有用？给个 Star ⭐**

[![Star History](https://api.star-history.com/svg?repos=Kaiji-Z/workout-timer&type=Date)](https://star-history.com/#Kaiji-Z/workout-timer&Date)

</div>
