#!/bin/bash

# WorkoutTimer Flutter项目国内镜像配置脚本
# 用于配置所有必要的国内镜像源，提升下载速度

echo "🏁 开始配置WorkoutTimer项目的国内镜像..."

# 配置Flutter pub镜像
echo "📦 配置Flutter pub镜像..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 写入到bashrc/zshrc以永久生效
SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -f "$SHELL_RC" ]; then
    echo "💾 将镜像配置写入 $SHELL_RC"
    echo "" >> "$SHELL_RC"
    echo "# WorkoutTimer Flutter项目镜像配置" >> "$SHELL_RC"
    echo "export PUB_HOSTED_URL=https://pub.flutter-io.cn" >> "$SHELL_RC"
    echo "export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn" >> "$SHELL_RC"
    source "$SHELL_RC"
fi

# 检查是否为macOS，如果是则配置iOS相关镜像
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 检测到macOS，配置iOS相关镜像..."

    # 检查是否有gem命令
    if command -v gem &> /dev/null; then
        echo "💎 配置Ruby Gems镜像..."
        gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ 2>/dev/null || true

        # 检查是否有pod命令
        if command -v pod &> /dev/null; then
            echo "📱 配置CocoaPods镜像..."
            cd ios 2>/dev/null || echo "⚠️  未找到ios目录，跳过CocoaPods配置"
            if [ -d "ios" ]; then
                pod repo remove master 2>/dev/null || true
                pod repo add master https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git
                echo "📋 请稍后手动运行: pod repo update"
                cd ..
            fi
        else
            echo "⚠️  未安装CocoaPods，请先安装: sudo gem install cocoapods"
        fi
    else
        echo "⚠️  未找到gem命令，跳过Ruby相关配置"
    fi
fi

echo "✅ 镜像配置完成！"
echo ""
echo "🔄 请重新启动终端或运行: source $SHELL_RC"
echo "🧪 运行测试验证: flutter pub get && flutter test"
echo ""
echo "📚 备用镜像地址:"
echo "  Flutter pub: https://mirrors.aliyun.com/dart-pub"
echo "  Flutter storage: https://mirrors.aliyun.com/flutter"
echo "  CocoaPods: https://mirrors.aliyun.com/rubygems/"