#!/bin/bash
# =============================================================
# 文件名(File): local_build_linux.sh
# 版本(Version): v2.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 简介(Description): 本地Linux构建脚本 - 支持在x86_linux下直接构建x86_linux应用，无需Docker
# =============================================================

set -e

# 导入通用构建工具
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_build_utils.sh"

# 显示帮助信息
show_help() {
    cat << EOF
Linux本地构建脚本 v1.0.0

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
    $0                   # 构建Linux应用
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境
    $0 --no-appimage    # 不创建AppImage

注意: 此脚本仅构建当前Linux架构的应用

EOF
}

# 全局变量
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false
SKIP_DEPS=false
SKIP_APPIMAGE=false
SKIP_DEB=false





# 检查系统依赖
check_system_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查基础工具
    for cmd in python3 pip3; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    # 检查必要的系统工具
    for tool in git curl wget; do
        if ! command -v $tool &> /dev/null; then
            log_error "缺少必要工具: $tool"
            return 1
        fi
    done
    
    # 检查关键系统库（简化检查）
    if ! ldconfig -p | grep -q "libssl"; then
        missing_deps+=("libssl-dev")
    fi
    
    if ! ldconfig -p | grep -q "libportaudio"; then
        missing_deps+=("portaudio19-dev")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "缺少以下依赖: ${missing_deps[*]}"
        log_info "将尝试自动安装依赖..."
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
        libportaudio2 \
        portaudio19-dev \
        libasound2-dev
    
    log_success "系统依赖安装完成"
}



# 设置Python虚拟环境
setup_python_environment() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "跳过Python环境设置"
        return 0
    fi
    
    # 检查Python环境
    local python_cmd
    python_cmd=$(check_python_environment)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 设置Python环境（调用通用工具函数）
    local venv_path="$PROJECT_ROOT/venv"
    
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
    pip install --no-cache-dir "pyinstaller==5.13.2"
    
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

# 本地构建应用
build_application_local() {
    local target_arch=$(uname -m)
    local build_dir="$BUILD_DIR/linux"
    local dist_dir="$DIST_DIR/linux"
    
    log_info "开始构建Linux应用 (架构: $target_arch)..."
    
    # 创建构建目录
    mkdir -p "$build_dir" "$dist_dir"
    cd "$build_dir"
    
    # 检查Python环境
    local python_cmd
    python_cmd=$(check_python_environment)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 设置Python环境
    setup_python_environment "$python_cmd"
    
    # 复制项目文件
    log_info "复制项目文件..."
    cp -r "$PROJECT_ROOT"/* .
    
    # 构建PyInstaller命令
    local pyinstaller_cmd
    pyinstaller_cmd=$(build_pyinstaller_command)
    
    # 使用PyInstaller构建
    log_info "使用PyInstaller构建应用..."
    if eval "$pyinstaller_cmd"; then
        # 复制构建产物
        if [[ -d "dist/translate-chat" ]]; then
            cp -r "dist/translate-chat" "$dist_dir/"
            
            # 验证构建产物
            if validate_build_artifact "$dist_dir/translate-chat/translate-chat"; then
                log_success "Linux应用构建成功"
                return 0
            else
                log_error "构建产物验证失败"
                return 1
            fi
        else
            log_error "Linux应用构建失败"
            return 1
        fi
    else
        log_error "PyInstaller构建失败"
        return 1
    fi
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
    if [[ ! -f "$DIST_DIR/linux/translate-chat/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/linux/translate-chat/translate-chat"
        return 1
    fi
    
    # 创建AppDir结构
    local appdir="$BUILD_DIR/AppDir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/share/applications"
    mkdir -p "$appdir/usr/share/icons/hicolor/256x256/apps"
    
    # 复制可执行文件
    cp "$DIST_DIR/linux/translate-chat/translate-chat" "$appdir/usr/bin/"
    
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
    if [[ ! -f "$DIST_DIR/linux/translate-chat/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/linux/translate-chat/translate-chat"
        return 1
    fi
    
    # 创建deb包结构
    local deb_dir="$BUILD_DIR/deb"
    mkdir -p "$deb_dir/usr/bin"
    mkdir -p "$deb_dir/usr/share/applications"
    mkdir -p "$deb_dir/DEBIAN"
    
    # 复制可执行文件
    cp "$DIST_DIR/linux/translate-chat/translate-chat" "$deb_dir/usr/bin/"
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
    echo "==== Linux本地构建脚本 v1.0.0 ===="
    echo "开始时间: $(date)"
    echo ""
    
    # 检查是否在项目根目录
    if [[ ! -f "main.py" ]]; then
        log_error "未找到main.py文件，请确保在项目根目录运行"
        exit 1
    fi
    
    # 检查是否为Linux系统
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "此脚本仅适用于Linux系统"
        exit 1
    fi
    
    # 检测当前架构
    local current_arch=$(uname -m)
    log_info "当前架构: $current_arch"
    
    # 清理构建缓存
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_build_cache
        exit 0
    fi
    
    # 检查环境
    local python_cmd
    python_cmd=$(check_python_environment)
    if [[ $? -ne 0 ]]; then
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
    
    # 构建应用
    if ! build_application_local; then
        exit 1
    fi
    
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