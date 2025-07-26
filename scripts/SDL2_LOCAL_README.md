# SDL2 本地文件优化指南

## 概述

为了加快Android应用的构建速度，避免在构建过程中重复下载SDL2相关文件，我们提供了本地文件优先的解决方案。

**支持平台：**
- ✅ macOS (Intel/Apple Silicon)
- ✅ Ubuntu Linux

## 支持的SDL2文件

- `SDL2-2.28.5.tar` - SDL2核心库
- `SDL2_image-2.8.0.tar` - SDL2图像处理库
- `SDL2_mixer-2.6.3.tar` - SDL2音频混合库
- `SDL2_ttf-2.20.2.tar` - SDL2字体渲染库

## 使用方法

### 1. 下载SDL2本地文件

运行下载脚本，将所有SDL2文件下载到 `/tmp` 目录：

```bash
./scripts/download_sdl2_local.sh
```

### 2. 检查本地文件状态

运行检查脚本，查看本地文件状态：

```bash
./scripts/sdl2_local_setup.sh
```

### 3. 构建Android应用

运行构建脚本，系统会自动优先使用本地文件：

```bash
# macOS
./scripts/build_android_macos.sh

# Ubuntu
./scripts/build_android_ubuntu.sh
```

## 环境变量配置

构建脚本会自动设置以下环境变量：

- `SDL2_LOCAL_PATH=/tmp` - SDL2本地文件根目录
- `SDL2_MIXER_LOCAL_PATH=/tmp/SDL2_mixer-2.6.3.tar` - SDL2_mixer本地文件路径
- `SDL2_IMAGE_LOCAL_PATH=/tmp/SDL2_image-2.8.0.tar` - SDL2_image本地文件路径
- `SDL2_TTF_LOCAL_PATH=/tmp/SDL2_ttf-2.20.2.tar` - SDL2_ttf本地文件路径

## 文件位置

所有SDL2本地文件应放置在 `/tmp` 目录下：

```
/tmp/
├── SDL2-2.28.5.tar
├── SDL2_image-2.8.0.tar
├── SDL2_mixer-2.6.3.tar
└── SDL2_ttf-2.20.2.tar
```

## 优势

1. **加快构建速度** - 避免重复下载大文件
2. **网络稳定性** - 减少对网络连接的依赖
3. **版本控制** - 确保使用特定版本的SDL2库
4. **离线构建** - 支持完全离线环境下的构建

## 注意事项

1. 确保 `/tmp` 目录有足够的磁盘空间
2. 文件权限应设置为可读（644）
3. 如果本地文件损坏，构建脚本会自动从网络下载
4. 建议定期更新本地文件以获取最新的安全补丁

## 故障排除

### 文件下载失败
```bash
# 手动下载单个文件
curl -L -o /tmp/SDL2_mixer-2.6.3.tar https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz
```

### 权限问题
```bash
# 修复文件权限
chmod 644 /tmp/SDL2_*.tar
```

### 磁盘空间不足
```bash
# 检查磁盘空间
df -h /tmp
``` 