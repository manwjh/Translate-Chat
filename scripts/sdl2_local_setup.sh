#!/bin/bash
# SDL2 本地文件管理脚本
# 文件名(File): sdl2_local_setup.sh
# 版本(Version): v0.1.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 管理 SDL2 相关文件的本地优先下载

set -e

echo "==== SDL2 本地文件管理脚本 ===="
echo ""

# 检查 /tmp 目录下的 SDL2 文件
echo "检查 /tmp 目录下的 SDL2 文件:"
echo ""

SDL2_FILES=(
    "SDL2-2.28.5.tar"
    "SDL2_image-2.8.0.tar"
    "SDL2_mixer-2.6.3.tar"
    "SDL2_ttf-2.20.2.tar"
    "SDL_ttf-release-2.0.15.tar"  # 兼容旧版本命名
)

for file in "${SDL2_FILES[@]}"; do
    if [ -f "/tmp/$file" ]; then
        size=$(du -h "/tmp/$file" | cut -f1)
        echo "✓ 找到: $file (大小: $size)"
    else
        echo "✗ 缺失: $file"
    fi
done

echo ""
echo "==== 使用说明 ===="
echo "1. 将 SDL2 相关文件放在 /tmp 目录下"
echo "2. 文件名格式: SDL2-{version}.tar (注意是 .tar 不是 .tar.gz)"
echo "3. 支持的版本:"
echo "   - SDL2: 2.28.5"
echo "   - SDL2_image: 2.8.0"
echo "   - SDL2_mixer: 2.6.3"
echo "   - SDL2_ttf: 2.20.2"
echo ""
echo "4. 运行构建脚本时，系统会优先使用本地文件"
echo "5. 如果本地文件不存在，会自动从网络下载"
echo ""

# 提供下载链接
echo "==== 下载链接 ===="
echo "如果需要在本地下载这些文件，可以使用以下链接:"
echo ""
echo "SDL2:"
echo "wget -O /tmp/SDL2-2.28.5.tar https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz"
echo ""
echo "SDL2_image:"
echo "wget -O /tmp/SDL2_image-2.8.0.tar https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.0/SDL2_image-2.8.0.tar.gz"
echo ""
echo "SDL2_mixer:"
echo "wget -O /tmp/SDL2_mixer-2.6.3.tar https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz"
echo ""
echo "SDL2_ttf:"
echo "wget -O /tmp/SDL2_ttf-2.20.2.tar https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.20.2/SDL2_ttf-2.20.2.tar.gz"
echo ""

echo "==== 注意事项 ===="
echo "- 确保下载的文件是 .tar 格式（不是 .tar.gz）"
echo "- 如果下载的是 .tar.gz 文件，请解压后重命名为 .tar"
echo "- 文件权限应该是可读的"
echo "" 