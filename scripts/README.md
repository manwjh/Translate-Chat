# Translate Chat - 构建脚本目录说明

## 目录概述

scripts目录包含了Translate Chat项目的所有构建和部署相关脚本，经过重构后现在只保留4个核心文件，结构简洁明了。

## 文件结构

```
scripts/
├── unified_build_system.sh     # 统一跨平台构建系统（主要构建脚本）
├── common_build_utils.sh       # 通用构建工具函数库
├── linux_dependency_manager.sh # Linux依赖包管理脚本
├── CROSS_PLATFORM_BUILD.md     # 跨平台构建详细指南
└── README.md                  # 本说明文档
```

## 文件详细说明

### 1. unified_build_system.sh - 统一构建系统

**功能**: 主要的跨平台构建脚本，支持在macOS和Linux主机上构建x86_64和ARM64 Linux应用

**特点**:
- 支持macOS(ARM64)和Linux(x86_64)主机平台
- 自动检测主机平台和目标架构
- 使用Docker进行交叉编译
- 完整的错误处理和日志输出
- 支持环境测试和缓存清理

**使用方法**:
```bash
# 构建所有架构
./scripts/unified_build_system.sh all

# 仅构建x86_64架构
./scripts/unified_build_system.sh x86_64

# 仅构建arm64架构
./scripts/unified_build_system.sh arm64

# 测试环境
./scripts/unified_build_system.sh -t

# 清理构建缓存
./scripts/unified_build_system.sh -c

# 显示帮助信息
./scripts/unified_build_system.sh -h
```

**支持的主机平台**:
- macOS (ARM64) → 构建 x86_64 Linux 和 ARM64 Linux
- Linux (x86_64) → 构建 x86_64 Linux 和 ARM64 Linux

### 2. common_build_utils.sh - 通用构建工具函数

**功能**: 提供通用的构建工具函数，被其他脚本引用

**主要功能**:
- 系统检测和Python版本检查
- 兼容Python版本自动安装
- 日志输出和错误处理
- 环境检查和依赖验证
- 跨平台兼容性处理

**包含的函数**:
- `detect_system()` - 检测操作系统类型
- `check_python_version()` - 检查Python版本兼容性
- `install_compatible_python()` - 安装兼容的Python版本
- `check_environment()` - 完整环境检查
- 各种日志函数和工具函数

### 3. linux_dependency_manager.sh - Linux依赖管理

**功能**: 在macOS上预先下载Linux应用打包所需的依赖包

**特点**:
- 仅适用于macOS系统
- 自动下载Ubuntu系统依赖包
- 下载Python依赖包
- 支持断点续传和重试机制
- 使用国内镜像源加速下载

**下载的依赖包类型**:
- 基础库: libssl3, libffi8
- 图像处理: libjpeg8, libpng16, libfreetype6
- 音频库: libportaudio2, libasound2, libpulse0
- FFmpeg库: libavcodec58, libavformat58等

**使用方法**:
```bash
# 在macOS上运行
./scripts/linux_dependency_manager.sh
```

### 4. CROSS_PLATFORM_BUILD.md - 跨平台构建指南

**功能**: 详细的跨平台构建技术文档

**内容**:
- 系统要求和依赖安装
- 构建原理和技术细节
- 故障排除和调试指南
- 性能优化建议
- 部署说明

## 使用流程

### 快速开始（推荐）

1. **环境准备**:
   ```bash
   # 确保在项目根目录
   cd /path/to/Translate-Chat
   
   # 给脚本添加执行权限
   chmod +x scripts/*.sh
   ```

2. **构建应用**:
   ```bash
   # 使用统一构建系统
   ./scripts/unified_build_system.sh all
   ```

3. **可选：预下载依赖**（仅macOS）:
   ```bash
   ./scripts/linux_dependency_manager.sh
   ```

### 高级用法

1. **仅构建特定架构**:
   ```bash
   # 仅构建x86_64版本
   ./scripts/unified_build_system.sh x86_64
   
   # 仅构建ARM64版本
   ./scripts/unified_build_system.sh arm64
   ```

2. **环境测试**:
   ```bash
   # 测试构建环境
   ./scripts/unified_build_system.sh -t
   ```

3. **清理缓存**:
   ```bash
   # 清理构建缓存
   ./scripts/unified_build_system.sh -c
   ```

## 构建输出

### 目录结构
```
dist/
├── translate-chat-x86_64/      # x86_64版本文件
├── translate-chat-arm64/       # ARM64版本文件
├── Translate-Chat-x86_64.AppImage
├── Translate-Chat-arm64.AppImage
├── translate-chat_1.0.0_amd64.deb
└── translate-chat_1.0.0_arm64.deb
```

### 输出文件说明
- **可执行文件**: 适用于对应架构的Linux系统
- **AppImage**: 便携式应用包，无需安装
- **deb包**: Debian/Ubuntu系统安装包

## 系统要求

### 主机系统要求
- **macOS**: 10.15+ (推荐ARM64)
- **Linux**: Ubuntu 20.04+ / CentOS 8+ (x86_64)
- **Python**: 3.9-3.11
- **Docker**: 用于交叉编译

### 目标系统要求
- **Linux**: Ubuntu 20.04+ / CentOS 8+
- **架构**: x86_64 或 ARM64
- **运行时依赖**: 已包含在打包文件中

## 故障排除

### 常见问题

1. **Docker未运行**:
   ```bash
   # 启动Docker Desktop (macOS)
   # 或启动Docker服务 (Linux)
   sudo systemctl start docker
   ```

2. **Python版本不兼容**:
   ```bash
   # 脚本会自动安装兼容版本
   # 或手动安装Python 3.10
   ```

3. **权限问题**:
   ```bash
   # 确保脚本有执行权限
   chmod +x scripts/*.sh
   
   # 确保在项目根目录运行
   cd /path/to/Translate-Chat
   ```

4. **网络问题**:
   ```bash
   # 使用国内镜像源
   export PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple/
   ```

### 调试模式

启用详细输出：
```bash
# 设置调试环境变量
export DEBUG=1
./scripts/unified_build_system.sh all
```

## 更新日志

### v3.0.0 (2025/7/28)
- 重构构建系统，统一为unified_build_system.sh
- 删除冗余的构建脚本，简化目录结构
- 支持macOS和Linux主机的跨平台构建
- 优化构建流程和错误处理

### v2.0.0 (2025/7/25)
- 移除Android支持，专注桌面端体验
- 简化依赖管理，移除SDL2相关配置
- 优化Linux桌面应用打包流程

### v1.0.0 (2025/7/25)
- 初始版本发布
- 支持macOS交叉编译Linux应用
- 生成可执行文件、AppImage和deb包

## 技术支持

如果遇到问题，请：

1. 检查环境要求是否满足
2. 查看构建日志中的错误信息
3. 参考故障排除指南
4. 清理缓存后重新构建
5. 查看CROSS_PLATFORM_BUILD.md获取详细技术信息

---

*本文档最后更新: 2025/7/28* 