#!/bin/bash
# 依赖包本地化管理脚本 / Dependency Local Manager Script
# 文件名(File): dependency_manager.sh
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/1/27
# 简介(Description): 提前下载SDL2和Python依赖包到本地，方便离线打包

set -e

echo "==== 依赖包本地化准备 / Dependency Local Preparation ===="
echo ""

# 1. 下载SDL2相关依赖
# 1. Download SDL2 related dependencies
if [ -f ./scripts/sdl2_local_manager.sh ]; then
    echo "1. 下载SDL2相关依赖... / Downloading SDL2 related dependencies..."
    bash ./scripts/sdl2_local_manager.sh
else
    echo "未找到 scripts/sdl2_local_manager.sh，跳过SDL2依赖下载 / Not found, skipping SDL2 download."
fi

echo ""
# 2. 下载Python依赖包到本地wheels目录
# 2. Download Python dependencies to local wheels directory
mkdir -p ./wheels
echo "2. 下载Python依赖包到本地wheels目录... / Downloading Python dependencies to ./wheels ..."
if [ -f requirements-android.txt ]; then
    pip download -r requirements-android.txt -d ./wheels
fi
if [ -f requirements-desktop.txt ]; then
    pip download -r requirements-desktop.txt -d ./wheels
fi
# 可选：下载常用工具包
pip download buildozer cython -d ./wheels

echo ""
echo "==== 依赖包下载完成 / Dependency Download Complete ===="
echo ""
echo "==== 使用说明 / Usage Instructions ===="
echo "打包时可用如下命令优先本地依赖："
echo "  pip install --no-index --find-links=./wheels -r requirements-android.txt"
echo "  pip install --no-index --find-links=./wheels -r requirements-desktop.txt"
echo ""
echo "buildozer会自动检测SDL2本地包。"
echo "如需自定义Android SDK/NDK路径，请提前下载并设置环境变量。"
echo ""
echo "==== 完成 / Done ====" 