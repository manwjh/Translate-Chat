#!/bin/bash
# Translate Chat - Ubuntu Android 打包自动化脚本
# 文件名(File): build_android_ubuntu.sh
# 版本(Version): v0.1.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): Ubuntu环境下Android APK自动化打包脚本
set -e

echo "==== Translate Chat - Ubuntu Android 打包脚本 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为Ubuntu系统
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "错误: 此脚本仅适用于Ubuntu系统"
    echo "检测到的系统: $(cat /etc/os-release | grep PRETTY_NAME)"
    exit 1
fi

# 配置 pip 全局镜像（清华源）
echo "==== 0. 配置 pip 国内镜像 ===="
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
echo "pip镜像已配置为清华源"

# 更新系统包
echo "==== 1. 更新系统包 ===="
sudo apt update
sudo apt upgrade -y

# 安装系统依赖
echo "==== 2. 安装系统依赖 ===="
sudo apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    git \
    openjdk-8-jdk \
    unzip \
    zlib1g-dev \
    libncurses5 \
    libstdc++6 \
    libffi-dev \
    libssl-dev \
    build-essential \
    autoconf \
    libtool \
    pkg-config \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libgif-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportmidi-dev \
    libswscale-dev \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libavresample-dev \
    libpostproc-dev \
    libswresample-dev \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libavresample-dev \
    libpostproc-dev \
    libswresample-dev \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libavresample-dev \
    libpostproc-dev \
    libswresample-dev

echo "系统依赖安装完成"

# 设置JAVA环境
echo "==== 3. 配置Java环境 ===="
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"
echo "JAVA_HOME设置为: $JAVA_HOME"
java -version

# 创建/激活虚拟环境
echo "==== 4. 创建Python虚拟环境 ===="
if [ ! -d venv ]; then
    python3 -m venv venv
    echo "虚拟环境创建完成"
else
    echo "虚拟环境已存在"
fi

source venv/bin/activate
echo "虚拟环境已激活: $(which python)"

# 升级pip和安装基础工具
echo "==== 5. 安装Python基础工具 ===="
pip install --upgrade pip setuptools wheel
pip install cython

# 安装buildozer
echo "==== 6. 安装Buildozer ===="
pip install buildozer

# 检查buildozer.spec文件
echo "==== 7. 检查Buildozer配置 ===="
if [ ! -f buildozer.spec ]; then
    echo "未找到buildozer.spec，正在初始化..."
    buildozer init
    echo "buildozer.spec已创建，请检查配置后重新运行脚本"
    exit 0
else
    echo "找到buildozer.spec文件"
    echo "当前配置摘要:"
    echo "- 应用名称: $(grep '^title =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    echo "- 包名: $(grep '^package.name =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    echo "- 版本: $(grep '^version =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    echo "- 目标架构: $(grep '^android.arch =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
fi

# 清理之前的构建
echo "==== 8. 清理之前的构建 ===="
if [ -d ".buildozer" ]; then
    echo "清理之前的构建缓存..."
    buildozer android clean
fi

# 开始打包APK
echo "==== 9. 开始打包APK ===="
echo "注意: 首次打包可能需要较长时间，需要下载Android SDK/NDK"
echo "如果网络较慢，建议使用科学上网工具"
echo ""

# 设置环境变量确保在虚拟环境中可见
export JAVA_HOME
export PATH

# 执行打包
buildozer -v android debug

# 检查打包结果
echo "==== 10. 检查打包结果 ===="
if [ -d "bin" ]; then
    echo "APK文件列表:"
    ls -lh bin/*.apk 2>/dev/null || echo "未找到APK文件"
    
    # 统计APK大小
    if ls bin/*.apk >/dev/null 2>&1; then
        echo ""
        echo "APK文件详情:"
        for apk in bin/*.apk; do
            echo "- $(basename $apk): $(du -h $apk | cut -f1)"
        done
    fi
else
    echo "警告: 未找到bin目录，打包可能失败"
fi

echo ""
echo "==== 11. 部署说明 ===="
echo "如需部署到设备，请:"
echo "1. 连接Android设备并开启USB调试"
echo "2. 运行: buildozer android deploy run"
echo "3. 查看日志: buildozer android logcat"
echo ""

echo "==== 打包完成 ===="
echo "结束时间: $(date)"
echo ""

# 可选：自动部署到设备
read -p "是否立即部署到连接的设备? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在部署到设备..."
    buildozer android deploy run
fi 