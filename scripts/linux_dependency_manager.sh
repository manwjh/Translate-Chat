#!/bin/bash
# Translate Chat - Linux 桌面应用依赖管理脚本
# 文件名(File): linux_dependency_manager.sh
# 版本(Version): v2.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): 下载和准备Linux桌面应用打包所需的依赖包 - 移除Android支持

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - Linux 桌面应用依赖管理脚本 v2.0.0 ===="
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

# 创建依赖目录
mkdir -p build/linux/dependencies
cd build/linux/dependencies

echo "==== 1. 下载Linux系统依赖包 ===="
log_info "下载Linux系统依赖包..."

# 定义需要下载的依赖包
LINUX_DEPS=(
    # 基础库
    "libssl3_3.0.2-0ubuntu1.12_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl3_3.0.2-0ubuntu1.12_amd64.deb"
    "libffi8_3.4.2-4_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/libf/libffi/libffi8_3.4.2-4_amd64.deb"
    
    # 图像处理库
    "libjpeg8_8c-2ubuntu10_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg8_8c-2ubuntu10_amd64.deb"
    "libpng16-16_1.6.37-3build5_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng1.6/libpng16-16_1.6.37-3build5_amd64.deb"
    "libfreetype6_2.11.1+dfsg-1ubuntu4.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/f/freetype/libfreetype6_2.11.1+dfsg-1ubuntu4.1_amd64.deb"
    
    # 音频库
    "libportaudio2_19.7.0-1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/p/portaudio19/libportaudio2_19.7.0-1_amd64.deb"
    "libasound2_1.2.4-1.1ubuntu4_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/a/alsa-lib/libasound2_1.2.4-1.1ubuntu4_amd64.deb"
    "libpulse0_15.99.1+dfsg1-1ubuntu2.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/p/pulseaudio/libpulse0_15.99.1+dfsg1-1ubuntu2.1_amd64.deb"
    "libjack-jackd2-0_1.9.20~dfsg-1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/main/j/jackd2/libjack-jackd2-0_1.9.20~dfsg-1_amd64.deb"
    
    # FFmpeg库
    "libavcodec58_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavcodec58_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libavformat58_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavformat58_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libavdevice58_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavdevice58_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libavutil56_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavutil56_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libswscale5_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libswscale5_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libavfilter7_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavfilter7_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libavresample4_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libavresample4_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libpostproc55_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libpostproc55_4.4.2-0ubuntu0.22.04.1_amd64.deb"
    "libswresample3_4.4.2-0ubuntu0.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/f/ffmpeg/libswresample3_4.4.2-0ubuntu0.22.04.1_amd64.deb"
)

# 下载系统依赖包
for dep in "${LINUX_DEPS[@]}"; do
    IFS='|' read -r filename url <<< "$dep"
    
    if [[ -f "$filename" ]]; then
        log_success "已存在: $filename"
    else
        log_info "下载: $filename"
        for attempt in 1 2 3; do
            if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "$filename" "$url"; then
                log_success "下载完成: $filename"
                break
            else
                log_warning "第 $attempt 次下载失败，重试..."
                if [[ $attempt -eq 3 ]]; then
                    log_error "下载失败: $filename (已重试3次)"
                    log_info "请手动下载: curl -L -o $filename $url"
                    exit 1
                fi
                sleep 2
            fi
        done
    fi
done

echo ""
echo "==== 2. 下载Python依赖包 ===="
log_info "下载Python依赖包..."

# 创建Python依赖目录
mkdir -p python_deps
cd python_deps

# 定义Python依赖包
PYTHON_DEPS=(
    "kivy-2.3.0-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/K/Kivy/Kivy-2.3.0-py3-none-any.whl"
    "kivymd-1.1.1-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/K/KivyMD/KivyMD-1.1.1-py3-none-any.whl"
    "websocket_client-1.6.4-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/w/websocket_client/websocket_client-1.6.4-py3-none-any.whl"
    "aiohttp-3.9.1-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/a/aiohttp/aiohttp-3.9.1-cp39-cp39-linux_x86_64.whl"
    "cryptography-41.0.7-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/c/cryptography/cryptography-41.0.7-cp39-cp39-linux_x86_64.whl"
    "pyaudio-0.2.11-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/P/PyAudio/PyAudio-0.2.11-cp39-cp39-linux_x86_64.whl"
    "requests-2.31.0-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/r/requests/requests-2.31.0-py3-none-any.whl"
    "numpy-1.21.6-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/n/numpy/numpy-1.21.6-cp39-cp39-linux_x86_64.whl"
    "scipy-1.7.3-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/s/scipy/scipy-1.7.3-cp39-cp39-linux_x86_64.whl"
    "webrtcvad-2.0.10-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/w/webrtcvad/webrtcvad-2.0.10-py3-none-any.whl"
    "resemblyzer-0.1.1-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/r/resemblyzer/resemblyzer-0.1.1-py3-none-any.whl"
)

for dep in "${PYTHON_DEPS[@]}"; do
    IFS='|' read -r filename url <<< "$dep"
    
    if [[ -f "$filename" ]]; then
        log_success "已存在: $filename"
    else
        log_info "下载: $filename"
        for attempt in 1 2 3; do
            if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "$filename" "$url"; then
                log_success "下载完成: $filename"
                break
            else
                log_warning "第 $attempt 次下载失败，重试..."
                if [[ $attempt -eq 3 ]]; then
                    log_error "下载失败: $filename (已重试3次)"
                    log_info "请手动下载: curl -L -o $filename $url"
                    exit 1
                fi
                sleep 2
            fi
        done
    fi
done

cd ..

echo ""
echo "==== 3. 下载打包工具 ===="
log_info "下载打包工具..."

# 下载AppImage工具
APPIMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
APPIMAGE_TOOL_FILE="appimagetool-x86_64.AppImage"

if [[ -f "$APPIMAGE_TOOL_FILE" ]]; then
    log_success "已存在: $APPIMAGE_TOOL_FILE"
else
    log_info "下载: $APPIMAGE_TOOL_FILE"
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "$APPIMAGE_TOOL_FILE" "$APPIMAGE_TOOL_URL"; then
            log_success "下载完成: $APPIMAGE_TOOL_FILE"
            chmod +x "$APPIMAGE_TOOL_FILE"
            break
        else
            log_warning "第 $attempt 次下载失败，重试..."
            if [[ $attempt -eq 3 ]]; then
                log_error "下载失败: $APPIMAGE_TOOL_FILE (已重试3次)"
                log_info "请手动下载: curl -L -o $APPIMAGE_TOOL_FILE $APPIMAGE_TOOL_URL"
                exit 1
            fi
            sleep 2
        fi
    done
fi

# 下载PyInstaller
PYINSTALLER_URL="https://files.pythonhosted.org/packages/py3/P/PyInstaller/PyInstaller-5.13.2-py3-none-any.whl"
PYINSTALLER_FILE="pyinstaller-5.13.2-py3-none-any.whl"

if [[ -f "$PYINSTALLER_FILE" ]]; then
    log_success "已存在: $PYINSTALLER_FILE"
else
    log_info "下载: $PYINSTALLER_FILE"
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "$PYINSTALLER_FILE" "$PYINSTALLER_URL"; then
            log_success "下载完成: $PYINSTALLER_FILE"
            break
        else
            log_warning "第 $attempt 次下载失败，重试..."
            if [[ $attempt -eq 3 ]]; then
                log_error "下载失败: $PYINSTALLER_FILE (已重试3次)"
                log_info "请手动下载: curl -L -o $PYINSTALLER_FILE $PYINSTALLER_URL"
                exit 1
            fi
            sleep 2
        fi
    done
fi

echo ""
echo "==== 4. 创建安装脚本 ===="
log_info "创建安装脚本..."

# 创建安装脚本
cat > install_dependencies.sh << 'EOF'
#!/bin/bash
# Linux依赖安装脚本

set -e

echo "==== 安装Linux系统依赖 ===="

# 安装系统依赖包
echo "安装系统依赖包..."
sudo dpkg -i *.deb
sudo apt-get install -f

echo "==== 安装Python依赖 ===="

# 安装Python依赖
echo "安装Python依赖..."
pip3 install python_deps/*.whl

# 安装PyInstaller
echo "安装PyInstaller..."
pip3 install pyinstaller-5.13.2-py3-none-any.whl

echo "==== 依赖安装完成 ===="
echo "现在可以运行构建脚本了"
EOF

chmod +x install_dependencies.sh

# 创建依赖清单
cat > dependencies.txt << 'EOF'
# Translate Chat - Linux 桌面应用依赖清单
# 版本: v2.0.0
# 创建日期: 2025/7/25

## 系统依赖包 (Ubuntu 22.04)
### 基础库
- libssl3_3.0.2-0ubuntu1.12_amd64.deb
- libffi8_3.4.2-4_amd64.deb

### 图像处理库
- libjpeg8_8c-2ubuntu10_amd64.deb
- libpng16-16_1.6.37-3build5_amd64.deb
- libfreetype6_2.11.1+dfsg-1ubuntu4.1_amd64.deb

### 音频库
- libportaudio2_19.7.0-1_amd64.deb
- libasound2_1.2.4-1.1ubuntu4_amd64.deb
- libpulse0_15.99.1+dfsg1-1ubuntu2.1_amd64.deb
- libjack-jackd2-0_1.9.20~dfsg-1_amd64.deb

### FFmpeg库
- libavcodec58_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libavformat58_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libavdevice58_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libavutil56_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libswscale5_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libavfilter7_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libavresample4_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libpostproc55_4.4.2-0ubuntu0.22.04.1_amd64.deb
- libswresample3_4.4.2-0ubuntu0.22.04.1_amd64.deb

## Python依赖包 (Python 3.9)
- kivy-2.3.0-cp39-cp39-linux_x86_64.whl
- kivymd-1.1.1-py3-none-any.whl
- websocket_client-1.6.4-py3-none-any.whl
- aiohttp-3.9.1-cp39-cp39-linux_x86_64.whl
- cryptography-41.0.7-cp39-cp39-linux_x86_64.whl
- pyaudio-0.2.11-cp39-cp39-linux_x86_64.whl
- requests-2.31.0-py3-none-any.whl
- numpy-1.21.6-cp39-cp39-linux_x86_64.whl
- scipy-1.7.3-cp39-cp39-linux_x86_64.whl
- webrtcvad-2.0.10-py3-none-any.whl
- resemblyzer-0.1.1-py3-none-any.whl

## 打包工具
- appimagetool-x86_64.AppImage
- pyinstaller-5.13.2-py3-none-any.whl

## 使用说明
1. 系统依赖包用于在Linux系统中安装必要的库文件
2. Python依赖包用于在Docker容器中安装Python模块
3. 打包工具用于创建AppImage和可执行文件

## 安装命令示例
### 系统依赖包安装
```bash
sudo dpkg -i *.deb
sudo apt-get install -f  # 修复依赖关系
```

### Python依赖包安装
```bash
pip install python_deps/*.whl
```

### 打包工具安装
```bash
pip install pyinstaller-5.13.2-py3-none-any.whl
chmod +x appimagetool-x86_64.AppImage
```

## 注意事项
- 此版本已移除Android相关依赖
- 专注桌面端体验，支持ARM和x86_64架构
- 简化了依赖管理，提高构建效率
EOF

echo ""
echo "==== 5. 下载完成总结 ===="
log_success "所有依赖包下载完成！"
echo ""
echo "下载位置: $(pwd)"
echo ""
echo "包含内容:"
echo "- 系统依赖包: $(ls *.deb | wc -l) 个"
echo "- Python依赖包: $(ls python_deps/*.whl | wc -l) 个"
echo "- 打包工具: 2 个"
echo ""
echo "使用方法:"
echo "1. 将整个dependencies目录复制到Linux系统"
echo "2. 运行: ./install_dependencies.sh"
echo "3. 开始构建Linux桌面应用"
echo ""
echo "注意事项:"
echo "- 此版本已移除Android相关依赖"
echo "- 专注桌面端体验，支持ARM和x86_64架构"
echo "- 简化了依赖管理，提高构建效率"

cd ../.. 