#!/bin/bash
# SDL2 本地文件管理脚本 / SDL2 Local File Management Script
# 文件名(File): sdl2_local_manager.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 检查并下载SDL2相关文件到本地/tmp目录，避免构建时网络下载
#                    Check and download SDL2 related files to local /tmp directory to avoid network downloads during build

set -e

echo "==== SDL2 本地文件管理脚本 ===="
echo "==== SDL2 Local File Management Script ===="
echo ""

# 创建临时目录
mkdir -p /tmp

# SDL2文件配置
SDL2_FILES=(
    "SDL2-2.28.5.tar|https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz"
    "SDL2_image-2.8.0.tar|https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.0/SDL2_image-2.8.0.tar.gz"
    "SDL2_mixer-2.6.3.tar|https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz"
    "SDL2_ttf-2.20.2.tar|https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.20.2/SDL2_ttf-2.20.2.tar.gz"
)

# 兼容旧版本命名
LEGACY_FILES=(
    "SDL_ttf-release-2.0.15.tar"
)

echo "第一步: 检查现有文件 / Step 1: Check existing files"
echo "=================================================="
echo ""

# 检查现有文件
existing_files=()
missing_files=()

for download in "${SDL2_FILES[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    
    if [ -f "/tmp/$filename" ]; then
        size=$(du -h "/tmp/$filename" | cut -f1)
        echo "✓ 找到: $filename (大小: $size)"
        existing_files+=("$filename")
    else
        echo "✗ 缺失: $filename"
        missing_files+=("$download")
    fi
done

# 检查兼容文件
echo ""
echo "检查兼容文件 / Check legacy files:"
for file in "${LEGACY_FILES[@]}"; do
    if [ -f "/tmp/$file" ]; then
        size=$(du -h "/tmp/$file" | cut -f1)
        echo "✓ 找到兼容文件: $file (大小: $size)"
    fi
done

echo ""
echo "文件状态统计 / File status summary:"
echo "- 已存在: ${#existing_files[@]} 个文件"
echo "- 缺失: ${#missing_files[@]} 个文件"
echo ""

# 如果没有缺失文件，直接退出
if [ ${#missing_files[@]} -eq 0 ]; then
    echo "✓ 所有必需的SDL2文件都已存在，无需下载"
    echo "✓ All required SDL2 files exist, no download needed"
    echo ""
    echo "==== 使用说明 / Usage Instructions ===="
    echo "现在可以运行构建脚本，将优先使用本地文件:"
    echo "  ./scripts/build_android_macos.sh"
    echo ""
    echo "Now you can run the build script, which will prioritize local files:"
    echo "  ./scripts/build_android_macos.sh"
    exit 0
fi

# 第二步: 下载缺失文件
echo "第二步: 下载缺失文件 / Step 2: Download missing files"
echo "====================================================="
echo ""

echo "开始下载缺失的SDL2文件到 /tmp 目录..."
echo "Starting to download missing SDL2 files to /tmp directory..."
echo ""

for download in "${missing_files[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    
    echo "正在下载: $filename"
    echo "URL: $url"
    
    # 下载文件（带重试机制）
    echo "正在下载，请稍候... / Downloading, please wait..."
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "/tmp/$filename" "$url"; then
            size=$(du -h "/tmp/$filename" | cut -f1)
            echo "✓ 下载完成: $filename (大小: $size)"
            echo "✓ Download completed: $filename (size: $size)"
            break
        else
            echo "⚠ 第 $attempt 次下载失败，正在重试... / Attempt $attempt failed, retrying..."
            if [ $attempt -eq 3 ]; then
                echo "✗ 下载失败: $filename (已重试3次)"
                echo "✗ Download failed: $filename (retried 3 times)"
                echo "请手动下载: curl -L -o /tmp/$filename $url"
                echo "Please download manually: curl -L -o /tmp/$filename $url"
                exit 1
            fi
            sleep 2
        fi
    done
    echo ""
done

echo "==== 下载完成 / Download Complete ===="
echo "所有SDL2文件已下载到 /tmp 目录:"
echo "All SDL2 files have been downloaded to /tmp directory:"
echo ""

# 最终检查
for download in "${SDL2_FILES[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    if [ -f "/tmp/$filename" ]; then
        size=$(du -h "/tmp/$filename" | cut -f1)
        echo "✓ /tmp/$filename (大小: $size)"
    fi
done

echo ""
echo "==== 使用说明 / Usage Instructions ===="
echo "现在可以运行构建脚本，将优先使用本地文件:"
echo "  ./scripts/build_android_macos.sh"
echo ""
echo "Now you can run the build script, which will prioritize local files:"
echo "  ./scripts/build_android_macos.sh"
echo ""
echo "==== 注意事项 / Notes ===="
echo "- 确保下载的文件是 .tar 格式（不是 .tar.gz）"
echo "- 如果下载的是 .tar.gz 文件，请解压后重命名为 .tar"
echo "- 文件权限应该是可读的"
echo ""
echo "- Ensure downloaded files are in .tar format (not .tar.gz)"
echo "- If downloaded files are .tar.gz, please extract and rename to .tar"
echo "- File permissions should be readable"
echo "" 