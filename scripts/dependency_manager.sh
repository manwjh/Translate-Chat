#!/bin/bash
# 统一预下载脚本 / Unified Pre-download Script
# 文件名(File): dependency_manager.sh
# 创建日期(Created): 2024/06/09
# 作者(Author): AI Assistant
# 简介(Description): 统一下载SDL2和Python依赖包到本地，供主打包脚本离线使用。

set -e

echo "==== 统一预下载脚本 / Unified Pre-download Script ===="
echo ""

# SDL2文件配置
SDL2_FILES=(
    "SDL2-2.28.5.tar|https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz"
    "SDL2_image-2.8.0.tar|https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.0/SDL2_image-2.8.0.tar.gz"
    "SDL2_mixer-2.6.3.tar|https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz"
    "SDL2_ttf-2.20.2.tar|https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.20.2/SDL2_ttf-2.20.2.tar.gz"
    # 新增libwebp源码包
    "libwebp-1.3.2.tar.gz|https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz"
)

# 新增OpenJDK17文件配置
OPENJDK_FILES=(
    "OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.2_8.tar.gz|https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.2%2B8/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.2_8.tar.gz"
    "OpenJDK17U-jdk_x64_mac_hotspot_17.0.2_8.tar.gz|https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.2%2B8/OpenJDK17U-jdk_x64_mac_hotspot_17.0.2_8.tar.gz"
)

# 新增Android SDK/NDK文件配置
ANDROID_SDK_NDK_FILES=(
    # Android SDK Command Line Tools (macOS)
    "commandlinetools-mac-10406996_latest.zip|https://dl.google.com/android/repository/commandlinetools-mac-10406996_latest.zip"
    # Android NDK r25b (macOS)
    "android-ndk-r25b-darwin.dmg|https://dl.google.com/android/repository/android-ndk-r25b-darwin.dmg"
)

echo "第一步: 下载SDL2相关依赖 / Step 1: Download SDL2 dependencies"
echo "=========================================================="
mkdir -p /tmp

for download in "${SDL2_FILES[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    base_name="${filename%.tar}"
    # 检查.tar文件或.tar.gz文件是否存在
    if [ -f "/tmp/$filename" ] || [ -f "/tmp/${base_name}.tar.gz" ]; then
        if [ -f "/tmp/$filename" ]; then
            echo "✓ 已存在: /tmp/$filename"
        else
            echo "✓ 已存在: /tmp/${base_name}.tar.gz (替代 $filename)"
        fi
        continue
    fi
    echo "→ 下载: $filename"
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "/tmp/$filename" "$url"; then
            echo "✓ 下载完成: $filename"
            break
        else
            echo "⚠ 第 $attempt 次下载失败，重试..."
            if [ $attempt -eq 3 ]; then
                echo "✗ 下载失败: $filename (已重试3次)"
                echo "请手动下载: curl -L -o /tmp/$filename $url"
                exit 1
            fi
            sleep 2
        fi
    done
    echo ""
done

echo "第二步: 下载OpenJDK17 / Step 2: Download OpenJDK17"
echo "=================================================="
for download in "${OPENJDK_FILES[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    if [ -f "/tmp/$filename" ]; then
        echo "✓ 已存在: /tmp/$filename"
        continue
    fi
    echo "→ 下载: $filename"
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "/tmp/$filename" "$url"; then
            echo "✓ 下载完成: $filename"
            break
        else
            echo "⚠ 第 $attempt 次下载失败，重试..."
            if [ $attempt -eq 3 ]; then
                echo "✗ 下载失败: $filename (已重试3次)"
                echo "请手动下载: curl -L -o /tmp/$filename $url"
                exit 1
            fi
            sleep 2
        fi
    done
    echo ""
done

echo "第三步: 下载Python依赖wheels / Step 3: Download Python wheels"
echo "=============================================================="
mkdir -p ./wheels
if [ -f requirements-android.txt ]; then
    pip download -r requirements-android.txt -d ./wheels
fi
if [ -f requirements-desktop.txt ]; then
    pip download -r requirements-desktop.txt -d ./wheels
fi
pip download buildozer cython -d ./wheels

echo "第四步: 下载Android SDK/NDK / Step 4: Download Android SDK/NDK"
echo "==============================================================="
for download in "${ANDROID_SDK_NDK_FILES[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    if [ -f "/tmp/$filename" ]; then
        echo "✓ 已存在: /tmp/$filename"
        continue
    fi
    echo "→ 下载: $filename"
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "/tmp/$filename" "$url"; then
            echo "✓ 下载完成: $filename"
            break
        else
            echo "⚠ 第 $attempt 次下载失败，重试..."
            if [ $attempt -eq 3 ]; then
                echo "✗ 下载失败: $filename (已重试3次)"
                echo "请手动下载: curl -L -o /tmp/$filename $url"
                exit 1
            fi
            sleep 2
        fi
    done
    echo ""
done

echo ""
echo "==== 所有依赖预下载完成 / All dependencies pre-downloaded ===="
echo "✓ SDL2文件已下载到 /tmp 目录"
echo "✓ OpenJDK17文件已下载到 /tmp 目录"
echo "✓ Android SDK/NDK文件已下载到 /tmp 目录"
echo "✓ Python依赖已下载到 ./wheels 目录"
echo ""
echo "现在可以运行打包脚本，将优先使用本地文件:"
echo "  ./scripts/build_android_macos.sh"
echo "  ./scripts/build_android_ubuntu.sh"
echo ""
echo "本地包说明:"
echo "- SDL2相关包: 自动解压到构建目录，避免网络下载"
echo "- libwebp: 自动解压到SDL2_image/external目录"
echo "- OpenJDK17: 自动解压并配置JAVA_HOME，支持ARM64和x64架构"
echo "- Android SDK/NDK: 自动解压/挂载到构建目录，避免在线下载" 