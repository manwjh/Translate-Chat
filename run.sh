#!/bin/bash

# =============================================================
# 文件名(File): run.sh
# 版本(Version): v0.6
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 跨平台自动化启动脚本，自动安装依赖，支持 KivyMD
# =============================================================

set -e

PLATFORM="$(uname)"

# 1. 自动安装 Linux 下的 PortAudio 开发包
if [[ "$PLATFORM" == "Linux" ]]; then
    if ! ldconfig -p | grep -q portaudio; then
        echo "[INFO] 未检测到 PortAudio 库，正在尝试自动安装..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y portaudio19-dev
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y portaudio-devel
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm portaudio
        else
            echo "[ERROR] 未知的包管理器，请手动安装 PortAudio 开发包。"
            exit 1
        fi
    fi
fi

# 2. 自动创建 Python 虚拟环境
if [[ ! -d "venv" ]]; then
    echo "[INFO] 未检测到虚拟环境，正在自动创建..."
    python3 -m venv venv
fi

# 3. 自动激活虚拟环境
source venv/bin/activate

# 4. 自动升级 pip
pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple

# 5. 自动安装 Python 依赖
if [[ "$PLATFORM" == "Darwin" || "$PLATFORM" == "Linux" ]]; then
    pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    python3 main.py
elif [[ "$PLATFORM" == "Android" ]]; then
    pip install -r requirements-android.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    python3 main.py
else
    echo "Unsupported platform: $PLATFORM"
    exit 1
fi 