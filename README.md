# Translate Chat 语音实时翻译对照软件

**版本：v0.1.1**  
**作者：深圳王哥 & AI**  
**创建日期：2025/7/25**  

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
- 📦 自动化打包脚本（Ubuntu/macOS）

---

## 更新日志 / Changelog

### v0.1.1 (2025/1/27)
- ✨ 新增 Ubuntu 和 macOS 自动化打包脚本
- 📚 新增开发文档和打包说明
- 🔧 优化 buildozer 配置
- 🆕 新增热词检测和说话人切换检测功能
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
  ├── config_template.py           # 配置模板（请复制为config.py）
  ├── config.py                    # 实际配置（含密钥，勿上传）
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
# 复制配置模板
cp config_template.py config.py

# 编辑配置文件，填入你的API密钥
# 或设置环境变量
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

请在运行前设置以下环境变量，或复制 `config_template.py` 为 `config.py` 并填写密钥：
- `ASR_APP_KEY` - 火山引擎ASR应用密钥
- `ASR_ACCESS_KEY` - 火山引擎访问密钥
- `LLM_API_KEY` - 大语言模型API密钥

示例（Linux/macOS终端）：
```bash
export ASR_APP_KEY=你的ASR_APP_KEY
export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
export LLM_API_KEY=你的LLM_API_KEY
```
> ⚠️ 建议不要将密钥写入代码或上传到GitHub。

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
- 配置模板请参考 `config_template.py`
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