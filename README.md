# Translate-Chat

**文件名(File):** README.md  
**版本(Version):** v0.1.3  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/1/27  
**简介(Description):** 基于火山引擎ASR和LLM的实时语音翻译工具，支持多语言互译

---

## 🧭 项目简介 / Project Overview

Translate Chat 是一款跨平台（macOS、Linux、Android）轻量级、基于火山引擎的实时语音转文字与中英互译软件。主界面采用 KivyMD 框架，支持流式语音识别、自动语种检测与翻译，并以气泡对照方式展示原文与译文。

---

## 主要功能 / Features
- 🎤 实时语音转文字（火山 ASR 流式识别）
- 🌍 自动语种检测（中英互译）
- 💬 识别结果与翻译对照气泡展示
- ⏰ 超时自动固化分句提示
- 🔄 一键重置、翻译显示开关
- 📱 跨平台支持：桌面（PyAudio）、Android（Plyer）
- 🔥 热词检测与说话人切换检测
- 🔒 智能令牌管理（动态刷新、过期处理）
- 📦 自动化打包脚本（Ubuntu/macOS）

---

## 更新日志 / Changelog

### v0.1.1 (2025/1/27)
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
  ├── audio_capture.py             # 跨平台音频采集入口
  ├── audio_capture_pyaudio.py     # 桌面端音频采集实现
  ├── audio_capture_plyer.py       # Android音频采集实现
  
  
  ├── lang_detect.py               # 语言检测
  ├── main.py                      # 程序主入口（KivyMD UI）
  ├── hotwords.py                  # 热词检测功能
  ├── speaker_change_detector.py   # 说话人切换检测
  ├── requirements-desktop.txt     # 桌面依赖
  ├── requirements-android.txt     # Android依赖
  ├── run.sh                       # 跨平台启动脚本
  ├── translator.py                # 翻译逻辑
  ├── buildozer.spec              # Android打包配置
  ├── assets/
  │     └── fonts/
  │           └── NotoSansSC-VariableFont_wght.ttf
  ├── ui/
  │     ├── main_window_kivy.py    # KivyMD主界面
  │     ├── main_window_qt.py      # PyQt备用界面
  │     ├── font_test.py           # 字体测试
  │     └── UI_README.md           # UI说明文档
  ├── scripts/
  │     ├── build_android_ubuntu.sh # Ubuntu打包脚本
  │     ├── build_android_macos.sh  # macOS打包脚本
  │     ├── sdl2_local_manager.sh   # SDL2本地文件管理脚本
  │     ├── buildozer.spec         # 脚本专用配置
  │     └── README.md              # 打包脚本说明
  ├── docs/
  │     ├── linux_dev_guide.md      # Linux开发、运行和打包说明
  │     ├── macos_dev_guide.md      # macOS开发说明（可选）
  │     └── android_dev_guide.md    # Android开发说明（可选）
  └── ...
```

---

## 快速开始 / Quick Start

### 1. 环境准备
```bash
# 克隆项目
git clone https://github.com/manwjh/Translate-Chat.git
cd Translate-Chat

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# 或 venv\Scripts\activate  # Windows
```

### 2. 安装依赖
```bash
# 桌面版本
pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# Android版本
pip install -r requirements-android.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3. 配置API密钥
```bash
# 方式一：使用图形界面配置（推荐）
python3 setup_config.py

# 方式二：使用配置脚本
bash scripts/setup_env.sh -i

# 方式三：手动设置环境变量
export ASR_APP_KEY=你的ASR_APP_KEY
export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
export LLM_API_KEY=你的LLM_API_KEY


```

### 4. 运行程序
```bash
# 使用启动脚本（推荐）
bash run.sh

# 或直接运行
python3 main.py
```

---

## 📦 打包说明 / Build Instructions

### Android APK 打包

#### Ubuntu 环境（推荐）
```bash
# 给脚本添加执行权限
chmod +x scripts/build_android_ubuntu.sh

# 运行打包脚本
bash scripts/build_android_ubuntu.sh
```

#### macOS 环境
```bash
# 给脚本添加执行权限
chmod +x scripts/build_android_macos.sh

# 运行打包脚本
bash scripts/build_android_macos.sh
```

### 打包脚本特点
- 🚀 **自动化配置**：自动安装依赖、配置环境
- 🇨🇳 **国内镜像**：使用清华源加速下载
- 📱 **跨平台支持**：Ubuntu 和 macOS 双平台
- 📚 **详细文档**：完整的使用说明和故障排除
- 📦 **SDL2本地管理**：智能检查并下载SDL2依赖文件

### SDL2 本地文件管理

在打包Android应用之前，建议先运行SDL2本地文件管理脚本，以加速构建过程：

```bash
# 检查并下载SDL2依赖文件
bash scripts/sdl2_local_manager.sh
```

**脚本功能**：
- 🔍 **智能检查**：检查 `/tmp` 目录下是否已存在SDL2文件
- ⬇️ **按需下载**：只下载缺失的文件，避免重复下载
- 🔄 **重试机制**：下载失败时自动重试，提高成功率
- 🌐 **国内镜像**：使用GitHub官方源，确保文件完整性

详细说明请参考：[scripts/README.md](scripts/README.md)

---

## 依赖安装 / Dependencies

### 桌面（macOS/Linux）
- Python 3.7+
- PyAudio
- Kivy >=2.3.0
- KivyMD ==1.1.1
- websocket-client
- aiohttp

### Android 打包环境
- **Ubuntu**: OpenJDK 8, Python 3.7-3.10
- **macOS**: OpenJDK 17, Python 3.7-3.10
- **内存**: 建议4GB以上
- **磁盘**: 建议10GB以上可用空间

---

## API密钥配置 / API Key Configuration

本系统支持三种配置方式，按优先级排序：

### 配置优先级机制

**重要说明**: 系统按以下优先级加载配置，最终所有配置都会统一存储在配置管理器中：

1. **环境变量** (最高优先级) - 存储在操作系统环境变量中
2. **默认配置** (最低优先级) - 硬编码在代码中（仅用于开发测试，不包含敏感信息）

**统一存储**: 无论使用哪种配置方式，最终所有配置都会被统一存储在 `config_manager.config` 字典中，确保配置访问的一致性和统一性。

### 方式一：环境变量配置（推荐）

#### 使用图形界面配置（最简单）
```bash
# 启动图形配置界面
python3 setup_config.py
```

#### 使用配置脚本
```bash
# macOS/Linux/Android
bash scripts/setup_env.sh -i

# Windows
scripts\setup_env.bat -i
```

#### 手动设置环境变量

**macOS/Linux/Android:**
```bash
export ASR_APP_KEY=你的ASR_APP_KEY
export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
export LLM_API_KEY=你的LLM_API_KEY
export ASR_APP_ID=你的ASR_APP_ID  # 可选
```

**Windows (PowerShell):**
```powershell
$env:ASR_APP_KEY="你的ASR_APP_KEY"
$env:ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"
$env:LLM_API_KEY="你的LLM_API_KEY"
$env:ASR_APP_ID="你的ASR_APP_ID"  # 可选
```

**Windows (CMD):**
```cmd
set ASR_APP_KEY=你的ASR_APP_KEY
set ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
set LLM_API_KEY=你的LLM_API_KEY
set ASR_APP_ID=你的ASR_APP_ID  # 可选
```



### 配置检查

```bash
# macOS/Linux/Android
bash scripts/setup_env.sh -c

# Windows
scripts\setup_env.bat -c
```

### 配置机制详解

#### 配置加载流程
```
启动程序 → 配置管理器初始化 → 按优先级检查配置源:
    1. 检查环境变量 → 如果存在，加载到config_manager.config
    2. 使用默认配置 → 如果环境变量不存在，加载到config_manager.config
    ↓
所有模块通过config_manager.config访问配置
```

#### 令牌管理机制
系统支持智能令牌管理，包括：
- **动态令牌刷新**：自动检测令牌状态，支持实时刷新
- **过期处理**：令牌过期时自动重新获取，确保服务连续性
- **安全存储**：令牌仅存储在内存中，不写入文件
- **环境变量优先**：优先使用环境变量中的令牌，确保安全性

#### 配置访问方式
```python
# 通过配置管理器访问
from config_manager import config_manager
value = config_manager.get('ASR_APP_KEY')
```

#### 存储位置说明
| 配置方式 | 原始存储位置 | 最终统一存储位置 |
|---------|-------------|-----------------|
| **环境变量** | 操作系统环境变量 | config_manager.config |
| **默认配置** | 代码中硬编码（不含敏感信息） | config_manager.config |

> ⚠️ 建议使用环境变量方式，避免将密钥写入代码或上传到GitHub。

### 🔒 安全说明 / Security Notes

**重要安全提醒**：
- ✅ **已修复**：移除了代码中的硬编码API密钥
- ✅ **推荐**：使用环境变量方式配置API密钥
- ✅ **安全**：令牌仅存储在内存中，不写入文件
- ⚠️ **注意**：请勿将真实的API密钥提交到版本控制系统
- ⚠️ **注意**：定期更换API密钥，确保账户安全

**令牌管理最佳实践**：
1. 使用环境变量存储API密钥
2. 定期检查令牌有效性
3. 及时更新过期的令牌
4. 避免在日志中输出敏感信息

---

## 运行方式 / How to Run

推荐使用启动脚本自动安装依赖并运行：
```bash
bash run.sh
```
或手动：
```bash
python3 main.py
```

---

## 主界面说明 / Main UI Overview

- 采用 KivyMD 框架，气泡式对照显示原文与翻译
- 支持 Mic 开关、Stop、Reset、翻译显示开关
- 详细界面与交互逻辑见 [ui/UI_README.md](ui/UI_README.md)

---

## 试验模块 / Experimental Modules

1. **speaker_change_detector.py** - 人声切换检测
   - 基于 Resemblyzer 和 WebRTC VAD 的说话人变化检测
   - 支持实时音频流处理
   - 可配置的检测阈值和参数

---

## 开发文档 / Development Docs

- 📖 [Linux开发指南](docs/linux_dev_guide.md) - Linux环境开发、运行和打包
- 🍎 [Android开发指南](docs/android_dev_guide.md) - Android平台开发说明
- 📦 [打包脚本说明](scripts/README.md) - 自动化打包脚本使用指南
- 🖥️ [UI开发说明](ui/UI_README.md) - 界面开发文档

---

## 其他说明 / Notes
- `ui/main_window_kivy.py` 为主力UI，`ui/main_window_qt.py`为备用PyQt界面
- 字体已内置于 `assets/fonts/`
- `font_test.py` 可用于测试字体显示
- 旧版 `requirements.txt`、`ui/main_window.py` 已废弃

- 开发文档见 `docs/` 目录，包含各平台开发、运行与打包说明

---

## 📞 联系方式 / Contact

- **项目邮箱**: manwjh@126.com
- **GitHub**: https://github.com/manwjh/Translate-Chat

---

## 致谢 / Thanks
- 火山引擎 ASR & LLM API
- Kivy/KivyMD & PyQt
- 深圳王哥 & AI 