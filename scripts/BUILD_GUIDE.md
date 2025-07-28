# 构建脚本使用指南

## 概述

本项目提供了多个构建脚本，用于在不同平台上构建Translate-Chat应用。经过优化后，构建系统更加稳定和易用。

## 构建脚本分类

### 1. 已验证的本地构建脚本

#### `local_build_linux.sh` (v2.0.0)
- **用途**: 在Linux x86_64平台上构建Linux应用
- **特点**: 已验证稳定，无需Docker
- **支持**: 创建可执行文件、AppImage、deb包

#### `local_build_macos.sh` (v2.0.0)
- **用途**: 在macOS平台上构建macOS应用
- **特点**: 已验证稳定，支持ARM64和x86_64架构
- **支持**: 创建可执行文件、.app应用包

### 2. 优化的统一构建脚本

#### `unified_build_optimized.sh` (v2.0.0) ⭐ **推荐**
- **用途**: 跨平台统一构建系统
- **特点**: 基于已验证的本地构建脚本，提供更稳定的构建体验
- **支持**: 自动检测平台，智能选择构建方式

### 3. 实验性构建脚本

#### `unified_build_arm&x86_linux.sh` (v1.0.0)
- **用途**: 使用Docker进行跨架构构建
- **特点**: 未完全验证，可能存在稳定性问题
- **支持**: 在macOS上构建Linux应用（x86_64和ARM64）

## 推荐使用方式

### 方案一：使用优化的统一构建脚本（推荐）

```bash
# 在项目根目录运行
cd /path/to/Translate-Chat

# 构建当前平台的应用
./scripts/unified_build_optimized.sh

# 构建特定平台
./scripts/unified_build_optimized.sh linux    # 构建Linux应用
./scripts/unified_build_optimized.sh macos    # 构建macOS应用
./scripts/unified_build_optimized.sh all      # 构建所有平台

# 常用选项
./scripts/unified_build_optimized.sh -t       # 仅测试环境
./scripts/unified_build_optimized.sh -c       # 清理构建缓存
./scripts/unified_build_optimized.sh --no-deps # 跳过依赖安装
```

### 方案二：使用专用本地构建脚本

#### Linux平台
```bash
# 在Linux x86_64平台上
./scripts/local_build_linux.sh

# 常用选项
./scripts/local_build_linux.sh -t             # 仅测试环境
./scripts/local_build_linux.sh -c             # 清理构建缓存
./scripts/local_build_linux.sh --no-appimage  # 跳过AppImage创建
./scripts/local_build_linux.sh --no-deb       # 跳过deb包创建
```

#### macOS平台
```bash
# 在macOS平台上
./scripts/local_build_macos.sh

# 常用选项
./scripts/local_build_macos.sh -t             # 仅测试环境
./scripts/local_build_macos.sh -c             # 清理构建缓存
```

## 构建产物

### Linux平台
- `dist/translate-chat` - 可执行文件
- `dist/Translate-Chat-x86_64.AppImage` - AppImage包（如果appimagetool可用）
- `dist/translate-chat_1.0.0_x86_64.deb` - deb包（如果dpkg-deb可用）

### macOS平台
- `dist/translate-chat` - 可执行文件
- `dist/Translate-Chat.app` - macOS应用包

## 环境要求

### 通用要求
- Python 3.9-3.11
- pip
- git

### Linux特定要求
- Ubuntu 20.04+ 或类似发行版
- 系统开发工具包
- 音频库依赖（portaudio, alsa等）

### macOS特定要求
- macOS 10.15+
- Xcode Command Line Tools
- Homebrew（推荐，用于依赖管理）

## 故障排除

### 常见问题

#### 1. Python版本不兼容
```bash
# 检查Python版本
python3 --version

# 如果版本不兼容，安装合适的版本
# Ubuntu/Debian
sudo apt install python3.10 python3.10-venv python3.10-dev

# macOS
brew install python@3.10
```

#### 2. 依赖安装失败
```bash
# 清理pip缓存
pip cache purge

# 使用国内镜像源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
```

#### 3. 构建失败
```bash
# 清理构建缓存
./scripts/unified_build_optimized.sh -c

# 重新安装依赖
rm -rf venv
./scripts/unified_build_optimized.sh
```

#### 4. 权限问题
```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 在Linux上可能需要sudo权限安装系统依赖
sudo apt update && sudo apt install -y build-essential python3-dev
```

### 调试模式

使用详细输出模式获取更多信息：
```bash
./scripts/unified_build_optimized.sh -v
```

## 性能优化建议

### 1. 使用SSD存储
构建过程涉及大量I/O操作，使用SSD可以显著提升构建速度。

### 2. 增加内存
PyInstaller构建过程需要较多内存，建议至少4GB可用内存。

### 3. 并行构建
如果需要构建多个平台，可以在不同机器上并行运行构建脚本。

### 4. 缓存优化
- 保留`venv`目录避免重复创建虚拟环境
- 使用`--no-deps`选项跳过依赖安装（如果依赖已安装）

## 版本管理

### 构建脚本版本
- v1.0.0: 初始版本，包含基本功能
- v2.0.0: 优化版本，基于已验证的本地构建脚本，提供更稳定的构建体验

### 兼容性
- 所有v2.0.0脚本都向后兼容v1.0.0的功能
- 建议使用最新的v2.0.0脚本以获得最佳体验

## 贡献指南

### 报告问题
如果遇到构建问题，请提供以下信息：
1. 操作系统和版本
2. Python版本
3. 构建脚本版本
4. 完整的错误日志
5. 使用的命令

### 改进建议
欢迎提交改进建议，包括：
1. 构建速度优化
2. 错误处理改进
3. 新平台支持
4. 文档完善

## 更新日志

### v2.0.0 (2025-01-28)
- 创建通用构建工具脚本
- 优化Linux和macOS构建脚本
- 新增优化的统一构建脚本
- 改进错误处理和日志输出
- 增强构建产物验证

### v1.0.0 (2025-07-28)
- 初始版本发布
- 支持Linux和macOS平台
- 基本的PyInstaller集成
- Docker跨平台构建支持 