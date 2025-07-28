#!/bin/bash
# =============================================================
# 文件名(File): unified_build_system.sh
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/28
# 简介(Description): 统一跨平台打包系统 - 支持macOS(ARM)和Linux(x86)构建x86+Linux和ARM+Linux应用
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
统一跨平台打包系统 v1.0.0

用法: $0 [选项] [目标架构]

选项:
    -h, --help          显示此帮助信息
    -c, --clean         清理构建缓存
    -v, --verbose       详细输出
    -t, --test          仅测试环境，不构建
    -p, --platform      指定目标平台 (linux)
    -a, --arch          指定目标架构 (x86_64, arm64, all)

目标架构:
    x86_64              构建x86_64 Linux应用
    arm64               构建ARM64 Linux应用
    all                 构建所有架构 (x86_64 + arm64)

示例:
    $0 x86_64           # 构建x86_64 Linux应用
    $0 arm64            # 构建ARM64 Linux应用
    $0 all              # 构建所有架构
    $0 -c               # 清理构建缓存
    $0 -t               # 测试环境

支持的主机平台:
    - macOS (ARM64)     -> 构建 x86_64 Linux 和 ARM64 Linux
    - Linux (x86_64)    -> 构建 x86_64 Linux 和 ARM64 Linux

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

# 检查网络连接
check_network_connection() {
    log_info "检查网络连接..."
    
    # 测试Docker Hub连接
    if curl -s --connect-timeout 10 --max-time 30 https://registry-1.docker.io/v2/ > /dev/null; then
        log_success "Docker Hub连接正常"
        return 0
    else
        log_warning "Docker Hub连接可能有问题，将尝试使用国内镜像源"
        return 1
    fi
}

# 检查Docker环境
check_docker_environment() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker未运行"
        return 1
    fi
    
    # 检查Docker buildx
    if docker buildx inspect &> /dev/null; then
        log_success "Docker buildx可用"
        return 0
    else
        log_warning "Docker buildx不可用，将使用默认构建器"
        return 0
    fi
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

# 生成Dockerfile
generate_dockerfile() {
    local target_arch=$1
    local dockerfile_path="$BUILD_DIR/Dockerfile.$target_arch"
    
    log_info "生成Dockerfile for $target_arch..."
    
    # 根据目标架构设置Docker平台
    local docker_platform=""
    case "$target_arch" in
        "x86_64")
            docker_platform="linux/amd64"
            ;;
        "arm64")
            docker_platform="linux/arm64"
            ;;
        *)
            log_error "不支持的架构: $target_arch"
            return 1
            ;;
    esac
    
    # 检查网络连接，选择合适的基础镜像
    local base_image="ubuntu:22.04"
    if check_network_connection; then
        log_info "使用官方镜像源"
    else
        log_info "使用阿里云镜像源"
        base_image="registry.cn-hangzhou.aliyuncs.com/library/ubuntu:22.04"
    fi
    
    cat > "$dockerfile_path" << EOF
FROM --platform=$docker_platform $base_image

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TARGET_ARCH=$target_arch

# 配置国内镜像源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \\
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 更新系统并安装基础工具
RUN apt-get update && apt-get install -y \\
    python3 \\
    python3-pip \\
    python3-venv \\
    python3-dev \\
    build-essential \\
    git \\
    wget \\
    curl \\
    pkg-config \\
    libssl-dev \\
    libffi-dev \\
    libjpeg-dev \\
    libpng-dev \\
    libfreetype6-dev \\
    libgif-dev \\
    libportaudio2 \\
    portaudio19-dev \\
    libasound2-dev \\
    libpulse-dev \\
    libjack-jackd2-dev \\
    libavcodec-dev \\
    libavformat-dev \\
    libavdevice-dev \\
    libavutil-dev \\
    libswscale-dev \\
    libavfilter-dev \\
    libavresample-dev \\
    libpostproc-dev \\
    libswresample-dev \\
    && rm -rf /var/lib/apt/lists/*

# 配置pip使用国内镜像源
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/ && \\
    pip3 config set global.trusted-host pypi.tuna.tsinghua.edu.cn

# 安装PyInstaller
RUN pip3 install --no-cache-dir pyinstaller==5.13.2

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 创建虚拟环境
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:\$PATH"

# 安装Python依赖
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements-desktop.txt

# 创建构建脚本
RUN cat > /app/build_linux.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e
echo "开始构建Linux应用 (\$TARGET_ARCH)..."

# 清理之前的构建
rm -rf build dist

# 使用PyInstaller构建
pyinstaller \\
    --onefile \\
    --windowed \\
    --name="translate-chat" \\
    --add-data="assets:assets" \\
    --add-data="ui:ui" \\
    --add-data="utils:utils" \\
    --hidden-import=kivy \\
    --hidden-import=kivymd \\
    --hidden-import=websocket \\
    --hidden-import=aiohttp \\
    --hidden-import=cryptography \\
    --hidden-import=pyaudio \\
    --hidden-import=asr_client \\
    --hidden-import=translator \\
    --hidden-import=config_manager \\
    --hidden-import=speaker_change_detector \\
    --hidden-import=lang_detect \\
    --hidden-import=hotwords \\
    --hidden-import=audio_capture \\
    --hidden-import=audio_capture_pyaudio \\
    main.py

echo "构建完成！"
echo "可执行文件位置: dist/translate-chat"
SCRIPT_EOF

RUN chmod +x /app/build_linux.sh

# 设置入口点
ENTRYPOINT ["/app/build_linux.sh"]
EOF

    log_success "Dockerfile生成完成: $dockerfile_path"
}

# 构建Docker镜像
build_docker_image() {
    local target_arch=$1
    local image_name="translate-chat-builder-$target_arch"
    local dockerfile_path="$BUILD_DIR/Dockerfile.$target_arch"
    
    log_info "构建Docker镜像: $image_name"
    
    # 尝试构建，最多重试3次
    for attempt in 1 2 3; do
        log_info "第 $attempt 次尝试构建Docker镜像..."
        
        if docker build --network=host --progress=plain -f "$dockerfile_path" -t "$image_name" .; then
            log_success "Docker镜像构建成功: $image_name"
            return 0
        else
            if [[ $attempt -lt 3 ]]; then
                log_warning "第 $attempt 次构建失败，等待10秒后重试..."
                sleep 10
            else
                log_error "Docker镜像构建失败: $image_name (已重试3次)"
                return 1
            fi
        fi
    done
}

# 在Docker中构建应用
build_application() {
    local target_arch=$1
    local image_name="translate-chat-builder-$target_arch"
    local build_dir="$BUILD_DIR/$target_arch"
    local dist_dir="$DIST_DIR/$target_arch"
    
    log_info "在Docker中构建$target_arch应用..."
    
    # 设置Docker平台
    local docker_platform=""
    case "$target_arch" in
        "x86_64")
            docker_platform="linux/amd64"
            ;;
        "arm64")
            docker_platform="linux/arm64"
            ;;
    esac
    
    # 运行Docker容器进行构建
    if docker run --rm \
        --platform $docker_platform \
        -v "$build_dir:/app/build" \
        -v "$dist_dir:/app/dist" \
        "$image_name"; then
        log_success "$target_arch应用构建成功"
        return 0
    else
        log_error "$target_arch应用构建失败"
        return 1
    fi
}

# 创建AppImage
create_appimage() {
    local target_arch=$1
    local dist_dir="$DIST_DIR/$target_arch"
    local appimage_name="Translate-Chat-$target_arch.AppImage"
    
    log_info "创建AppImage: $appimage_name"
    
    # 检查可执行文件是否存在
    if [[ ! -f "$dist_dir/translate-chat" ]]; then
        log_error "可执行文件不存在: $dist_dir/translate-chat"
        return 1
    fi
    
    # 创建AppDir结构
    local appdir="$BUILD_DIR/AppDir-$target_arch"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/share/applications"
    mkdir -p "$appdir/usr/share/icons/hicolor/256x256/apps"
    
    # 复制可执行文件
    cp "$dist_dir/translate-chat" "$appdir/usr/bin/"
    
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
    local target_arch=$1
    local dist_dir="$DIST_DIR/$target_arch"
    local deb_name="translate-chat_1.0.0_$target_arch.deb"
    
    log_info "创建deb包: $deb_name"
    
    # 检查可执行文件是否存在
    if [[ ! -f "$dist_dir/translate-chat" ]]; then
        log_error "可执行文件不存在: $dist_dir/translate-chat"
        return 1
    fi
    
    # 创建deb包结构
    local deb_dir="$BUILD_DIR/deb-$target_arch"
    mkdir -p "$deb_dir/usr/bin"
    mkdir -p "$deb_dir/usr/share/applications"
    mkdir -p "$deb_dir/DEBIAN"
    
    # 复制可执行文件
    cp "$dist_dir/translate-chat" "$deb_dir/usr/bin/"
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
Architecture: $target_arch
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

# 构建单个架构
build_architecture() {
    local target_arch=$1
    
    log_info "开始构建 $target_arch 架构..."
    
    # 生成Dockerfile
    if ! generate_dockerfile "$target_arch"; then
        return 1
    fi
    
    # 构建Docker镜像
    if ! build_docker_image "$target_arch"; then
        return 1
    fi
    
    # 在Docker中构建应用
    if ! build_application "$target_arch"; then
        return 1
    fi
    
    # 创建AppImage
    create_appimage "$target_arch"
    
    # 创建deb包
    create_deb_package "$target_arch"
    
    log_success "$target_arch 架构构建完成"
}

# 清理构建缓存
clean_build_cache() {
    log_info "清理构建缓存..."
    
    # 清理Docker镜像
    docker rmi translate-chat-builder-x86_64 2>/dev/null || true
    docker rmi translate-chat-builder-arm64 2>/dev/null || true
    
    # 清理构建目录
    rm -rf "$BUILD_DIR"
    rm -rf "$CACHE_DIR"
    
    # 清理临时文件
    rm -f Dockerfile.linux
    rm -f test_dockerfile
    
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
            ls -la "$dist_dir" 2>/dev/null | grep -E "(translate-chat|\.AppImage|\.deb)" || echo "    无构建产物"
        fi
    done
    
    echo ""
    log_info "构建产物位置: $DIST_DIR"
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
    echo "==== 统一跨平台打包系统 v1.0.0 ===="
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
    if ! check_docker_environment; then
        exit 1
    fi
    
    if ! check_python_environment; then
        exit 1
    fi
    
    # 检查网络连接
    check_network_connection
    
    # 仅测试环境
    if [[ "$TEST_ONLY" == true ]]; then
        log_success "环境检查通过，可以进行构建"
        exit 0
    fi
    
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
    log_info "进入构建分支..."
    case "$target_arch" in
        "x86_64")
            log_info "构建x86_64架构..."
            build_architecture "x86_64"
            ;;
        "arm64")
            log_info "构建arm64架构..."
            build_architecture "arm64"
            ;;
        "all")
            log_info "构建所有架构..."
            build_architecture "x86_64"
            build_architecture "arm64"
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