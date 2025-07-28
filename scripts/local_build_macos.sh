#!/bin/bash
# =============================================================
# 文件名(File): local_build_macos.sh
# 版本(Version): v2.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/28
# 简介(Description): macOS本地构建脚本 - 无需Docker，直接构建macOS应用
# =============================================================

set -e

# 导入通用构建工具
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_build_utils.sh"

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
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false





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





# 本地构建应用
build_application_local() {
    local target_arch=$(uname -m)
    local build_dir="$BUILD_DIR/macos"
    local dist_dir="$DIST_DIR/macos"
    
    log_info "开始构建macOS应用 (架构: $target_arch)..."
    
    # 创建构建目录
    mkdir -p "$build_dir" "$dist_dir"
    cd "$build_dir"
    
    # 检查Python环境
    local python_cmd
    python_cmd=$(check_python_environment)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 创建虚拟环境
    log_info "创建Python虚拟环境..."
    $python_cmd -m venv venv
    source venv/bin/activate
    
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
        if [[ -f "dist/translate-chat" ]]; then
            cp "dist/translate-chat" "$dist_dir/"
            
            # 验证构建产物
            if validate_build_artifact "$dist_dir/translate-chat"; then
                log_success "macOS应用构建成功"
                return 0
            else
                log_error "构建产物验证失败"
                return 1
            fi
        else
            log_error "macOS应用构建失败"
            return 1
        fi
    else
        log_error "PyInstaller构建失败"
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