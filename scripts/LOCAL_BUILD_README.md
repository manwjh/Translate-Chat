# 本地Linux构建脚本使用说明

## 概述

`local_build_linux.sh` 是一个专门为在 **x86_64 Linux** 系统上构建 **x86_64 Linux** 应用而设计的脚本。与 `unified_build_system.sh` 不同，它**不需要Docker**，直接在本地环境中构建，速度更快，资源消耗更少。

## 为什么不需要Docker？

在 x86_64 Linux 下构建 x86_64 Linux 应用时：
- ✅ **架构匹配**：主机和目标都是 x86_64，可以直接编译
- ✅ **依赖兼容**：Linux系统可以直接安装所需的依赖包
- ✅ **性能更好**：本地构建比Docker容器构建更快
- ✅ **资源消耗更少**：不需要Docker的额外开销

## 使用场景

- 在 Ubuntu/Debian/CentOS 等 x86_64 Linux 系统上构建应用
- 快速开发和测试构建流程
- 不需要跨平台构建时

## 使用方法

### 基本用法

```bash
# 完整构建（推荐）
./scripts/local_build_linux.sh

# 仅测试环境
./scripts/local_build_linux.sh -t

# 清理构建缓存
./scripts/local_build_linux.sh -c
```

### 高级选项

```bash
# 跳过依赖安装（如果已安装）
./scripts/local_build_linux.sh --no-deps

# 跳过AppImage创建
./scripts/local_build_linux.sh --no-appimage

# 跳过deb包创建
./scripts/local_build_linux.sh --no-deb

# 组合使用
./scripts/local_build_linux.sh --no-appimage --no-deb
```

## 构建产物

构建完成后，在 `dist/` 目录下会生成：

- `translate-chat` - 可执行文件
- `Translate-Chat-x86_64.AppImage` - AppImage包（如果appimagetool可用）
- `translate-chat_1.0.0_x86_64.deb` - deb安装包（如果dpkg-deb可用）

## 系统要求

### 必需条件
- Linux x86_64 系统
- Python 3.9-3.11
- sudo权限（用于安装系统依赖）

### 自动安装的依赖
脚本会自动安装以下系统依赖：
- 基础开发工具（build-essential, git, wget等）
- Python开发环境（python3-dev, python3-venv等）
- 音频处理库（portaudio19-dev, libasound2-dev等）
- 多媒体库（libavcodec-dev, libavformat-dev等）
- 图形库（libjpeg-dev, libpng-dev, libfreetype6-dev等）

## 与Docker构建的对比

| 特性 | 本地构建 | Docker构建 |
|------|----------|------------|
| 速度 | ⚡ 更快 | 🐌 较慢 |
| 资源消耗 | 💚 更少 | 🔴 更多 |
| 依赖管理 | 🔧 自动安装 | 📦 容器内管理 |
| 跨平台支持 | ❌ 仅x86_64 | ✅ 支持多架构 |
| 环境隔离 | ❌ 无 | ✅ 完全隔离 |
| 网络依赖 | 💚 较少 | 🔴 需要下载镜像 |

## 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 确保脚本有执行权限
   chmod +x scripts/local_build_linux.sh
   ```

2. **Python版本不兼容**
   ```bash
   # 检查Python版本
   python3 --version
   # 需要3.9-3.11版本
   ```

3. **系统依赖缺失**
   ```bash
   # 手动安装依赖
   sudo apt-get update
   sudo apt-get install -y python3-dev build-essential
   ```

4. **网络问题**
   ```bash
   # 脚本会自动使用国内镜像源
   # 如果仍有问题，可以手动配置
   pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
   ```

### 日志信息

脚本使用彩色日志输出：
- 🔵 `[INFO]` - 信息提示
- 🟢 `[SUCCESS]` - 成功信息
- 🟡 `[WARNING]` - 警告信息
- 🔴 `[ERROR]` - 错误信息

## 最佳实践

1. **首次使用**：先运行 `./scripts/local_build_linux.sh -t` 测试环境
2. **开发阶段**：使用 `--no-appimage --no-deb` 跳过打包步骤
3. **发布阶段**：使用完整构建生成所有格式的安装包
4. **清理维护**：定期运行 `-c` 清理构建缓存

## 注意事项

- 此脚本仅支持 x86_64 Linux 系统
- 需要 sudo 权限安装系统依赖
- 构建过程会创建 Python 虚拟环境
- 建议在干净的环境中运行，避免依赖冲突 