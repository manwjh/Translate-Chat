#!/bin/bash
# Translate Chat - Ubuntu Android 打包自动化脚本
# 文件名(File): build_android_ubuntu.sh
# 版本(Version): v2.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): Ubuntu环境下Android APK自动化打包脚本，统一环境配置，解决兼容性问题

set -e

# 开启调试模式（可选，取消注释以启用）
# set -x

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - Ubuntu Android 打包脚本 v2.0.0 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为Ubuntu系统
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "此脚本仅适用于Ubuntu系统"
    log_error "检测到的系统: $(cat /etc/os-release | grep PRETTY_NAME)"
    exit 1
fi

# 确保在项目根目录运行
if [[ ! -f "main.py" ]]; then
    log_error "未找到main.py文件"
    log_error "请确保在项目根目录运行此脚本"
    log_error "当前目录: $(pwd)"
    log_error "请切换到项目根目录: cd /path/to/Translate-Chat"
    exit 1
fi

log_success "确认在项目根目录运行"
echo ""

# 显示系统信息
log_info "系统信息:"
log_info "  系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
log_info "  架构: $(uname -m)"
log_info "  内核: $(uname -r)"
log_info "  当前用户: $(whoami)"
echo ""

# 环境检查
echo "==== 1. 环境检查 ===="
log_info "开始环境检查..."

# 检查环境并获取Python命令
PYTHON_CMD=$(check_environment)
check_result=$?

log_info "环境检查结果: $check_result"
log_info "返回的Python命令: '$PYTHON_CMD'"

if [[ $check_result -ne 0 ]]; then
    log_error "环境检查失败，请修复问题后重试"
    exit 1
fi

if [[ -z "$PYTHON_CMD" ]]; then
    log_error "未获取到有效的Python命令"
    exit 1
fi

log_success "环境检查通过，使用Python: $PYTHON_CMD"

# 检查Java环境
if ! check_java_version; then
    log_error "Java环境检查失败"
    exit 1
fi

# 设置Java环境
setup_java_env

# 配置pip镜像
echo "==== 2. 配置pip镜像 ===="
setup_pip_mirror

# 检查并准备本地依赖包
echo "==== 3. 检查本地依赖包 ===="
verify_and_prepare_all_dependencies

# 更新系统包
echo "==== 4. 更新系统包 ===="
log_info "更新系统包..."
sudo apt update
sudo apt upgrade -y

# 安装系统依赖
echo "==== 5. 安装系统依赖 ===="
log_info "安装系统依赖..."

# 基础工具
sudo apt install -y \
    git \
    unzip \
    build-essential \
    autoconf \
    libtool \
    pkg-config \
    cmake

# 音频视频相关依赖
sudo apt install -y \
    zlib1g-dev \
    libncurses5 \
    libstdc++6 \
    libffi-dev \
    libssl-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libgif-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportmidi-dev

# FFmpeg相关依赖
sudo apt install -y \
    libswscale-dev \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libavresample-dev \
    libpostproc-dev \
    libswresample-dev

log_success "系统依赖安装完成"

# 安装Java环境
echo "==== 6. 安装Java环境 ===="

# 检查是否已安装JDK 17
if [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
    log_success "JDK 17已安装"
elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
    log_success "JDK 11已安装"
elif [[ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]]; then
    log_warning "检测到JDK 8，建议升级到JDK 11或17"
else
    log_info "安装JDK 17..."
    sudo apt install -y openjdk-17-jdk
fi

# 设置Java环境变量
setup_java_env

# 创建Python虚拟环境
echo "==== 7. 创建Python虚拟环境 ===="
create_venv "$PYTHON_CMD" "venv"

# 安装Python依赖
echo "==== 8. 安装Python依赖 ===="
install_python_deps "venv"

# 激活虚拟环境
source venv/bin/activate

# 检查buildozer.spec文件
echo "==== 9. 检查Buildozer配置 ===="
if [[ ! -f "buildozer.spec" ]]; then
    log_info "未找到buildozer.spec，正在初始化..."
    buildozer init
    log_warning "buildozer.spec已创建，请检查配置后重新运行脚本"
    exit 0
else
    log_success "找到buildozer.spec文件"
    log_info "当前配置摘要:"
    log_info "- 应用名称: $(grep '^title =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    log_info "- 包名: $(grep '^package.name =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    log_info "- 版本: $(grep '^version =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
    log_info "- 目标架构: $(grep '^android.archs =' buildozer.spec | cut -d'=' -f2 | tr -d ' ')"
fi

# 清理之前的构建
echo "==== 10. 清理之前的构建 ===="
clean_build_cache

# 开始打包APK
echo "==== 11. 开始打包APK ===="
log_info "注意: 首次打包可能需要较长时间，需要下载Android SDK/NDK"
log_info "如果网络较慢，建议使用科学上网工具"
echo ""

# 设置环境变量确保在虚拟环境中可见
export JAVA_HOME
export PATH
export SDL2_LOCAL_PATH
export SDL2_MIXER_LOCAL_PATH
export SDL2_IMAGE_LOCAL_PATH
export SDL2_TTF_LOCAL_PATH

# 执行打包
log_info "执行buildozer打包..."
log_info "使用Python: $PYTHON_CMD"
log_info "使用Java: $JAVA_HOME"

if buildozer -v android debug; then
    log_success "buildozer打包命令执行完成"
else
    log_error "buildozer打包失败"
    log_info "请检查日志并修复问题后重试"
    log_info "常见问题："
    log_info "1. 网络连接问题 - 检查网络或使用科学上网工具"
    log_info "2. 权限问题 - 确保有足够的磁盘空间和权限"
    log_info "3. 依赖问题 - 运行: ./scripts/pyjnius_patch.sh"
    exit 1
fi

# 检查打包结果
echo "==== 12. 检查打包结果 ===="
if check_build_result; then
    log_success "APK构建成功！"
else
    log_error "APK构建失败"
    exit 1
fi

echo ""
echo "==== 13. 构建完成总结 ===="
log_success "SDL2本地文件配置:"
[[ -n "$SDL2_LOCAL_PATH" ]] && echo "  - SDL2_LOCAL_PATH: $SDL2_LOCAL_PATH"
[[ -n "$SDL2_MIXER_LOCAL_PATH" ]] && echo "  - SDL2_MIXER_LOCAL_PATH: $SDL2_MIXER_LOCAL_PATH"
[[ -n "$SDL2_IMAGE_LOCAL_PATH" ]] && echo "  - SDL2_IMAGE_LOCAL_PATH: $SDL2_IMAGE_LOCAL_PATH"
[[ -n "$SDL2_TTF_LOCAL_PATH" ]] && echo "  - SDL2_TTF_LOCAL_PATH: $SDL2_TTF_LOCAL_PATH"
echo ""
log_success "环境配置:"
echo "  - Python版本: $($PYTHON_CMD --version)"
echo "  - Java版本: $(java -version 2>&1 | head -n 1)"
echo "  - JAVA_HOME: $JAVA_HOME"
echo ""

echo "==== 14. 部署说明 ===="
log_info "如需部署到设备，请:"
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
    log_info "正在部署到设备..."
    if buildozer android deploy run; then
        log_success "部署成功"
    else
        log_error "部署失败"
    fi
fi 