#!/bin/bash
# Translate Chat - macOS Android 打包自动化脚本
# 文件名(File): build_android_macos.sh
# 版本(Version): v2.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): macOS Android 打包自动化脚本，统一环境配置，解决兼容性问题

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - macOS Android 打包脚本 v2.0.0 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为macOS系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "此脚本仅适用于macOS系统"
    log_error "检测到的系统: $OSTYPE"
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

# 环境检查
echo "==== 1. 环境检查 ===="
if ! check_environment; then
    log_error "环境检查失败，请修复问题后重试"
    exit 1
fi

# 获取合适的Python命令
get_python_cmd() {
    # 优先检查Python 3.10
    if [[ -f "/opt/homebrew/bin/python3.10" ]]; then
        echo "/opt/homebrew/bin/python3.10"
    elif [[ -f "/usr/local/bin/python3.10" ]]; then
        echo "/usr/local/bin/python3.10"
    elif [[ -f "/opt/homebrew/bin/python3.11" ]]; then
        echo "/opt/homebrew/bin/python3.11"
    elif [[ -f "/usr/local/bin/python3.11" ]]; then
        echo "/usr/local/bin/python3.11"
    elif [[ -f "/opt/homebrew/bin/python3.9" ]]; then
        echo "/opt/homebrew/bin/python3.9"
    elif [[ -f "/usr/local/bin/python3.9" ]]; then
        echo "/usr/local/bin/python3.9"
    else
        echo "/opt/homebrew/bin/python3"
    fi
}

PYTHON_CMD=$(get_python_cmd)
log_info "使用Python命令: $PYTHON_CMD"

# 配置pip镜像
echo "==== 2. 配置pip镜像 ===="
setup_pip_mirror

# 检查并准备本地依赖包
echo "==== 3. 检查本地依赖包 ===="
verify_and_prepare_all_dependencies

echo ""
log_info "提示: 本地依赖包将优先使用，避免网络下载"
log_info "如需下载本地依赖包，请运行: ./scripts/dependency_manager.sh"
echo ""

# 检查并安装系统依赖
echo "==== 4. 安装系统依赖 ===="

# 检查Homebrew
if ! command -v brew &> /dev/null; then
    log_error "Homebrew未安装，请先安装Homebrew"
    log_info "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# 安装JDK 17
if ! brew list --versions openjdk@17 >/dev/null; then
    log_info "安装openjdk@17..."
    brew install openjdk@17
else
    log_success "openjdk@17已安装"
fi

# 安装其他必要依赖
log_info "安装其他系统依赖..."
brew install git cmake pkg-config

# 检查openssl@1.1
if ! brew list --versions openssl@1.1 >/dev/null; then
    log_warning "未安装openssl@1.1，尝试安装..."
    brew install openssl@1.1
fi

# 设置openssl环境变量
if [[ -d "/opt/homebrew/opt/openssl@1.1" ]]; then
    export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
    export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
    log_success "设置openssl@1.1环境变量: /opt/homebrew/opt/openssl@1.1"
elif [[ -d "/usr/local/opt/openssl@1.1" ]]; then
    export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
    export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
    log_success "设置openssl@1.1环境变量: /usr/local/opt/openssl@1.1"
else
    log_warning "未找到openssl@1.1，使用系统默认"
fi

# 创建Python虚拟环境
echo "==== 5. 创建Python虚拟环境 ===="
create_venv "$PYTHON_CMD" "venv"

# 安装Python依赖
echo "==== 6. 安装Python依赖 ===="
install_python_deps "venv"

# 激活虚拟环境
source venv/bin/activate

# 再次导出关键环境变量，确保venv内可见
export LDFLAGS
export CPPFLAGS
export PKG_CONFIG_PATH
export JAVA_HOME
export PATH
export SDL2_LOCAL_PATH
export SDL2_MIXER_LOCAL_PATH
export SDL2_IMAGE_LOCAL_PATH
export SDL2_TTF_LOCAL_PATH
export LIBWEBP_LOCAL_PATH
export OPENJDK_AARCH64_LOCAL_PATH
export OPENJDK_X64_LOCAL_PATH
export ANDROID_SDK_LOCAL_PATH
export ANDROID_NDK_LOCAL_PATH

# === 本地libwebp自动兜底机制 ===
log_info "检查是否需要自动解压本地libwebp包..."
# 先尝试触发external目录生成（不要求成功）
buildozer android release || true
EXTERNAL_DIR=$(find .buildozer -type d -path "*/SDL2_image/external" | head -n 1)
if [[ -n "$LIBWEBP_LOCAL_PATH" && -f "$LIBWEBP_LOCAL_PATH" && -n "$EXTERNAL_DIR" ]]; then
    log_info "检测到本地libwebp包，准备解压到external目录..."
    tar -xf "$LIBWEBP_LOCAL_PATH" -C "$EXTERNAL_DIR"
    log_success "libwebp已解压到: $EXTERNAL_DIR"
else
    log_info "未检测到本地libwebp包或external目录，跳过自动解压"
fi

# === 本地OpenJDK17自动兜底机制 ===
log_info "检查是否需要配置本地OpenJDK17包..."
# 检测系统架构并选择对应的OpenJDK包
if [[ "$(uname -m)" == "arm64" ]]; then
    OPENJDK_LOCAL_PATH="$OPENJDK_AARCH64_LOCAL_PATH"
    log_info "检测到ARM64架构，使用aarch64版本OpenJDK"
else
    OPENJDK_LOCAL_PATH="$OPENJDK_X64_LOCAL_PATH"
    log_info "检测到x64架构，使用x64版本OpenJDK"
fi

if [[ -n "$OPENJDK_LOCAL_PATH" && -f "$OPENJDK_LOCAL_PATH" ]]; then
    log_info "检测到本地OpenJDK17包，准备配置..."
    # 创建OpenJDK目标目录
    OPENJDK_TARGET_DIR="$HOME/.buildozer/android/platform/openjdk"
    mkdir -p "$OPENJDK_TARGET_DIR"
    
    # 解压OpenJDK到目标目录
    log_info "解压OpenJDK17到: $OPENJDK_TARGET_DIR"
    tar -xf "$OPENJDK_LOCAL_PATH" -C "$OPENJDK_TARGET_DIR"
    
    # 设置JAVA_HOME环境变量指向本地OpenJDK
    OPENJDK_EXTRACTED_DIR=$(find "$OPENJDK_TARGET_DIR" -maxdepth 1 -type d -name "*jdk*" | head -n 1)
    if [[ -n "$OPENJDK_EXTRACTED_DIR" ]]; then
        export JAVA_HOME="$OPENJDK_EXTRACTED_DIR"
        export PATH="$JAVA_HOME/bin:$PATH"
        log_success "OpenJDK17已配置: $JAVA_HOME"
    else
        log_warning "OpenJDK解压后未找到jdk目录，使用系统默认Java"
    fi
else
    log_info "未检测到本地OpenJDK17包，使用系统默认Java"
fi

# === 本地Android SDK/NDK自动兜底机制 ===
log_info "检查是否需要配置本地Android SDK/NDK包..."
ANDROID_SDK_TARGET_DIR="$HOME/.buildozer/android/platform/android-sdk"
ANDROID_NDK_TARGET_DIR="$HOME/.buildozer/android/platform/android-ndk-r25b"

# 配置SDK
if [[ -n "$ANDROID_SDK_LOCAL_PATH" && -f "$ANDROID_SDK_LOCAL_PATH" ]]; then
    log_info "检测到本地Android SDK包，准备解压..."
    mkdir -p "$ANDROID_SDK_TARGET_DIR"
    unzip -o "$ANDROID_SDK_LOCAL_PATH" -d "$ANDROID_SDK_TARGET_DIR" && log_success "Android SDK已解压到: $ANDROID_SDK_TARGET_DIR" || log_warning "Android SDK解压失败"
else
    log_info "未检测到本地Android SDK包，使用系统默认或在线下载"
fi

# 配置NDK
if [[ -n "$ANDROID_NDK_LOCAL_PATH" && -f "$ANDROID_NDK_LOCAL_PATH" ]]; then
    log_info "检测到本地Android NDK包，准备挂载/解压..."
    mkdir -p "$ANDROID_NDK_TARGET_DIR"
    # macOS下dmg需挂载，简化处理为提示用户手动挂载或解压
    hdiutil attach "$ANDROID_NDK_LOCAL_PATH" -mountpoint "$ANDROID_NDK_TARGET_DIR" && log_success "Android NDK已挂载到: $ANDROID_NDK_TARGET_DIR" || log_warning "Android NDK挂载失败，请手动解压或挂载"
else
    log_info "未检测到本地Android NDK包，使用系统默认或在线下载"
fi

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
echo "==== 10. 检查打包结果 ===="
if check_build_result; then
    log_success "APK构建成功！"
else
    log_error "APK构建失败"
    exit 1
fi

echo ""
echo "==== 11. 构建完成总结 ===="
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

echo "==== 12. 部署说明 ===="
log_info "如需部署到设备，请:"
echo "1. 连接Android设备并开启USB调试"
echo "2. 运行: buildozer android deploy run"
echo "3. 查看日志: buildozer android logcat"
echo ""

echo "==== 打包完成 ===="
echo "结束时间: $(date)"
echo ""

# 显示构建统计信息
if [[ -d "bin" ]]; then
    echo "==== 构建统计 ===="
    log_info "APK文件信息:"
    for apk in bin/*.apk; do
        if [[ -f "$apk" ]]; then
            local size=$(du -h "$apk" | cut -f1)
            local filename=$(basename "$apk")
            echo "  - $filename ($size)"
        fi
    done
    echo ""
fi

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