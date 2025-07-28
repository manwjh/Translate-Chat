#!/bin/bash
# Translate Chat - 跨平台交叉编译打包脚本
# 文件名(File): build_cross_platform.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 在x86+Linux平台上交叉编译打包x86+Linux和ARM+Linux版本

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - 跨平台交叉编译打包脚本 v1.0.0 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为Linux系统
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "此脚本仅适用于Linux系统"
    log_error "检测到的系统: $OSTYPE"
    exit 1
fi

# 确保在项目根目录运行
if [[ ! -f "main.py" ]]; then
    log_error "未找到main.py文件"
    log_error "请确保在项目根目录运行此脚本"
    log_error "当前目录: $(pwd)"
    log_error "请切换到项目根目录: cd /path/to/Translate-Chat"
    exit 1
fi

log_success "确认在项目根目录运行"
echo ""

# 显示系统信息
log_info "系统信息:"
log_info "  系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
log_info "  架构: $(uname -m)"
log_info "  内核: $(uname -r)"
log_info "  当前用户: $(whoami)"
echo ""

# 环境检查
echo "==== 1. 环境检查 ===="
log_info "开始环境检查..."

# 检查环境并获取Python命令
PYTHON_CMD=$(check_environment)
check_result=$?

if [[ $check_result -ne 0 ]]; then
    log_error "环境检查失败，请修复问题后重试"
    exit 1
fi

if [[ -z "$PYTHON_CMD" ]]; then
    log_error "未获取到有效的Python命令"
    exit 1
fi

log_success "环境检查通过，使用Python: $PYTHON_CMD"
echo ""

# 安装交叉编译工具链
echo "==== 2. 安装交叉编译工具链 ===="
log_info "安装ARM64交叉编译工具链..."

# 检测包管理器
if command -v apt &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
else
    log_error "未找到支持的包管理器 (apt/yum/dnf)"
    exit 1
fi

# 安装交叉编译工具链
install_cross_compilation_tools() {
    log_info "使用包管理器: $PACKAGE_MANAGER"
    
    case $PACKAGE_MANAGER in
        "apt")
            log_info "安装ARM64交叉编译工具链..."
            sudo apt update
            sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
            sudo apt install -y python3-dev python3-venv
            sudo apt install -y build-essential cmake pkg-config
            sudo apt install -y libasound2-dev portaudio19-dev
            sudo apt install -y libssl-dev libffi-dev
            ;;
        "yum"|"dnf")
            log_info "安装ARM64交叉编译工具链..."
            sudo $PACKAGE_MANAGER update
            sudo $PACKAGE_MANAGER install -y gcc-aarch64-linux-gnu gcc-c++-aarch64-linux-gnu
            sudo $PACKAGE_MANAGER install -y python3-devel python3-venv
            sudo $PACKAGE_MANAGER install -y gcc gcc-c++ cmake pkgconfig
            sudo $PACKAGE_MANAGER install -y alsa-lib-devel portaudio-devel
            sudo $PACKAGE_MANAGER install -y openssl-devel libffi-devel
            ;;
    esac
    
    # 验证安装
    if command -v aarch64-linux-gnu-gcc &> /dev/null; then
        log_success "ARM64交叉编译工具链安装成功"
    else
        log_error "ARM64交叉编译工具链安装失败"
        exit 1
    fi
}

install_cross_compilation_tools
echo ""

# 创建构建目录
echo "==== 3. 准备构建环境 ===="
BUILD_DIR="build_cross_platform"
DIST_DIR="dist_cross_platform"

# 清理旧的构建目录
if [[ -d "$BUILD_DIR" ]]; then
    log_info "清理旧的构建目录: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

if [[ -d "$DIST_DIR" ]]; then
    log_info "清理旧的发布目录: $DIST_DIR"
    rm -rf "$DIST_DIR"
fi

# 创建新的构建目录
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

log_success "构建目录准备完成"
echo ""

# 构建函数
build_for_architecture() {
    local arch=$1
    local python_cmd=$2
    local build_suffix=$3
    
    echo "==== 构建 $arch 版本 ===="
    log_info "开始构建 $arch 版本..."
    
    # 创建架构特定的构建目录
    local arch_build_dir="$BUILD_DIR/$arch"
    local arch_dist_dir="$DIST_DIR/$arch"
    
    mkdir -p "$arch_build_dir"
    mkdir -p "$arch_dist_dir"
    
    # 复制项目文件
    log_info "复制项目文件到构建目录..."
    cp -r . "$arch_build_dir/"
    cd "$arch_build_dir"
    
    # 创建虚拟环境
    log_info "创建Python虚拟环境..."
    $python_cmd -m venv venv
    source venv/bin/activate
    
    # 升级pip
    log_info "升级pip..."
    pip install --upgrade pip
    
    # 安装依赖
    log_info "安装项目依赖..."
    pip install -r requirements-desktop.txt
    
    # 安装PyInstaller
    log_info "安装PyInstaller..."
    pip install pyinstaller
    
    # 创建PyInstaller配置文件
    create_pyinstaller_config "$arch"
    
    # 执行打包
    log_info "执行PyInstaller打包..."
    pyinstaller --clean translate_chat.spec
    
    # 复制构建结果
    log_info "复制构建结果..."
    cp -r dist/* "$arch_dist_dir/"
    
    # 创建压缩包
    log_info "创建发布包..."
    cd "$arch_dist_dir"
    tar -czf "../translate-chat-${arch}-$(date +%Y%m%d).tar.gz" *
    
    log_success "$arch 版本构建完成"
    echo ""
    
    # 返回项目根目录
    cd ../../..
}

# 创建PyInstaller配置文件
create_pyinstaller_config() {
    local arch=$1
    
    cat > translate_chat.spec << EOF
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('assets', 'assets'),
        ('hotwords.json', '.'),
        ('config_manager.py', '.'),
        ('translator.py', '.'),
        ('asr_client.py', '.'),
        ('audio_capture.py', '.'),
        ('audio_capture_pyaudio.py', '.'),
        ('speaker_change_detector.py', '.'),
        ('lang_detect.py', '.'),
        ('hotwords.py', '.'),
        ('ui/main_window_kivy.py', 'ui'),
        ('ui/sys_config_window.py', 'ui'),
        ('utils/__init__.py', 'utils'),
        ('utils/file_downloader.py', 'utils'),
        ('utils/secure_storage.py', 'utils'),
    ],
    hiddenimports=[
        'kivy',
        'kivymd',
        'pyaudio',
        'websocket',
        'aiohttp',
        'cryptography',
        'requests',
        'numpy',
        'scipy',
        'webrtcvad',
        'resemblyzer',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='translate-chat',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='translate-chat',
)
EOF
}

# 主构建流程
echo "==== 4. 开始构建流程 ===="

# 构建x86_64版本
log_info "构建x86_64版本..."
build_for_architecture "x86_64" "$PYTHON_CMD" ""

# 构建ARM64版本
log_info "构建ARM64版本..."
# 对于ARM64，我们需要使用交叉编译环境
# 这里我们使用Docker来确保环境一致性
build_arm64_with_docker() {
    log_info "使用Docker构建ARM64版本..."
    
    # 创建Dockerfile
    cat > Dockerfile.arm64 << EOF
FROM python:3.10-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y \\
    build-essential \\
    cmake \\
    pkg-config \\
    libasound2-dev \\
    portaudio19-dev \\
    libssl-dev \\
    libffi-dev \\
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 安装Python依赖
RUN pip install --upgrade pip
RUN pip install -r requirements-desktop.txt
RUN pip install pyinstaller

# 创建PyInstaller配置
RUN echo '$(cat translate_chat.spec)' > translate_chat.spec

# 执行打包
RUN pyinstaller --clean translate_chat.spec

# 创建输出目录
RUN mkdir -p /output
RUN cp -r dist/* /output/

# 设置输出卷
VOLUME /output
EOF
    
    # 构建Docker镜像
    log_info "构建Docker镜像..."
    docker build -f Dockerfile.arm64 -t translate-chat-arm64 .
    
    # 运行Docker容器并复制结果
    log_info "运行Docker容器..."
    docker run --rm -v "$(pwd)/$DIST_DIR/arm64:/output" translate-chat-arm64
    
    # 清理Docker镜像
    log_info "清理Docker镜像..."
    docker rmi translate-chat-arm64
    
    # 创建压缩包
    cd "$DIST_DIR/arm64"
    tar -czf "../translate-chat-arm64-$(date +%Y%m%d).tar.gz" *
    cd ../..
    
    log_success "ARM64版本构建完成"
}

build_arm64_with_docker
echo ""

# 构建完成
echo "==== 5. 构建完成 ===="
log_success "所有架构构建完成！"
echo ""

# 显示构建结果
echo "==== 构建结果 ===="
log_info "构建目录: $BUILD_DIR"
log_info "发布目录: $DIST_DIR"
echo ""

log_info "发布包列表:"
ls -la "$DIST_DIR"/*.tar.gz 2>/dev/null || log_warning "未找到发布包"

echo ""
log_info "各架构构建结果:"
for arch_dir in "$DIST_DIR"/*/; do
    if [[ -d "$arch_dir" ]]; then
        arch_name=$(basename "$arch_dir")
        log_info "  $arch_name: $(ls -la "$arch_dir" | wc -l) 个文件"
    fi
done

echo ""
log_success "跨平台构建脚本执行完成！"
echo "结束时间: $(date)" 