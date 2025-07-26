#!/bin/bash
# Translate Chat - Ubuntu Android 打包自动化脚本
# 文件名(File): build_android_ubuntu.sh
# 版本(Version): v1.0.1
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): Ubuntu环境下Android APK自动化打包脚本，支持SDL2本地文件优先

set -e

# 验证SDL2本地文件的函数
verify_sdl2_local_files() {
    local sdl2_files=(
        "SDL2-2.28.5.tar"
        "SDL2_image-2.8.0.tar"
        "SDL_image-release-2.0.tar"  # 兼容新版本命名
        "SDL2_mixer-2.6.3.tar"
        "SDL2_ttf-2.20.2.tar"
        "SDL_ttf-release-2.0.15.tar"  # 兼容旧版本命名
    )
    
    local all_files_exist=true
    
    # 特殊处理SDL2_ttf和SDL2_image文件（支持多个版本）
    local sdl2_ttf_found=false
    local sdl2_image_found=false
    
    for file in "${sdl2_files[@]}"; do
        if [ -f "/tmp/$file" ]; then
            size=$(du -h "/tmp/$file" | cut -f1)
            echo "✓ 验证通过: /tmp/$file (大小: $size)"
            # 检查文件是否可读
            if [ ! -r "/tmp/$file" ]; then
                echo "⚠ 警告: /tmp/$file 不可读，正在修复权限..."
                chmod 644 "/tmp/$file"
            fi
            
            # 标记SDL2_ttf和SDL2_image文件已找到
            if [[ "$file" == *"ttf"* ]]; then
                sdl2_ttf_found=true
            fi
            if [[ "$file" == *"image"* ]]; then
                sdl2_image_found=true
            fi
        else
            # 对于SDL2_ttf和SDL2_image文件，只有在所有版本都缺失时才报告错误
            if [[ "$file" == *"ttf"* ]] || [[ "$file" == *"image"* ]]; then
                continue
            else
                echo "✗ 文件缺失: /tmp/$file"
                all_files_exist=false
            fi
        fi
    done
    
    # 检查SDL2_ttf文件状态
    if [ "$sdl2_ttf_found" = false ]; then
        echo "✗ SDL2_ttf文件缺失"
        all_files_exist=false
    fi
    
    # 检查SDL2_image文件状态
    if [ "$sdl2_image_found" = false ]; then
        echo "✗ SDL2_image文件缺失"
        all_files_exist=false
    fi
    
    if [ "$all_files_exist" = true ]; then
        echo "✓ 所有SDL2本地文件验证通过，将优先使用本地文件"
        return 0
    else
        echo "⚠ 部分SDL2文件缺失，将混合使用本地文件和网络下载"
        return 1
    fi
}

echo "==== Translate Chat - Ubuntu Android 打包脚本 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为Ubuntu系统
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "错误: 此脚本仅适用于Ubuntu系统"
    echo "检测到的系统: $(cat /etc/os-release | grep PRETTY_NAME)"
    exit 1
fi

# 确保在项目根目录运行
if [ ! -f "main.py" ]; then
    echo "错误: 未找到main.py文件"
    echo "请确保在项目根目录运行此脚本"
    echo "当前目录: $(pwd)"
    echo "请切换到项目根目录: cd /path/to/Translate-Chat"
    exit 1
fi

echo "✓ 确认在项目根目录运行"
echo ""

# 配置 pip 全局镜像（清华源）
echo "==== 0. 配置 pip 国内镜像 ===="
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
echo "pip镜像已配置为清华源"

# 检查 SDL2 本地文件并设置环境变量
echo "==== 0.5. 检查 SDL2 本地文件并配置环境变量 ===="

# 设置SDL2本地文件路径环境变量
export SDL2_LOCAL_PATH="/tmp"
export SDL2_MIXER_LOCAL_PATH="/tmp/SDL2_mixer-2.6.3.tar"

# 检查SDL2_image文件（支持新旧版本命名）
if [ -f "/tmp/SDL2_image-2.8.0.tar" ]; then
    export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL2_image-2.8.0.tar"
elif [ -f "/tmp/SDL_image-release-2.0.tar" ]; then
    export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL_image-release-2.0.tar"
else
    export SDL2_IMAGE_LOCAL_PATH=""
fi

# 检查SDL2_ttf文件（支持新旧版本命名）
if [ -f "/tmp/SDL2_ttf-2.20.2.tar" ]; then
    export SDL2_TTF_LOCAL_PATH="/tmp/SDL2_ttf-2.20.2.tar"
elif [ -f "/tmp/SDL_ttf-release-2.0.15.tar" ]; then
    export SDL2_TTF_LOCAL_PATH="/tmp/SDL_ttf-release-2.0.15.tar"
else
    export SDL2_TTF_LOCAL_PATH=""
fi

echo "已设置SDL2本地文件环境变量:"
echo "  SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
echo "  SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
echo ""

# 验证SDL2本地文件
verify_sdl2_local_files

echo ""
echo "提示: 本地文件将优先使用，避免网络下载"
echo "如需下载本地文件，请运行: ./scripts/sdl2_local_manager.sh"
echo ""

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
if [ ! -d "venv" ]; then
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
    # 添加错误处理
    if ! buildozer android clean; then
        echo "⚠ buildozer clean失败，尝试手动清理..."
        rm -rf .buildozer
        echo "✓ 已手动清理.buildozer目录"
    fi
fi

# 开始打包APK
echo "==== 9. 开始打包APK ===="
echo "注意: 首次打包可能需要较长时间，需要下载Android SDK/NDK"
echo "如果网络较慢，建议使用科学上网工具"
echo ""

# 设置环境变量确保在虚拟环境中可见
export JAVA_HOME
export PATH
export SDL2_LOCAL_PATH
export SDL2_MIXER_LOCAL_PATH
export SDL2_IMAGE_LOCAL_PATH
export SDL2_TTF_LOCAL_PATH

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
echo "==== 11. 构建完成总结 ===="
echo "✓ SDL2本地文件配置:"
echo "  - SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
echo "  - SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
echo "  - SDL2_IMAGE_LOCAL_PATH: $SDL2_IMAGE_LOCAL_PATH"
echo "  - SDL2_TTF_LOCAL_PATH: $SDL2_TTF_LOCAL_PATH"
echo ""
echo "==== 12. 部署说明 ===="
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