#!/bin/bash
# 通用打包工具函数脚本 / Common Build Utilities Script
# 文件名(File): common_build_utils.sh
# 创建日期(Created): 2024/06/09
# 作者(Author): AI Assistant
# 简介(Description): 提供SDL2本地包检测/下载、环境变量设置、Python依赖wheels准备等通用函数，供主打包脚本调用。

set -e

# 检查并设置SDL2相关环境变量
# 检查/tmp下是否有SDL2相关包，无则自动调用下载脚本
verify_and_prepare_sdl2() {
    local sdl2_files=(
        "SDL2-2.28.5.tar"
        "SDL2_image-2.8.0.tar"
        "SDL_image-release-2.0.tar"  # 兼容新旧命名
        "SDL2_mixer-2.6.3.tar"
        "SDL2_ttf-2.20.2.tar"
        "SDL_ttf-release-2.0.15.tar"  # 兼容旧版命名
    )
    local all_files_exist=true
    local sdl2_ttf_found=false
    local sdl2_image_found=false
    
    # 检查文件是否存在（支持.tar和.tar.gz两种格式）
    for file in "${sdl2_files[@]}"; do
        local base_name="${file%.tar}"
        local found=false
        
        # 检查.tar文件
        if [ -f "/tmp/$file" ]; then
            found=true
        fi
        # 检查.tar.gz文件
        if [ -f "/tmp/${base_name}.tar.gz" ]; then
            found=true
        fi
        
        if [ "$found" = true ]; then
            if [[ "$file" == *"ttf"* ]]; then sdl2_ttf_found=true; fi
            if [[ "$file" == *"image"* ]]; then sdl2_image_found=true; fi
        else
            if [[ "$file" == *"ttf"* ]] || [[ "$file" == *"image"* ]]; then
                continue
            else
                all_files_exist=false
            fi
        fi
    done
    
    if [ "$sdl2_ttf_found" = false ] || [ "$sdl2_image_found" = false ]; then
        all_files_exist=false
    fi
    
    if [ "$all_files_exist" = false ]; then
        echo "[INFO] 检测到SDL2本地包不全，自动调用统一预下载脚本..."
        bash ./scripts/dependency_manager.sh
    fi
    
    # 设置环境变量（支持.tar和.tar.gz两种格式）
    export SDL2_LOCAL_PATH="/tmp"
    
    # SDL2_mixer环境变量
    if [ -f "/tmp/SDL2_mixer-2.6.3.tar" ]; then
        export SDL2_MIXER_LOCAL_PATH="/tmp/SDL2_mixer-2.6.3.tar"
    elif [ -f "/tmp/SDL2_mixer-2.6.3.tar.gz" ]; then
        export SDL2_MIXER_LOCAL_PATH="/tmp/SDL2_mixer-2.6.3.tar.gz"
    else
        export SDL2_MIXER_LOCAL_PATH=""
    fi
    
    # SDL2_image环境变量
    if [ -f "/tmp/SDL2_image-2.8.0.tar" ]; then
        export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL2_image-2.8.0.tar"
    elif [ -f "/tmp/SDL2_image-2.8.0.tar.gz" ]; then
        export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL2_image-2.8.0.tar.gz"
    elif [ -f "/tmp/SDL_image-release-2.0.tar" ]; then
        export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL_image-release-2.0.tar"
    elif [ -f "/tmp/SDL_image-release-2.0.tar.gz" ]; then
        export SDL2_IMAGE_LOCAL_PATH="/tmp/SDL_image-release-2.0.tar.gz"
    else
        export SDL2_IMAGE_LOCAL_PATH=""
    fi
    
    # SDL2_ttf环境变量
    if [ -f "/tmp/SDL2_ttf-2.20.2.tar" ]; then
        export SDL2_TTF_LOCAL_PATH="/tmp/SDL2_ttf-2.20.2.tar"
    elif [ -f "/tmp/SDL2_ttf-2.20.2.tar.gz" ]; then
        export SDL2_TTF_LOCAL_PATH="/tmp/SDL2_ttf-2.20.2.tar.gz"
    elif [ -f "/tmp/SDL_ttf-release-2.0.15.tar" ]; then
        export SDL2_TTF_LOCAL_PATH="/tmp/SDL_ttf-release-2.0.15.tar"
    elif [ -f "/tmp/SDL_ttf-release-2.0.15.tar.gz" ]; then
        export SDL2_TTF_LOCAL_PATH="/tmp/SDL_ttf-release-2.0.15.tar.gz"
    else
        export SDL2_TTF_LOCAL_PATH=""
    fi
    
    echo "[INFO] SDL2本地包环境变量已设置。"
    echo "  SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
    echo "  SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
    echo "  SDL2_IMAGE_LOCAL_PATH: $SDL2_IMAGE_LOCAL_PATH"
    echo "  SDL2_TTF_LOCAL_PATH: $SDL2_TTF_LOCAL_PATH"
}

# 下载Python依赖到本地wheels目录，便于离线安装
prepare_python_wheels() {
    mkdir -p ./wheels
    if [ -f requirements-android.txt ]; then
        pip download -r requirements-android.txt -d ./wheels
    fi
    if [ -f requirements-desktop.txt ]; then
        pip download -r requirements-desktop.txt -d ./wheels
    fi
    pip download buildozer cython -d ./wheels
    echo "[INFO] Python依赖已下载到./wheels目录。"
}

# 优先本地wheels安装Python依赖
install_python_wheels() {
    if [ -d ./wheels ]; then
        if [ -f requirements-android.txt ]; then
            pip install --no-index --find-links=./wheels -r requirements-android.txt
        fi
        if [ -f requirements-desktop.txt ]; then
            pip install --no-index --find-links=./wheels -r requirements-desktop.txt
        fi
    fi
    echo "[INFO] Python依赖已本地安装。"
}

# 通用本地依赖检测和准备函数
# 检查/tmp下是否有各种依赖包，优先使用本地文件
verify_and_prepare_all_dependencies() {
    echo "[INFO] 开始检查本地依赖包..."
    
    # 1. 检查SDL2相关依赖
    echo "[INFO] 检查SDL2本地依赖..."
    verify_and_prepare_sdl2
    
    # 2. 检查Python wheels依赖
    echo "[INFO] 检查Python wheels本地依赖..."
    if [ ! -d "./wheels" ] || [ -z "$(ls -A ./wheels 2>/dev/null)" ]; then
        echo "[INFO] Python wheels目录为空，准备下载..."
        prepare_python_wheels
    else
        echo "[INFO] Python wheels目录已存在，将优先使用本地文件"
    fi
    
    # 3. 检查Android SDK/NDK本地路径（如果设置了环境变量）
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        echo "[INFO] 检测到Android SDK本地路径: $ANDROID_SDK_ROOT"
        export ANDROID_SDK_ROOT
    fi
    
    if [ -n "$ANDROID_NDK_ROOT" ] && [ -d "$ANDROID_NDK_ROOT" ]; then
        echo "[INFO] 检测到Android NDK本地路径: $ANDROID_NDK_ROOT"
        export ANDROID_NDK_ROOT
    fi
    
    # 4. 检查其他可能的本地依赖包
    local common_deps=(
        "openssl"
        "python"
        "java"
        "gradle"
        "cmake"
    )
    
    echo "[INFO] 检查其他本地依赖..."
    for dep in "${common_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "[INFO] ✓ 找到本地 $dep: $(which $dep)"
        fi
    done
    
    echo "[INFO] 本地依赖检查完成"
} 