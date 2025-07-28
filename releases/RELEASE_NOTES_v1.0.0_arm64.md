# Translate Chat v1.0.0 - 树莓派版本发布说明

## 版本信息
- **版本号**: v1.0.0
- **发布日期**: 2025年7月28日
- **目标平台**: ARM64 Linux (树莓派)
- **构建平台**: macOS ARM64
- **文件大小**: 63.8 MB

## 下载链接
- **完整包**: [translate-chat-arm64-20250728.tar.gz](translate-chat-arm64-20250728.tar.gz)

## 新功能特性

### 🚀 跨平台构建支持
- **macOS本地构建**: 无需Docker，直接在macOS上构建Linux应用
- **ARM64架构优化**: 专门针对树莓派ARM64架构优化
- **自动化构建流程**: 一键构建，自动处理依赖和环境配置

### 📦 多种部署方式
1. **Python包部署** (推荐)
   - 包含完整源代码
   - 自动安装脚本
   - 虚拟环境管理
   - 详细的安装文档

2. **可执行文件部署**
   - 单文件可执行程序
   - 无需安装Python环境
   - 即下即用

### 🔧 技术改进
- **不依赖Docker**: 使用本地工具链，构建更快更稳定
- **国内镜像源**: 自动使用清华源加速下载
- **错误处理**: 完善的错误处理和重试机制
- **日志系统**: 彩色日志输出，便于调试

## 系统要求

### 目标系统 (树莓派)
- **操作系统**: Linux (Ubuntu/Debian/CentOS/RHEL)
- **架构**: ARM64
- **Python**: 3.9-3.11 (如果使用Python包部署)
- **内存**: 建议2GB以上
- **存储**: 建议1GB可用空间

### 构建系统 (macOS)
- **操作系统**: macOS 10.15+
- **架构**: ARM64 或 x86_64
- **Python**: 3.9-3.11
- **Homebrew**: 用于安装构建工具

## 安装说明

### 方法一：Python包安装 (推荐)

```bash
# 1. 解压发布包
tar -xzf translate-chat-arm64-20250728.tar.gz

# 2. 进入Python包目录
cd python_package_arm64

# 3. 运行自动安装脚本
./install.sh

# 4. 启动应用
./run.sh
```

### 方法二：可执行文件安装

```bash
# 1. 解压发布包
tar -xzf translate-chat-arm64-20250728.tar.gz

# 2. 进入可执行文件目录
cd arm64

# 3. 添加执行权限
chmod +x translate-chat

# 4. 运行应用
./translate-chat
```

## 功能特性

### 🎯 核心功能
- **实时语音识别**: 支持多种语言的语音转文字
- **智能翻译**: 多语言实时翻译
- **热词检测**: 自动识别和标记重要词汇
- **说话人切换**: 检测不同说话人的语音
- **异步处理**: 翻译不阻塞实时识别

### 🎨 用户界面
- **现代化UI**: 基于KivyMD的Material Design界面
- **响应式设计**: 适配不同屏幕尺寸
- **中文界面**: 完整的中文用户界面
- **实时反馈**: 语音识别和翻译状态实时显示

### 🔒 安全特性
- **加密存储**: 敏感信息加密保存
- **本地处理**: 语音数据本地处理，保护隐私
- **安全配置**: 配置文件安全存储

## 故障排除

### 常见问题

#### 1. 音频设备问题
```bash
# 安装PortAudio依赖
sudo apt-get install portaudio19-dev  # Ubuntu/Debian
sudo yum install portaudio-devel      # CentOS/RHEL
```

#### 2. Python版本问题
```bash
# 检查Python版本
python3 --version

# 安装兼容版本
sudo apt-get install python3.10 python3.10-venv
```

#### 3. 权限问题
```bash
# 确保脚本有执行权限
chmod +x *.sh
chmod +x translate-chat
```

#### 4. 网络连接问题
```bash
# 检查网络连接
ping -c 3 google.com

# 配置代理（如果需要）
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

### 日志查看
```bash
# 查看应用日志
./translate-chat 2>&1 | tee app.log

# 查看系统日志
journalctl -u translate-chat -f
```

## 更新日志

### v1.0.0 (2025-07-28)
- 🎉 **首次发布**: 树莓派版本正式发布
- 🚀 **跨平台构建**: 支持macOS构建Linux应用
- 📦 **多种部署**: Python包和可执行文件两种部署方式
- 🔧 **自动化**: 完整的安装和部署脚本
- 📚 **文档完善**: 详细的安装和使用文档

## 技术支持

### 获取帮助
- **GitHub Issues**: [项目Issues页面](https://github.com/manwjh/Translate-Chat/issues)
- **文档**: [项目Wiki](https://github.com/manwjh/Translate-Chat/wiki)
- **讨论**: [GitHub Discussions](https://github.com/manwjh/Translate-Chat/discussions)

### 贡献代码
欢迎提交Pull Request和Issue报告！

## 许可证
本项目采用MIT许可证，详见LICENSE文件。

---

**感谢使用Translate Chat！** 🎉 