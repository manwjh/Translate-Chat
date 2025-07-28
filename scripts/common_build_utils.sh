#!/bin/bash
# =============================================================
# 文件名(File): common_build_utils.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 简介(Description): 通用构建工具脚本 - 提供所有构建脚本共享的配置和函数
# =============================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 全局配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
CACHE_DIR="$PROJECT_ROOT/.build_cache"

# PyInstaller配置
PYINSTALLER_VERSION="5.13.2"
PYINSTALLER_OPTIONS=(
    "--onefile"
    "--windowed"
    "--name=translate-chat"
    "--add-data=assets:assets"
    "--add-data=ui:ui"
    "--add-data=utils:utils"
)

# 隐藏导入列表
HIDDEN_IMPORTS=(
    "kivy"
    "kivymd"
    "kivymd.icon_definitions"
    "kivymd.icon_definitions.md_icons"
    "kivymd.uix.label"
    "kivymd.uix.button"
    "kivymd.uix.card"
    "kivymd.uix.boxlayout"
    "kivymd.uix.textfield"
    "kivymd.uix.dialog"
    "kivymd.uix.list"
    "kivymd.uix.selectioncontrol"
    "kivymd.uix.screen"
    "kivymd.uix.toolbar"
    "kivymd.uix.widget"
    "websocket"
    "aiohttp"
    "cryptography"
    "pyaudio"
    "asr_client"
    "translator"
    "config_manager"
    "lang_detect"
    "hotwords"
    "audio_capture"
    "audio_capture_pyaudio"
    "webrtcvad"
    "numpy"
    "scipy"
    "requests"
    "urllib3"
    "utils.secure_storage"
    "utils.file_downloader"
)

# 检测主机平台
detect_host_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
        "darwin")
            if [[ "$arch" == "arm64" ]]; then
                echo "macos-arm64"
            else
                echo "macos-x86_64"
            fi
            ;;
        "linux")
            if [[ "$arch" == "x86_64" ]]; then
                echo "linux-x86_64"
            elif [[ "$arch" == "aarch64" ]]; then
                echo "linux-arm64"
            else
                echo "linux-unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检查Python环境
check_python_environment() {
    log_info "检查Python环境..."
    
    local python_cmd=""
    for cmd in python3.10 python3.9 python3; do
        if command -v $cmd &> /dev/null; then
            local version=$($cmd --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
            if [[ "$version" =~ ^3\.(9|10|11)$ ]]; then
                python_cmd=$cmd
                break
            fi
        fi
    done
    
    if [[ -z "$python_cmd" ]]; then
        log_error "未找到兼容的Python版本 (需要3.9-3.11)"
        return 1
    fi
    
    log_success "使用Python: $($python_cmd --version)"
    echo "$python_cmd"
    return 0
}

# 创建构建目录
create_build_directories() {
    log_info "创建构建目录..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$CACHE_DIR"
    
    log_success "构建目录创建完成"
}

# 设置Python虚拟环境
setup_python_environment() {
    local venv_path="$PROJECT_ROOT/venv"
    local python_cmd="$1"
    
    log_info "设置Python虚拟环境..."
    
    # 创建虚拟环境
    if [[ ! -d "$venv_path" ]]; then
        $python_cmd -m venv "$venv_path"
    fi
    
    # 激活虚拟环境
    source "$venv_path/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    # 配置pip使用国内镜像源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
    
    # 安装PyInstaller
    pip install --no-cache-dir "pyinstaller==$PYINSTALLER_VERSION"
    
    # 安装项目依赖
    if [[ -f "requirements-desktop.txt" ]]; then
        pip install -r requirements-desktop.txt
    else
        log_warning "未找到requirements-desktop.txt文件"
    fi
    
    # 移除与PyInstaller不兼容的typing包
    if pip show typing &> /dev/null; then
        log_warning "检测到typing包，正在移除（PyInstaller兼容性要求）..."
        pip uninstall -y typing
    fi
    
    log_success "Python环境设置完成"
}

# 构建PyInstaller命令
build_pyinstaller_command() {
    local cmd="pyinstaller"
    
    # 添加基本选项
    for option in "${PYINSTALLER_OPTIONS[@]}"; do
        cmd="$cmd $option"
    done
    
    # 添加隐藏导入
    for import in "${HIDDEN_IMPORTS[@]}"; do
        cmd="$cmd --hidden-import=$import"
    done
    
    # 添加主文件
    cmd="$cmd main.py"
    
    echo "$cmd"
}

# 清理构建缓存
clean_build_cache() {
    log_info "清理构建缓存..."
    
    # 清理构建目录
    rm -rf "$BUILD_DIR"
    rm -rf "$CACHE_DIR"
    rm -rf "$PROJECT_ROOT/build"
    rm -rf "$PROJECT_ROOT/dist"
    
    # 清理PyInstaller缓存
    rm -f "$PROJECT_ROOT/translate-chat.spec"
    
    # 清理Python缓存
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    log_success "构建缓存清理完成"
}

# 显示构建结果
show_build_results() {
    log_info "构建结果:"
    echo ""
    
    if [[ -d "$DIST_DIR" ]]; then
        echo "  构建产物:"
        ls -la "$DIST_DIR" 2>/dev/null | grep -E "(translate-chat|\.AppImage|\.deb|\.app)" || echo "    无构建产物"
    fi
    
    echo ""
    log_info "构建产物位置: $DIST_DIR"
}

# 检查网络连接
check_network_connection() {
    log_info "检查网络连接..."
    
    if curl -s --connect-timeout 10 --max-time 30 https://pypi.org/ > /dev/null; then
        log_success "网络连接正常"
        return 0
    else
        log_warning "网络连接可能有问题，将使用国内镜像源"
        return 1
    fi
}

# 验证构建产物
validate_build_artifact() {
    local artifact_path="$1"
    
    if [[ ! -f "$artifact_path" ]]; then
        log_error "构建产物不存在: $artifact_path"
        return 1
    fi
    
    if [[ ! -x "$artifact_path" ]]; then
        log_error "构建产物不可执行: $artifact_path"
        return 1
    fi
    
    log_success "构建产物验证通过: $artifact_path"
    return 0
}

# 显示帮助信息模板
show_help_template() {
    local script_name="$1"
    local description="$2"
    local additional_options="$3"
    
    cat << EOF
$script_name

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
$additional_options

示例:
    $0                   # 完整构建
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

EOF
} 