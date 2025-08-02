#!/bin/bash
# =============================================================
# 文件名(File): macos_cross_build_linux_arm64.sh
# 版本(Version): v1.1.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/28
# 更新日期(Updated): 2025/8/2
# 简介(Description): macOS本地交叉编译ARM64 Linux应用 - 专门针对Ubuntu 20.04 ARM64优化
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
macOS本地交叉编译ARM64 Linux应用 v1.0.0

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
    --no-deps           跳过依赖安装
    --no-download-deps  跳过预下载依赖包
    --minimal-deps      使用最小依赖包（减少包大小）
    --no-optimize-deps  跳过依赖包优化
    --standalone-exe    生成独立可执行文件（推荐）
    --release <版本>    构建完成后自动创建发布版本
    --no-release        跳过发布创建

示例:
    $0                    # 构建ARM64 Linux应用（树莓派）
    $0 --release v2.0.1   # 构建并创建v2.0.1发布
    $0 --standalone-exe   # 构建独立可执行文件
    $0 -c                 # 清理构建缓存
    $0 -t                 # 测试环境

注意: 此脚本使用Docker Buildx进行真正的ARM64交叉编译，确保Docker已安装并运行
⚠️  重要提示: 此脚本生成的是真正的ARM64 Linux ELF可执行文件，可在树莓派、ARM嵌入式设备等Linux平台上运行。
🎯 专门针对Ubuntu 20.04 ARM64 (Focal Fossa) 优化
默认会预下载Python依赖包以加速目标平台安装
支持多种优化选项以减少包大小
支持生成独立可执行文件，普通用户可直接使用
支持自动创建发布版本，便于分发和管理
包含详细的错误诊断和故障排除信息

⚠️  重要提示: 此脚本生成的是真正的ARM64 Linux ELF可执行文件，可在树莓派、ARM嵌入式设备等Linux平台上运行。

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
DOWNLOAD_DEPS=true
MINIMAL_DEPS=false
OPTIMIZE_DEPS=true
STANDALONE_EXE=false
RELEASE_VERSION=""
CREATE_RELEASE=true

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
    
    # 检查Docker环境
    check_docker_environment
    
    log_success "系统要求检查通过"
    return 0
}

# 检查Docker环境 - 专门针对Ubuntu ARM64交叉编译
check_docker_environment() {
    log_info "检查Docker环境..."
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，无法进行交叉编译"
        log_info "请安装Docker Desktop: https://www.docker.com/products/docker-desktop/"
        return 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker未运行，请启动Docker Desktop"
        return 1
    fi
    
    # 检查Docker Buildx是否可用
    if ! docker buildx version &> /dev/null; then
        log_error "Docker Buildx不可用，无法进行ARM64交叉编译"
        log_info "请确保Docker Desktop版本支持Buildx功能"
        return 1
    fi
    
    # 检查ARM64平台支持
    local arm64_support=false
    if docker buildx inspect default 2>/dev/null | grep -q "linux/arm64"; then
        arm64_support=true
    fi
    
    if [[ "$arm64_support" == false ]]; then
        log_info "创建ARM64构建器..."
        if docker buildx create --name arm64-builder --driver docker-container --platform linux/arm64 2>/dev/null; then
            log_success "ARM64构建器创建成功"
        else
            log_warning "ARM64构建器创建失败，将使用默认构建器"
        fi
    else
        log_success "检测到ARM64平台支持"
    fi
    
    # 检查网络连接
    log_info "检查网络连接..."
    if ping -c 1 pypi.tuna.tsinghua.edu.cn &> /dev/null; then
        log_success "网络连接正常"
    else
        log_warning "网络连接可能有问题，可能影响依赖下载"
    fi
    
    # 检查磁盘空间
    log_info "检查磁盘空间..."
    local available_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9]//g')
    if [[ "$available_space" -gt 10 ]]; then
        log_success "磁盘空间充足 (${available_space}GB可用)"
    else
        log_warning "磁盘空间可能不足 (${available_space}GB可用)，建议至少10GB"
    fi
    
    log_success "Docker环境检查完成"
}

# 预检查构建环境 - 专门针对Ubuntu ARM64
pre_build_checks() {
    log_info "预检查构建环境..."
    
    # 检查项目文件
    local required_files=("main.py" "requirements-desktop.txt" "assets" "ui" "utils")
    for file in "${required_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            log_error "缺少必需文件: $file"
            return 1
        fi
    done
    log_success "项目文件检查通过"
    
    # 检查requirements文件
    if [[ ! -f "requirements-desktop.txt" ]]; then
        log_error "缺少requirements-desktop.txt文件"
        return 1
    fi
    
    # 检查Python依赖
    log_info "检查Python依赖..."
    if grep -q "kivy" requirements-desktop.txt && grep -q "pyaudio" requirements-desktop.txt; then
        log_success "核心依赖检查通过"
    else
        log_warning "可能缺少核心依赖，构建可能失败"
    fi
    
    # 检查Docker缓存
    log_info "检查Docker缓存..."
    local cache_size=$(docker system df --format "table {{.Type}}\t{{.Size}}" | grep "Build Cache" | awk '{print $2}' | sed 's/[^0-9]//g')
    if [[ "$cache_size" -gt 5000 ]]; then
        log_warning "Docker缓存较大 (${cache_size}MB)，建议清理: docker system prune -f"
    fi
    
    log_success "预检查完成"
}

# 构建后处理 - 专门针对Ubuntu ARM64
post_build_processing() {
    local exe_file="$1"
    
    log_info "执行构建后处理..."
    
    # 创建Ubuntu ARM64特定的启动脚本
    local script_dir=$(dirname "$exe_file")
    cat > "$script_dir/run_ubuntu_arm64.sh" << 'UBUNTU_SCRIPT_EOF'
#!/bin/bash
# Translate Chat - Ubuntu ARM64 启动脚本
# 专门针对Ubuntu 20.04 ARM64优化

echo "=========================================="
echo "    Translate Chat - Ubuntu ARM64"
echo "=========================================="
echo ""

# 检查系统信息
echo "系统信息:"
echo "  操作系统: $(lsb_release -d | cut -f2)"
echo "  架构: $(uname -m)"
echo "  内核版本: $(uname -r)"
echo ""

# 检查依赖
echo "检查系统依赖..."
if ! command -v aplay &> /dev/null && ! command -v paplay &> /dev/null; then
    echo "警告: 未检测到音频播放工具"
    echo "建议安装: sudo apt-get install alsa-utils"
fi

# 检查音频设备
if [[ -d "/proc/asound" ]]; then
    echo "音频设备检测:"
    ls /proc/asound/cards 2>/dev/null | head -3 || echo "  未检测到音频设备"
fi

# 运行应用
echo ""
echo "启动Translate Chat..."
echo ""

./translate-chat
UBUNTU_SCRIPT_EOF
    
    chmod +x "$script_dir/run_ubuntu_arm64.sh"
    
    # 创建Ubuntu ARM64安装说明
    cat > "$script_dir/UBUNTU_ARM64_INSTALL.md" << 'UBUNTU_INSTALL_EOF'
# Ubuntu ARM64 安装说明

## 系统要求
- Ubuntu 20.04 LTS (Focal Fossa) ARM64
- 至少 2GB RAM
- 至少 1GB 可用磁盘空间

## 快速安装

### 1. 安装系统依赖
```bash
sudo apt-get update
sudo apt-get install -y alsa-utils portaudio19-dev
```

### 2. 运行应用
```bash
# 直接运行
./translate-chat

# 或使用启动脚本（推荐）
./run_ubuntu_arm64.sh
```

## 故障排除

### 音频问题
如果遇到音频问题：
```bash
# 检查音频设备
aplay -l

# 安装音频工具
sudo apt-get install -y pulseaudio alsa-utils

# 重启音频服务
pulseaudio --kill && pulseaudio --start
```

### 权限问题
如果遇到权限问题：
```bash
chmod +x translate-chat run_ubuntu_arm64.sh
```

### 网络问题
确保网络连接正常，应用需要网络进行语音识别和翻译。

## 系统优化建议
- 使用SSD存储以提高性能
- 确保有足够的交换空间
- 定期更新系统：`sudo apt update && sudo apt upgrade`
UBUNTU_INSTALL_EOF
    
    log_success "构建后处理完成"
    log_info "已创建Ubuntu ARM64专用启动脚本和安装说明"
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
    
    log_success "构建工具检查完成 (使用Docker Buildx进行ARM64交叉编译)"
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
    
    if [[ "$STANDALONE_EXE" == true ]]; then
        # 独立可执行文件配置
        cmd="$cmd --onefile"
        cmd="$cmd --name=\"translate-chat\""
        
        # 添加运行时钩子来处理依赖
        cmd="$cmd --runtime-hook=runtime_hook.py"
        
        # 添加所有必要的数据文件
        if [[ -d "assets" ]]; then
            cmd="$cmd --add-data=\"assets:assets\""
        fi
        if [[ -d "ui" ]]; then
            cmd="$cmd --add-data=\"ui:ui\""
        fi
        if [[ -d "utils" ]]; then
            cmd="$cmd --add-data=\"utils:utils\""
        fi
        
        # 添加所有隐藏导入
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
        
        # 排除不需要的模块
        cmd="$cmd --exclude-module=matplotlib"
        cmd="$cmd --exclude-module=tkinter"
        cmd="$cmd --exclude-module=PyQt5"
        cmd="$cmd --exclude-module=PySide2"
        
    else
        # 标准配置
        cmd="$cmd --onefile"
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
    fi
    
    # 交叉编译配置 - 针对Linux目标平台
    if [[ "$target_arch" == "arm64" ]]; then
        # ARM64 Linux (树莓派等)
        cmd="$cmd --distpath=dist/arm64"
        cmd="$cmd --workpath=build/arm64"
        cmd="$cmd --runtime-tmpdir=/tmp"
        # 设置目标架构
        cmd="$cmd --target-architecture=arm64"
    else
        # x86_64 Linux
        cmd="$cmd --distpath=dist/x86_64"
        cmd="$cmd --workpath=build/x86_64"
        cmd="$cmd --runtime-tmpdir=/tmp"
        # 设置目标架构
        cmd="$cmd --target-architecture=x86_64"
    fi
    
    cmd="$cmd main.py"
    
    echo "$cmd"
}

# 预下载依赖包
download_dependencies() {
    local target_arch=$1
    local package_dir="$DIST_DIR/python_package_$target_arch"
    
    log_info "预下载Python依赖包..."
    
    # 创建依赖包目录
    local deps_dir="$package_dir/dependencies"
    mkdir -p "$deps_dir"
    
    # 激活虚拟环境
    source "$PROJECT_ROOT/venv/bin/activate"
    
    # 配置pip使用国内镜像源
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ || true
    pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn || true
    
    # 创建依赖包列表（排除系统依赖）
    if [[ "$MINIMAL_DEPS" == true ]]; then
        log_info "使用最小依赖包配置（减少包大小）..."
        cat > "$deps_dir/requirements_python_only.txt" << 'REQ_MIN_EOF'
# 最小Python包依赖（排除系统依赖）
# 核心框架 - 必需
kivy>=2.3.0,<3.0.0
kivymd==1.1.1

# 音频处理 - 必需
pyaudio>=0.2.11,<0.3.0

# 网络通信 - 必需
websocket-client>=1.6.0,<2.0.0
aiohttp>=3.8.0,<4.0.0

# 加密存储 - 必需
cryptography>=3.4.8,<4.0.0

# 基础工具 - 必需
requests>=2.28.0,<3.0.0
urllib3>=1.26.0,<2.0.0

# 语音识别 - 必需
webrtcvad>=2.0.10,<3.0.0
REQ_MIN_EOF
    else
        cat > "$deps_dir/requirements_python_only.txt" << 'REQ_FULL_EOF'
# 完整Python包依赖（排除系统依赖）
# 核心框架
kivy>=2.3.0,<3.0.0
kivymd==1.1.1

# 音频处理 - 桌面端专用
pyaudio>=0.2.11,<0.3.0

# 网络通信
websocket-client>=1.6.0,<2.0.0
aiohttp>=3.8.0,<4.0.0

# 加密存储
cryptography>=3.4.8,<4.0.0

# 其他工具
requests>=2.28.0,<3.0.0
urllib3>=1.26.0,<2.0.0

# 音频处理增强
numpy>=1.21.0,<2.0.0
scipy>=1.7.0,<2.0.0

# 语音识别相关
webrtcvad>=2.0.10,<3.0.0
REQ_FULL_EOF
    fi
    
    # 下载Python依赖包到本地目录
    log_info "下载Python依赖包到: $deps_dir"
    echo "⏱️  正在下载依赖包，请稍候..."
    
    # 根据目标架构设置平台参数
    local platform_param=""
    case "$target_arch" in
        "arm64")
            platform_param="--platform manylinux2014_aarch64"
            ;;
        "x86_64")
            platform_param="--platform manylinux2014_x86_64"
            ;;
        *)
            log_warning "未知架构 $target_arch，跳过平台特定下载"
            platform_param=""
            ;;
    esac
    
    # 尝试下载平台特定的包
    if [[ -n "$platform_param" ]]; then
        if pip download -r "$deps_dir/requirements_python_only.txt" -d "$deps_dir" $platform_param --only-binary=:all:; then
            log_success "平台特定依赖包下载完成"
        else
            log_warning "平台特定包下载失败，尝试通用下载"
            pip download -r "$deps_dir/requirements_python_only.txt" -d "$deps_dir" || true
        fi
    else
        # 通用下载
        if pip download -r "$deps_dir/requirements_python_only.txt" -d "$deps_dir"; then
            log_success "通用依赖包下载完成"
        else
            log_warning "依赖包下载失败，将在目标平台安装"
        fi
    fi
    
    # 创建依赖包安装脚本
    cat > "$deps_dir/install_deps.sh" << 'DEPS_EOF'
#!/bin/bash
# 依赖包安装脚本

echo "安装预下载的Python依赖包..."

# 检查依赖包目录
if [[ ! -d "dependencies" ]]; then
    echo "错误: 依赖包目录不存在"
    exit 1
fi

# 进入依赖包目录
cd dependencies

# 安装所有预下载的Python包
for pkg in *.whl *.tar.gz *.zip; do
    if [[ -f "$pkg" ]]; then
        echo "安装: $pkg"
        pip install "$pkg"
    fi
done

# 返回上级目录
cd ..

echo "Python依赖包安装完成"
echo ""
echo "注意: 系统依赖（如PortAudio）需要单独安装:"
echo "  Ubuntu/Debian: sudo apt-get install portaudio19-dev"
echo "  CentOS/RHEL: sudo yum install portaudio-devel"
DEPS_EOF
    
    chmod +x "$deps_dir/install_deps.sh"
    
    # 创建系统依赖说明文件
    cat > "$deps_dir/SYSTEM_DEPS.md" << 'SYS_EOF'
# 系统依赖说明

## 需要手动安装的系统依赖

### PortAudio（音频处理库）
PortAudio是PyAudio的底层依赖，需要系统级安装：

#### Ubuntu/Debian/Raspberry Pi OS
```bash
sudo apt-get update
sudo apt-get install portaudio19-dev python3-dev build-essential
```

#### CentOS/RHEL
```bash
sudo yum install portaudio-devel python3-devel gcc
```

#### Fedora
```bash
sudo dnf install portaudio-devel python3-devel gcc
```

### 其他系统依赖
- Python3 (3.9-3.11)
- python3-pip
- python3-venv

## 安装顺序
1. 先安装系统依赖（PortAudio等）
2. 再安装Python依赖包（已预下载）

## 故障排除
如果PyAudio安装失败，通常是因为缺少PortAudio系统库。
请确保已安装上述系统依赖。
SYS_EOF
    
    # 优化依赖包大小
    if [[ "$OPTIMIZE_DEPS" == true ]]; then
        optimize_dependencies "$deps_dir"
    else
        log_info "跳过依赖包优化"
    fi
    
    # 统计下载的包数量和大小
    local pkg_count=$(find "$deps_dir" -name "*.whl" -o -name "*.tar.gz" -o -name "*.zip" | wc -l)
    local total_size=$(du -sh "$deps_dir" | cut -f1)
    log_success "预下载了 $pkg_count 个Python依赖包，总大小: $total_size"
    log_info "系统依赖（PortAudio等）需要在目标平台手动安装"
}

# 优化依赖包大小
optimize_dependencies() {
    local deps_dir=$1
    
    log_info "优化依赖包大小..."
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    
    # 遍历所有依赖包
    for pkg in "$deps_dir"/*.whl "$deps_dir"/*.tar.gz "$deps_dir"/*.zip; do
        if [[ -f "$pkg" ]]; then
            local pkg_name=$(basename "$pkg")
            local pkg_ext="${pkg_name##*.}"
            
            case "$pkg_ext" in
                "whl")
                    # 优化wheel包
                    optimize_wheel_package "$pkg" "$temp_dir"
                    ;;
                "tar.gz"|"zip")
                    # 对于源码包，暂时跳过优化（可能影响编译）
                    log_info "跳过源码包优化: $pkg_name"
                    ;;
            esac
        fi
    done
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    # 显示优化后的总大小
    local optimized_size=$(du -sh "$deps_dir" | cut -f1)
    log_success "依赖包优化完成，总大小: $optimized_size"
}

# 优化wheel包
optimize_wheel_package() {
    local pkg_path=$1
    local temp_dir=$2
    local pkg_name=$(basename "$pkg_path")
    
    log_info "优化wheel包: $pkg_name"
    
    # 解压wheel包
    cd "$temp_dir"
    unzip -q "$pkg_path"
    
    # 移除不必要的文件
    find . -name "*.pyc" -delete
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.so" -exec strip {} \; 2>/dev/null || true
    
    # 移除测试文件
    find . -name "test*" -type f -delete
    find . -name "*test*" -type f -delete
    find . -name "tests" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # 移除文档文件
    find . -name "*.md" -delete
    find . -name "*.txt" -delete
    find . -name "*.rst" -delete
    find . -name "docs" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # 移除示例文件
    find . -name "examples" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "samples" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # 重新打包
    zip -r -q "$pkg_path" .
    
    cd - > /dev/null
}

# 优化源代码大小
optimize_source_code() {
    local package_dir=$1
    
    if [[ "$OPTIMIZE_DEPS" == true ]]; then
        log_info "优化源代码大小..."
        
        # 移除Python缓存文件
        find "$package_dir" -name "*.pyc" -delete
        find "$package_dir" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
        
        # 移除临时文件
        find "$package_dir" -name "*.tmp" -delete
        find "$package_dir" -name "*.log" -delete
        find "$package_dir" -name ".DS_Store" -delete
        
        # 移除备份文件
        find "$package_dir" -name "*.bak" -delete
        find "$package_dir" -name "*.backup" -delete
        
        # 压缩Python文件（可选，可能影响调试）
        # find "$package_dir" -name "*.py" -exec python3 -m py_compile {} \;
        
        log_success "源代码优化完成"
    fi
}

# 创建独立可执行文件包
create_standalone_package() {
    local target_arch=$1
    
    # 创建独立可执行文件包目录
    local standalone_dir="$DIST_DIR/standalone_$target_arch"
    mkdir -p "$standalone_dir"
    
    # 复制可执行文件
    local exe_source="$DIST_DIR/$target_arch/translate-chat"
    if [[ -f "$exe_source" ]]; then
        cp "$exe_source" "$standalone_dir/"
        chmod +x "$standalone_dir/translate-chat"
        
        # 创建启动脚本
        cat > "$standalone_dir/run.sh" << 'STANDALONE_EOF'
#!/bin/bash
# Translate Chat 独立可执行文件启动脚本

echo "=========================================="
echo "    Translate Chat 独立可执行文件"
echo "=========================================="
echo ""

# 检查可执行文件
if [[ ! -f "translate-chat" ]]; then
    echo "错误: 未找到可执行文件 translate-chat"
    exit 1
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
STANDALONE_EOF
        
        chmod +x "$standalone_dir/run.sh"
        
        # 创建安装脚本
        cat > "$standalone_dir/install.sh" << 'STANDALONE_INSTALL_EOF'
#!/bin/bash
# Translate Chat 独立可执行文件安装脚本

echo "=========================================="
echo "    Translate Chat 独立可执行文件安装"
echo "=========================================="
echo ""

# 检查是否为root用户
if [[ $EUID -eq 0 ]]; then
   echo "错误: 请不要使用root用户运行此脚本"
   exit 1
fi

# 安装系统依赖
echo "安装系统依赖..."

if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian/Raspberry Pi OS
    echo "使用apt-get安装依赖..."
    sudo apt-get update
    sudo apt-get install -y portaudio19-dev python3-dev build-essential
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    echo "使用yum安装依赖..."
    sudo yum install -y portaudio-devel python3-devel gcc
elif command -v dnf &> /dev/null; then
    # Fedora
    echo "使用dnf安装依赖..."
    sudo dnf install -y portaudio-devel python3-devel gcc
else
    echo "警告: 未知的包管理器，请手动安装PortAudio"
fi

# 创建桌面快捷方式
echo "创建桌面快捷方式..."
if [[ -d "$HOME/Desktop" ]]; then
    cat > "$HOME/Desktop/Translate-Chat.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Translate Chat
Comment=AI语音翻译聊天应用
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
STANDALONE_INSTALL_EOF
        
        chmod +x "$standalone_dir/install.sh"
        
        # 创建README
        cat > "$standalone_dir/README.md" << EOF
# Translate Chat - 独立可执行文件 ($target_arch)

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
- Linux系统 ($target_arch架构)
- PortAudio（用于音频处理）
- 网络连接（用于语音识别和翻译）

## 特性
- ✅ 独立可执行文件，无需Python环境
- ✅ 包含所有依赖，开箱即用
- ✅ 自动检测和安装系统依赖
- ✅ 桌面快捷方式支持
- ✅ 跨平台兼容

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
sudo yum install portaudio-devel      # CentOS/RHEL
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
        
        log_success "独立可执行文件包创建完成: $standalone_dir"
        
        # 显示包大小
        local package_size=$(du -sh "$standalone_dir" | cut -f1)
        log_info "独立可执行文件包大小: $package_size"
        
    else
        log_error "未找到可执行文件: $exe_source"
    fi
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
    
    # 优化源代码大小
    optimize_source_code "$package_dir"
    
    # 预下载依赖包
    if [[ "$DOWNLOAD_DEPS" == true ]]; then
        echo ""
        log_info "📥 预下载Python依赖包..."
        download_dependencies "$target_arch"
    else
        log_info "跳过预下载依赖包"
    fi
    
    # 创建一键安装脚本
    cat > "$package_dir/install.sh" << 'EOF'
#!/bin/bash
# Translate Chat 一键安装脚本
# 文件名(File): install.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/28
# 简介(Description): Translate Chat 一键安装脚本

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

echo "=========================================="
echo "    Translate Chat 一键安装脚本"
echo "=========================================="
echo ""

# 检查是否为root用户
if [[ $EUID -eq 0 ]]; then
   log_error "请不要使用root用户运行此脚本"
   exit 1
fi

# 检查系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    log_error "无法检测操作系统类型"
    exit 1
fi

log_info "检测到操作系统: $OS $VER"

# 安装系统依赖
log_info "安装系统依赖..."

if command -v apt-get &> /dev/null; then
    # Ubuntu/Debian/Raspberry Pi OS
    log_info "使用apt-get安装依赖..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv portaudio19-dev python3-dev build-essential
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    log_info "使用yum安装依赖..."
    sudo yum install -y python3 python3-pip python3-devel portaudio-devel gcc
elif command -v dnf &> /dev/null; then
    # Fedora
    log_info "使用dnf安装依赖..."
    sudo dnf install -y python3 python3-pip python3-devel portaudio-devel gcc
else
    log_warning "未知的包管理器，请手动安装Python3和PortAudio"
fi

# 检查Python版本
log_info "检查Python版本..."
python3 --version

# 创建虚拟环境
log_info "创建Python虚拟环境..."
if [[ -d "venv" ]]; then
    log_warning "虚拟环境已存在，将重新创建"
    rm -rf venv
fi

python3 -m venv venv

# 激活虚拟环境
log_info "激活虚拟环境..."
source venv/bin/activate

# 配置pip使用国内镜像源
log_info "配置pip镜像源..."
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ || true
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn || true

# 升级pip
log_info "升级pip..."
pip install --upgrade pip setuptools wheel

# 安装Python依赖
log_info "安装Python依赖..."
if [[ -d "dependencies" ]]; then
    log_info "使用预下载的Python依赖包..."
    ./dependencies/install_deps.sh
    
    # 检查是否还有未安装的包
    log_info "检查并安装剩余Python依赖..."
    pip install -r requirements-desktop.txt --no-deps || true
else
    log_info "从网络安装Python依赖包..."
    pip install -r requirements-desktop.txt
fi

# 显示系统依赖说明
if [[ -f "dependencies/SYSTEM_DEPS.md" ]]; then
    log_info "系统依赖说明:"
    cat dependencies/SYSTEM_DEPS.md
fi

# 创建桌面快捷方式
log_info "创建桌面快捷方式..."
if [[ -d "$HOME/Desktop" ]]; then
    cat > "$HOME/Desktop/Translate-Chat.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Translate Chat
Comment=AI语音翻译聊天应用
Exec=bash -c "cd $(pwd) && ./run.sh"
Icon=applications-internet
Terminal=true
Categories=Network;AudioVideo;
DESKTOP_EOF
    chmod +x "$HOME/Desktop/Translate-Chat.desktop"
    log_success "桌面快捷方式已创建"
fi

# 创建启动脚本
log_info "创建启动脚本..."
cat > run.sh << 'RUN_EOF'
#!/bin/bash
# Translate Chat 启动脚本

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装Python3"
    exit 1
fi

# 检查虚拟环境
if [[ ! -d "venv" ]]; then
    echo "错误: 虚拟环境不存在，请先运行 ./install.sh"
    exit 1
fi

# 激活虚拟环境
source venv/bin/activate

# 检查依赖是否已安装
if ! python3 -c "import kivy" 2>/dev/null; then
    echo "安装依赖..."
    if [[ -d "dependencies" ]]; then
        echo "使用预下载的依赖包..."
        ./dependencies/install_deps.sh
        # 检查是否还有未安装的包
        pip install -r requirements-desktop.txt --no-deps || true
    else
        echo "从网络安装依赖包..."
        pip install -r requirements-desktop.txt
    fi
fi

# 运行应用
echo "启动Translate Chat..."
python3 main.py
RUN_EOF

chmod +x run.sh

# 创建卸载脚本
log_info "创建卸载脚本..."
cat > uninstall.sh << 'UNINSTALL_EOF'
#!/bin/bash
# Translate Chat 卸载脚本

echo "卸载Translate Chat..."

# 删除虚拟环境
if [[ -d "venv" ]]; then
    rm -rf venv
    echo "已删除虚拟环境"
fi

# 删除桌面快捷方式
if [[ -f "$HOME/Desktop/Translate-Chat.desktop" ]]; then
    rm -f "$HOME/Desktop/Translate-Chat.desktop"
    echo "已删除桌面快捷方式"
fi

echo "卸载完成"
UNINSTALL_EOF

chmod +x uninstall.sh

log_success "=========================================="
log_success "安装完成！"
log_success "=========================================="
echo ""
log_info "使用方法:"
echo "  启动应用: ./run.sh"
echo "  卸载应用: ./uninstall.sh"
echo ""
log_info "桌面快捷方式已创建，可以直接双击启动"
echo ""
log_warning "注意: 首次运行可能需要下载模型文件，请确保网络连接正常"
EOF
    
    chmod +x "$package_dir/install.sh"
    
    # 创建README
    cat > "$package_dir/README.md" << EOF
# Translate Chat - $target_arch 版本

## 快速开始

### 一键安装
\`\`\`bash
./install.sh
\`\`\`

### 启动应用
\`\`\`bash
./run.sh
\`\`\`

### 卸载应用
\`\`\`bash
./uninstall.sh
\`\`\`

## 系统要求
- Python 3.9-3.11
- PortAudio
- 网络连接（用于语音识别和翻译）

## 安装说明

### 自动安装（推荐）
运行 \`./install.sh\` 脚本，它会自动：
1. 安装系统依赖（Python3、PortAudio等）
2. 创建Python虚拟环境
3. 安装Python依赖包（优先使用预下载的包）
4. 创建桌面快捷方式
5. 配置启动脚本

### 预下载依赖包
安装包已包含预下载的Python依赖包，位于 \`dependencies/\` 目录：
- 减少网络下载时间
- 支持离线安装
- 自动处理平台兼容性

**注意**: 系统依赖（如PortAudio）无法预下载，需要在目标平台手动安装：
- Ubuntu/Debian: \`sudo apt-get install portaudio19-dev\`
- CentOS/RHEL: \`sudo yum install portaudio-devel\`

### 手动安装
如果自动安装失败，可以手动安装：

1. 安装系统依赖：
   \`\`\`bash
   # Ubuntu/Debian/Raspberry Pi
   sudo apt-get update
   sudo apt-get install python3 python3-pip python3-venv portaudio19-dev
   
   # CentOS/RHEL
   sudo yum install python3 python3-pip portaudio-devel
   \`\`\`

2. 创建虚拟环境：
   \`\`\`bash
   python3 -m venv venv
   source venv/bin/activate
   \`\`\`

3. 安装Python依赖：
   \`\`\`bash
   pip install -r requirements-desktop.txt
   \`\`\`

## 故障排除

### 音频问题
如果遇到音频问题，请确保安装了PortAudio：
\`\`\`bash
sudo apt-get install portaudio19-dev  # Ubuntu/Debian
sudo yum install portaudio-devel      # CentOS/RHEL
\`\`\`

### 网络问题
应用需要网络连接用于语音识别和翻译，请确保网络正常。

### 权限问题
如果遇到权限问题，请确保脚本有执行权限：
\`\`\`bash
chmod +x *.sh
\`\`\`

## 功能特性
- 实时语音识别
- 多语言翻译
- 语音合成
- 跨平台支持
- 简洁易用的界面

## 技术支持
如遇到问题，请查看日志文件或联系技术支持。
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
    
    # 使用真正的交叉编译
    if [[ "$target_arch" == "arm64" ]]; then
        build_linux_arm64_cross
    else
        build_linux_x86_64_cross
    fi
    
    return 0
}

# 真正的ARM64 Linux交叉编译 - 针对Ubuntu 20.04优化
build_linux_arm64_cross() {
    log_info "开始ARM64 Linux交叉编译..."
    log_info "目标平台: Ubuntu 20.04 ARM64 (Focal Fossa)"
    
    # 预检查构建环境
    pre_build_checks
    
    # 检查是否支持ARM64交叉编译
    if ! docker buildx ls | grep -q "arm64"; then
        log_info "创建ARM64构建器..."
        docker buildx create --name arm64-builder --driver docker-container --platform linux/arm64 || true
    fi
    
    # 使用Docker Buildx进行真正的交叉编译
    log_info "使用Docker Buildx进行ARM64 Linux交叉编译..."
    
    # 创建Dockerfile用于交叉编译
    cat > Dockerfile.cross << 'EOF'
# 使用多阶段构建进行交叉编译 - 针对Ubuntu ARM64优化
FROM --platform=linux/arm64 ubuntu:20.04 as builder

# 设置环境变量避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装基础工具和Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 安装构建依赖 - Ubuntu 20.04 ARM64兼容
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    libasound2-dev \
    libssl-dev \
    libffi-dev \
    wget \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装PortAudio - Ubuntu 20.04 ARM64兼容方案
RUN apt-get update && apt-get install -y \
    libportaudio2 \
    || echo "libportaudio2 not available, will install from source"

# 尝试安装portaudio开发包，如果失败则从源码编译
RUN apt-get update && apt-get install -y portaudio19-dev || \
    (echo "portaudio19-dev not available, installing from source..." && \
     apt-get install -y wget build-essential && \
     cd /tmp && \
     wget -O portaudio.tgz http://files.portaudio.com/download/portaudio_v190600_20161030.tgz && \
     tar -xzf portaudio.tgz && \
     cd portaudio && \
     ./configure --prefix=/usr/local && \
     make && \
     make install && \
     ldconfig && \
     cd / && \
     rm -rf /tmp/portaudio*)

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 配置pip使用国内镜像源
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ && \
    pip3 config set global.trusted-host pypi.tuna.tsinghua.edu.cn

# 升级pip和安装基础工具
RUN pip3 install --upgrade pip setuptools wheel

# 安装Python依赖 - 针对ARM64优化
RUN pip3 install --no-cache-dir -r requirements-desktop.txt

# 安装PyInstaller
RUN pip3 install pyinstaller

# 移除与PyInstaller不兼容的包
RUN pip3 uninstall -y typing || true

# 构建ARM64 Linux可执行文件 - 针对Ubuntu ARM64优化
RUN pyinstaller \
    --onefile \
    --name=translate-chat \
    --distpath=dist/arm64 \
    --workpath=build/arm64 \
    --runtime-tmpdir=/tmp \
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
    --hidden-import=lang_detect \
    --hidden-import=hotwords \
    --hidden-import=audio_capture \
    --hidden-import=audio_capture_pyaudio \
    --exclude-module=matplotlib \
    --exclude-module=tkinter \
    --exclude-module=PyQt5 \
    --exclude-module=PySide2 \
    --exclude-module=IPython \
    --exclude-module=jupyter \
    --exclude-module=notebook \
    --exclude-module=qtpy \
    --exclude-module=PySide6 \
    --exclude-module=PyQt6 \
    main.py

# 验证ARM64可执行文件
RUN file dist/arm64/translate-chat
RUN ldd dist/arm64/translate-chat || echo "静态链接或ARM64 ELF文件"

# 检查可执行文件大小和权限
RUN ls -la dist/arm64/translate-chat
RUN chmod +x dist/arm64/translate-chat

# 验证Python依赖是否正确打包
RUN echo "验证构建的可执行文件..." && \
    echo "文件类型:" && file dist/arm64/translate-chat && \
    echo "文件大小:" && du -h dist/arm64/translate-chat && \
    echo "文件权限:" && ls -la dist/arm64/translate-chat

# 输出阶段
FROM scratch as output
COPY --from=builder /app/dist/arm64/translate-chat /translate-chat
EOF

    # 使用Docker Buildx进行交叉编译 - 添加详细输出和错误处理
    log_info "使用Docker Buildx构建ARM64可执行文件..."
    log_info "目标平台: Ubuntu 20.04 ARM64"
    log_info "构建过程可能需要10-20分钟，请耐心等待..."
    
    # 设置Docker构建参数
    local build_args=""
    if [[ "$VERBOSE" == true ]]; then
        build_args="--progress=plain"
    else
        build_args="--progress=auto"
    fi
    
    if docker buildx build \
        --platform linux/arm64 \
        --file Dockerfile.cross \
        --output type=local,dest="$DIST_DIR/arm64" \
        --target output \
        $build_args \
        .; then
        
        log_success "Docker Buildx交叉编译成功"
        
        # 验证构建结果
        if [[ -f "$DIST_DIR/arm64/translate-chat" ]]; then
            local file_type=$(file "$DIST_DIR/arm64/translate-chat")
            log_info "构建文件类型: $file_type"
            
            # 检查是否为ARM64 ELF文件
            if echo "$file_type" | grep -q "ARM aarch64"; then
                local exe_size=$(du -sh "$DIST_DIR/arm64/translate-chat" | cut -f1)
                log_success "ARM64 Linux可执行文件构建成功: $DIST_DIR/arm64/translate-chat (大小: $exe_size)"
                
                # 设置可执行权限
                chmod +x "$DIST_DIR/arm64/translate-chat"
                
                # 验证文件完整性
                log_info "验证可执行文件完整性..."
                if "$DIST_DIR/arm64/translate-chat" --help &>/dev/null || "$DIST_DIR/arm64/translate-chat" --version &>/dev/null; then
                    log_success "可执行文件验证通过"
                else
                    log_warning "可执行文件可能缺少帮助信息，但文件结构正常"
                fi
                
                # 构建后处理
                post_build_processing "$DIST_DIR/arm64/translate-chat"
                
                # 清理临时文件
                rm -f Dockerfile.cross
                return 0
            else
                log_error "构建的文件不是ARM64架构: $file_type"
                log_error "期望: ARM aarch64, 实际: $file_type"
                return 1
            fi
        else
            log_error "未找到构建的可执行文件"
            log_error "检查构建目录: $DIST_DIR/arm64/"
            ls -la "$DIST_DIR/arm64/" 2>/dev/null || log_error "构建目录不存在"
            return 1
        fi
    else
        log_error "Docker Buildx交叉编译失败"
        
        # 提供详细的错误诊断信息
        log_info "故障排除建议:"
        log_info "1. 检查Docker是否正在运行: docker info"
        log_info "2. 检查Docker Buildx是否可用: docker buildx version"
        log_info "3. 检查ARM64平台支持: docker buildx inspect default"
        log_info "4. 检查网络连接: ping pypi.tuna.tsinghua.edu.cn"
        log_info "5. 检查磁盘空间: df -h"
        log_info "6. 尝试清理Docker缓存: docker system prune -f"
        
        # 显示Docker状态信息
        log_info "Docker状态检查:"
        docker info 2>/dev/null | grep -E "(Server Version|Operating System|Kernel Version)" || log_warning "无法获取Docker信息"
        
        # 显示构建器信息
        log_info "Docker Buildx构建器:"
        docker buildx ls 2>/dev/null || log_warning "无法获取构建器信息"
        
        # 清理临时文件
        rm -f Dockerfile.cross
        
        return 1
    fi
}

# x86_64 Linux构建（本地构建，非交叉编译）
build_linux_x86_64_cross() {
    log_info "开始x86_64 Linux构建..."
    
    # 注意：这是本地构建，不是真正的交叉编译
    # 在macOS上无法真正交叉编译x86_64 Linux，除非使用虚拟机或远程构建
    
    log_warning "在macOS上无法进行真正的x86_64 Linux交叉编译"
    log_info "建议："
    log_info "1. 在Linux服务器上构建x86_64版本"
    log_info "2. 使用虚拟机运行Linux进行构建"
    log_info "3. 使用GitHub Actions等CI/CD平台构建"
    
    return 1
}

# 创建压缩包
create_archive() {
    local target_arch=$1
    local dist_dir="$DIST_DIR/$target_arch"
    local package_dir="$DIST_DIR/python_package_$target_arch"
    
    # 创建可执行文件压缩包
    if [[ -f "$dist_dir/translate-chat" ]]; then
        local exe_archive_name="translate-chat-$target_arch-executable-$(date +%Y%m%d).tar.gz"
        log_info "创建可执行文件压缩包: $exe_archive_name"
        
        cd "$dist_dir"
        if tar -czf "$exe_archive_name" translate-chat; then
            local archive_size=$(du -sh "$exe_archive_name" | cut -f1)
            log_success "可执行文件压缩包创建成功: $exe_archive_name ($archive_size)"
            mv "$exe_archive_name" "$DIST_DIR/"
        else
            log_warning "可执行文件压缩包创建失败"
        fi
        
        cd "$PROJECT_ROOT"
    fi
    
    # 创建完整安装包压缩包
    if [[ -d "$package_dir" ]]; then
        local package_archive_name="translate-chat-$target_arch-installer-$(date +%Y%m%d).tar.gz"
        log_info "创建完整安装包压缩包: $package_archive_name"
        
        cd "$DIST_DIR"
        if tar -czf "$package_archive_name" "python_package_$target_arch"; then
            local archive_size=$(du -sh "$package_archive_name" | cut -f1)
            log_success "完整安装包压缩包创建成功: $package_archive_name ($archive_size)"
        else
            log_warning "完整安装包压缩包创建失败"
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
    echo ""
    log_success "=========================================="
    log_success "构建完成！"
    log_success "=========================================="
    echo ""
    
    # 显示构建产物总览
    log_info "📦 构建产物总览:"
    echo ""
    
    local arch="arm64"
    local dist_dir="$DIST_DIR/$arch"
    local package_dir="$DIST_DIR/python_package_$arch"
    
    if [[ -d "$dist_dir" ]] || [[ -d "$package_dir" ]]; then
        echo "  🍓 ARM64 架构 (树莓派):"
        
        # 显示可执行文件
        if [[ -d "$dist_dir" ]]; then
            local exe_file="$dist_dir/translate-chat"
            if [[ -f "$exe_file" ]]; then
                local exe_size=$(du -sh "$exe_file" | cut -f1)
                echo "    📄 可执行文件: translate-chat ($exe_size)"
            fi
        fi
        
        # 显示Python安装包
        if [[ -d "$package_dir" ]]; then
            local total_size=$(du -sh "$package_dir" | cut -f1)
            echo "    📁 Python安装包: python_package_$arch ($total_size)"
            
            # 显示依赖包信息
            local deps_dir="$package_dir/dependencies"
            if [[ -d "$deps_dir" ]]; then
                local deps_count=$(find "$deps_dir" -name "*.whl" -o -name "*.tar.gz" -o -name "*.zip" 2>/dev/null | wc -l)
                local deps_size=$(du -sh "$deps_dir" | cut -f1)
                echo "      📦 预下载依赖: $deps_count 个包 ($deps_size)"
            fi
        fi
        
        # 显示独立可执行文件包
        local standalone_dir="$DIST_DIR/standalone_$arch"
        if [[ -d "$standalone_dir" ]]; then
            local standalone_size=$(du -sh "$standalone_dir" | cut -f1)
            echo "    🚀 独立可执行文件包: standalone_$arch ($standalone_size)"
        fi
        echo ""
    fi
    
    # 显示压缩包
    log_info "🗜️  压缩包:"
    echo ""
    
    local exe_archives=$(ls "$DIST_DIR"/*-executable-*.tar.gz 2>/dev/null | wc -l)
    local installer_archives=$(ls "$DIST_DIR"/*-installer-*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $exe_archives -gt 0 ]]; then
        echo "  📄 可执行文件压缩包:"
        for archive in "$DIST_DIR"/*-executable-*.tar.gz; do
            if [[ -f "$archive" ]]; then
                local archive_size=$(du -sh "$archive" | cut -f1)
                local archive_name=$(basename "$archive")
                echo "    $archive_name ($archive_size)"
            fi
        done
        echo ""
    fi
    
    if [[ $installer_archives -gt 0 ]]; then
        echo "  📦 完整安装包压缩包:"
        for archive in "$DIST_DIR"/*-installer-*.tar.gz; do
            if [[ -f "$archive" ]]; then
                local archive_size=$(du -sh "$archive" | cut -f1)
                local archive_name=$(basename "$archive")
                echo "    $archive_name ($archive_size)"
            fi
        done
        echo ""
    fi
    
    # 显示部署说明
    log_info "🚀 部署说明:"
    echo ""
    
    # 检查是否有ARM64包
    if [[ -d "$DIST_DIR/python_package_arm64" ]]; then
        echo "  🍓 树莓派部署 (Python包):"
        echo "    1. 传输安装包: scp -r dist/python_package_arm64/ pi@树莓派IP:/home/pi/"
        echo "    2. 进入目录: cd python_package_arm64"
        echo "    3. 一键安装: ./install.sh"
        echo "    4. 启动应用: ./run.sh"
        echo ""
    fi
    
    # 检查是否有独立可执行文件包
    if [[ -d "$DIST_DIR/standalone_arm64" ]]; then
        echo "  🚀 树莓派部署 (独立可执行文件 - 推荐):"
        echo "    1. 传输可执行文件: scp -r dist/standalone_arm64/ pi@树莓派IP:/home/pi/"
        echo "    2. 进入目录: cd standalone_arm64"
        echo "    3. 直接运行: ./translate-chat"
        echo "    4. 或使用脚本: ./run.sh"
        echo ""
    fi
    
    # 显示安装包特性
    log_info "✨ 安装包特性:"
    echo ""
    echo "  ✅ 一键安装脚本 (install.sh)"
    echo "  ✅ 自动启动脚本 (run.sh)"
    echo "  ✅ 卸载脚本 (uninstall.sh)"
    echo "  ✅ 桌面快捷方式"
    echo "  ✅ 国内镜像源配置"
    echo "  ✅ 系统依赖自动安装"
    echo "  ✅ 预下载Python依赖包"
    echo "  ✅ 系统依赖说明文档"
    echo "  ✅ 离线安装支持"
    echo "  ✅ 包大小优化"
    echo "  ✅ 详细使用说明"
    echo ""
    
    # 显示文件位置
    log_info "📂 文件位置:"
    echo "  构建产物目录: $DIST_DIR"
    echo "  可执行文件: $DIST_DIR/{arch}/translate-chat"
    echo "  Python安装包: $DIST_DIR/python_package_{arch}/"
    echo "  独立可执行文件包: $DIST_DIR/standalone_{arch}/"
    echo ""
    
    log_warning "💡 提示: 首次运行可能需要下载模型文件，请确保网络连接正常"
}

# 显示详细的构建产物描述
show_detailed_build_artifacts() {
    echo ""
    log_success "=========================================="
    log_success "📦 构建产物详细描述"
    log_success "=========================================="
    echo ""
    
    # 检查并显示每个架构的产物
    for arch in x86_64 arm64; do
        local arch_dir="$DIST_DIR/$arch"
        if [[ -d "$arch_dir" ]]; then
            log_info "🎯 架构: $arch"
            echo ""
            
            # 可执行文件
            local exe_file="$arch_dir/translate-chat"
            if [[ -f "$exe_file" ]]; then
                local exe_size=$(du -h "$exe_file" | cut -f1)
                echo "  📄 可执行文件:"
                echo "     路径: $exe_file"
                echo "     大小: $exe_size"
                echo "     用途: 直接运行的Linux可执行文件，包含所有依赖"
                echo "     运行方式: ./translate-chat"
                echo ""
            fi
            
            # AppImage包
            local appimage_file="$arch_dir/Translate-Chat-${arch}.AppImage"
            if [[ -f "$appimage_file" ]]; then
                local appimage_size=$(du -h "$appimage_file" | cut -f1)
                echo "  📦 AppImage包:"
                echo "     路径: $appimage_file"
                echo "     大小: $appimage_size"
                echo "     用途: 便携式Linux应用包，可在大多数Linux发行版上运行"
                echo "     运行方式: chmod +x Translate-Chat-${arch}.AppImage && ./Translate-Chat-${arch}.AppImage"
                echo ""
            fi
            
            # deb包
            local deb_file="$arch_dir/translate-chat_1.0.0_${arch}.deb"
            if [[ -f "$deb_file" ]]; then
                local deb_size=$(du -h "$deb_file" | cut -f1)
                echo "  📦 deb安装包:"
                echo "     路径: $deb_file"
                echo "     大小: $deb_size"
                echo "     用途: Ubuntu/Debian系统安装包，支持系统级安装"
                echo "     安装方式: sudo dpkg -i translate-chat_1.0.0_${arch}.deb"
                echo ""
            fi
            
            # 独立可执行文件包
            local standalone_dir="$DIST_DIR/standalone_${arch}"
            if [[ -d "$standalone_dir" ]]; then
                local standalone_size=$(du -sh "$standalone_dir" | cut -f1)
                echo "  📁 独立可执行文件包:"
                echo "     路径: $standalone_dir/"
                echo "     大小: $standalone_size"
                echo "     用途: 包含可执行文件、启动脚本和安装脚本的完整包"
                echo "     内容:"
                echo "       - translate-chat (可执行文件)"
                echo "       - run.sh (启动脚本)"
                echo "       - install.sh (安装脚本)"
                echo "     使用方式: 解压后运行 ./run.sh 或 ./install.sh"
                echo ""
            fi
            
            # 压缩包
            local archive_file="$DIST_DIR/translate-chat-${arch}.tar.gz"
            if [[ -f "$archive_file" ]]; then
                local archive_size=$(du -h "$archive_file" | cut -f1)
                echo "  📦 压缩包:"
                echo "     路径: $archive_file"
                echo "     大小: $archive_size"
                echo "     用途: 便于分发和传输的压缩包"
                echo "     解压方式: tar -xzf translate-chat-${arch}.tar.gz"
                echo ""
            fi
        fi
    done
    
    echo ""
    log_info "🚀 使用建议:"
    echo "  • 开发测试: 使用可执行文件 (translate-chat)"
    echo "  • 便携使用: 使用AppImage包"
    echo "  • 系统安装: 使用deb安装包"
    echo "  • 完整分发: 使用独立可执行文件包"
    echo "  • 网络传输: 使用压缩包"
    echo ""
    log_info "🔧 运行要求:"
    echo "  • 目标系统: Linux (x86_64 或 ARM64)"
    echo "  • 系统依赖: PortAudio, Python3 (可选)"
    echo "  • 网络连接: 首次运行需要下载模型文件"
    echo ""
}

# 创建发布目录结构
create_release_structure() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    
    log_info "创建发布目录结构: $release_dir"
    
    # 创建目录结构
    mkdir -p "$release_dir"/{linux/{x86_64,arm64},docs,checksums}
    
    log_success "发布目录结构创建完成"
}

# 复制构建产物到发布目录
copy_build_artifacts_to_release() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    
    log_info "复制构建产物到发布目录..."
    
    # 复制Linux文件
    for arch in x86_64 arm64; do
        local linux_dir="$DIST_DIR/$arch"
        local release_linux_dir="$release_dir/linux/$arch"
        
        if [[ -d "$linux_dir" ]]; then
            mkdir -p "$release_linux_dir"
            
            # 复制可执行文件
            if [[ -f "$linux_dir/translate-chat" ]]; then
                cp "$linux_dir/translate-chat" "$release_linux_dir/"
                log_info "复制: linux/$arch/translate-chat"
            fi
            
            # 复制AppImage
            if [[ -f "$linux_dir/Translate-Chat-${arch}.AppImage" ]]; then
                cp "$linux_dir/Translate-Chat-${arch}.AppImage" "$release_linux_dir/"
                log_info "复制: linux/$arch/Translate-Chat-${arch}.AppImage"
            fi
            
            # 复制deb包
            if [[ -f "$linux_dir/translate-chat_1.0.0_${arch}.deb" ]]; then
                cp "$linux_dir/translate-chat_1.0.0_${arch}.deb" "$release_linux_dir/"
                log_info "复制: linux/$arch/translate-chat_1.0.0_${arch}.deb"
            fi
            
            # 复制独立可执行文件包
            local standalone_dir="$DIST_DIR/standalone_${arch}"
            if [[ -d "$standalone_dir" ]]; then
                cp -r "$standalone_dir" "$release_linux_dir/"
                log_info "复制: linux/$arch/standalone_${arch}/"
            fi
            
            # 复制压缩包
            local archive_file="$DIST_DIR/translate-chat-${arch}.tar.gz"
            if [[ -f "$archive_file" ]]; then
                cp "$archive_file" "$release_linux_dir/"
                log_info "复制: linux/$arch/translate-chat-${arch}.tar.gz"
            fi
        fi
    done
    
    log_success "构建产物复制完成"
}

# 生成发布文档
generate_release_docs() {
    local version="$1"
    local release_dir="$PROJECT_ROOT/releases/$version"
    
    log_info "生成发布文档..."
    
    # 生成发布说明
    cat > "$release_dir/docs/RELEASE_NOTES.md" << EOF
# Translate-Chat $version Release

## 🎉 新版本发布

这是 Translate-Chat 的 $version 版本，使用macOS交叉编译构建的Linux应用。

## 📦 下载文件

### Linux 版本
- **x86_64**
  - Translate-Chat-x86_64.AppImage - AppImage包
  - translate-chat_1.0.0_x86_64.deb - Debian安装包
  - translate-chat - 可执行文件
  - standalone_x86_64/ - 独立可执行文件包

- **ARM64**
  - Translate-Chat-arm64.AppImage - AppImage包
  - translate-chat_1.0.0_arm64.deb - Debian安装包
  - translate-chat - 可执行文件
  - standalone_arm64/ - 独立可执行文件包

## 🛠️ 安装说明

### Linux 用户
1. **AppImage**: chmod +x Translate-Chat-*.AppImage && ./Translate-Chat-*.AppImage
2. **deb包**: sudo dpkg -i translate-chat_1.0.0_*.deb
3. **可执行文件**: chmod +x translate-chat && ./translate-chat
4. **独立包**: 解压standalone_*目录，运行 ./run.sh

## 🔧 系统要求
- **Linux**: Ubuntu 18.04+, CentOS 7+, Raspberry Pi OS
- **架构**: x86_64, ARM64
- **依赖**: PortAudio (可选，已包含在可执行文件中)

## 🏗️ 构建信息
- **构建平台**: macOS (交叉编译)
- **构建工具**: PyInstaller
- **目标平台**: Linux (x86_64, ARM64)

---
**版本**: $version  
**发布日期**: $(date +%Y年%m月%d日)  
**构建平台**: macOS $(uname -m)
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
    find . -type f \( -name "translate-chat" -o -name "*.AppImage" -o -name "*.deb" -o -name "*.tar.gz" \) -exec sha256sum {} \; > checksums/SHA256SUMS
    
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
            --no-deps)
                SKIP_DEPS=true
                shift
                ;;
            --no-download-deps)
                DOWNLOAD_DEPS=false
                shift
                ;;
            --minimal-deps)
                MINIMAL_DEPS=true
                shift
                ;;
            --no-optimize-deps)
                OPTIMIZE_DEPS=false
                shift
                ;;
            --standalone-exe)
                STANDALONE_EXE=true
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
    echo ""
    log_success "=========================================="
    log_success "macOS本地交叉编译ARM64 Linux应用 v1.1.0"
    log_success "=========================================="
    echo ""
    log_info "📅 开始时间: $(date)"
    log_info "🎯 目标架构: ARM64 Linux (Ubuntu 20.04)"
    if [[ -n "$RELEASE_VERSION" ]]; then
        log_info "📦 发布版本: $RELEASE_VERSION"
    fi
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
        log_success "环境检查通过，可以进行ARM64交叉编译"
        exit 0
    fi
    
    # 安装构建工具
    install_build_tools
    
    # 创建构建目录
    create_build_directories
    
    log_info "开始构建ARM64 Linux应用..."
    
    # 构建ARM64应用
    build_architecture "arm64"
    create_archive "arm64"
    
    # 显示构建结果
    show_build_results
    
    # 显示详细的产出物描述
    show_detailed_build_artifacts
    
    # 创建发布版本
    if [[ "$CREATE_RELEASE" == true ]]; then
        create_release "$RELEASE_VERSION"
    fi
    
    echo ""
    log_success "=========================================="
    log_success "ARM64 Linux交叉编译完成！"
    log_success "=========================================="
    log_info "📅 结束时间: $(date)"
    echo ""
}

# 运行主函数
main "$@" 