#!/bin/bash
# =============================================================
# 文件名(File): local_build_linux_arm64.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/30
# 简介(Description): ARM64 Linux本地构建脚本 - 专为Ubuntu 20.04+设计
# =============================================================

set -e

# 导入通用构建工具
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common_build_utils.sh"

# 显示帮助信息
show_help() {
    cat << EOF
ARM64 Linux本地构建脚本 v1.0.0

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建

示例:
    $0                   # 构建ARM64 Linux应用
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

注意: 此脚本专为ARM64架构设计，目标平台兼容Ubuntu 20.04+

EOF
}

# 全局变量
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false

# 检查ARM64架构
check_arm64_architecture() {
    local current_arch=$(uname -m)
    
    if [[ "$current_arch" != "aarch64" && "$current_arch" != "arm64" ]]; then
        log_error "此脚本仅适用于ARM64架构，当前架构: $current_arch"
        log_info "请使用x86_64版本的构建脚本"
        return 1
    fi
    
    log_success "检测到ARM64架构: $current_arch"
    return 0
}

# 检查Ubuntu 20.04+兼容性
check_ubuntu_compatibility() {
    log_info "检查Ubuntu兼容性..."
    
    # 检查是否为Ubuntu系统
    if [[ -f "/etc/os-release" ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            log_info "检测到Ubuntu系统: $VERSION"
            
            # 检查版本号
            local version_number=$(echo "$VERSION_ID" | cut -d. -f1)
            if [[ "$version_number" -ge 20 ]]; then
                log_success "Ubuntu版本兼容: $VERSION_ID (>= 20.04)"
            else
                log_warning "Ubuntu版本较低: $VERSION_ID (建议20.04+)"
            fi
        else
            log_info "检测到Linux发行版: $ID $VERSION"
        fi
    else
        log_warning "无法检测系统版本信息"
    fi
    
    return 0
}

# 检查系统依赖
check_system_dependencies() {
    log_info "检查系统依赖..."
    
    # 检查包管理器
    if ! command -v apt-get &> /dev/null; then
        log_warning "未检测到apt-get，可能不是Ubuntu/Debian系统"
        log_info "建议在Ubuntu 20.04+环境下运行"
    else
        log_success "检测到apt包管理器"
    fi
    
    # 检查必要的系统工具
    for tool in git curl wget; do
        if ! command -v $tool &> /dev/null; then
            log_error "缺少必要工具: $tool"
            log_info "安装命令: sudo apt-get install $tool"
            return 1
        fi
    done
    
    # 检查编译工具
    if ! command -v gcc &> /dev/null; then
        log_warning "未找到gcc，某些依赖可能需要编译"
        log_info "安装命令: sudo apt-get install build-essential"
    else
        log_success "GCC编译器已安装"
    fi
    
    # 检查PortAudio
    if ! pkg-config --exists portaudio-2.0 2>/dev/null; then
        log_warning "未找到PortAudio开发库，PyAudio可能无法正常工作"
        log_info "安装命令: sudo apt-get install portaudio19-dev"
    else
        log_success "PortAudio开发库已安装"
    fi
    
    log_success "系统依赖检查通过"
    return 0
}

# ARM64本地构建应用
build_arm64_application() {
    local build_dir="$BUILD_DIR/linux_arm64"
    local dist_dir="$DIST_DIR/linux_arm64"
    
    log_info "开始构建ARM64 Linux应用..."
    
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
    
    # 构建PyInstaller命令 - 针对ARM64优化
    local pyinstaller_cmd
    pyinstaller_cmd=$(build_pyinstaller_command)
    
    # 添加ARM64特定优化
    pyinstaller_cmd="$pyinstaller_cmd --target-arch arm64"
    
    # 使用PyInstaller构建
    log_info "使用PyInstaller构建ARM64应用..."
    if eval "$pyinstaller_cmd"; then
        # 复制构建产物
        if [[ -d "dist/translate-chat" ]]; then
            cp -r "dist/translate-chat" "$dist_dir/"
            
            # 验证构建产物
            if validate_build_artifact "$dist_dir/translate-chat/translate-chat"; then
                log_success "ARM64 Linux应用构建成功"
                return 0
            else
                log_error "构建产物验证失败"
                return 1
            fi
        else
            log_error "ARM64 Linux应用构建失败"
            return 1
        fi
    else
        log_error "PyInstaller构建失败"
        return 1
    fi
}

# 创建ARM64独立可执行文件包
create_arm64_standalone_package() {
    local dist_dir="$DIST_DIR/linux_arm64"
    local standalone_dir="$DIST_DIR/standalone_arm64"
    
    log_info "创建ARM64独立可执行文件包..."
    
    # 检查可执行文件是否存在
    if [[ ! -f "$dist_dir/translate-chat/translate-chat" ]]; then
        log_error "可执行文件不存在: $dist_dir/translate-chat/translate-chat"
        return 1
    fi
    
    # 创建独立可执行文件目录
    mkdir -p "$standalone_dir"
    
    # 复制可执行文件
    cp "$dist_dir/translate-chat/translate-chat" "$standalone_dir/"
    chmod +x "$standalone_dir/translate-chat"
    
    # 创建启动脚本
    cat > "$standalone_dir/run.sh" << 'EOF'
#!/bin/bash
# Translate Chat ARM64 独立可执行文件启动脚本

echo "=========================================="
echo "    Translate Chat ARM64 独立可执行文件"
echo "=========================================="
echo ""

# 检查可执行文件
if [[ ! -f "translate-chat" ]]; then
    echo "错误: 未找到可执行文件 translate-chat"
    exit 1
fi

# 检查系统架构
if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm64" ]]; then
    echo "警告: 当前系统不是ARM64架构，可能无法正常运行"
fi

# 检查系统依赖
echo "检查系统依赖..."
if ! command -v python3 &> /dev/null; then
    echo "警告: 未找到Python3，但可执行文件可能仍能运行"
fi

# 检查音频支持
if ! command -v aplay &> /dev/null && ! command -v paplay &> /dev/null; then
    echo "警告: 未检测到音频播放工具"
fi

# 运行应用
echo "启动Translate Chat..."
echo ""

./translate-chat
EOF
    
    chmod +x "$standalone_dir/run.sh"
    
    # 创建安装脚本 - 针对Ubuntu 20.04+
    cat > "$standalone_dir/install.sh" << 'EOF'
#!/bin/bash
# Translate Chat ARM64 独立可执行文件安装脚本

echo "=========================================="
echo "    Translate Chat ARM64 独立可执行文件安装"
echo "=========================================="
echo ""

# 检查是否为root用户
if [[ $EUID -eq 0 ]]; then
   echo "错误: 请不要使用root用户运行此脚本"
   exit 1
fi

# 检查系统架构
if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm64" ]]; then
    echo "错误: 此安装包仅适用于ARM64架构"
    exit 1
fi

# 安装系统依赖
echo "安装系统依赖..."

if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian/Raspberry Pi OS
    echo "使用apt-get安装依赖..."
    sudo apt-get update
    sudo apt-get install -y portaudio19-dev python3-dev build-essential
else
    echo "警告: 未检测到apt-get，请手动安装PortAudio"
    echo "Ubuntu/Debian: sudo apt-get install portaudio19-dev"
fi

# 创建桌面快捷方式
echo "创建桌面快捷方式..."
if [[ -d "$HOME/Desktop" ]]; then
    cat > "$HOME/Desktop/Translate-Chat.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Translate Chat
Comment=AI语音翻译聊天应用 (ARM64)
Exec=bash -c "cd $(pwd) && ./translate-chat"
Icon=applications-internet
Terminal=true
Categories=Network;AudioVideo;
DESKTOP_EOF
    chmod +x "$HOME/Desktop/Translate-Chat.desktop"
    echo "桌面快捷方式已创建"
fi

echo ""
echo "安装完成！"
echo "使用方法:"
echo "  直接运行: ./translate-chat"
echo "  或使用脚本: ./run.sh"
echo ""
echo "桌面快捷方式已创建，可以直接双击启动"
EOF
    
    chmod +x "$standalone_dir/install.sh"
    
    # 创建README
    cat > "$standalone_dir/README.md" << EOF
# Translate Chat - ARM64 独立可执行文件

## 快速开始

### 直接运行
\`\`\`bash
./translate-chat
\`\`\`

### 使用启动脚本
\`\`\`bash
./run.sh
\`\`\`

### 安装（可选）
\`\`\`bash
./install.sh
\`\`\`

## 系统要求
- **架构**: ARM64 (aarch64/arm64)
- **操作系统**: Ubuntu 20.04+, Debian 11+, Raspberry Pi OS
- **依赖**: PortAudio（用于音频处理）
- **网络连接**: 用于语音识别和翻译

## 特性
- ✅ 专为ARM64架构优化
- ✅ 独立可执行文件，无需Python环境
- ✅ 包含所有依赖，开箱即用
- ✅ 自动检测和安装系统依赖
- ✅ 桌面快捷方式支持
- ✅ Ubuntu 20.04+兼容

## 故障排除

### 权限问题
如果遇到权限问题，请确保文件有执行权限：
\`\`\`bash
chmod +x translate-chat run.sh install.sh
\`\`\`

### 音频问题
如果遇到音频问题，请安装PortAudio：
\`\`\`bash
sudo apt-get install portaudio19-dev  # Ubuntu/Debian
\`\`\`

### 架构问题
此版本仅适用于ARM64架构，请确认您的系统架构：
\`\`\`bash
uname -m
\`\`\`

### 网络问题
应用需要网络连接用于语音识别和翻译，请确保网络正常。

## 文件说明
- \`translate-chat\`: 主可执行文件
- \`run.sh\`: 启动脚本（包含依赖检查）
- \`install.sh\`: 安装脚本（安装系统依赖）
- \`README.md\`: 使用说明

## 技术支持
如遇到问题，请查看错误信息或联系技术支持。
EOF
    
    log_success "ARM64独立可执行文件包创建完成: $standalone_dir"
    
    # 显示包大小
    local package_size=$(du -sh "$standalone_dir" | cut -f1)
    log_info "ARM64独立可执行文件包大小: $package_size"
}

# 显示ARM64构建结果
show_arm64_build_results() {
    echo ""
    log_success "=========================================="
    log_success "📦 ARM64构建产物"
    log_success "=========================================="
    echo ""
    
    local dist_dir="$DIST_DIR/linux_arm64"
    local standalone_dir="$DIST_DIR/standalone_arm64"
    
    log_info "🎯 目标架构: ARM64 (aarch64)"
    log_info "🎯 目标平台: Ubuntu 20.04+"
    echo ""
    
    # 可执行文件
    local exe_file="$dist_dir/translate-chat/translate-chat"
    if [[ -f "$exe_file" ]]; then
        local exe_size=$(du -h "$exe_file" | cut -f1)
        echo "  📄 ARM64可执行文件:"
        echo "     路径: $exe_file"
        echo "     大小: $exe_size"
        echo "     用途: 专为ARM64优化的Linux可执行文件"
        echo "     运行方式: ./translate-chat"
        echo ""
    fi
    
    # 独立可执行文件包
    if [[ -d "$standalone_dir" ]]; then
        local standalone_size=$(du -sh "$standalone_dir" | cut -f1)
        echo "  📁 ARM64独立可执行文件包:"
        echo "     路径: $standalone_dir/"
        echo "     大小: $standalone_size"
        echo "     用途: 包含可执行文件、启动脚本和安装脚本的完整包"
        echo "     内容:"
        echo "       - translate-chat (ARM64可执行文件)"
        echo "       - run.sh (启动脚本)"
        echo "       - install.sh (安装脚本)"
        echo "       - README.md (使用说明)"
        echo "     使用方式: 解压后运行 ./run.sh 或 ./install.sh"
        echo ""
    fi
    
    echo ""
    log_info "🚀 使用建议:"
    echo "  • 开发测试: 使用可执行文件 (linux_arm64/translate-chat/translate-chat)"
    echo "  • 完整分发: 使用独立可执行文件包 (standalone_arm64/)"
    echo ""
    log_info "🔧 运行要求:"
    echo "  • 目标系统: Ubuntu 20.04+, Debian 11+, Raspberry Pi OS"
    echo "  • 目标架构: ARM64 (aarch64/arm64)"
    echo "  • 系统依赖: PortAudio (可选，已包含在可执行文件中)"
    echo "  • 网络连接: 首次运行需要下载模型文件"
    echo ""
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
    echo ""
    log_success "=========================================="
    log_success "ARM64 Linux本地构建脚本 v1.0.0"
    log_success "=========================================="
    echo ""
    log_info "📅 开始时间: $(date)"
    log_info "🏠 主机平台: $(detect_host_platform)"
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
    
    # 检查ARM64架构
    if ! check_arm64_architecture; then
        exit 1
    fi
    
    # 检查Ubuntu兼容性
    check_ubuntu_compatibility
    
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
        log_success "环境检查通过，可以进行ARM64构建"
        exit 0
    fi
    
    # 创建构建目录
    create_build_directories
    
    # 构建ARM64应用
    if ! build_arm64_application; then
        exit 1
    fi
    
    # 创建ARM64独立可执行文件包
    create_arm64_standalone_package
    
    # 显示ARM64构建结果
    show_arm64_build_results
    
    echo ""
    log_success "=========================================="
    log_success "ARM64构建完成！"
    log_success "=========================================="
    log_info "📅 结束时间: $(date)"
    echo ""
}

# 运行主函数
main "$@" 