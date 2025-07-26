#!/bin/bash
# Translate Chat - macOS Android 打包自动化脚本
# 文件名(File): build_android_macos.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): macOS Android 打包自动化脚本，支持SDL2本地文件优先

set -e

# 验证SDL2本地文件的函数
verify_sdl2_local_files() {
    local sdl2_files=(
        "SDL2-2.28.5.tar"
        "SDL2_image-2.8.0.tar"
        "SDL2_mixer-2.6.3.tar"
        "SDL2_ttf-2.20.2.tar"
        "SDL_ttf-release-2.0.15.tar"  # 兼容旧版本命名
    )
    
    local all_files_exist=true
    
    # 特殊处理SDL2_ttf文件（支持多个版本）
    local sdl2_ttf_found=false
    
    for file in "${sdl2_files[@]}"; do
        if [ -f "/tmp/$file" ]; then
            size=$(du -h "/tmp/$file" | cut -f1)
            echo "✓ 验证通过: /tmp/$file (大小: $size)"
            # 检查文件是否可读
            if [ ! -r "/tmp/$file" ]; then
                echo "⚠ 警告: /tmp/$file 不可读，正在修复权限..."
                chmod 644 "/tmp/$file"
            fi
            
            # 标记SDL2_ttf文件已找到
            if [[ "$file" == *"ttf"* ]]; then
                sdl2_ttf_found=true
            fi
        else
            # 对于SDL2_ttf文件，只有在所有版本都缺失时才报告错误
            if [[ "$file" == *"ttf"* ]]; then
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
    
    if [ "$all_files_exist" = true ]; then
        echo "✓ 所有SDL2本地文件验证通过，将优先使用本地文件"
        return 0
    else
        echo "⚠ 部分SDL2文件缺失，将混合使用本地文件和网络下载"
        return 1
    fi
}

# 配置 pip 全局镜像（清华源）
echo "==== 0. 配置 pip 国内镜像 ===="
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
EOF

# 检查 SDL2 本地文件并设置环境变量
echo "==== 0.5. 检查 SDL2 本地文件并配置环境变量 ===="

# 设置SDL2本地文件路径环境变量
export SDL2_LOCAL_PATH="/tmp"
export SDL2_MIXER_LOCAL_PATH="/tmp/SDL2_mixer-2.6.3.tar"
export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL2_image-2.8.0.tar"

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
echo "如需下载本地文件，请运行: ./scripts/sdl2_local_setup.sh"
echo ""

# 检查 openssl@1.1 路径并自动设置环境变量
if [ -d "/usr/local/opt/openssl@1.1" ]; then
  export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
  export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
  echo "==== openssl@1.1 路径: /usr/local/opt/openssl@1.1，已设置环境变量 ===="
elif [ -d "/opt/homebrew/opt/openssl@1.1" ]; then
  export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
  echo "==== openssl@1.1 路径: /opt/homebrew/opt/openssl@1.1，已设置环境变量 ===="
else
  echo "==== 未检测到 openssl@1.1，请先手动编译安装 ===="
  exit 1
fi

# 优先使用 JDK 17
if brew list --versions openjdk@17 >/dev/null; then
  echo "==== 1. openjdk@17 已安装 ===="
else
  echo "==== 1. 安装 openjdk@17（如有 JDK 11/24 建议先卸载） ===="
  brew install openjdk@17
fi
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"
echo "JAVA_HOME set to $JAVA_HOME"

# 依赖安装
brew install python@3.9 git

# 创建/激活虚拟环境
if [ ! -d venv ]; then
  /opt/homebrew/bin/python3.9 -m venv venv
fi
source venv/bin/activate

# 再次 export 关键环境变量，确保 venv 内可见
export LDFLAGS
export CPPFLAGS
export PKG_CONFIG_PATH
export JAVA_HOME
export PATH

echo "==== 2. 安装 Python 依赖 ===="
pip install --upgrade pip cython buildozer

echo "==== 3. 初始化 buildozer.spec（如未存在） ===="
if [ ! -f buildozer.spec ]; then
  buildozer init
fi

echo "==== 4. 开始打包 APK ===="
buildozer -v android debug

echo "==== 5. APK 生成于 bin/ 目录 ===="
ls -lh bin/*.apk

echo "==== 6. 构建完成总结 ===="
echo "✓ SDL2本地文件配置:"
echo "  - SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
echo "  - SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
echo "  - SDL2_IMAGE_LOCAL_PATH: $SDL2_IMAGE_LOCAL_PATH"
echo "  - SDL2_TTF_LOCAL_PATH: $SDL2_TTF_LOCAL_PATH"
echo ""
echo "==== 7. 如需部署到设备，请连接设备并执行：buildozer android deploy run ====" 