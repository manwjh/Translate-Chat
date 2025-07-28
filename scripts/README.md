# Translate Chat - 桌面端构建脚本使用指南

## 概述

本项目提供了一套完整的桌面端应用构建解决方案，支持macOS和Linux环境，专注桌面端体验。

## 文件结构

```
scripts/
├── build_linux_desktop.sh      # macOS交叉编译Linux桌面应用脚本
├── linux_dependency_manager.sh # Linux桌面应用依赖管理脚本
├── test_linux_build.sh         # Linux打包环境测试脚本
├── common_build_utils.sh       # 通用构建工具函数
└── README.md                  # 本说明文档
```

## 环境要求

### Linux 桌面应用打包环境

#### macOS 交叉编译环境
- **Python**: 3.9-3.11 (推荐3.10) - **脚本会自动安装**
- **Docker**: Docker Desktop - **需要手动安装**
- **PyInstaller**: 5.13.2 - **脚本会自动安装**
- **AppImage工具**: **脚本会自动下载**

### 自动化特性

脚本具备以下自动化功能：

#### Linux 桌面应用打包
1. **自动检测Docker环境**
2. **自动创建Linux交叉编译环境**
3. **自动下载和安装打包工具**
4. **自动构建Docker镜像**
5. **自动生成AppImage和deb包**
6. **自动清理构建文件**

## 使用方法

### 1. 快速开始

#### Linux 桌面应用打包

##### macOS用户（交叉编译）
```bash
# 1. 测试Linux打包环境（推荐）
./scripts/test_linux_build.sh

# 2. 下载Linux依赖包（可选，用于加速构建）
./scripts/linux_dependency_manager.sh

# 3. 构建Linux桌面应用
./scripts/build_linux_desktop.sh
```

### 2. 手动步骤 (可选)

如果自动脚本遇到问题，可以按以下步骤手动执行：

#### 步骤1: 环境检查
```bash
# 检查Python版本 (需要3.9-3.11)
python3 --version

# 检查Docker环境
docker --version
```

#### 步骤2: 创建虚拟环境
```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate
```

#### 步骤3: 安装依赖
```bash
# 升级pip
pip install --upgrade pip setuptools wheel

# 安装项目依赖
pip install -r requirements-desktop.txt

# 安装打包工具
pip install pyinstaller==5.13.2
```

#### 步骤4: 构建应用
```bash
# 使用PyInstaller构建
pyinstaller --onefile --windowed --name="translate-chat" main.py
```

## 配置说明

### requirements-desktop.txt 依赖锁定

```
# 核心框架
kivy>=2.3.0,<3.0.0
kivymd==1.1.1

# 音频处理
pyaudio>=0.2.11,<0.3.0

# 网络通信
websocket-client>=1.6.0,<2.0.0
aiohttp>=3.8.0,<4.0.0

# 加密存储
cryptography>=3.4.8,<4.0.0

# 音频处理增强
numpy>=1.21.0,<2.0.0
scipy>=1.7.0,<2.0.0

# 语音识别相关
webrtcvad>=2.0.10,<3.0.0
resemblyzer>=0.1.1,<1.0.0
```

## 常见问题解决

### 1. Docker未运行
**错误信息**: `Cannot connect to the Docker daemon`

**解决方案**:
- 启动Docker Desktop应用
- 检查Docker服务状态

### 2. Python版本不兼容
**错误信息**: `Python version not supported`

**解决方案**:
- 使用Python 3.9-3.11版本
- 推荐使用Python 3.10

### 3. 网络连接问题
**错误信息**: `Failed to download Docker image`

**解决方案**:
- 检查网络连接
- 使用VPN或代理
- 使用国内镜像源

### 4. 权限问题
**解决方案**:
```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 确保在项目根目录运行
cd /path/to/Translate-Chat
```

## 构建输出

### Linux 桌面应用构建输出

成功构建后，Linux应用文件将生成在 `dist/` 目录：

```
dist/
├── translate-chat                    # Linux可执行文件
├── Translate-Chat-x86_64.AppImage   # AppImage包
└── translate-chat_1.0.0_amd64.deb   # deb安装包
```

## 部署说明

### Linux 桌面应用部署

#### 可执行文件部署
```bash
# 将可执行文件复制到Linux系统
cp dist/translate-chat /usr/local/bin/
chmod +x /usr/local/bin/translate-chat
translate-chat
```

#### AppImage部署
```bash
# 将AppImage复制到Linux系统
cp dist/Translate-Chat-x86_64.AppImage ~/Desktop/
chmod +x ~/Desktop/Translate-Chat-x86_64.AppImage
./Translate-Chat-x86_64.AppImage
```

#### deb包部署
```bash
# 在Ubuntu/Debian系统上安装
sudo dpkg -i dist/translate-chat_1.0.0_amd64.deb
sudo apt-get install -f  # 修复依赖关系
```

## 技术支持

如果遇到问题，请：

1. 检查环境要求是否满足
2. 查看构建日志中的错误信息
3. 参考故障排除指南
4. 清理缓存后重新构建

## 更新日志

### v2.0.0 (2025/7/25)
- 移除Android支持，专注桌面端体验
- 简化依赖管理，移除SDL2相关配置
- 优化Linux桌面应用打包流程
- 更新文档和说明

### v1.0.0 (2025/7/25)
- 初始版本发布
- 支持macOS交叉编译Linux应用
- 生成可执行文件、AppImage和deb包
- 完整的自动化构建流程
- 详细的文档和故障排除指南

---

*本文档最后更新: 2025/7/25* 