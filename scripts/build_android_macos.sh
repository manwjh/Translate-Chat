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

# 检查buildozer.spec文件
echo "==== 7. 检查Buildozer配置 ===="
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
echo "==== 8. 清理之前的构建 ===="
clean_build_cache

# 开始打包APK
echo "==== 9. 开始打包APK ===="
log_info "注意: 首次打包可能需要较长时间，需要下载Android SDK/NDK"
log_info "如果网络较慢，建议使用科学上网工具"
echo ""

# 验证环境变量
log_info "验证环境变量..."
if [[ -z "$JAVA_HOME" ]]; then
    log_error "JAVA_HOME未设置"
    exit 1
fi

if [[ -z "$PYTHON_CMD" ]]; then
    log_error "PYTHON_CMD未设置"
    exit 1
fi

log_success "环境变量验证通过"

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