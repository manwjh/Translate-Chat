# SDL2 本地文件管理指南 / SDL2 Local File Management Guide

## 概述 / Overview

为了加快Android应用的构建速度，避免在构建过程中重复下载SDL2相关文件，我们提供了智能的本地文件管理解决方案。

**支持平台 / Supported Platforms：**
- ✅ macOS (Intel/Apple Silicon)
- ✅ Ubuntu Linux

## 支持的SDL2文件 / Supported SDL2 Files

- `SDL2-2.28.5.tar` - SDL2核心库 / SDL2 Core Library
- `SDL2_image-2.8.0.tar` - SDL2图像处理库 / SDL2 Image Processing Library
- `SDL2_mixer-2.6.3.tar` - SDL2音频混合库 / SDL2 Audio Mixing Library
- `SDL2_ttf-2.20.2.tar` - SDL2字体渲染库 / SDL2 Font Rendering Library

## 使用方法 / Usage

### 智能SDL2文件管理 / Smart SDL2 File Management

使用合并后的管理脚本，实现先检查后下载的智能管理：

```bash
# 检查并下载SDL2文件
./scripts/sdl2_local_manager.sh
```

**脚本功能 / Script Features：**
- 🔍 **智能检查** - 检查 `/tmp` 目录下是否已存在SDL2文件
- ⬇️ **按需下载** - 只下载缺失的文件，避免重复下载
- 🔄 **重试机制** - 下载失败时自动重试，提高成功率
- 🌐 **官方源** - 使用GitHub官方源，确保文件完整性
- 📊 **状态统计** - 显示已存在和缺失文件的数量

### 构建Android应用 / Build Android Application

运行构建脚本，系统会自动优先使用本地文件：

```bash
# macOS
./scripts/build_android_macos.sh

# Ubuntu
./scripts/build_android_ubuntu.sh
```

## 工作流程 / Workflow

### 第一步：检查现有文件 / Step 1: Check Existing Files
脚本首先检查 `/tmp` 目录下是否已存在所需的SDL2文件，并显示文件状态统计。

### 第二步：智能下载 / Step 2: Smart Download
- 如果所有文件都已存在，脚本直接退出并提示用户
- 如果存在缺失文件，脚本只下载缺失的文件
- 下载过程中包含重试机制，确保下载成功率

### 第三步：最终验证 / Step 3: Final Verification
下载完成后，脚本会进行最终验证并显示所有文件的状态。

## 环境变量配置 / Environment Variables

构建脚本会自动设置以下环境变量：

- `SDL2_LOCAL_PATH=/tmp` - SDL2本地文件根目录 / SDL2 Local File Root Directory
- `SDL2_MIXER_LOCAL_PATH=/tmp/SDL2_mixer-2.6.3.tar` - SDL2_mixer本地文件路径
- `SDL2_IMAGE_LOCAL_PATH=/tmp/SDL2_image-2.8.0.tar` - SDL2_image本地文件路径
- `SDL2_TTF_LOCAL_PATH=/tmp/SDL2_ttf-2.20.2.tar` - SDL2_ttf本地文件路径

## 文件位置 / File Locations

所有SDL2本地文件应放置在 `/tmp` 目录下：

```
/tmp/
├── SDL2-2.28.5.tar
├── SDL2_image-2.8.0.tar
├── SDL2_mixer-2.6.3.tar
└── SDL2_ttf-2.20.2.tar
```

## 优势 / Advantages

1. **加快构建速度** - 避免重复下载大文件 / Speed up build process
2. **网络稳定性** - 减少对网络连接的依赖 / Reduce network dependency
3. **版本控制** - 确保使用特定版本的SDL2库 / Version control
4. **离线构建** - 支持完全离线环境下的构建 / Offline build support
5. **智能管理** - 先检查后下载，避免不必要的网络请求 / Smart management

## 注意事项 / Notes

1. 确保 `/tmp` 目录有足够的磁盘空间 / Ensure sufficient disk space in `/tmp`
2. 文件权限应设置为可读（644） / Set file permissions to readable (644)
3. 如果本地文件损坏，构建脚本会自动从网络下载 / Build script will auto-download if local files are corrupted
4. 建议定期更新本地文件以获取最新的安全补丁 / Regular updates recommended for security patches
5. 脚本支持双语输出，便于不同语言环境的用户使用 / Bilingual output support

## 故障排除 / Troubleshooting

### 文件下载失败 / Download Failure
```bash
# 手动下载单个文件 / Manual download single file
curl -L -o /tmp/SDL2_mixer-2.6.3.tar https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.6.3/SDL2_mixer-2.6.3.tar.gz
```

### 权限问题 / Permission Issues
```bash
# 修复文件权限 / Fix file permissions
chmod 644 /tmp/SDL2_*.tar
```

### 磁盘空间不足 / Insufficient Disk Space
```bash
# 检查磁盘空间 / Check disk space
df -h /tmp
```

### 脚本执行权限 / Script Execution Permission
```bash
# 添加执行权限 / Add execution permission
chmod +x scripts/sdl2_local_manager.sh
```

## 更新日志 / Changelog

### v1.0.0 (2025/1/27)
- 🔄 **脚本合并** - 将 `download_sdl2_local.sh` 和 `sdl2_local_setup.sh` 合并为 `sdl2_local_manager.sh`
- 🧠 **智能检查** - 实现先检查后下载的智能管理逻辑
- 🌐 **双语支持** - 添加中英文双语输出
- 📊 **状态统计** - 显示文件存在状态统计
- 🔄 **重试机制** - 改进下载重试机制
- 📝 **文档更新** - 更新使用说明和故障排除指南 