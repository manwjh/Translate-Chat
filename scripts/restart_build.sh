#!/bin/bash
# Translate Chat - 重启构建脚本
# 文件名(File): restart_build.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 重启卡住的buildozer构建

echo "==== 重启 Buildozer 构建 ===="
echo "重启时间: $(date)"
echo ""

# 检查是否在scripts目录
if [ ! -f "buildozer.spec" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

echo "⚠️  警告: 这将清理当前的构建缓存并重新开始"
read -p "确定要继续吗? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消"
    exit 0
fi

echo ""
echo "1. 停止正在运行的构建进程..."
# 查找并停止buildozer相关进程
pkill -f "buildozer" 2>/dev/null || echo "  没有找到正在运行的buildozer进程"
pkill -f "pythonforandroid" 2>/dev/null || echo "  没有找到正在运行的pythonforandroid进程"

echo "2. 清理构建缓存..."
if [ -d "scripts/.buildozer" ]; then
    rm -rf scripts/.buildozer
    echo "✓ 已清理 scripts/.buildozer 目录"
fi

if [ -d ".buildozer" ]; then
    rm -rf .buildozer
    echo "✓ 已清理 .buildozer 目录"
fi

echo "3. 清理旧的APK文件..."
if [ -d "bin" ]; then
    rm -f bin/*.apk
    echo "✓ 已清理旧的APK文件"
fi

echo "4. 检查环境..."
# 检查虚拟环境
if [ ! -d "scripts/venv" ]; then
    echo "⚠️  虚拟环境不存在，正在创建..."
    cd scripts
    python3 -m venv venv
    cd ..
    echo "✓ 虚拟环境已创建"
fi

echo "5. 设置环境变量..."
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"

# 设置SDL2本地文件环境变量
export SDL2_LOCAL_PATH="/tmp"
export SDL2_MIXER_LOCAL_PATH="/tmp/SDL2_mixer-2.6.3.tar"

# 检查SDL2_image文件
if [ -f "/tmp/SDL2_image-2.8.0.tar" ]; then
    export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL2_image-2.8.0.tar"
elif [ -f "/tmp/SDL_image-release-2.0.tar" ]; then
    export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL_image-release-2.0.tar"
else
    export SDL2_IMAGE_LOCAL_PATH=""
fi

# 检查SDL2_ttf文件
if [ -f "/tmp/SDL2_ttf-2.20.2.tar" ]; then
    export SDL2_TTF_LOCAL_PATH="/tmp/SDL2_ttf-2.20.2.tar"
elif [ -f "/tmp/SDL_ttf-release-2.0.15.tar" ]; then
    export SDL2_TTF_LOCAL_PATH="/tmp/SDL_ttf-release-2.0.15.tar"
else
    export SDL2_TTF_LOCAL_PATH=""
fi

echo "✓ 环境变量已设置"

echo ""
echo "6. 重新开始构建..."
echo "正在启动构建脚本..."

# 重新运行构建脚本
./scripts/build_android_ubuntu.sh

echo ""
echo "==== 重启完成 ====" 