# 撸铁计时器 | Workout Timer

专业健身休息计时器 - 让每一组训练都精准高效

## 功能特性

### 计时器核心
- 预设休息时长：30秒、60秒、90秒、120秒 一键选择
- 大号倒计时显示，训练时一目了然
- 组数自动记录，完整训练追踪
- 后台运行：锁屏后计时器继续工作

### 智能提醒
- 多渠道通知：声音 + 振动 + 屏幕弹窗
- 可自定义提醒方式
- 前台服务保证提醒不遗漏

### 健身数据库
- 870+ 健身动作库，涵盖所有肌群
- 肌肉部位筛选，快速找到目标动作
- 动作详情与示范图片
- 支持中英文双语搜索

### AI 训练计划
- 智能生成个性化训练计划
- 根据目标肌群自动推荐动作
- 支持计划导入与调整
- 日历视图管理训练安排

### 训练记录
- 详细记录每组重量、次数
- 实时训练进度追踪
- 训练历史回顾

### 数据统计
- 训练历史记录
- 周/月/年统计图表
- 活动热力图日历
- 肌群训练分布
- 数据可视化分析

### 个性化
- 5种精美主题配色（琥珀金、珊瑚橙、薄荷绿、玫瑰粉、天际蓝）
- Flat Vitality 设计系统
- Material Design 3 现代界面

## 快速开始

### 环境要求
- Flutter 3.10+
- Dart 3.10+

### 安装运行

```bash
# 克隆项目
git clone https://github.com/Kaiji-Z/workout-timer.git
cd workout-timer

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 Release APK
./build_release.sh        # Linux/macOS
flutter build apk --release --no-tree-shake-icons  # 直接构建
```

### 国内用户镜像配置

```bash
# 设置环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 或使用阿里云镜像
export PUB_HOSTED_URL=https://mirrors.aliyun.com/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.aliyun.com/flutter
```

## 项目结构

```
lib/
├── main.dart              # 应用入口，导航
├── bloc/                  # 状态管理 (Provider/ChangeNotifier)
│   ├── timer_provider.dart
│   ├── training_provider.dart
│   ├── plan_provider.dart
│   ├── record_provider.dart
│   └── training_progress_provider.dart
├── models/                # 数据模型
│   ├── workout_session.dart
│   ├── workout_record.dart
│   ├── workout_plan.dart
│   ├── exercise.dart
│   └── muscle_group.dart
├── screens/               # 页面
│   ├── timer_screen.dart
│   ├── plan_screen.dart
│   ├── history_screen.dart
│   ├── stats_screen.dart
│   └── settings_screen.dart
├── widgets/               # 组件
│   ├── training_widget.dart
│   ├── timer_widget.dart
│   ├── calendar_widget.dart
│   └── charts/            # 图表组件
├── theme/                 # 主题系统
│   ├── app_theme.dart
│   └── theme_provider.dart
├── services/              # 服务层
│   ├── database_helper.dart
│   ├── notification_service.dart
│   └── *_repository.dart
├── utils/                 # 工具类
└── data/                  # 静态数据
```

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter/Dart | 跨平台 UI 框架 |
| Provider | 状态管理 |
| SQLite (sqflite) | 本地数据存储 |
| flutter_local_notifications | 本地通知 |
| cached_network_image | 图片缓存 |
| fl_chart | 数据可视化图表 |
| fuzzy | 模糊搜索匹配 |
| intl | 国际化 |

## 开发命令

```bash
# 运行测试
flutter test                           # 运行所有测试
flutter test test/widget_test.dart     # 运行单个测试文件
flutter test --name "pattern"          # 按名称模式运行测试

# 代码分析
flutter analyze                        # 静态分析
dart format lib/ test/                 # 格式化代码

# 构建
flutter build apk --release --no-tree-shake-icons  # Android APK
flutter build web                      # Web 版本
```

## 开源致谢

### 核心框架
- [Flutter](https://flutter.dev) - BSD 3-Clause
- [Dart](https://dart.dev) - BSD 3-Clause

### 第三方库
| 包名 | 许可证 | 用途 |
|------|--------|------|
| provider | MIT | 状态管理 |
| sqflite | BSD 2-Clause | SQLite 数据库 |
| flutter_local_notifications | BSD 3-Clause | 本地通知 |
| shared_preferences | BSD 3-Clause | 偏好设置 |
| google_fonts | Apache 2.0 | Google 字体 |
| cached_network_image | MIT | 图片缓存 |
| fl_chart | MIT | 图表绘制 |
| fuzzy | MIT | 模糊搜索 |
| intl | BSD 3-Clause | 国际化 |
| uuid | MIT | UUID 生成 |

### 数据与设计资源
| 资源 | 来源 | 许可证 |
|------|------|--------|
| 健身动作数据库 | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | CC0 Public Domain |
| 健身动作图片 | [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) | CC0 Public Domain |
| Orbitron 字体 | [Google Fonts](https://fonts.google.com/specimen/Orbitron) | SIL OFL |
| Rajdhani 字体 | [Google Fonts](https://fonts.google.com/specimen/Rajdhani) | SIL OFL |

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 [MIT 许可证](LICENSE) 开源。

---

如果这个项目对你有帮助，请给一个 Star ⭐ 支持一下！
