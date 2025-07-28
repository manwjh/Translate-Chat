#!/bin/bash
# Translate Chat - Linux 桌面应用依赖管理脚本
# 文件名(File): linux_dependency_manager.sh
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): 下载和准备Linux桌面应用打包所需的依赖包

set -e

# 引入通用打包工具函数
source ./scripts/common_build_utils.sh

echo "==== Translate Chat - Linux 桌面应用依赖管理脚本 v1.0.0 ===="
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
    
    # SDL2库
    "libsdl2-2.0-0_2.0.20+dfsg-2ubuntu1.22.04.1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/libs/libsdl2/libsdl2-2.0-0_2.0.20+dfsg-2ubuntu1.22.04.1_amd64.deb"
    "libsdl2-image-2.0-0_2.6.2-1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/libs/libsdl2-image/libsdl2-image-2.0-0_2.6.2-1_amd64.deb"
    "libsdl2-mixer-2.0-0_2.6.2-1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/libs/libsdl2-mixer/libsdl2-mixer-2.0-0_2.6.2-1_amd64.deb"
    "libsdl2-ttf-2.0-0_2.20.1-1_amd64.deb|http://archive.ubuntu.com/ubuntu/pool/universe/libs/libsdl2-ttf/libsdl2-ttf-2.20.1-1_amd64.deb"
    
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

# 下载依赖包
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

# 下载Python依赖包
PYTHON_DEPS=(
    "kivy-2.3.0-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/K/Kivy/Kivy-2.3.0-py3-none-any.whl"
    "kivymd-1.1.1-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/K/KivyMD/KivyMD-1.1.1-py3-none-any.whl"
    "websocket_client-1.6.4-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/w/websocket_client/websocket_client-1.6.4-py3-none-any.whl"
    "aiohttp-3.9.1-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/a/aiohttp/aiohttp-3.9.1-cp39-cp39-linux_x86_64.whl"
    "cryptography-41.0.7-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/c/cryptography/cryptography-41.0.7-cp39-cp39-linux_x86_64.whl"
    "pyaudio-0.2.11-cp39-cp39-linux_x86_64.whl|https://files.pythonhosted.org/packages/py3/P/PyAudio/PyAudio-0.2.11-cp39-cp39-linux_x86_64.whl"
    "requests-2.31.0-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/r/requests/requests-2.31.0-py3-none-any.whl"
    "plyer-2.1.0-py3-none-any.whl|https://files.pythonhosted.org/packages/py3/p/plyer/plyer-2.1.0-py3-none-any.whl"
)

cd python_deps

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
log_info "下载Linux打包工具..."

# 下载AppImage工具
if [[ ! -f "appimagetool-x86_64.AppImage" ]]; then
    log_info "下载AppImage工具..."
    APPIMAGE_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "appimagetool-x86_64.AppImage" "$APPIMAGE_URL"; then
            chmod +x appimagetool-x86_64.AppImage
            log_success "AppImage工具下载完成"
            break
        else
            log_warning "第 $attempt 次下载失败，重试..."
            if [[ $attempt -eq 3 ]]; then
                log_error "AppImage工具下载失败"
                exit 1
            fi
            sleep 2
        fi
    done
else
    log_success "AppImage工具已存在"
fi

# 下载PyInstaller
if [[ ! -f "pyinstaller-5.13.2-py3-none-any.whl" ]]; then
    log_info "下载PyInstaller..."
    PYINSTALLER_URL="https://files.pythonhosted.org/packages/py3/P/PyInstaller/PyInstaller-5.13.2-py3-none-any.whl"
    
    for attempt in 1 2 3; do
        if curl -L --retry 3 --retry-delay 2 --connect-timeout 30 -o "pyinstaller-5.13.2-py3-none-any.whl" "$PYINSTALLER_URL"; then
            log_success "PyInstaller下载完成"
            break
        else
            log_warning "第 $attempt 次下载失败，重试..."
            if [[ $attempt -eq 3 ]]; then
                log_error "PyInstaller下载失败"
                exit 1
            fi
            sleep 2
        fi
    done
else
    log_success "PyInstaller已存在"
fi

echo ""
echo "==== 4. 创建依赖清单 ===="
log_info "创建依赖清单..."

# 创建依赖清单文件
cat > dependencies.txt << 'EOF'
# Translate Chat - Linux 桌面应用依赖清单
# 文件名(File): dependencies.txt
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/7/25
# 简介(Description): Linux桌面应用打包所需的依赖包清单

## 系统依赖包 (Ubuntu 22.04)
### 基础库
- libssl3_3.0.2-0ubuntu1.12_amd64.deb
- libffi8_3.4.2-4_amd64.deb

### 图像处理库
- libjpeg8_8c-2ubuntu10_amd64.deb
- libpng16-16_1.6.37-3build5_amd64.deb
- libfreetype6_2.11.1+dfsg-1ubuntu4.1_amd64.deb

### SDL2库
- libsdl2-2.0-0_2.0.20+dfsg-2ubuntu1.22.04.1_amd64.deb
- libsdl2-image-2.0-0_2.6.2-1_amd64.deb
- libsdl2-mixer-2.0-0_2.6.2-1_amd64.deb
- libsdl2-ttf-2.0-0_2.20.1-1_amd64.deb

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
- plyer-2.1.0-py3-none-any.whl

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
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
pip install pyinstaller-5.13.2-py3-none-any.whl
```
EOF

log_success "依赖清单创建完成: dependencies.txt"

echo ""
echo "==== 5. 创建安装脚本 ===="
log_info "创建自动安装脚本..."

# 创建Linux依赖安装脚本
cat > install_dependencies.sh << 'EOF'
#!/bin/bash
# Linux依赖自动安装脚本

set -e

echo "==== 安装Linux依赖包 ===="

# 安装系统依赖包
echo "安装系统依赖包..."
sudo dpkg -i *.deb
sudo apt-get install -f

# 安装Python依赖包
echo "安装Python依赖包..."
cd python_deps
pip install *.whl
cd ..

# 安装打包工具
echo "安装打包工具..."
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
pip install pyinstaller-5.13.2-py3-none-any.whl

echo "依赖安装完成！"
EOF

chmod +x install_dependencies.sh
log_success "安装脚本创建完成: install_dependencies.sh"

# 返回项目根目录
cd ../../..

echo ""
echo "==== 6. 构建完成总结 ===="
log_success "Linux桌面应用依赖管理完成！"
echo ""
log_info "下载的依赖包:"
echo "  - 系统依赖包: $(ls build/linux/dependencies/*.deb | wc -l) 个"
echo "  - Python依赖包: $(ls build/linux/dependencies/python_deps/*.whl | wc -l) 个"
echo "  - 打包工具: 2 个"
echo ""
log_info "文件位置:"
echo "  - 依赖包目录: build/linux/dependencies/"
echo "  - 依赖清单: build/linux/dependencies/dependencies.txt"
echo "  - 安装脚本: build/linux/dependencies/install_dependencies.sh"
echo ""

echo "==== 7. 使用说明 ===="
log_info "Linux依赖包使用说明:"
echo ""
echo "1. 在Linux系统中安装依赖:"
echo "   cd build/linux/dependencies"
echo "   ./install_dependencies.sh"
echo ""
echo "2. 在Docker容器中使用:"
echo "   - 将依赖包复制到Docker容器中"
echo "   - 在Dockerfile中安装依赖包"
echo ""
echo "3. 手动安装:"
echo "   - 系统依赖: sudo dpkg -i *.deb"
echo "   - Python依赖: pip install python_deps/*.whl"
echo ""

echo "==== 依赖管理完成 ===="
echo "结束时间: $(date)"
echo ""

# 显示下载统计信息
echo "==== 下载统计 ===="
log_info "依赖包统计信息:"
echo "  - 系统依赖包:"
for deb in build/linux/dependencies/*.deb; do
    if [[ -f "$deb" ]]; then
        local size=$(du -h "$deb" | cut -f1)
        local filename=$(basename "$deb")
        echo "    - $filename ($size)"
    fi
done

echo "  - Python依赖包:"
for whl in build/linux/dependencies/python_deps/*.whl; do
    if [[ -f "$whl" ]]; then
        local size=$(du -h "$whl" | cut -f1)
        local filename=$(basename "$whl")
        echo "    - $filename ($size)"
    fi
done

echo "  - 打包工具:"
for tool in build/linux/dependencies/appimagetool-* build/linux/dependencies/pyinstaller-*; do
    if [[ -f "$tool" ]]; then
        local size=$(du -h "$tool" | cut -f1)
        local filename=$(basename "$tool")
        echo "    - $filename ($size)"
    fi
done
echo "" 