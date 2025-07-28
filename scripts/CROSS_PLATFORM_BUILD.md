# Translate Chat - 跨平台构建指南

## 概述

本项目提供了两个脚本用于在x86+Linux平台上交叉编译打包x86+Linux和ARM+Linux版本：

1. **完整版脚本**: `build_cross_platform.sh` - 功能完整，包含详细的环境检查和错误处理
2. **快速版脚本**: `quick_build.sh` - 简化版本，专注于快速构建

## 系统要求

### 基础要求
- **操作系统**: Linux (Ubuntu/Debian/CentOS/RHEL等)
- **架构**: x86_64
- **Python**: 3.9-3.11
- **Docker**: 用于ARM64交叉编译

### 依赖安装

#### Ubuntu/Debian
```bash
# 安装Docker
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 安装Python3
sudo apt install -y python3 python3-venv python3-pip

# 安装构建工具
sudo apt install -y build-essential cmake pkg-config
```

#### CentOS/RHEL
```bash
# 安装Docker
sudo yum install -y docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# 安装Python3
sudo yum install -y python3 python3-pip

# 安装构建工具
sudo yum install -y gcc gcc-c++ cmake pkgconfig
```

## 使用方法

### 快速构建 (推荐)

```bash
# 在项目根目录执行
./scripts/quick_build.sh
```

**特点**:
- 使用Docker容器确保环境一致性
- 自动处理依赖安装
- 构建完成后自动清理
- 生成压缩包便于分发

### 完整构建

```bash
# 在项目根目录执行
./scripts/build_cross_platform.sh
```

**特点**:
- 详细的环境检查
- 支持多种包管理器
- 更完善的错误处理
- 可配置的构建选项

## 构建输出

### 目录结构
```
quick_dist/
├── x86_64/
│   └── translate-chat/          # x86_64版本文件
├── arm64/
│   └── translate-chat/          # ARM64版本文件
├── translate-chat-x86_64-20250127.tar.gz
└── translate-chat-arm64-20250127.tar.gz
```

### 文件说明
- **x86_64目录**: 包含适用于x86_64架构Linux系统的可执行文件
- **arm64目录**: 包含适用于ARM64架构Linux系统的可执行文件
- **tar.gz文件**: 压缩包，便于分发和部署

## 技术细节

### 交叉编译原理

1. **x86_64版本**: 在本地环境直接编译
2. **ARM64版本**: 使用Docker容器进行交叉编译
   - 使用`--platform=linux/arm64`指定目标平台
   - 在ARM64环境中编译，确保二进制文件兼容性

### 依赖处理

脚本会自动处理以下依赖：
- **系统依赖**: ALSA、PortAudio、OpenSSL等
- **Python依赖**: 从`requirements-desktop.txt`安装
- **构建工具**: PyInstaller、CMake等

### 打包配置

使用PyInstaller进行打包，包含：
- 所有必要的Python模块
- 项目资源文件
- 系统库依赖
- 优化的二进制文件

## 故障排除

### 常见问题

#### 1. Docker权限问题
```bash
# 解决方案：将用户添加到docker组
sudo usermod -aG docker $USER
# 重新登录或重启系统
```

#### 2. 内存不足
```bash
# 增加Docker内存限制
# 在Docker Desktop设置中调整内存限制
# 或使用命令行参数
docker run --memory=4g ...
```

#### 3. 网络问题
```bash
# 使用国内镜像源
export PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple/
```

#### 4. 构建失败
```bash
# 清理缓存重新构建
rm -rf quick_build quick_dist
docker system prune -f
./scripts/quick_build.sh
```

### 调试模式

启用详细输出：
```bash
# 设置调试环境变量
export DEBUG=1
./scripts/quick_build.sh
```

## 性能优化

### 构建时间优化
- 使用Docker镜像缓存
- 并行构建（如果资源充足）
- 使用SSD存储

### 文件大小优化
- 启用UPX压缩
- 排除不必要的模块
- 优化依赖列表

## 部署说明

### 目标系统要求
- **x86_64版本**: 需要x86_64架构的Linux系统
- **ARM64版本**: 需要ARM64架构的Linux系统
- **运行时依赖**: 通常已包含在打包文件中

### 安装步骤
```bash
# 解压发布包
tar -xzf translate-chat-x86_64-20250127.tar.gz

# 进入目录
cd translate-chat

# 运行应用
./translate-chat
```

## 更新日志

### v1.0.0 (2025-01-27)
- 初始版本
- 支持x86_64和ARM64交叉编译
- 使用Docker确保环境一致性
- 自动依赖管理和错误处理

## 贡献指南

如需修改构建脚本：
1. 测试在多种Linux发行版上的兼容性
2. 确保Docker容器能正确构建
3. 更新文档说明
4. 提交Pull Request

## 许可证

本项目采用MIT许可证，详见LICENSE文件。 