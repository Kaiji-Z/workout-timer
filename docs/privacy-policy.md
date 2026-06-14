# 隐私政策

**最后更新：2026年6月14日**

## 概述

撸铁计时器（以下简称"本应用"）是一款专业的健身休息计时应用。我们高度重视您的隐私。本隐私政策说明我们如何收集、使用和保护您的数据。

## 数据收集

**本应用不收集任何个人信息。**

- 所有训练数据（训练记录、计划、统计等）均存储在您的设备本地（SQLite 数据库）
- 我们没有服务器，不上传、不传输、不分享您的任何数据
- 本应用不包含任何第三方数据分析 SDK、广告 SDK 或追踪代码

## 本地存储的数据

以下数据仅保存在您的设备上：

| 数据类型 | 说明 | 存储方式 |
|---------|------|---------|
| 训练记录 | 组数、重量、次数、日期 | 本地 SQLite |
| 训练计划 | 自定义计划、日历安排 | 本地 SQLite |
| 用户设置 | 训练目标、频率、设备偏好 | 本地存储 |
| 计时器设置 | 预设时长、声音、振动偏好 | 本地存储 |

**卸载本应用将永久删除所有数据。**

## 设备权限说明

| 权限 | 用途 | 是否必须 |
|------|------|---------|
| 通知 (POST_NOTIFICATIONS) | 计时结束时发送通知提醒（声音、振动、弹窗） | 是 |
| 振动 (VIBRATE) | 计时结束时振动提醒 | 是 |
| 前台服务 (FOREGROUND_SERVICE) | 计时器在后台持续运行，确保锁屏不中断 | 是 |
| 前台特殊服务 (FOREGROUND_SERVICE_SPECIAL_USE) | 计时器作为特殊前台服务运行，确保后台精确计时 | 是 |
| 网络 (INTERNET) | 加载健身动作的示例图片（CC0 公共领域图片资源） | 部分（核心功能不需要） |
| 开机启动 (RECEIVE_BOOT_COMPLETED) | 开机后恢复通知渠道 | 否 |
| 电池优化豁免 (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) | 防止系统省电策略中断计时器运行 | 是 |

## 网络访问

本应用包含 INTERNET 权限，仅用于以下用途：

- 加载健身动作的示例图片（来自公开的 CC0 图片资源）
- 在"AI 训练分析"功能中，您需要手动复制提示词到第三方 AI 工具（如 ChatGPT、豆包等），本应用本身不发送任何数据

**本应用不会主动向任何服务器发送您的数据。**

## 儿童隐私

本应用面向健身爱好者，不针对 13 岁以下儿童。我们不会有意收集儿童的个人信息。

## 数据安全

由于所有数据存储在您的本地设备上，数据安全取决于您对设备的安全管理。建议您：

- 定期备份重要数据
- 设置设备锁屏密码

## 政策变更

如果本隐私政策有变更，我们会在应用内通知您，并更新本页面的日期。

## 联系我们

如有任何关于隐私政策的问题，请联系：

- GitHub: [Kaiji-Z/workout-timer](https://github.com/Kaiji-Z/workout-timer)
- Email: lookatmedia@163.com

---

## Privacy Policy (English)

**Last Updated: June 14, 2026**

### Overview

Workout Timer ("this app") is a professional fitness rest timer application. We take your privacy seriously. This privacy policy explains how we handle your data.

### Data Collection

**This app does not collect any personal information.**

- All workout data is stored locally on your device (SQLite database)
- We have no servers. We do not upload, transmit, or share any of your data
- This app contains no third-party analytics SDKs, ad SDKs, or tracking code

### Permissions

| Permission | Purpose | Required |
|-----------|---------|----------|
| Notifications (POST_NOTIFICATIONS) | Timer completion alerts (sound, vibration, popup) | Yes |
| Vibration (VIBRATE) | Vibration alerts when timer ends | Yes |
| Foreground Service (FOREGROUND_SERVICE) | Keep timer running in background | Yes |
| Foreground Special Use (FOREGROUND_SERVICE_SPECIAL_USE) | Timer runs as special foreground service for precise background timing | Yes |
| Internet (INTERNET) | Load exercise demo images (CC0 public domain) | Partial |
| Receive Boot Completed (RECEIVE_BOOT_COMPLETED) | Restore notification channels after device reboot | No |
| Battery Optimization Exemption (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) | Prevent system power-saving from interrupting timer | Yes |

### Contact

- GitHub: [Kaiji-Z/workout-timer](https://github.com/Kaiji-Z/workout-timer)
- Email: lookatmedia@163.com
