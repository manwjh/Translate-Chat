#!/bin/bash
# Translate Chat - Linux 桌面应用打包自动化脚本
# 文件名(File): build_linux_desktop.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): 在macOS上交叉编译Linux桌面应用，支持AppImage和deb包格式

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - Linux 桌面应用打包脚本 v1.0.0 ===="
echo "开始时间: $(date)"
echo ""

# 检查是否为macOS系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "此脚本仅适用于macOS系统"
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
log_info "  系统: macOS $(sw_vers -productVersion)"
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

# 检查Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装，请先安装Docker Desktop"
    log_info "下载地址: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    log_error "Docker未运行，请启动Docker Desktop"
    exit 1
fi

log_success "Docker环境检查通过"

# 配置pip镜像
echo "==== 2. 配置pip镜像 ===="
setup_pip_mirror

# 创建Python虚拟环境
echo "==== 3. 创建Python虚拟环境 ===="
create_venv "$PYTHON_CMD" "venv"

# 安装Python依赖
echo "==== 4. 安装Python依赖 ===="
install_python_deps "venv"

# 激活虚拟环境
source venv/bin/activate

# 安装Linux打包工具
echo "==== 5. 安装Linux打包工具 ===="
log_info "安装Linux打包相关工具..."

# 安装PyInstaller
pip install pyinstaller==5.13.2

# 安装AppImage工具
if ! command -v appimagetool &> /dev/null; then
    log_info "下载AppImage工具..."
    mkdir -p tools
    cd tools
    
    # 下载AppImage工具
    if [[ "$(uname -m)" == "arm64" ]]; then
        APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    else
        APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    fi
    
    curl -L -o appimagetool "$APPIMAGE_TOOL_URL"
    chmod +x appimagetool
    sudo mv appimagetool /usr/local/bin/
    cd ..
    log_success "AppImage工具安装完成"
else
    log_success "AppImage工具已安装"
fi

# 创建Docker构建环境
echo "==== 6. 创建Docker构建环境 ===="
log_info "创建Linux交叉编译环境..."

# 创建Dockerfile
cat > Dockerfile.linux << 'EOF'
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 更新系统并安装基础工具
RUN apt-get update && apt-get install -y \
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
    libgif-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-ttf-dev \
    libportaudio2 \
    portaudio19-dev \
    libasound2-dev \
    libpulse-dev \
    libjack-jackd2-dev \
    libavcodec-dev \
    libavformat-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libavfilter-dev \
    libavresample-dev \
    libpostproc-dev \
    libswresample-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装PyInstaller
RUN pip3 install --no-cache-dir pyinstaller==5.13.2

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 创建虚拟环境
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# 安装Python依赖
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements-desktop.txt

# 创建构建脚本
RUN echo '#!/bin/bash\n\
set -e\n\
echo "开始构建Linux应用..."\n\
\n\
# 清理之前的构建\n\
rm -rf build dist\n\
\n\
# 使用PyInstaller构建\n\
pyinstaller \\\n\
    --onefile \\\n\
    --windowed \\\n\
    --name="translate-chat" \\\n\
    --add-data="assets:assets" \\\n\
    --add-data="ui:ui" \\\n\
    --add-data="utils:utils" \\\n\
    --hidden-import=kivy \\\n\
    --hidden-import=kivymd \\\n\
    --hidden-import=plyer \\\n\
    --hidden-import=websocket \\\n\
    --hidden-import=aiohttp \\\n\
    --hidden-import=cryptography \\\n\
    --hidden-import=pyaudio \\\n\
    --hidden-import=asr_client \\\n\
    --hidden-import=translator \\\n\
    --hidden-import=config_manager \\\n\
    --hidden-import=speaker_change_detector \\\n\
    --hidden-import=lang_detect \\\n\
    --hidden-import=hotwords \\\n\
    --hidden-import=audio_capture \\\n\
    --hidden-import=audio_capture_pyaudio \\\n\
    --hidden-import=audio_capture_plyer \\\n\
    main.py\n\
\n\
echo "构建完成！"\n\
echo "可执行文件位置: dist/translate-chat"\n\
' > /app/build_linux.sh

RUN chmod +x /app/build_linux.sh

# 设置入口点
ENTRYPOINT ["/app/build_linux.sh"]
EOF

log_success "Docker构建环境创建完成"

# 构建Docker镜像
echo "==== 7. 构建Docker镜像 ===="
log_info "构建Linux交叉编译Docker镜像..."

if docker build -f Dockerfile.linux -t translate-chat-linux-builder .; then
    log_success "Docker镜像构建成功"
else
    log_error "Docker镜像构建失败"
    exit 1
fi

# 在Docker中构建应用
echo "==== 8. 在Docker中构建应用 ===="
log_info "在Docker容器中构建Linux应用..."

# 创建构建目录
mkdir -p build/linux

# 运行Docker容器进行构建
if docker run --rm \
    -v "$(pwd)/build/linux:/app/build" \
    -v "$(pwd)/dist:/app/dist" \
    translate-chat-linux-builder; then
    log_success "Linux应用构建成功"
else
    log_error "Linux应用构建失败"
    exit 1
fi

# 创建AppImage
echo "==== 9. 创建AppImage包 ===="
log_info "创建AppImage包..."

# 创建AppDir结构
mkdir -p build/linux/AppDir
mkdir -p build/linux/AppDir/usr/bin
mkdir -p build/linux/AppDir/usr/share/applications
mkdir -p build/linux/AppDir/usr/share/icons/hicolor/256x256/apps

# 复制可执行文件
cp dist/translate-chat build/linux/AppDir/usr/bin/

# 创建桌面文件
cat > build/linux/AppDir/usr/share/applications/translate-chat.desktop << 'EOF'
[Desktop Entry]
Name=Translate Chat
Comment=Real-time voice translation application
Exec=translate-chat
Icon=translate-chat
Terminal=false
Type=Application
Categories=AudioVideo;Audio;Network;
EOF

# 创建图标（如果有的话）
if [[ -f "assets/icon.png" ]]; then
    cp assets/icon.png build/linux/AppDir/usr/share/icons/hicolor/256x256/apps/translate-chat.png
else
    # 创建一个简单的占位图标
    log_warning "未找到应用图标，将使用默认图标"
    # 这里可以生成一个简单的图标或下载一个默认图标
fi

# 创建AppRun脚本
cat > build/linux/AppDir/AppRun << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
exec "$(dirname "$0")/usr/bin/translate-chat" "$@"
EOF

chmod +x build/linux/AppDir/AppRun

# 创建AppImage
if appimagetool build/linux/AppDir dist/Translate-Chat-x86_64.AppImage; then
    log_success "AppImage创建成功: dist/Translate-Chat-x86_64.AppImage"
else
    log_error "AppImage创建失败"
fi

# 创建deb包
echo "==== 10. 创建deb包 ===="
log_info "创建deb包..."

# 创建deb包结构
mkdir -p build/linux/deb/DEBIAN
mkdir -p build/linux/deb/usr/bin
mkdir -p build/linux/deb/usr/share/applications
mkdir -p build/linux/deb/usr/share/icons/hicolor/256x256/apps

# 复制文件
cp dist/translate-chat build/linux/deb/usr/bin/
cp build/linux/AppDir/usr/share/applications/translate-chat.desktop build/linux/deb/usr/share/applications/
if [[ -f "build/linux/AppDir/usr/share/icons/hicolor/256x256/apps/translate-chat.png" ]]; then
    cp build/linux/AppDir/usr/share/icons/hicolor/256x256/apps/translate-chat.png build/linux/deb/usr/share/icons/hicolor/256x256/apps/
fi

# 创建控制文件
cat > build/linux/deb/DEBIAN/control << 'EOF'
Package: translate-chat
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Depends: libc6, libssl3, libffi8, libjpeg8, libpng16-16, libfreetype6, libsdl2-2.0-0, libsdl2-image-2.0-0, libsdl2-mixer-2.0-0, libsdl2-ttf-2.0-0, libportaudio2, libasound2, libpulse0, libjack-jackd2-0, libavcodec58, libavformat58, libavdevice58, libavutil56, libswscale5, libavfilter7, libavresample4, libpostproc55, libswresample3
Maintainer: Translate Chat Team <support@translatechat.org>
Description: Real-time voice translation application
 Translate Chat is a powerful real-time voice translation
 application that supports multiple languages and provides
 seamless communication across language barriers.
EOF

# 创建deb包
if dpkg-deb --build build/linux/deb dist/translate-chat_1.0.0_amd64.deb; then
    log_success "deb包创建成功: dist/translate-chat_1.0.0_amd64.deb"
else
    log_warning "deb包创建失败，可能需要安装dpkg-deb工具"
fi

# 清理构建文件
echo "==== 11. 清理构建文件 ===="
log_info "清理临时构建文件..."

# 清理Docker镜像
docker rmi translate-chat-linux-builder 2>/dev/null || true

# 清理构建目录
rm -rf build/linux
rm -f Dockerfile.linux

log_success "清理完成"

# 检查构建结果
echo "==== 12. 检查构建结果 ===="
if [[ -f "dist/translate-chat" ]]; then
    log_success "Linux可执行文件构建成功: dist/translate-chat"
    ls -lh dist/translate-chat
else
    log_error "Linux可执行文件构建失败"
    exit 1
fi

if [[ -f "dist/Translate-Chat-x86_64.AppImage" ]]; then
    log_success "AppImage包构建成功: dist/Translate-Chat-x86_64.AppImage"
    ls -lh dist/Translate-Chat-x86_64.AppImage
fi

if [[ -f "dist/translate-chat_1.0.0_amd64.deb" ]]; then
    log_success "deb包构建成功: dist/translate-chat_1.0.0_amd64.deb"
    ls -lh dist/translate-chat_1.0.0_amd64.deb
fi

echo ""
echo "==== 13. 构建完成总结 ===="
log_success "Linux桌面应用构建完成！"
echo ""
log_info "构建产物:"
if [[ -f "dist/translate-chat" ]]; then
    echo "  - 可执行文件: dist/translate-chat"
fi
if [[ -f "dist/Translate-Chat-x86_64.AppImage" ]]; then
    echo "  - AppImage包: dist/Translate-Chat-x86_64.AppImage"
fi
if [[ -f "dist/translate-chat_1.0.0_amd64.deb" ]]; then
    echo "  - deb包: dist/translate-chat_1.0.0_amd64.deb"
fi
echo ""

echo "==== 14. 部署说明 ===="
log_info "Linux应用部署说明:"
echo ""
echo "1. 可执行文件部署:"
echo "   - 将 dist/translate-chat 复制到Linux系统"
echo "   - 确保目标系统安装了必要的依赖库"
echo "   - 运行: ./translate-chat"
echo ""
echo "2. AppImage部署:"
echo "   - 将 dist/Translate-Chat-x86_64.AppImage 复制到Linux系统"
echo "   - 添加执行权限: chmod +x Translate-Chat-x86_64.AppImage"
echo "   - 运行: ./Translate-Chat-x86_64.AppImage"
echo ""
echo "3. deb包部署:"
echo "   - 将 dist/translate-chat_1.0.0_amd64.deb 复制到Ubuntu/Debian系统"
echo "   - 安装: sudo dpkg -i translate-chat_1.0.0_amd64.deb"
echo "   - 修复依赖: sudo apt-get install -f"
echo ""

echo "==== 打包完成 ===="
echo "结束时间: $(date)"
echo ""

# 显示构建统计信息
if [[ -d "dist" ]]; then
    echo "==== 构建统计 ===="
    log_info "构建产物信息:"
    for file in dist/*; do
        if [[ -f "$file" ]]; then
            local size=$(du -h "$file" | cut -f1)
            local filename=$(basename "$file")
            echo "  - $filename ($size)"
        fi
    done
    echo ""
fi 