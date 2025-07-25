#!/bin/bash

# =============================================================
# 文件名(File): run.sh
# 版本(Version): v0.4
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 跨平台启动脚本，自动选择依赖文件，支持 KivyMD
# =============================================================

PLATFORM="$(uname)"
if [[ "$PLATFORM" == "Darwin" || "$PLATFORM" == "Linux" ]]; then
    # 桌面端
    source venv/bin/activate
    pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    python3 main.py
elif [[ "$PLATFORM" == "Android" ]]; then
    # Android (如 Termux)
    pip install -r requirements-android.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    python3 main.py
else
    echo "Unsupported platform: $PLATFORM"
    exit 1
fi 