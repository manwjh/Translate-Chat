# Translate Chat - Linux 桌面应用打包系统

## 概述

本项目在macOS上实现了完整的Linux桌面应用打包系统，支持交叉编译生成Linux可执行文件、AppImage包和deb安装包。**现在支持x86_64和ARM64两种架构**。

## 系统架构

### 核心组件

1. **Docker交叉编译环境** - 使用Ubuntu 22.04容器进行Linux应用构建
2. **PyInstaller打包工具** - 将Python应用打包为可执行文件
3. **AppImage工具** - 创建便携式Linux应用包
4. **deb包构建** - 创建Ubuntu/Debian安装包
5. **多架构支持** - 支持x86_64和ARM64架构

### 文件结构

```
scripts/
├── build_linux_desktop.sh      # 主打包脚本（支持多架构）
├── linux_dependency_manager.sh # 依赖管理脚本
├── test_linux_build.sh         # 环境测试脚本
└── common_build_utils.sh       # 通用工具函数

build/linux/
└── dependencies/               # Linux依赖包目录
    ├── *.deb                   # 系统依赖包
    ├── python_deps/*.whl       # Python依赖包
    ├── appimagetool-*          # AppImage工具
    ├── pyinstaller-*           # PyInstaller工具
    ├── dependencies.txt        # 依赖清单
    └── install_dependencies.sh # 安装脚本

dist/                           # 构建输出目录
├── translate-chat              # Linux可执行文件
├── Translate-Chat-x86_64.AppImage # x86_64 AppImage包
├── Translate-Chat-aarch64.AppImage # ARM64 AppImage包
├── translate-chat_1.0.0_amd64.deb # x86_64 deb包
└── translate-chat_1.0.0_arm64.deb # ARM64 deb包
```

## 功能特性

### 🚀 自动化构建
- 自动检测系统环境
- 自动安装Python依赖
- 自动创建Docker构建环境
- 自动生成多种格式的安装包

### 🐳 Docker交叉编译
- 使用Ubuntu 22.04容器确保兼容性
- 自动安装所有必要的系统依赖
- 支持Python 3.9-3.11版本
- 自动处理音频、视频等依赖

### 📦 多格式输出
- **可执行文件**: 独立的Linux二进制文件
- **AppImage**: 便携式应用包，无需安装
- **deb包**: Ubuntu/Debian系统安装包

### 🏗️ 多架构支持
- **x86_64架构**: 支持Intel/AMD处理器
- **ARM64架构**: 支持ARM处理器（如树莓派、ARM服务器）
- **自动架构检测**: 根据参数自动选择目标架构
- **交叉编译**: 在macOS上构建ARM64应用

### 🇨🇳 国内优化
- 使用清华源加速Python包下载
- 支持本地依赖包缓存
- 智能重试机制提高下载成功率

## 使用方法

### 1. 环境准备

确保系统满足以下要求：
- macOS系统
- Docker Desktop已安装并运行
- 至少10GB可用磁盘空间
- 稳定的网络连接

### 2. 环境测试

```bash
# 测试Linux打包环境
./scripts/test_linux_build.sh
```

### 3. 下载依赖（可选）

```bash
# 下载Linux依赖包，加速后续构建
./scripts/linux_dependency_manager.sh
```

### 4. 构建应用

#### 构建x86_64版本（默认）
```bash
# 构建x86_64 Linux桌面应用
./scripts/build_linux_desktop.sh

# 或明确指定架构
./scripts/build_linux_desktop.sh x86_64
```

#### 构建ARM64版本
```bash
# 构建ARM64 Linux桌面应用
./scripts/build_linux_desktop.sh arm64

# 或使用aarch64（会自动转换为arm64）
./scripts/build_linux_desktop.sh aarch64
```

## 构建流程

### 阶段1: 架构检测和配置
1. 检测当前系统架构
2. 验证目标架构参数
3. 设置架构相关变量
4. 配置Docker平台

### 阶段2: 环境检查
1. 验证macOS系统环境
2. 检查Python版本兼容性
3. 验证Docker环境
4. 检查磁盘空间和网络连接

### 阶段3: 依赖准备
1. 配置pip镜像源
2. 创建Python虚拟环境
3. 安装PyInstaller和AppImage工具
4. 下载本地依赖包（如果存在）

### 阶段4: Docker环境构建
1. 创建Ubuntu 22.04 Dockerfile（指定目标架构）
2. 安装系统依赖包
3. 配置Python环境
4. 安装项目依赖

### 阶段5: 应用打包
1. 使用PyInstaller构建可执行文件
2. 创建AppDir结构
3. 生成AppImage包
4. 构建deb安装包

### 阶段6: 清理和验证
1. 清理Docker镜像和临时文件
2. 验证构建产物
3. 生成构建报告

## 输出文件说明

### translate-chat (可执行文件)
- **格式**: Linux ELF二进制文件
- **大小**: 约50-100MB
- **依赖**: 需要目标系统安装相关库文件
- **使用**: 直接运行 `./translate-chat`

### Translate-Chat-x86_64.AppImage / Translate-Chat-aarch64.AppImage
- **格式**: AppImage便携式应用包
- **大小**: 约80-150MB
- **依赖**: 自包含，无需额外依赖
- **使用**: 添加执行权限后直接运行

### translate-chat_1.0.0_amd64.deb / translate-chat_1.0.0_arm64.deb
- **格式**: Debian软件包
- **大小**: 约60-120MB
- **依赖**: 自动处理依赖关系
- **使用**: `sudo dpkg -i translate-chat_1.0.0_[arch].deb`

## 部署指南

### Linux系统部署

#### 方法1: 可执行文件部署
```bash
# 复制到系统目录
sudo cp dist/translate-chat /usr/local/bin/
sudo chmod +x /usr/local/bin/translate-chat

# 运行应用
translate-chat
```

#### 方法2: AppImage部署
```bash
# 复制到用户目录
cp dist/Translate-Chat-[arch].AppImage ~/Desktop/

# 添加执行权限
chmod +x ~/Desktop/Translate-Chat-[arch].AppImage

# 运行应用
./Translate-Chat-[arch].AppImage
```

#### 方法3: deb包安装
```bash
# 安装软件包
sudo dpkg -i dist/translate-chat_1.0.0_[arch].deb

# 修复依赖关系（如果需要）
sudo apt-get install -f

# 运行应用
translate-chat
```

### 架构选择指南

#### x86_64架构
- **适用场景**: Intel/AMD处理器，大多数桌面和服务器
- **优势**: 兼容性最好，依赖包最丰富
- **推荐**: 一般用户首选

#### ARM64架构
- **适用场景**: ARM处理器，树莓派、ARM服务器、Apple Silicon
- **优势**: 功耗低，性能优秀
- **推荐**: ARM设备用户

### 依赖库要求

目标Linux系统需要安装以下依赖库：

#### 基础库
- libssl3
- libffi8
- libjpeg8
- libpng16-16
- libfreetype6

#### 音频库
- libportaudio2
- libasound2
- libpulse0
- libjack-jackd2-0

#### FFmpeg相关库
- libavcodec58
- libavformat58
- libavdevice58
- libavutil56
- libswscale5
- libavfilter7
- libavresample4
- libpostproc55
- libswresample3

## 故障排除

### 常见问题

#### 1. Docker未运行
**错误**: `Cannot connect to the Docker daemon`
**解决**: 启动Docker Desktop应用

#### 2. 架构不支持
**错误**: `不支持的目标架构`
**解决**: 使用支持的架构参数：x86_64, arm64, aarch64

#### 3. 磁盘空间不足
**错误**: `No space left on device`
**解决**: 清理磁盘空间，确保至少10GB可用

#### 4. 网络连接问题
**错误**: `Failed to download Docker image`
**解决**: 检查网络连接，使用VPN或代理

#### 5. Python版本不兼容
**错误**: `Python version not supported`
**解决**: 使用Python 3.9-3.11版本

#### 6. 依赖包下载失败
**错误**: `Failed to download dependency`
**解决**: 运行依赖管理脚本重新下载

### 调试技巧

1. **查看详细日志**: 脚本会输出详细的构建日志
2. **检查Docker容器**: `docker ps -a` 查看容器状态
3. **清理缓存**: 删除 `.buildozer` 和 `build` 目录重新构建
4. **测试环境**: 运行 `./scripts/test_linux_build.sh` 检查环境

## 性能优化

### 构建速度优化
1. 使用本地依赖包缓存
2. 增加Docker构建缓存
3. 使用SSD存储
4. 增加系统内存

### 包大小优化
1. 排除不必要的依赖
2. 使用UPX压缩可执行文件
3. 优化PyInstaller配置
4. 清理临时文件

## 版本历史

### v2.0.0 (2025/7/25)
- **新增ARM64支持**: 支持ARM64架构交叉编译
- **多架构参数**: 支持通过参数指定目标架构
- **架构检测**: 自动检测和配置目标架构
- **Docker平台**: 支持多平台Docker构建
- **输出文件**: 根据架构生成对应的文件名

### v1.0.0 (2025/7/25)
- 初始版本发布
- 支持macOS交叉编译Linux应用
- 生成可执行文件、AppImage和deb包
- 完整的自动化构建流程
- 详细的文档和故障排除指南

## 技术支持

如果遇到问题，请：

1. 运行环境测试脚本检查配置
2. 查看构建日志中的错误信息
3. 参考故障排除指南
4. 清理缓存后重新构建
5. 提交Issue并提供详细的错误信息

## 贡献指南

欢迎贡献代码和改进建议：

1. Fork项目仓库
2. 创建功能分支
3. 提交代码更改
4. 创建Pull Request
5. 等待代码审查

---

*本文档最后更新: 2025/7/25* 