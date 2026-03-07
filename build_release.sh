#!/bin/bash
# 构建发布版本APK（禁用图标树摇，防止Material Icons显示为乱码）
flutter build apk --release --no-tree-shake-icons
