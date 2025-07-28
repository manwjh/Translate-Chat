#!/bin/bash
# Translate Chat - 快速跨平台构建脚本
# 文件名(File): quick_build.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/27
# 简介(Description): 快速构建x86_64和ARM64版本的简化脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "==== Translate Chat - 快速跨平台构建脚本 ===="
echo "开始时间: $(date)"
echo ""

# 检查系统
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "此脚本仅适用于Linux系统"
    exit 1
fi

# 检查Docker
if ! command -v docker &> /dev/null; then
    log_error "需要安装Docker"
    log_info "安装命令: sudo apt install docker.io"
    exit 1
fi

# 检查Python
if ! command -v python3 &> /dev/null; then
    log_error "需要安装Python3"
    exit 1
fi

# 创建构建目录
BUILD_DIR="quick_build"
DIST_DIR="quick_dist"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

log_success "构建目录准备完成"
echo ""

# 构建x86_64版本
echo "==== 构建 x86_64 版本 ===="
log_info "创建x86_64构建环境..."

# 创建x86_64 Dockerfile
cat > Dockerfile.x86_64 << 'EOF'
FROM python:3.10-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libasound2-dev \
    portaudio19-dev \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# 安装Python依赖
RUN pip install --upgrade pip
RUN pip install -r requirements-desktop.txt
RUN pip install pyinstaller

# 创建PyInstaller配置
RUN cat > translate_chat.spec << 'SPEC_EOF'
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
SPEC_EOF

# 执行打包
RUN pyinstaller --clean translate_chat.spec

# 创建输出目录
RUN mkdir -p /output
RUN cp -r dist/* /output/

VOLUME /output
EOF

# 构建x86_64镜像
log_info "构建x86_64 Docker镜像..."
docker build -f Dockerfile.x86_64 -t translate-chat-x86_64 .

# 运行x86_64容器
log_info "运行x86_64构建容器..."
docker run --rm -v "$(pwd)/$DIST_DIR/x86_64:/output" translate-chat-x86_64

# 创建x86_64压缩包
cd "$DIST_DIR/x86_64"
tar -czf "../translate-chat-x86_64-$(date +%Y%m%d).tar.gz" *
cd ../..

log_success "x86_64版本构建完成"
echo ""

# 构建ARM64版本
echo "==== 构建 ARM64 版本 ===="
log_info "创建ARM64构建环境..."

# 创建ARM64 Dockerfile
cat > Dockerfile.arm64 << 'EOF'
FROM --platform=linux/arm64 python:3.10-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libasound2-dev \
    portaudio19-dev \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# 安装Python依赖
RUN pip install --upgrade pip
RUN pip install -r requirements-desktop.txt
RUN pip install pyinstaller

# 创建PyInstaller配置
RUN cat > translate_chat.spec << 'SPEC_EOF'
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
SPEC_EOF

# 执行打包
RUN pyinstaller --clean translate_chat.spec

# 创建输出目录
RUN mkdir -p /output
RUN cp -r dist/* /output/

VOLUME /output
EOF

# 构建ARM64镜像
log_info "构建ARM64 Docker镜像..."
docker build --platform linux/arm64 -f Dockerfile.arm64 -t translate-chat-arm64 .

# 运行ARM64容器
log_info "运行ARM64构建容器..."
docker run --rm -v "$(pwd)/$DIST_DIR/arm64:/output" translate-chat-arm64

# 创建ARM64压缩包
cd "$DIST_DIR/arm64"
tar -czf "../translate-chat-arm64-$(date +%Y%m%d).tar.gz" *
cd ../..

log_success "ARM64版本构建完成"
echo ""

# 清理Docker镜像
log_info "清理Docker镜像..."
docker rmi translate-chat-x86_64 translate-chat-arm64 2>/dev/null || true

# 清理临时文件
rm -f Dockerfile.x86_64 Dockerfile.arm64

# 显示结果
echo "==== 构建完成 ===="
log_success "所有版本构建完成！"
echo ""

log_info "发布包:"
ls -la "$DIST_DIR"/*.tar.gz 2>/dev/null || log_warning "未找到发布包"

echo ""
log_info "构建目录结构:"
tree "$DIST_DIR" 2>/dev/null || ls -la "$DIST_DIR"

echo ""
log_success "快速构建脚本执行完成！"
echo "结束时间: $(date)" 