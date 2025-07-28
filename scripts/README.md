# Translate Chat - 构建脚本使用指南

## 概述

本项目提供了一套完整的Android APK构建解决方案，支持macOS和Ubuntu环境，解决了Python 3.11兼容性问题。

## 文件结构

```
scripts/
├── build_android_macos.sh      # macOS Android构建脚本
├── build_android_ubuntu.sh     # Ubuntu Android构建脚本
├── common_build_utils.sh       # 通用构建工具函数
├── pyjnius_patch.sh           # pyjnius兼容性补丁脚本
├── buildozer.spec             # Buildozer配置文件
└── README.md                  # 本说明文档
```

## 环境要求

### 统一环境配置
- **Python**: 3.9-3.11 (推荐3.10) - **脚本会自动安装**
- **Java**: JDK 11+ (推荐JDK 17) - **脚本会自动安装**
- **Buildozer**: 1.5.0
- **Cython**: 0.29.36
- **pyjnius**: >=1.5.0

### 系统特定要求

#### macOS
- Homebrew
- Python 3.10: **脚本自动安装**
- JDK 17: **脚本自动安装**
- openssl@1.1: **脚本自动安装**

#### Ubuntu
- Python 3.10+: **脚本自动安装**
- JDK 17: **脚本自动安装**
- 系统依赖包: **脚本自动安装**

### 自动化特性

脚本具备以下自动化功能：

1. **自动检测系统环境**
2. **自动安装合适的Python版本** (3.9-3.11)
3. **自动安装Java环境** (JDK 11+)
4. **自动配置pip镜像** (清华源)
5. **自动安装系统依赖**
6. **自动创建虚拟环境**
7. **自动处理pyjnius兼容性问题**

## 使用方法

### 1. 快速开始

#### macOS用户
```bash
# 在项目根目录运行
./scripts/build_android_macos.sh
```

#### Ubuntu用户
```bash
# 在项目根目录运行
./scripts/build_android_ubuntu.sh
```

### 2. 手动步骤 (可选)

如果自动脚本遇到问题，可以按以下步骤手动执行：

#### 步骤1: 环境检查
```bash
# 检查Python版本 (需要3.9-3.11)
python3 --version

# 检查Java版本 (需要11+)
java -version
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

# 安装构建工具
pip install cython==0.29.36 buildozer==1.5.0

# 安装项目依赖
pip install -r requirements-android.txt
```

#### 步骤4: 构建APK
```bash
# 清理之前的构建
buildozer android clean

# 开始构建
buildozer -v android debug
```

### 3. 解决Python 3.11兼容性问题

如果使用Python 3.11遇到pyjnius编译错误，运行补丁脚本：

```bash
# 自动查找并修复pyjnius
./scripts/pyjnius_patch.sh

# 或手动指定pyjnius目录
./scripts/pyjnius_patch.sh /path/to/pyjnius
```

## 配置说明

### buildozer.spec 主要配置

```ini
# 应用信息
title = Translate Chat
package.name = translatechat
package.domain = org.translatechat
version = 1.0.0

# 依赖配置
requirements = python3,%(source.dir)s/requirements-android.txt

# Android配置
android.api = 33
android.minapi = 21
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a
android.permissions = android.permission.INTERNET,android.permission.RECORD_AUDIO,...

# Python for Android配置
p4a.bootstrap = sdl2
p4a.setup_py = false
```

### requirements-android.txt 依赖锁定

```
# 核心框架
kivy>=2.3.0,<3.0.0
kivymd==1.1.1

# 音频视频处理
plyer>=2.1.0,<3.0.0
ffpyplayer>=4.5.0,<5.0.0

# 网络通信
websocket-client>=1.6.0,<2.0.0
aiohttp>=3.8.0,<4.0.0

# Android兼容性关键依赖
pyjnius>=1.5.0,<2.0.0

# 构建工具
buildozer>=1.5.0,<2.0.0
cython>=0.29.36,<0.30.0
```

## 常见问题解决

### 1. pyjnius编译错误
**错误信息**: `undeclared name not builtin: long`

**解决方案**:
```bash
# 运行补丁脚本
./scripts/pyjnius_patch.sh
```

### 2. Java版本不兼容
**错误信息**: `Java version not supported`

**解决方案**:
- macOS: `brew install openjdk@17`
- Ubuntu: `sudo apt install openjdk-17-jdk`

### 3. Python版本不兼容
**错误信息**: `Python version not supported`

**解决方案**:
- 使用Python 3.9-3.11版本
- 推荐使用Python 3.10

### 4. 网络下载慢
**解决方案**:
- 脚本已配置清华源镜像
- 使用本地SDL2文件 (放在/tmp目录)
- 使用科学上网工具

### 5. 权限问题
**解决方案**:
```bash
# 确保脚本有执行权限
chmod +x scripts/*.sh

# 确保在项目根目录运行
cd /path/to/Translate-Chat
```

## 构建输出

成功构建后，APK文件将生成在 `bin/` 目录：

```
bin/
├── translatechat-1.0.0-arm64-v8a_armeabi-v7a-debug.apk
└── translatechat-1.0.0-arm64-v8a_armeabi-v7a-debug.aab
```

## 部署到设备

```bash
# 连接Android设备并开启USB调试
# 部署并运行
buildozer android deploy run

# 查看日志
buildozer android logcat
```

## 技术支持

如果遇到问题，请：

1. 检查环境要求是否满足
2. 查看构建日志中的错误信息
3. 运行补丁脚本解决兼容性问题
4. 清理构建缓存后重试

## 更新日志

### v2.0.0 (2025/7/25)
- 统一macOS和Ubuntu环境配置
- 解决Python 3.11兼容性问题
- 锁定所有关键依赖版本
- 添加pyjnius自动补丁功能
- 优化错误处理和日志输出 