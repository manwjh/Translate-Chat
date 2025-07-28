#!/bin/bash
# =============================================================
# 文件名(File): unified_build_optimized.sh
# 版本(Version): v2.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 简介(Description): 优化的统一跨平台打包系统 - 基于已验证的本地构建脚本
# =============================================================

set -e

# 导入通用构建工具
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_build_utils.sh"

# 显示帮助信息
show_help() {
    cat << EOF
优化的统一跨平台打包系统 v2.0.0

用法: $0 [选项] [目标平台]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
    --no-deps           跳过依赖安装
    --no-package        跳过打包（AppImage/deb/dmg）

目标平台:
    linux              构建Linux应用 (x86_64)
    macos              构建macOS应用 (当前架构)
    all                构建所有平台

示例:
    $0 linux            # 构建Linux应用
    $0 macos            # 构建macOS应用
    $0 all              # 构建所有平台
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

支持的主机平台:
    - macOS (ARM64/x86_64) -> 构建 macOS应用
    - Linux (x86_64)       -> 构建 Linux应用

注意: 此脚本基于已验证的本地构建脚本，提供更稳定的构建体验

EOF
}

# 全局变量
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false
SKIP_DEPS=false
SKIP_PACKAGE=false
TARGET_PLATFORM=""

# 检查Docker环境
check_docker_environment() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker未安装，将使用本地构建模式"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_warning "Docker未运行，将使用本地构建模式"
        return 1
    fi
    
    log_success "Docker环境可用"
    return 0
}

# 构建Linux应用
build_linux_application() {
    local host_platform=$(detect_host_platform)
    
    log_info "开始构建Linux应用..."
    
    # 检查是否在Linux平台上
    if [[ "$host_platform" == "linux-x86_64" ]]; then
        log_info "在Linux平台上直接构建..."
        
        # 检查Python环境
        local python_cmd
        python_cmd=$(check_python_environment)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        # 创建构建目录
        create_build_directories
        
        # 设置Python环境
        if [[ "$SKIP_DEPS" != true ]]; then
            setup_python_environment "$python_cmd"
        fi
        
        # 激活虚拟环境
        source "$PROJECT_ROOT/venv/bin/activate"
        
        # 清理之前的构建
        rm -rf build dist
        
        # 构建PyInstaller命令
        local pyinstaller_cmd
        pyinstaller_cmd=$(build_pyinstaller_command)
        
        # 执行构建
        if eval "$pyinstaller_cmd"; then
            # 复制构建产物到dist目录
            cp dist/translate-chat "$DIST_DIR/"
            
            # 验证构建产物
            if validate_build_artifact "$DIST_DIR/translate-chat"; then
                log_success "Linux应用构建成功"
                return 0
            else
                log_error "构建产物验证失败"
                return 1
            fi
        else
            log_error "PyInstaller构建失败"
            return 1
        fi
        
    else
        log_warning "不在Linux平台上，跳过Linux应用构建"
        log_info "如需构建Linux应用，请在Linux x86_64平台上运行"
        return 0
    fi
}

# 构建macOS应用
build_macos_application() {
    local host_platform=$(detect_host_platform)
    
    log_info "开始构建macOS应用..."
    
    # 检查是否在macOS平台上
    if [[ "$host_platform" =~ ^macos- ]]; then
        log_info "在macOS平台上直接构建..."
        
        # 检查Python环境
        local python_cmd
        python_cmd=$(check_python_environment)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        # 创建构建目录
        create_build_directories
        
        # 设置Python环境
        if [[ "$SKIP_DEPS" != true ]]; then
            setup_python_environment "$python_cmd"
        fi
        
        # 激活虚拟环境
        source "$PROJECT_ROOT/venv/bin/activate"
        
        # 清理之前的构建
        rm -rf build dist
        
        # 构建PyInstaller命令
        local pyinstaller_cmd
        pyinstaller_cmd=$(build_pyinstaller_command)
        
        # 执行构建
        if eval "$pyinstaller_cmd"; then
            # 复制构建产物到dist目录
            cp dist/translate-chat "$DIST_DIR/"
            
            # 验证构建产物
            if validate_build_artifact "$DIST_DIR/translate-chat"; then
                log_success "macOS应用构建成功"
                return 0
            else
                log_error "构建产物验证失败"
                return 1
            fi
        else
            log_error "PyInstaller构建失败"
            return 1
        fi
        
    else
        log_warning "不在macOS平台上，跳过macOS应用构建"
        log_info "如需构建macOS应用，请在macOS平台上运行"
        return 0
    fi
}

# 创建Linux包
create_linux_packages() {
    if [[ "$SKIP_PACKAGE" == true ]]; then
        log_info "跳过Linux包创建"
        return 0
    fi
    
    local host_platform=$(detect_host_platform)
    if [[ "$host_platform" != "linux-x86_64" ]]; then
        log_info "不在Linux平台上，跳过Linux包创建"
        return 0
    fi
    
    log_info "创建Linux包..."
    
    # 检查可执行文件是否存在
    if [[ ! -f "$DIST_DIR/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/translate-chat"
        return 1
    fi
    
    # 创建AppImage
    create_appimage_package
    
    # 创建deb包
    create_deb_package
    
    return 0
}

# 创建AppImage包
create_appimage_package() {
    local appimage_name="Translate-Chat-x86_64.AppImage"
    
    log_info "创建AppImage: $appimage_name"
    
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
    local deb_name="translate-chat_1.0.0_x86_64.deb"
    
    log_info "创建deb包: $deb_name"
    
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

# 创建macOS包
create_macos_packages() {
    if [[ "$SKIP_PACKAGE" == true ]]; then
        log_info "跳过macOS包创建"
        return 0
    fi
    
    local host_platform=$(detect_host_platform)
    if [[ ! "$host_platform" =~ ^macos- ]]; then
        log_info "不在macOS平台上，跳过macOS包创建"
        return 0
    fi
    
    log_info "创建macOS包..."
    
    # 检查可执行文件是否存在
    if [[ ! -f "$DIST_DIR/translate-chat" ]]; then
        log_error "可执行文件不存在: $DIST_DIR/translate-chat"
        return 1
    fi
    
    # 创建macOS应用包
    create_macos_app_package
    
    return 0
}

# 创建macOS应用包
create_macos_app_package() {
    local app_name="Translate-Chat.app"
    local app_path="$DIST_DIR/$app_name"
    
    log_info "创建macOS应用包..."
    
    # 创建应用包结构
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"
    
    # 复制可执行文件
    cp "$DIST_DIR/translate-chat" "$app_path/Contents/MacOS/"
    
    # 创建Info.plist
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
            --no-package)
                SKIP_PACKAGE=true
                shift
                ;;
            linux|macos|all)
                TARGET_PLATFORM="$1"
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
    echo "==== 优化的统一跨平台打包系统 v2.0.0 ===="
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
    
    # 检查网络连接（不退出脚本）
    check_network_connection || true
    
    # 仅测试环境
    if [[ "$TEST_ONLY" == true ]]; then
        log_success "环境检查通过，可以进行构建"
        exit 0
    fi
    
    # 确定目标平台
    if [[ -z "$TARGET_PLATFORM" ]]; then
        # 根据主机平台自动选择目标
        if [[ "$host_platform" =~ ^macos- ]]; then
            TARGET_PLATFORM="macos"
        elif [[ "$host_platform" == "linux-x86_64" ]]; then
            TARGET_PLATFORM="linux"
        else
            log_error "无法确定目标平台，请手动指定 (linux|macos|all)"
            show_help
            exit 1
        fi
    fi
    
    log_info "目标平台: $TARGET_PLATFORM"
    
    # 构建应用
    case "$TARGET_PLATFORM" in
        "linux")
            if ! build_linux_application; then
                exit 1
            fi
            if ! create_linux_packages; then
                log_warning "Linux包创建失败，但应用构建成功"
            fi
            ;;
        "macos")
            if ! build_macos_application; then
                exit 1
            fi
            if ! create_macos_packages; then
                log_warning "macOS包创建失败，但应用构建成功"
            fi
            ;;
        "all")
            if ! build_linux_application; then
                log_warning "Linux应用构建失败"
            fi
            if ! build_macos_application; then
                log_warning "macOS应用构建失败"
            fi
            if ! create_linux_packages; then
                log_warning "Linux包创建失败"
            fi
            if ! create_macos_packages; then
                log_warning "macOS包创建失败"
            fi
            ;;
        *)
            log_error "不支持的目标平台: $TARGET_PLATFORM"
            exit 1
            ;;
    esac
    
    # 显示构建结果
    show_build_results
    
    echo ""
    echo "==== 构建完成 ===="
    echo "结束时间: $(date)"
}

# 运行主函数
main "$@" 