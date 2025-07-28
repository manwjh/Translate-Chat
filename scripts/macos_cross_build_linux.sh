#!/bin/bash
# =============================================================
# 文件名(File): macos_cross_build_linux.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/28
# 简介(Description): macOS本地交叉编译Linux应用 - 不依赖Docker，适用于树莓派
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
macOS本地交叉编译Linux应用 v1.0.0

用法: $0 [选项] [目标架构]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
    --no-deps           跳过依赖安装

目标架构:
    x86_64              构建x86_64 Linux应用
    arm64               构建ARM64 Linux应用（树莓派）
    all                 构建所有架构

示例:
    $0 arm64            # 构建ARM64 Linux应用（树莓派）
    $0 x86_64           # 构建x86_64 Linux应用
    $0 all              # 构建所有架构
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

注意: 此脚本使用本地工具链进行交叉编译，不依赖Docker

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
        *)
            echo "unknown"
            ;;
    esac
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    local host_platform=$(detect_host_platform)
    if [[ "$host_platform" != "macos-arm64" && "$host_platform" != "macos-x86_64" ]]; then
        log_error "此脚本仅适用于macOS系统"
        return 1
    fi
    
    # 检查Homebrew
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew未安装，请先安装Homebrew"
        log_info "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    # 检查Python
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
    
    log_success "系统要求检查通过"
    return 0
}

# 安装构建工具
install_build_tools() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log_info "跳过构建工具安装"
        return 0
    fi
    
    log_info "安装构建工具..."
    
    # 安装基础工具
    brew install cmake pkg-config
    
    log_success "构建工具安装完成"
}

# 创建构建目录
create_build_directories() {
    log_info "创建构建目录..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$CACHE_DIR"
    
    # 创建架构特定目录
    mkdir -p "$BUILD_DIR/x86_64"
    mkdir -p "$BUILD_DIR/arm64"
    mkdir -p "$DIST_DIR/x86_64"
    mkdir -p "$DIST_DIR/arm64"
    
    log_success "构建目录创建完成"
}

# 设置Python虚拟环境
setup_python_environment() {
    local python_cmd=$1
    
    log_info "设置Python虚拟环境..."
    
    # 创建虚拟环境
    if [[ ! -d "$PROJECT_ROOT/venv" ]]; then
        $python_cmd -m venv "$PROJECT_ROOT/venv"
    fi
    
    # 激活虚拟环境
    source "$PROJECT_ROOT/venv/bin/activate"
    
    # 升级pip
    pip install --upgrade pip setuptools wheel
    
    # 配置pip使用国内镜像源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
    
    # 安装依赖
    pip install -r requirements-desktop.txt
    
    # 安装PyInstaller
    pip install pyinstaller
    
    # 移除与PyInstaller不兼容的typing包
    pip uninstall -y typing || true
    
    log_success "Python环境设置完成"
}

# 构建PyInstaller命令
build_pyinstaller_command() {
    local target_arch=$1
    
    local cmd="pyinstaller"
    cmd="$cmd --onefile"
    cmd="$cmd --windowed"
    cmd="$cmd --name=\"translate-chat\""
    
    # 只在目录存在时添加数据文件
    if [[ -d "assets" ]]; then
        cmd="$cmd --add-data=\"assets:assets\""
    fi
    if [[ -d "ui" ]]; then
        cmd="$cmd --add-data=\"ui:ui\""
    fi
    if [[ -d "utils" ]]; then
        cmd="$cmd --add-data=\"utils:utils\""
    fi
    
    cmd="$cmd --hidden-import=kivy"
    cmd="$cmd --hidden-import=kivymd"
    cmd="$cmd --hidden-import=websocket"
    cmd="$cmd --hidden-import=aiohttp"
    cmd="$cmd --hidden-import=cryptography"
    cmd="$cmd --hidden-import=pyaudio"
    cmd="$cmd --hidden-import=asr_client"
    cmd="$cmd --hidden-import=translator"
    cmd="$cmd --hidden-import=config_manager"
    cmd="$cmd --hidden-import=lang_detect"
    cmd="$cmd --hidden-import=hotwords"
    cmd="$cmd --hidden-import=audio_capture"
    cmd="$cmd --hidden-import=audio_capture_pyaudio"
    
    # 添加架构特定的配置
    if [[ "$target_arch" == "arm64" ]]; then
        cmd="$cmd --distpath=dist/arm64"
        cmd="$cmd --workpath=build/arm64"
    else
        cmd="$cmd --distpath=dist/x86_64"
        cmd="$cmd --workpath=build/x86_64"
    fi
    
    cmd="$cmd main.py"
    
    echo "$cmd"
}

# 创建Python包
create_python_package() {
    local target_arch=$1
    
    log_info "创建Python包 for $target_arch..."
    
    # 创建包目录
    local package_dir="$DIST_DIR/python_package_$target_arch"
    mkdir -p "$package_dir"
    
    # 复制源代码
    cp -r main.py "$package_dir/"
    cp -r assets "$package_dir/"
    cp -r ui "$package_dir/"
    cp -r utils "$package_dir/"
    cp -r translator.py "$package_dir/"
    cp -r config_manager.py "$package_dir/"
    cp -r lang_detect.py "$package_dir/"
    cp -r hotwords.py "$package_dir/"
    cp -r audio_capture.py "$package_dir/"
    cp -r audio_capture_pyaudio.py "$package_dir/"
    cp -r asr_client.py "$package_dir/"
    cp -r hotwords.json "$package_dir/"
    cp requirements-desktop.txt "$package_dir/"
    
    # 创建启动脚本
    cat > "$package_dir/run.sh" << 'EOF'
#!/bin/bash
# Translate Chat 启动脚本

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装Python3"
    exit 1
fi

# 检查虚拟环境
if [[ ! -d "venv" ]]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
echo "安装依赖..."
pip install -r requirements-desktop.txt

# 运行应用
echo "启动Translate Chat..."
python3 main.py
EOF
    
    chmod +x "$package_dir/run.sh"
    
    # 创建安装脚本
    cat > "$package_dir/install.sh" << 'EOF'
#!/bin/bash
# Translate Chat 安装脚本

echo "安装Translate Chat..."

# 安装系统依赖
if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv portaudio19-dev
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    sudo yum install -y python3 python3-pip portaudio-devel
else
    echo "警告: 未知的包管理器，请手动安装Python3和PortAudio"
fi

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装Python依赖
pip install -r requirements-desktop.txt

echo "安装完成！运行 ./run.sh 启动应用"
EOF
    
    chmod +x "$package_dir/install.sh"
    
    # 创建README
    cat > "$package_dir/README.md" << EOF
# Translate Chat - $target_arch 版本

## 安装说明

### 自动安装
\`\`\`bash
./install.sh
\`\`\`

### 手动安装
1. 安装Python3和PortAudio
2. 创建虚拟环境: \`python3 -m venv venv\`
3. 激活虚拟环境: \`source venv/bin/activate\`
4. 安装依赖: \`pip install -r requirements-desktop.txt\`

## 运行应用
\`\`\`bash
./run.sh
\`\`\`

## 系统要求
- Python 3.9-3.11
- PortAudio
- 网络连接（用于语音识别和翻译）

## 故障排除
如果遇到音频问题，请确保安装了PortAudio：
- Ubuntu/Debian: \`sudo apt-get install portaudio19-dev\`
- CentOS/RHEL: \`sudo yum install portaudio-devel\`
EOF
    
    log_success "Python包创建完成: $package_dir"
}

# 构建单个架构
build_architecture() {
    local target_arch=$1
    
    log_info "开始构建 $target_arch 架构..."
    
    # 检查Python环境
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
        log_error "未找到兼容的Python版本"
        return 1
    fi
    
    # 设置Python环境
    setup_python_environment "$python_cmd"
    
    # 激活虚拟环境
    source "$PROJECT_ROOT/venv/bin/activate"
    
    # 清理之前的构建
    rm -rf build dist
    
    # 构建PyInstaller命令
    local pyinstaller_cmd
    pyinstaller_cmd=$(build_pyinstaller_command "$target_arch")
    
    # 执行构建
    log_info "使用PyInstaller构建应用..."
    if eval "$pyinstaller_cmd"; then
        log_success "$target_arch 架构构建成功"
        
        # 复制构建产物到最终目录
        if [[ "$target_arch" == "arm64" ]]; then
            if [[ -f "dist/arm64/translate-chat" ]]; then
                cp "dist/arm64/translate-chat" "$DIST_DIR/arm64/"
                log_success "ARM64可执行文件已复制到: $DIST_DIR/arm64/translate-chat"
            fi
        else
            if [[ -f "dist/x86_64/translate-chat" ]]; then
                cp "dist/x86_64/translate-chat" "$DIST_DIR/x86_64/"
                log_success "x86_64可执行文件已复制到: $DIST_DIR/x86_64/translate-chat"
            fi
        fi
        
        # 创建Python包（用于在目标平台上运行）
        create_python_package "$target_arch"
        
        return 0
    else
        log_error "$target_arch 架构构建失败"
        return 1
    fi
}

# 创建压缩包
create_archive() {
    local target_arch=$1
    local dist_dir="$DIST_DIR/$target_arch"
    local archive_name="translate-chat-$target_arch-$(date +%Y%m%d).tar.gz"
    
    if [[ -f "$dist_dir/translate-chat" ]]; then
        log_info "创建压缩包: $archive_name"
        
        cd "$dist_dir"
        tar -czf "$archive_name" translate-chat
        
        if [[ $? -eq 0 ]]; then
            log_success "压缩包创建成功: $archive_name"
            mv "$archive_name" "$DIST_DIR/"
        else
            log_warning "压缩包创建失败"
        fi
        
        cd "$PROJECT_ROOT"
    fi
}

# 清理构建缓存
clean_build_cache() {
    log_info "清理构建缓存..."
    
    # 清理构建目录
    rm -rf "$BUILD_DIR"
    rm -rf "$CACHE_DIR"
    
    # 清理临时文件
    rm -rf build dist
    
    log_success "构建缓存清理完成"
}

# 显示构建结果
show_build_results() {
    log_info "构建结果:"
    echo ""
    
    for arch in x86_64 arm64; do
        local dist_dir="$DIST_DIR/$arch"
        if [[ -d "$dist_dir" ]]; then
            echo "  $arch 架构:"
            ls -la "$dist_dir" 2>/dev/null | grep -E "translate-chat" || echo "    无构建产物"
        fi
        
        local package_dir="$DIST_DIR/python_package_$arch"
        if [[ -d "$package_dir" ]]; then
            echo "  Python包 ($arch):"
            ls -la "$package_dir" 2>/dev/null | head -10 || echo "    无Python包"
        fi
    done
    
    # 显示压缩包
    echo ""
    echo "  压缩包:"
    ls -la "$DIST_DIR"/*.tar.gz 2>/dev/null || echo "    无压缩包"
    
    echo ""
    log_info "构建产物位置: $DIST_DIR"
    echo ""
    log_info "部署说明:"
    echo "  1. 将 python_package_arm64 目录复制到树莓派"
    echo "  2. 在树莓派上运行: ./install.sh"
    echo "  3. 启动应用: ./run.sh"
}

# 主函数
main() {
    local target_arch=""
    
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
            x86_64|arm64|all)
                target_arch="$1"
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
    echo "==== macOS本地交叉编译Linux应用 v1.0.0 ===="
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
    
    # 检查系统要求
    if ! check_system_requirements; then
        exit 1
    fi
    
    # 仅测试环境
    if [[ "$TEST_ONLY" == true ]]; then
        log_success "环境检查通过，可以进行构建"
        exit 0
    fi
    
    # 安装构建工具
    install_build_tools
    
    # 创建构建目录
    create_build_directories
    
    # 确定目标架构
    if [[ -z "$target_arch" ]]; then
        log_error "请指定目标架构 (x86_64, arm64, all)"
        show_help
        exit 1
    fi
    
    log_info "开始构建架构: $target_arch"
    
    # 构建应用
    case "$target_arch" in
        "x86_64")
            build_architecture "x86_64"
            create_archive "x86_64"
            ;;
        "arm64")
            build_architecture "arm64"
            create_archive "arm64"
            ;;
        "all")
            build_architecture "x86_64"
            create_archive "x86_64"
            build_architecture "arm64"
            create_archive "arm64"
            ;;
        *)
            log_error "不支持的架构: $target_arch"
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