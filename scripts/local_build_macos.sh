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
    --release <版本>    构建完成后自动创建发布版本
    --no-release        跳过发布创建

示例:
    $0                   # 构建macOS应用
    $0 --release v2.0.1  # 构建并创建v2.0.1发布
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

注意: 此脚本仅构建当前macOS架构的应用

EOF
}

# 全局变量
VERBOSE=false
TEST_ONLY=false
CLEAN_BUILD=false
RELEASE_VERSION=""
CREATE_RELEASE=true





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
    if [[ ! -f "$dist_dir/translate-chat/translate-chat" ]]; then
        log_error "可执行文件不存在: $dist_dir/translate-chat/translate-chat"
        return 1
    fi
    
    # 创建应用包结构
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"
    
    # 复制可执行文件
    cp "$dist_dir/translate-chat/translate-chat" "$app_path/Contents/MacOS/"
    
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

# 显示详细的构建产物描述
show_detailed_build_artifacts() {
    echo ""
    log_success "=========================================="
    log_success "📦 构建产物详细描述"
    log_success "=========================================="
    echo ""
    
    local dist_dir="$DIST_DIR/macos"
    local current_arch=$(uname -m)
    
    log_info "🎯 架构: $current_arch"
    echo ""
    
    # 可执行文件
    local exe_file="$dist_dir/translate-chat/translate-chat"
    if [[ -f "$exe_file" ]]; then
        local exe_size=$(du -h "$exe_file" | cut -f1)
        echo "  📄 可执行文件:"
        echo "     路径: $exe_file"
        echo "     大小: $exe_size"
        echo "     用途: 直接运行的macOS可执行文件，包含所有依赖"
        echo "     运行方式: ./translate-chat"
        echo ""
    fi
    
    # macOS应用包
    local app_file="$dist_dir/Translate-Chat.app"
    if [[ -d "$app_file" ]]; then
        local app_size=$(du -sh "$app_file" | cut -f1)
        echo "  🍎 macOS应用包:"
        echo "     路径: $app_file"
        echo "     大小: $app_size"
        echo "     用途: 标准macOS应用包，可在Finder中双击运行"
        echo "     运行方式:"
        echo "       - 双击应用包"
        echo "       - open $app_file"
        echo "       - ./Translate-Chat.app/Contents/MacOS/translate-chat"
        echo ""
    fi
    
    # 应用包内部结构
    if [[ -d "$app_file" ]]; then
        echo "  📁 应用包结构:"
        echo "     Contents/"
        echo "     ├── MacOS/translate-chat (可执行文件)"
        echo "     ├── Resources/ (资源文件)"
        echo "     ├── Frameworks/ (依赖框架)"
        echo "     ├── _CodeSignature/ (代码签名)"
        echo "     └── Info.plist (应用配置)"
        echo ""
    fi
    
    echo ""
    log_info "🚀 使用建议:"
    echo "  • 开发测试: 使用可执行文件 (translate-chat/translate-chat)"
    echo "  • 日常使用: 使用macOS应用包 (Translate-Chat.app)"
    echo "  • 分发安装: 将应用包拖拽到Applications文件夹"
    echo ""
    log_info "🔧 运行要求:"
    echo "  • 目标系统: macOS 10.15+"
    echo "  • 系统架构: $current_arch"
    echo "  • 系统依赖: 无需额外依赖，已包含所有必要库"
    echo "  • 网络连接: 首次运行需要下载模型文件"
    echo ""
    log_info "🔒 安全说明:"
    echo "  • 首次运行可能提示安全警告"
    echo "  • 需要在'系统偏好设置 > 安全性与隐私'中允许运行"
    echo "  • 或使用: sudo xattr -rd com.apple.quarantine $app_file"
    echo ""
}

# 创建发布目录结构
create_release_structure() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    
    log_info "创建发布目录结构: $release_dir"
    
    # 创建目录结构
    mkdir -p "$release_dir"/{macos/{arm64,x86_64},docs,checksums}
    
    log_success "发布目录结构创建完成"
}

# 复制构建产物到发布目录
copy_build_artifacts_to_release() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    local current_arch=$(uname -m)
    
    log_info "复制构建产物到发布目录..."
    
    # 复制macOS文件
    local dist_dir="$DIST_DIR/macos"
    local release_macos_dir="$release_dir/macos/$current_arch"
    
    if [[ -d "$dist_dir" ]]; then
        mkdir -p "$release_macos_dir"
        
        # 复制可执行文件
        if [[ -f "$dist_dir/translate-chat/translate-chat" ]]; then
            cp "$dist_dir/translate-chat/translate-chat" "$release_macos_dir/"
            log_info "复制: macos/$current_arch/translate-chat"
        fi
        
        # 复制应用包
        if [[ -d "$dist_dir/Translate-Chat.app" ]]; then
            cp -r "$dist_dir/Translate-Chat.app" "$release_macos_dir/"
            log_info "复制: macos/$current_arch/Translate-Chat.app"
        fi
    fi
    
    log_success "构建产物复制完成"
}

# 生成发布文档
generate_release_docs() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    local current_arch=$(uname -m)
    
    log_info "生成发布文档..."
    
    # 生成发布说明
    cat > "$release_dir/docs/RELEASE_NOTES.md" << EOF
# Translate-Chat $version Release

## 🎉 新版本发布

这是 Translate-Chat 的 $version 版本，macOS本地构建应用。

## 📦 下载文件

### macOS 版本
- **$current_arch**
  - Translate-Chat.app - macOS应用包
  - translate-chat - 可执行文件

## 🛠️ 安装说明

### macOS 用户
1. 下载对应架构的 Translate-Chat.app
2. 双击运行，或在终端中运行可执行文件

## 🔧 系统要求
- **macOS**: 10.15+ (Catalina)
- **架构**: $current_arch
- **依赖**: 无需额外依赖，已包含所有必要库

## 🏗️ 构建信息
- **构建平台**: macOS ($current_arch)
- **构建工具**: PyInstaller
- **目标平台**: macOS

---
**版本**: $version  
**发布日期**: $(date +%Y年%m月%d日)  
**构建平台**: macOS $current_arch
EOF
    
    log_success "发布文档生成完成"
}

# 生成校验文件
generate_release_checksums() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    
    log_info "生成校验文件..."
    
    cd "$release_dir"
    
    # 生成SHA256校验和
    find . -type f \( -name "translate-chat" -o -name "*.app" \) -exec shasum -a 256 {} \; > checksums/SHA256SUMS
    
    log_success "校验文件生成完成"
}

# 创建发布版本
create_release() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        log_warning "未指定版本号，跳过发布创建"
        return
    fi
    
    log_info "创建发布版本: $version"
    
    # 创建目录结构
    create_release_structure "$version"
    
    # 复制构建产物
    copy_build_artifacts_to_release "$version"
    
    # 生成文档
    generate_release_docs "$version"
    
    # 生成校验文件
    generate_release_checksums "$version"
    
    echo ""
    log_success "=========================================="
    log_success "📦 发布版本 $version 创建完成！"
    log_success "=========================================="
    log_info "📁 发布目录: $PROJECT_ROOT/releases/$version"
    log_info "📦 包含文件:"
    find "$PROJECT_ROOT/releases/$version" -type f | head -10
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
            --release)
                if [[ -n "$2" && "$2" != -* ]]; then
                    RELEASE_VERSION="$2"
                    shift 2
                else
                    log_error "--release 需要指定版本号"
                    exit 1
                fi
                ;;
            --no-release)
                CREATE_RELEASE=false
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
    
    # 显示详细的产出物描述
    show_detailed_build_artifacts
    
    # 创建发布版本
    if [[ "$CREATE_RELEASE" == true ]]; then
        create_release "$RELEASE_VERSION"
    fi
    
    echo ""
    echo "==== 构建完成 ===="
    echo "结束时间: $(date)"
}

# 运行主函数
main "$@" 