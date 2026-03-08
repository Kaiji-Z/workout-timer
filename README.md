# Workout Timer

一个跨平台的健身计时器应用，用于在健身组间休息时进行计时。支持预设时间、多渠道通知（声音+振动+屏幕弹窗）、基本数据记录功能。

## 功能特性

- 🕒 **预设计时器**: 30秒、60秒、90秒、120秒快速选择
- 🔊 **多渠道通知**: 声音提醒 + 振动反馈 + 屏幕弹窗
- 📊 **数据记录**: 自动记录组数和总休息时间
- 📱 **跨平台**: 支持Android和iOS
- 🎨 **Material Design 3**: 现代化的用户界面
- 🌙 **深色模式**: 支持系统主题切换

## 快速开始

### 环境要求

- Flutter 3.10+
- Dart 3.0+

### 安装依赖

#### 快速配置国内镜像（推荐）

项目提供了自动配置脚本，一键设置所有国内镜像：

```bash
# 运行配置脚本（Linux/macOS）
chmod +x setup_mirrors.sh
./setup_mirrors.sh

# Windows用户请手动配置以下环境变量
```

#### 手动配置Flutter国内镜像

**临时配置:**
```bash
# 设置pub镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 或者使用阿里云镜像
export PUB_HOSTED_URL=https://mirrors.aliyun.com/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.aliyun.com/flutter
```

**永久配置:**
```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
echo 'export PUB_HOSTED_URL=https://pub.flutter-io.cn' >> ~/.bashrc
echo 'export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn' >> ~/.bashrc
source ~/.bashrc
```

#### 2. 安装项目依赖

```bash
flutter pub get
```

#### 3. iOS开发环境配置（macOS）

如果在macOS上开发iOS，需要配置CocoaPods镜像：

```bash
# 替换Ruby源为国内镜像
gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/
gem sources -l  # 确认替换成功

# 安装bundler（如果需要）
gem install bundler

# 配置CocoaPods镜像
cd ios
pod repo remove master
pod repo add master https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git
pod repo update
```

### 运行应用

```bash
# 运行在连接的设备或模拟器上
flutter run

# 构建调试APK
flutter build apk --debug

# 构建发布APK
flutter build apk --release
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/
│   └── workout_session.dart  # 数据模型
├── screens/
│   ├── timer_screen.dart     # 主计时器界面
│   ├── settings_screen.dart  # 设置界面
│   └── history_screen.dart   # 历史记录界面
├── widgets/
│   └── timer_widget.dart     # 计时器组件
├── bloc/
│   └── timer_provider.dart   # 状态管理
└── services/
    ├── database_helper.dart  # 数据库操作
    ├── notification_service.dart # 通知服务
    └── workout_repository.dart   # 数据仓库
```

## 架构设计

采用MVVM模式：
- **Model**: 数据层，使用SQLite存储
- **View**: UI层，使用Flutter Widgets
- **ViewModel**: 业务逻辑层，使用Provider状态管理

## 测试

```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test/
```

## 构建命令

```bash
# 静态代码分析
flutter analyze

# 格式化代码
dart format lib/

# 修复自动修复的问题
dart fix --apply
```

## 权限要求

应用需要以下权限：
- 通知权限：发送计时结束提醒
- 振动权限：提供触觉反馈

## 技术栈

- **Flutter/Dart**: 跨平台UI框架
- **SQLite (sqflite)**: 本地数据存储
- **Provider**: 状态管理
- **flutter_local_notifications**: 本地通知
- **shared_preferences**: 偏好设置存储
- **vibration**: 设备振动控制

## 开发规范

项目遵循：
- [Dart代码风格指南](https://dart.dev/guides/language/effective-dart)
- [Flutter最佳实践](https://docs.flutter.dev/development/tools/formatting)
- MVVM架构模式

## 贡献指南

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 国内用户配置指南

为了提升下载速度，推荐配置国内镜像源：

### 🚀 一键配置（推荐）

项目根目录提供了 `setup_mirrors.sh` 脚本，可以自动配置所有国内镜像：

```bash
# Linux/macOS
chmod +x setup_mirrors.sh && ./setup_mirrors.sh

# Windows用户请查看下方手动配置方法
```

### Flutter SDK 镜像

```bash
# 临时配置
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 或使用阿里云镜像
export PUB_HOSTED_URL=https://mirrors.aliyun.com/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.aliyun.com/flutter
```

### Android 构建加速

项目已配置阿里云maven仓库镜像，自动使用国内源下载Android依赖。

### iOS 构建加速（macOS）

```bash
# 配置Ruby Gems镜像
gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/

# 配置CocoaPods镜像
cd ios
pod repo remove master
pod repo add master https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git
pod repo update
```

### 网络问题排查

如果仍然遇到网络问题：

1. **检查Flutter配置**: `flutter config`
2. **更换镜像源**: 尝试阿里云、腾讯云或华为云镜像
3. **代理设置**: 配置系统代理或VPN
4. **清理缓存**: `flutter clean` 后重新下载

## 开源致谢

本项目使用了以下开源项目和资源，感谢它们的贡献：

### 核心框架

| 项目 | 许可证 | 链接 |
|------|--------|------|
| Flutter | BSD 3-Clause | https://flutter.dev |
| Dart | BSD 3-Clause | https://dart.dev |

### 第三方依赖

| 包名 | 许可证 | 用途 |
|------|--------|------|
| provider | MIT | 状态管理 |
| sqflite | BSD 2-Clause | SQLite 数据库 |
| flutter_local_notifications | BSD 3-Clause | 本地通知 |
| shared_preferences | BSD 3-Clause | 偏好设置存储 |
| google_fonts | Apache 2.0 | Google 字体 |
| intl | BSD 3-Clause | 国际化支持 |
| uuid | MIT | UUID 生成 |
| cached_network_image | MIT | 图片缓存 |
| permission_handler | MIT | 权限管理 |
| cupertino_icons | MIT | iOS 风格图标 |
| flutter_launcher_icons | MIT | 应用图标生成 |

### 字体资源

| 字体 | 来源 | 许可证 |
|------|------|--------|
| [Orbitron](https://fonts.google.com/specimen/Orbitron) | Google Fonts | SIL Open Font License |
| [Rajdhani](https://fonts.google.com/specimen/Rajdhani) | Google Fonts | SIL Open Font License |

### 图标资源

| 资源 | 许可证 |
|------|--------|
| Material Icons | Apache 2.0 |
| Cupertino Icons | MIT |

---

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情
