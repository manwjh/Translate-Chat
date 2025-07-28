#!/bin/bash
# =============================================================
# 文件名(File): local_build_linux.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 简介(Description): 本地Linux构建脚本 - 支持在x86_linux下直接构建x86_linux应用，无需Docker
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
本地Linux构建脚本 v1.0.0

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
    --no-deps           跳过依赖安装
    --no-appimage       跳过AppImage创建
    --no-deb            跳过deb包创建

示例:
    $0                   # 完整构建
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境
    $0 --no-appimage    # 不创建AppImage

支持的主机平台:
    - Linux (x86_64)    -> 构建 x86_64 Linux应用

EOF
}

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
CACHE_DIR="$PROJECT_ROOT/.build_cache"
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false
SKIP_DEPS=false
SKIP_APPIMAGE=false
SKIP_DEB=false

# 检测主机平台
detect_host_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
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
    
    local missing_deps=()
    
    # 检查基础工具
    for cmd in pip3 virtualenv; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    # 检查系统库
    local libs=("libssl" "libffi" "libjpeg" "libpng" "libfreetype" "libportaudio" "libasound")
    for lib in "${libs[@]}"; do
        if ! ldconfig -p | grep -q "$lib"; then
            missing_deps+=("$lib-dev")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "缺少以下依赖: ${missing_deps[*]}"
        log_info "请运行以下命令安装依赖:"
        echo "sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
        return 1
    fi
    
    log_success "系统依赖检查通过"
    return 0
}

# 安装系统依赖
install_system_dependencies() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "跳过系统依赖安装"
        return 0
    fi
    
    log_info "安装系统依赖..."
    
    # 更新包列表
    sudo apt-get update
    
    # 安装基础开发工具
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        git \
        wget \
        curl \
        pkg-config \
        libssl-dev \
        libffi-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        libgif-dev \
        libportaudio2 \
        portaudio19-dev \
        libasound2-dev \
        libpulse-dev \
        libjack-jackd2-dev \
        libavcodec-dev \
        libavformat-dev \
        libavdevice-dev \
        libavutil-dev \
        libswscale-dev \
        libavfilter-dev \
        libavresample-dev \
        libpostproc-dev \
        libswresample-dev
    
    log_success "系统依赖安装完成"
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
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "跳过Python环境设置"
        return 0
    fi
    
    log_info "设置Python虚拟环境..."
    
    local venv_path="$PROJECT_ROOT/venv"
    
    # 创建虚拟环境
    if [[ ! -d "$venv_path" ]]; then
        python3 -m venv "$venv_path"
    fi
    
    # 激活虚拟环境
    source "$venv_path/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    # 配置pip使用国内镜像源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
    
    # 安装PyInstaller
    pip install --no-cache-dir pyinstaller==5.13.2
    
    # 安装项目依赖
    if [[ -f "requirements-desktop.txt" ]]; then
        pip install -r requirements-desktop.txt
    else
        log_warning "未找到requirements-desktop.txt文件"
    fi
    
    log_success "Python环境设置完成"
}

# 本地构建应用
build_application_local() {
    log_info "开始本地构建应用..."
    
    # 激活虚拟环境
    source "$PROJECT_ROOT/venv/bin/activate"
    
    # 清理之前的构建
    rm -rf build dist
    
    # 使用PyInstaller构建
    pyinstaller \
        --onefile \
        --windowed \
        --name="translate-chat" \
        --add-data="assets:assets" \
        --add-data="ui:ui" \
        --add-data="utils:utils" \
        --hidden-import=kivy \
        --hidden-import=kivymd \
        --hidden-import=websocket \
        --hidden-import=aiohttp \
        --hidden-import=cryptography \
        --hidden-import=pyaudio \
        --hidden-import=asr_client \
        --hidden-import=translator \
        --hidden-import=config_manager \
        --hidden-import=speaker_change_detector \
        --hidden-import=lang_detect \
        --hidden-import=hotwords \
        --hidden-import=audio_capture \
        --hidden-import=audio_capture_pyaudio \
        main.py
    
    # 复制构建产物到dist目录
    cp dist/translate-chat "$DIST_DIR/"
    
    log_success "本地构建完成"
}

# 创建AppImage
create_appimage() {
    if [[ "$SKIP_APPIMAGE" == true ]]; then
        log_info "跳过AppImage创建"
        return 0
    fi
    
    local appimage_name="Translate-Chat-x86_64.AppImage"
    
    log_info "创建AppImage: $appimage_name"
    
    # 检查可执行文件是否存在
    if [[ ! -f "$DIST_DIR/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/translate-chat"
        return 1
    fi
    
    # 创建AppDir结构
    local appdir="$BUILD_DIR/AppDir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/share/applications"
    mkdir -p "$appdir/usr/share/icons/hicolor/256x256/apps"
    
    # 复制可执行文件
    cp "$DIST_DIR/translate-chat" "$appdir/usr/bin/"
    
    # 创建桌面文件
    cat > "$appdir/usr/share/applications/translate-chat.desktop" << EOF
[Desktop Entry]
Name=Translate Chat
Comment=Real-time voice translation application
Exec=translate-chat
Icon=translate-chat
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Network;
EOF
    
    # 创建AppRun脚本
    cat > "$appdir/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}"/usr/bin/:"${PATH}"
export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${LD_LIBRARY_PATH}"
exec "${HERE}"/usr/bin/translate-chat "$@"
EOF
    
    chmod +x "$appdir/AppRun"
    
    # 创建AppImage（如果appimagetool可用）
    if command -v appimagetool &> /dev/null; then
        if appimagetool "$appdir" "$DIST_DIR/$appimage_name"; then
            log_success "AppImage创建成功: $appimage_name"
        else
            log_warning "AppImage创建失败，但可执行文件可用"
        fi
    else
        log_warning "appimagetool不可用，跳过AppImage创建"
    fi
    
    # 清理AppDir
    rm -rf "$appdir"
}

# 创建deb包
create_deb_package() {
    if [[ "$SKIP_DEB" == true ]]; then
        log_info "跳过deb包创建"
        return 0
    fi
    
    local deb_name="translate-chat_1.0.0_x86_64.deb"
    
    log_info "创建deb包: $deb_name"
    
    # 检查可执行文件是否存在
    if [[ ! -f "$DIST_DIR/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/translate-chat"
        return 1
    fi
    
    # 创建deb包结构
    local deb_dir="$BUILD_DIR/deb"
    mkdir -p "$deb_dir/usr/bin"
    mkdir -p "$deb_dir/usr/share/applications"
    mkdir -p "$deb_dir/DEBIAN"
    
    # 复制可执行文件
    cp "$DIST_DIR/translate-chat" "$deb_dir/usr/bin/"
    chmod +x "$deb_dir/usr/bin/translate-chat"
    
    # 创建桌面文件
    cat > "$deb_dir/usr/share/applications/translate-chat.desktop" << EOF
[Desktop Entry]
Name=Translate Chat
Comment=Real-time voice translation application
Exec=translate-chat
Icon=translate-chat
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Network;
EOF
    
    # 创建control文件
    cat > "$deb_dir/DEBIAN/control" << EOF
Package: translate-chat
Version: 1.0.0
Architecture: amd64
Maintainer: Translate Chat Team
Description: Real-time voice translation application
 A lightweight real-time voice translation application
 based on Kivy framework.
EOF
    
    # 创建deb包
    if command -v dpkg-deb &> /dev/null; then
        if dpkg-deb --build "$deb_dir" "$DIST_DIR/$deb_name"; then
            log_success "deb包创建成功: $deb_name"
        else
            log_warning "deb包创建失败"
        fi
    else
        log_warning "dpkg-deb不可用，跳过deb包创建"
    fi
    
    # 清理deb目录
    rm -rf "$deb_dir"
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
    rm -rf "$PROJECT_ROOT/build"
    rm -rf "$PROJECT_ROOT/dist"
    rm -f "$PROJECT_ROOT/translate-chat.spec"
    
    log_success "构建缓存清理完成"
}

# 显示构建结果
show_build_results() {
    log_info "构建结果:"
    echo ""
    
    if [[ -d "$DIST_DIR" ]]; then
        echo "  构建产物:"
        ls -la "$DIST_DIR" 2>/dev/null | grep -E "(translate-chat|\.AppImage|\.deb)" || echo "    无构建产物"
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
            --no-deps)
                SKIP_DEPS=true
                shift
                ;;
            --no-appimage)
                SKIP_APPIMAGE=true
                shift
                ;;
            --no-deb)
                SKIP_DEB=true
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
    echo "==== 本地Linux构建脚本 v1.0.0 ===="
    echo "开始时间: $(date)"
    echo ""
    
    # 检查是否在项目根目录
    if [[ ! -f "main.py" ]]; then
        log_error "未找到main.py文件，请确保在项目根目录运行"
        exit 1
    fi
    
    # 检测主机平台
    local host_platform=$(detect_host_platform)
    log_info "主机平台: $host_platform"
    
    # 检查平台兼容性
    if [[ "$host_platform" != "linux-x86_64" ]]; then
        log_error "此脚本仅支持在Linux x86_64平台上运行"
        exit 1
    fi
    
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
        log_warning "系统依赖检查失败，将尝试安装依赖"
        install_system_dependencies
    fi
    
    # 仅测试环境
    if [[ "$TEST_ONLY" == true ]]; then
        log_success "环境检查通过，可以进行构建"
        exit 0
    fi
    
    # 创建构建目录
    create_build_directories
    
    # 设置Python环境
    setup_python_environment
    
    # 构建应用
    build_application_local
    
    # 创建AppImage
    create_appimage
    
    # 创建deb包
    create_deb_package
    
    # 显示构建结果
    show_build_results
    
    echo ""
    echo "==== 构建完成 ===="
    echo "结束时间: $(date)"
}

# 运行主函数
main "$@" 