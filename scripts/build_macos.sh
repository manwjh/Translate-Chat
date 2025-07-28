#!/bin/bash
# =============================================================
# 文件名(File): build_macos.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/28
# 简介(Description): macOS本地构建脚本 - 无需Docker，直接构建macOS应用
# =============================================================

set -e

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

# 显示帮助信息
show_help() {
    cat << EOF
macOS本地构建脚本 v1.0.0

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建

示例:
    $0                   # 构建macOS应用
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

注意: 此脚本仅构建当前macOS架构的应用

EOF
}

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false

# 检测当前架构
detect_current_arch() {
    local arch=$(uname -m)
    case "$arch" in
        "x86_64")
            echo "x86_64"
            ;;
        "arm64")
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检查Python环境
check_python_environment() {
    log_info "检查Python环境..."
    
    # 检查Python版本
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
    return 0
}

# 检查系统依赖
check_system_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查Homebrew
    if ! command -v brew &> /dev/null; then
        log_warning "未找到Homebrew，建议安装以获取更好的依赖管理"
        log_info "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
        log_success "Homebrew已安装"
    fi
    
    # 检查必要的系统工具
    for tool in git curl wget; do
        if ! command -v $tool &> /dev/null; then
            log_error "缺少必要工具: $tool"
            return 1
        fi
    done
    
    log_success "系统依赖检查通过"
    return 0
}

# 创建构建目录
create_build_directories() {
    log_info "创建构建目录..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    
    log_success "构建目录创建完成"
}

# 清理构建缓存
clean_build_cache() {
    log_info "清理构建缓存..."
    
    # 清理构建目录
    rm -rf "$BUILD_DIR"
    rm -rf "$DIST_DIR"
    
    # 清理Python缓存
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    log_success "构建缓存清理完成"
}

# 本地构建应用
build_application_local() {
    local target_arch=$(detect_current_arch)
    local build_dir="$BUILD_DIR/macos"
    local dist_dir="$DIST_DIR/macos"
    
    log_info "开始构建macOS应用 (架构: $target_arch)..."
    
    # 创建构建目录
    mkdir -p "$build_dir" "$dist_dir"
    cd "$build_dir"
    
    # 创建虚拟环境
    log_info "创建Python虚拟环境..."
    python3 -m venv venv
    source venv/bin/activate
    
    # 安装依赖
    log_info "安装Python依赖..."
    pip install --upgrade pip setuptools wheel
    pip install -r "$PROJECT_ROOT/requirements-desktop.txt"
    pip install pyinstaller==5.13.2
    
    # 移除与PyInstaller不兼容的typing包
    if pip show typing &> /dev/null; then
        log_warning "检测到typing包，正在移除（PyInstaller兼容性要求）..."
        pip uninstall -y typing
    fi
    
    # 复制项目文件
    log_info "复制项目文件..."
    cp -r "$PROJECT_ROOT"/* .
    
    # 使用PyInstaller构建
    log_info "使用PyInstaller构建应用..."
    pyinstaller \
        --onefile \
        --windowed \
        --name="translate-chat" \
        --add-data="assets:assets" \
        --add-data="ui:ui" \
        --add-data="utils:utils" \
        --hidden-import=kivy \
        --hidden-import=kivymd \
        --hidden-import=kivymd.icon_definitions \
        --hidden-import=kivymd.icon_definitions.md_icons \
        --hidden-import=kivymd.uix.label \
        --hidden-import=kivymd.uix.button \
        --hidden-import=kivymd.uix.card \
        --hidden-import=kivymd.uix.boxlayout \
        --hidden-import=kivymd.uix.textfield \
        --hidden-import=kivymd.uix.dialog \
        --hidden-import=kivymd.uix.list \
        --hidden-import=kivymd.uix.selectioncontrol \
        --hidden-import=kivymd.uix.screen \
        --hidden-import=kivymd.uix.toolbar \
        --hidden-import=kivymd.uix.widget \
        --hidden-import=websocket \
        --hidden-import=aiohttp \
        --hidden-import=cryptography \
        --hidden-import=pyaudio \
        --hidden-import=asr_client \
        --hidden-import=translator \
        --hidden-import=config_manager \
        --hidden-import=lang_detect \
        --hidden-import=hotwords \
        --hidden-import=audio_capture \
        --hidden-import=audio_capture_pyaudio \
        --hidden-import=webrtcvad \
        --hidden-import=numpy \
        --hidden-import=scipy \
        --hidden-import=requests \
        --hidden-import=urllib3 \
        --hidden-import=utils.secure_storage \
        --hidden-import=utils.file_downloader \
        main.py
    
    # 复制构建产物
    if [[ -f "dist/translate-chat" ]]; then
        cp "dist/translate-chat" "$dist_dir/"
        log_success "macOS应用构建成功"
        return 0
    else
        log_error "macOS应用构建失败"
        return 1
    fi
}

# 创建macOS应用包
create_macos_app() {
    local dist_dir="$DIST_DIR/macos"
    local app_name="Translate-Chat.app"
    local app_path="$dist_dir/$app_name"
    
    log_info "创建macOS应用包..."
    
    # 检查可执行文件是否存在
    if [[ ! -f "$dist_dir/translate-chat" ]]; then
        log_error "可执行文件不存在: $dist_dir/translate-chat"
        return 1
    fi
    
    # 创建应用包结构
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"
    
    # 复制可执行文件
    cp "$dist_dir/translate-chat" "$app_path/Contents/MacOS/"
    
    # 创建Info.plist（确保先删除可能存在的目录）
    rm -rf "$app_path/Contents/Info.plist"
    cat > "$app_path/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>translate-chat</string>
    <key>CFBundleIdentifier</key>
    <string>com.translatechat.app</string>
    <key>CFBundleName</key>
    <string>Translate Chat</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
    
    log_success "macOS应用包创建完成: $app_path"
}

# 显示构建结果
show_build_results() {
    log_info "构建结果:"
    echo ""
    
    local dist_dir="$DIST_DIR/macos"
    if [[ -d "$dist_dir" ]]; then
        echo "  macOS应用:"
        ls -la "$dist_dir" 2>/dev/null | grep -E "(translate-chat|\.app)" || echo "    无构建产物"
    fi
    
    echo ""
    log_info "构建产物位置: $DIST_DIR"
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -t|--test)
                TEST_ONLY=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 显示开始信息
    echo "==== macOS本地构建脚本 v1.0.0 ===="
    echo "开始时间: $(date)"
    echo ""
    
    # 检查是否在项目根目录
    if [[ ! -f "main.py" ]]; then
        log_error "未找到main.py文件，请确保在项目根目录运行"
        exit 1
    fi
    
    # 检查是否为macOS系统
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "此脚本仅适用于macOS系统"
        exit 1
    fi
    
    # 检测当前架构
    local current_arch=$(detect_current_arch)
    log_info "当前架构: $current_arch"
    
    # 清理构建缓存
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_build_cache
        exit 0
    fi
    
    # 检查环境
    if ! check_python_environment; then
        exit 1
    fi
    
    if ! check_system_dependencies; then
        exit 1
    fi
    
    # 仅测试环境
    if [[ "$TEST_ONLY" == true ]]; then
        log_success "环境检查通过，可以进行构建"
        exit 0
    fi
    
    # 创建构建目录
    create_build_directories
    
    # 构建应用
    if ! build_application_local; then
        exit 1
    fi
    
    # 创建macOS应用包
    create_macos_app
    
    # 显示构建结果
    show_build_results
    
    echo ""
    echo "==== 构建完成 ===="
    echo "结束时间: $(date)"
}

# 运行主函数
main "$@" 