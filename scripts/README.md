# Translate Chat - 构建脚本目录说明

## 目录概述

scripts目录包含了Translate Chat项目的所有构建和部署相关脚本。经过v2.0.0优化后，构建系统更加稳定和易用，提供了多种构建方案以满足不同需求。

## 文件结构

```
scripts/
├── common_build_utils.sh           # 通用构建工具函数库（核心）
├── local_build_linux.sh            # Linux本地构建脚本（已验证）
├── local_build_macos.sh            # macOS本地构建脚本（已验证）
├── unified_build_optimized.sh      # 优化的统一构建脚本（推荐）
├── unified_build_arm&x86_linux.sh  # 实验性Docker跨平台构建
├── BUILD_GUIDE.md                  # 详细构建指南
├── CROSS_PLATFORM_BUILD.md         # 跨平台构建技术文档
└── README.md                       # 本说明文档
```

## 构建脚本分类

### 🟢 已验证的本地构建脚本

#### 1. local_build_linux.sh (v2.0.0)
**功能**: 在Linux x86_64平台上构建Linux应用
- ✅ **已验证稳定**，无需Docker
- 🎯 支持创建可执行文件、AppImage、deb包
- 🚀 基于已验证的构建流程

**使用方法**:
```bash
# 在Linux x86_64平台上
./scripts/local_build_linux.sh

# 常用选项
./scripts/local_build_linux.sh -t             # 仅测试环境
./scripts/local_build_linux.sh -c             # 清理构建缓存
./scripts/local_build_linux.sh --no-appimage  # 跳过AppImage创建
./scripts/local_build_linux.sh --no-deb       # 跳过deb包创建
```

#### 2. local_build_macos.sh (v2.0.0)
**功能**: 在macOS平台上构建macOS应用
- ✅ **已验证稳定**，支持ARM64和x86_64架构
- 🎯 支持创建可执行文件和.app应用包
- 🚀 基于已验证的构建流程

**使用方法**:
```bash
# 在macOS平台上
./scripts/local_build_macos.sh

# 常用选项
./scripts/local_build_macos.sh -t             # 仅测试环境
./scripts/local_build_macos.sh -c             # 清理构建缓存
```

### ⭐ 推荐的统一构建脚本

#### 3. unified_build_optimized.sh (v2.0.0) - **推荐使用**
**功能**: 跨平台统一构建系统
- 🎯 基于已验证的本地构建脚本
- 🚀 智能平台检测和构建方式选择
- 📦 自动创建平台特定的包格式
- 🔧 更稳定的构建体验

**使用方法**:
```bash
# 自动构建当前平台应用
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

### 🟡 实验性构建脚本

#### 4. unified_build_arm&x86_linux.sh (v1.0.0)
**功能**: 使用Docker进行跨架构构建
- ⚠️ **未完全验证**，可能存在稳定性问题
- 🐳 支持在macOS上构建Linux应用（x86_64和ARM64）
- 🔬 实验性功能，建议谨慎使用

**使用方法**:
```bash
# 构建所有架构
./scripts/unified_build_arm&x86_linux.sh all

# 仅构建x86_64架构
./scripts/unified_build_arm&x86_linux.sh x86_64

# 仅构建arm64架构
./scripts/unified_build_arm&x86_linux.sh arm64
```

### 🔧 工具脚本

#### 5. common_build_utils.sh (v2.0.0)
**功能**: 通用构建工具函数库
- 📚 提供所有构建脚本共享的配置和函数
- 🔧 统一的PyInstaller配置和隐藏导入列表
- 🎨 标准化的日志输出和错误处理
- 🛠️ 环境检查和验证函数

**主要功能**:
- 平台检测和Python环境检查
- PyInstaller命令生成
- 构建产物验证
- 缓存清理和结果展示

## 推荐使用流程

### 🎯 方案一：使用优化的统一构建脚本（推荐）

```bash
# 1. 确保在项目根目录
cd /path/to/Translate-Chat

# 2. 给脚本添加执行权限
chmod +x scripts/*.sh

# 3. 构建当前平台应用
./scripts/unified_build_optimized.sh

# 4. 或构建特定平台
./scripts/unified_build_optimized.sh linux
./scripts/unified_build_optimized.sh macos
```

### 🔧 方案二：使用专用本地构建脚本

```bash
# Linux平台
./scripts/local_build_linux.sh

# macOS平台
./scripts/local_build_macos.sh
```

## 构建产物

### Linux平台
```
dist/
├── translate-chat                    # 可执行文件
├── Translate-Chat-x86_64.AppImage   # AppImage包（如果appimagetool可用）
└── translate-chat_1.0.0_x86_64.deb  # deb包（如果dpkg-deb可用）
```

### macOS平台
```
dist/
├── translate-chat                    # 可执行文件
└── Translate-Chat.app               # macOS应用包
```

## 系统要求

### 通用要求
- **Python**: 3.9-3.11
- **pip**: 最新版本
- **git**: 版本控制工具

### Linux特定要求
- **系统**: Ubuntu 20.04+ 或类似发行版
- **开发工具**: build-essential, python3-dev
- **音频库**: portaudio, alsa等

### macOS特定要求
- **系统**: macOS 10.15+
- **开发工具**: Xcode Command Line Tools
- **包管理**: Homebrew（推荐）

## 故障排除

### 常见问题

#### 1. Python版本不兼容
```bash
# 检查Python版本
python3 --version

# 安装兼容版本
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

# 在Linux上可能需要sudo权限
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
- **v1.0.0**: 初始版本，包含基本功能
- **v2.0.0**: 优化版本，基于已验证的本地构建脚本，提供更稳定的构建体验

### 兼容性
- 所有v2.0.0脚本都向后兼容v1.0.0的功能
- 建议使用最新的v2.0.0脚本以获得最佳体验

## 文档资源

### 详细指南
- **BUILD_GUIDE.md**: 完整的构建脚本使用指南
- **CROSS_PLATFORM_BUILD.md**: 跨平台构建技术文档

### 快速参考
```bash
# 查看帮助信息
./scripts/unified_build_optimized.sh -h

# 测试环境
./scripts/unified_build_optimized.sh -t

# 清理缓存
./scripts/unified_build_optimized.sh -c
```

## 更新日志

### v2.0.0 (2025-01-28) - 优化版本
- ✅ 创建通用构建工具脚本 (`common_build_utils.sh`)
- ✅ 优化Linux和macOS构建脚本
- ✅ 新增优化的统一构建脚本 (`unified_build_optimized.sh`)
- ✅ 改进错误处理和日志输出
- ✅ 增强构建产物验证
- ✅ 创建详细的构建指南 (`BUILD_GUIDE.md`)

### v1.0.0 (2025-07-28) - 初始版本
- 初始版本发布
- 支持Linux和macOS平台
- 基本的PyInstaller集成
- Docker跨平台构建支持

## 技术支持

如果遇到问题，请：

1. 检查环境要求是否满足
2. 查看构建日志中的错误信息
3. 参考故障排除指南
4. 清理缓存后重新构建
5. 查看BUILD_GUIDE.md获取详细使用信息

---

*本文档最后更新: 2025-01-28* 