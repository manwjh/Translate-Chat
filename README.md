# Translate-Chat

**文件名(File):** README.md  
**版本(Version):** v2.0.1  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/7/28  
**简介(Description):** 基于火山引擎ASR和LLM的实时语音翻译工具，专注桌面端体验

---

## 🧭 项目简介 / Project Overview

Translate Chat 是一款桌面端（macOS、Linux）轻量级、基于火山引擎的实时语音转文字与中英互译软件。主界面采用 KivyMD 框架，支持流式语音识别、自动语种检测与翻译，并以气泡对照方式展示原文与译文。

---

## 主要功能 / Features
- 🎤 实时语音转文字（火山 ASR 流式识别）
- 🌍 自动语种检测（中英互译）
- 💬 识别结果与翻译对照气泡展示
- ⚡ **并行异步处理**：ASR识别与翻译完全分离，翻译不阻塞实时识别
- 🔄 异步翻译队列，支持并发翻译处理
- 📥 **对话记录导出**：支持将所有对话记录下载为txt文件
- ⏰ 超时自动固化分句提示
- 🔄 一键重置、翻译显示开关
- 🖥️ 桌面端优化：macOS、Linux（ARM/x86_64）
- 🔥 热词检测与说话人切换检测
- 🔒 智能令牌管理（动态刷新、过期处理）
- 🛡️ 增强网络错误处理和重试机制
- 📦 自动化打包脚本（Ubuntu/macOS）

---

## 更新日志 / Changelog

### v2.0.1 (2025/7/28)
- 🎨 **界面优化**: 完善界面显示，解决中文显示问题
- 🖥️ **用户体验**: 优化界面布局和显示效果
- 🔧 **稳定性提升**: 修复界面相关的显示问题

### v2.0.0 (2025/7/25)
- 🚀 **重大重构**: 移除Android支持，专注桌面端体验
- 🖥️ **桌面优化**: 优化macOS和Linux平台性能
- 🎯 **简化依赖**: 移除SDL2等Android相关依赖
- 📦 **ARM支持**: 更好的ARM Linux平台兼容性
- 🔧 **代码清理**: 移除Android相关代码和配置

### v0.1.2 (2025/7/25)
- 🚀 **重大优化**: 重构为并行异步架构，ASR识别与翻译完全分离
- ⚡ **性能提升**: 翻译不再阻塞ASR实时识别，大幅提升响应速度
- 🔄 **异步队列**: 使用异步队列处理翻译任务，支持并发翻译
- 📥 **新增下载功能**: 支持将所有对话记录导出为txt文件
- 🛡️ **错误处理**: 增强网络超时和重试机制，提高稳定性
- 📝 **代码优化**: 重构翻译和ASR客户端，提升代码质量

### v0.1.1 (2025/7/25)
- ✨ 新增 Ubuntu 和 macOS 自动化打包脚本
- 📚 新增开发文档和打包说明
- 🔧 优化 buildozer 配置
- 🆕 新增热词检测和说话人切换检测功能
- 🔒 新增令牌管理功能，支持动态令牌刷新和过期处理
- 🛡️ 修复安全漏洞，移除硬编码API密钥
- 🐛 修复界面显示问题
- 📝 完善项目文档结构

### v0.1.0 (2025/1/25)
- 🎉 初始版本发布
- 🎤 实现基础语音识别和翻译功能
- 🖥️ 支持桌面和Android平台

---

## 目录结构 / Directory Structure

```
Translate-Chat/
  ├── asr_client.py                # 火山ASR客户端
  ├── audio_capture.py             # 桌面端音频采集入口
  ├── audio_capture_pyaudio.py     # 桌面端音频采集实现
  ├── lang_detect.py               # 语言检测
  ├── main.py                      # 程序主入口（KivyMD UI）
  ├── hotwords.py                  # 热词检测功能
  ├── speaker_change_detector.py.disabled   # 说话人切换检测（已禁用）
  ├── requirements-desktop.txt     # 桌面依赖
  ├── run.sh                       # 桌面端启动脚本
  ├── translator.py                # 翻译逻辑
  
  ├── ui/
  │     ├── main_window_kivy.py    # KivyMD主界面
  │     ├── main_window_qt.py      # PyQt备用界面
  │     ├── font_test.py           # 字体测试
  │     └── UI_README.md           # UI说明文档
  ├── scripts/
  │     ├── build_linux_desktop.sh      # macOS交叉编译Linux桌面应用脚本
  │     ├── linux_dependency_manager.sh # Linux桌面应用依赖管理脚本
  │     ├── test_linux_build.sh         # Linux打包环境测试脚本
  │     └── common_build_utils.sh       # 通用工具函数
  ├── utils/
  │     ├── __init__.py
  │     ├── file_downloader.py
  │     └── secure_storage.py
  ├── docs/
  │     ├── config_guide.md
  │     ├── linux_desktop_build.md
  │     ├── macos_quick_start.md
  │     └── sys_config_ui.md
  ├── config_manager.py            # 配置管理
  ├── setup_config.py              # 配置启动脚本
  └── README.md                    # 项目说明
```

---

## 快速开始 / Quick Start

### 1. 环境要求
- **Python**: 3.9-3.11 (推荐3.10)
- **系统**: macOS 10.15+ 或 Linux (Ubuntu 18.04+)
- **内存**: 建议4GB以上
- **磁盘**: 建议2GB以上可用空间

### 2. 一键启动
```bash
# 克隆项目
git clone https://github.com/your-repo/Translate-Chat.git
cd Translate-Chat

# 一键启动（自动安装依赖）
chmod +x run.sh
./run.sh
```

### 3. 手动安装
```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements-desktop.txt

# 运行应用
python3 main.py
```

---

## 依赖安装 / Dependencies

### 桌面端依赖
- **Python**: 3.9-3.11 (推荐3.10)
- **PyAudio**: 音频采集
- **Kivy**: >=2.3.0,<3.0.0
- **KivyMD**: ==1.1.1
- **websocket-client**: 网络通信
- **aiohttp**: 异步HTTP
- **cryptography**: 加密存储
- **numpy/scipy**: 音频处理
- **webrtcvad**: 语音活动检测

### Linux 桌面应用打包环境
- **macOS**: Docker Desktop, Python 3.9-3.11
- **内存**: 建议8GB以上
- **磁盘**: 建议15GB以上可用空间
- **网络**: 需要稳定的网络连接下载Docker镜像

---

## API密钥配置 / API Key Configuration

本系统支持三种配置方式，按优先级排序：

### 配置优先级机制

1. **环境变量** (开发者模式)
2. **加密存储** (用户模式) 
3. **默认配置** (兜底模式)

### 配置方法

#### 方法1: 图形界面配置 (推荐)
```bash
python3 setup_config.py
```

#### 方法2: 环境变量配置
```bash
export ASR_APP_ID="your_asr_app_id"
export ASR_ACCESS_KEY="your_asr_access_key"
export LLM_API_KEY="your_llm_api_key"
python3 main.py
```

#### 方法3: 手动编辑配置文件
```bash
# 编辑配置文件
nano ~/.translate_chat/config.json
```

### 所需API密钥

1. **火山引擎ASR** (语音识别)
   - ASR_APP_ID: 应用ID
   - ASR_ACCESS_KEY: 访问密钥

2. **火山引擎LLM** (翻译服务)
   - LLM_API_KEY: API密钥

---

## 使用说明 / Usage

### 基本操作
1. **启动应用**: 运行 `./run.sh` 或 `python3 main.py`
2. **配置API**: 首次运行会自动启动配置界面
3. **开始录音**: 点击录音按钮开始语音识别
4. **查看结果**: 识别结果和翻译会实时显示
5. **导出记录**: 点击下载按钮导出对话记录

### 高级功能
- **热词检测**: 自动识别和标记重要词汇
- **说话人切换**: 检测不同说话人的语音
- **异步翻译**: 翻译不阻塞实时识别
- **错误重试**: 自动处理网络错误和重试

---

## 打包部署 / Build & Deploy

### Linux 桌面应用打包

#### macOS用户（交叉编译）
```bash
# 1. 测试Linux打包环境（推荐）
./scripts/test_linux_build.sh

# 2. 下载Linux依赖包（可选，用于加速构建）
./scripts/linux_dependency_manager.sh

# 3. 构建Linux桌面应用
./scripts/build_linux_desktop.sh
```

### 打包脚本特点
- 🚀 **自动化配置**：自动安装依赖、配置环境
- 🇨🇳 **国内镜像**：使用清华源加速下载
- 🖥️ **桌面端优化**：专注macOS和Linux平台
- 📚 **详细文档**：完整的使用说明和故障排除
- 🐳 **Docker交叉编译**：支持macOS交叉编译Linux应用

### Linux 桌面应用打包

详细说明请参考：[Linux桌面应用打包指南](docs/linux_desktop_build.md)

---

## 故障排除 / Troubleshooting

### 常见问题

#### 1. 音频设备问题
```bash
# Linux下安装PortAudio
sudo apt-get install portaudio19-dev

# macOS下安装PortAudio
brew install portaudio
```

#### 2. Python版本问题
```bash
# 检查Python版本
python3 --version

# 推荐使用Python 3.10
```

#### 3. 依赖安装失败
```bash
# 使用国内镜像
pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

#### 4. 权限问题
```bash
# 确保脚本有执行权限
chmod +x run.sh
chmod +x scripts/*.sh
```

#### 5. PyInstaller兼容性问题
```bash
# 如果遇到typing包兼容性错误，运行修复脚本
./scripts/fix_pyinstaller_compatibility.sh

# 或者手动移除typing包
pip uninstall -y typing
```

---

## 技术支持 / Support

如果遇到问题，请：

1. 检查环境要求是否满足
2. 查看错误日志信息
3. 参考故障排除指南
4. 提交Issue并提供详细的错误信息

---

## 贡献指南 / Contributing

欢迎贡献代码和改进建议：

1. Fork项目仓库
2. 创建功能分支
3. 提交代码更改
4. 创建Pull Request
5. 等待代码审查

---

*本文档最后更新: 2025/7/28* 
- 深圳王哥 & AI 