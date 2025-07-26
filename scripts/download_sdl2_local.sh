#!/bin/bash
# SDL2 本地文件下载脚本
# 文件名(File): download_sdl2_local.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 下载SDL2相关文件到本地/tmp目录，避免构建时网络下载

set -e

echo "==== SDL2 本地文件下载脚本 ===="
echo ""

# 创建临时目录
mkdir -p /tmp

# SDL2文件下载配置
SDL2_DOWNLOADS=(
    "SDL2-2.28.5.tar|https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz"
    "SDL2_image-2.8.0.tar|https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.0/SDL2_image-2.8.0.tar.gz"
    "SDL2_mixer-2.6.3.tar|https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz"
    "SDL2_ttf-2.20.2.tar|https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.20.2/SDL2_ttf-2.20.2.tar.gz"
)

echo "开始下载SDL2相关文件到 /tmp 目录..."
echo ""

for download in "${SDL2_DOWNLOADS[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    
    if [ -f "/tmp/$filename" ]; then
        size=$(du -h "/tmp/$filename" | cut -f1)
        echo "✓ $filename 已存在 (大小: $size)，跳过下载"
    else
        echo "正在下载: $filename"
        echo "URL: $url"
        
        # 下载文件（带重试机制）
        echo "正在下载，请稍候..."
        for attempt in 1 2 3; do
            if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "/tmp/$filename" "$url"; then
                size=$(du -h "/tmp/$filename" | cut -f1)
                echo "✓ 下载完成: $filename (大小: $size)"
                break
            else
                echo "⚠ 第 $attempt 次下载失败，正在重试..."
                if [ $attempt -eq 3 ]; then
                    echo "✗ 下载失败: $filename (已重试3次)"
                    echo "请手动下载: curl -L -o /tmp/$filename $url"
                    exit 1
                fi
                sleep 2
            fi
        done
    fi
    echo ""
done

echo "==== 下载完成 ===="
echo "所有SDL2文件已下载到 /tmp 目录:"
echo ""

for download in "${SDL2_DOWNLOADS[@]}"; do
    IFS='|' read -r filename url <<< "$download"
    if [ -f "/tmp/$filename" ]; then
        size=$(du -h "/tmp/$filename" | cut -f1)
        echo "✓ /tmp/$filename (大小: $size)"
    fi
done

echo ""
echo "现在可以运行构建脚本，将优先使用本地文件:"
echo "  ./scripts/build_android_macos.sh"
echo "" 