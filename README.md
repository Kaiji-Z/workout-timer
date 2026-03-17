<div align="center">

# 🏋️ 撸铁计时器 | Workout Timer

**专注训练，不再分心**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)](https://flutter.dev)

**免费 · 开源 · 无广告 · 无会员**

[功能特性](#-功能特性) · [快速开始](#-快速开始) · [截图预览](#-截图预览) · [技术栈](#-技术栈)

</div>

---

## 🎯 为什么选择撸铁计时器？

### 你是否也有这样的经历？

> 💪 刚做完一组卧推，拿起手机刷个短视频...
> 
> ⏰ 一抬头，**15分钟过去了**
> 
> 😰 身体凉了，训练状态全无

**组间休息时间失控，是健身效率的头号杀手。**

- ❌ 休息太短 → 肌肉恢复不足，下一组质量下降
- ❌ 休息太长 → 身体冷却，训练节奏被打断

### 市面上的健身 App 怎么样？

| 问题 | 现状 |
|------|------|
| 📱 **功能繁杂** | 社交、商城、课程...真正需要的计时功能反而难找 |
| 💰 **会员绑架** | 基础功能也要开会员，不付费就限制使用 |
| 📢 **广告干扰** | 训练中弹出广告，打断专注状态 |
| ☁️ **隐私担忧** | 数据上传云端，不知道被用来做什么 |

### 我们的解决方案

**撸铁计时器** —— 一个专注做好一件事的健身 App：

> ⏱️ **简单但专业** —— 只做计时，做到极致
> 
> 🔔 **提醒到位** —— 声音+振动+弹窗，不怕错过
> 
> 🆓 **完全免费** —— 开源项目，无广告，无会员，无套路

---

## ✨ 功能特性

### ⏱️ 专业计时器

| 功能 | 说明 |
|------|------|
| 预设时长 | 30秒 / 60秒 / 90秒 / 120秒 一键切换 |
| 大号显示 | 倒计时一目了然，训练中无需眯眼看 |
| 组数记录 | 自动统计训练组数 |
| 后台运行 | 锁屏后继续计时，不中断 |

### 🔔 多重提醒

- 🔊 **声音提醒** - 训练时无需盯屏幕
- 📳 **振动提醒** - 安静环境也能感知
- 📱 **弹窗通知** - 锁屏状态也能看到

### 📚 健身动作库

- **870+ 专业动作**，覆盖所有肌群
- 肌肉部位分类，快速筛选
- 动作详情 + 示范图片
- 中英文双语搜索

### 🤖 AI 训练计划

- 智能生成个性化训练计划
- 根据目标肌群自动推荐动作
- 日历视图管理训练安排

### 📊 训练记录 & 统计

- 详细记录每组重量、次数
- 周/月/年数据统计
- 肌群训练分布可视化
- 训练热力图日历

### 🎨 精美设计

- **5种主题配色**：琥珀金、珊瑚橙、薄荷绿、玫瑰粉、天际蓝
- Flat Vitality 设计系统
- Material Design 3 现代界面

### 🔒 隐私优先

- 所有数据**本地存储**
- 不上传云端，不收集个人信息
- 你的训练数据只属于你

---

## 📸 截图预览

| 计时器 | 训练计划 | 数据统计 |
|:------:|:--------:|:--------:|
| 计时界面 | 日历规划 | 图表分析 |

---

## 🚀 快速开始

### 下载安装

> **直接下载 APK**（推荐）
> 
> 前往 [Releases](https://github.com/Kaiji-Z/workout-timer/releases) 页面下载最新版本

### 从源码构建

```bash
# 克隆项目
git clone https://github.com/Kaiji-Z/workout-timer.git
cd workout-timer

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK
flutter build apk --release --no-tree-shake-icons
```

<details>
<summary>🇨🇳 国内用户镜像配置</summary>

```bash
# Flutter 中国镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 或阿里云镜像
export PUB_HOSTED_URL=https://mirrors.aliyun.com/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.aliyun.com/flutter
```

</details>

---

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| [Flutter](https://flutter.dev) | 跨平台 UI 框架 |
| [Provider](https://pub.dev/packages/provider) | 状态管理 |
| [SQLite](https://pub.dev/packages/sqflite) | 本地数据存储 |
| [fl_chart](https://pub.dev/packages/fl_chart) | 数据可视化 |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | 本地通知 |

---

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
├── bloc/                     # 状态管理 (Provider)
├── models/                   # 数据模型
├── screens/                  # 页面
├── widgets/                  # 组件
├── theme/                    # 主题系统
├── services/                 # 服务层
└── data/                     # 静态数据
```

---

## 🤝 贡献指南

欢迎参与贡献！无论是报告 Bug、提出建议，还是提交代码，我们都非常欢迎。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

---

## 🤖 AI-Powered Development

本项目由 **AI 辅助开发**，展示了人机协作编程的可能性。

| 工具 | 说明 |
|------|------|
| [OpenCode](https://github.com/opencode-ai/opencode) | AI 代码助手，提供智能代码补全和重构建议 |
| [Oh My OpenAgent](https://github.com/oh-my-openagent) | 强大的 AI Agent 插件，实现复杂任务的自动化开发 |

通过 AI 的辅助，我们实现了：
- 🚀 **快速迭代** - 从想法到实现，大幅缩短开发周期
- 🔧 **代码质量** - AI 辅助 code review 和最佳实践建议
- 📚 **知识整合** - AI 帮助整合健身领域知识和开发规范

---

## 🙏 致谢

| 资源 | 来源 |
|------|------|
| 健身动作数据库 | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) (CC0) |
| Orbitron 字体 | [Google Fonts](https://fonts.google.com/specimen/Orbitron) (SIL OFL) |
| Rajdhani 字体 | [Google Fonts](https://fonts.google.com/specimen/Rajdhani) (SIL OFL) |

---

<div align="center">

## ⭐ 如果这个项目对你有帮助

**给一个 Star 支持一下！**

这是对开源开发者最大的鼓励 🙏

[![Star History Chart](https://api.star-history.com/svg?repos=Kaiji-Z/workout-timer&type=Date)](https://star-history.com/#Kaiji-Z/workout-timer&Date)

**Made with ❤️ by [Kaiji](https://github.com/Kaiji-Z)**

</div>
