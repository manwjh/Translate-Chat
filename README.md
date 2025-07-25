# Translate Chat 语音实时翻译对照软件

**版本：v0.1.0**  
**作者：深圳王哥 & AI**  
**创建日期：2025/7/25**  

---

## 🧭 项目简介 / Project Overview

Translate Chat 是一款跨平台（macOS、Linux、Android）轻量级、基于火山引擎的实时语音转文字与中英互译软件。主界面采用 KivyMD 框架，支持流式语音识别、自动语种检测与翻译，并以气泡对照方式展示原文与译文。

---

## 主要功能 / Features
- 实时语音转文字（火山 ASR 流式识别）
- 自动语种检测（中英互译）
- 识别结果与翻译对照气泡展示
- 超时自动固化分句提示
- 一键重置、翻译显示开关
- 跨平台支持：桌面（PyAudio）、Android（Plyer）

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
  ├── requirements-desktop.txt     # 桌面依赖
  ├── requirements-android.txt     # Android依赖
  ├── run.sh                       # 跨平台启动脚本
  ├── translator.py                # 翻译逻辑
  ├── assets/
  │     └── fonts/
  │           └── NotoSansSC-VariableFont_wght.ttf
  ├── ui/
  │     ├── main_window_kivy.py    # KivyMD主界面
  │     ├── main_window_qt.py      # PyQt备用界面
  │     ├── font_test.py           # 字体测试
  │     └── UI_README.md           # UI说明文档
  └── ...
```

---

## 依赖安装 / Dependencies

### 桌面（macOS/Linux）
- Python 3.7+
- PyAudio
- Kivy >=2.3.0
- KivyMD ==1.1.1
- websocket-client
- aiohttp

安装命令：
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-desktop.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### Android (Termux等)
- 见 requirements-android.txt

---

## API密钥配置 / API Key Configuration

请在运行前设置以下环境变量，或复制 `config_template.py` 为 `config.py` 并填写密钥：
- `ASR_APP_KEY`
- `ASR_ACCESS_KEY`
- `LLM_API_KEY`

示例（Linux/macOS终端）：
```bash
export ASR_APP_KEY=你的ASR_APP_KEY
export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
export LLM_API_KEY=你的LLM_API_KEY
```
> 建议不要将密钥写入代码或上传到GitHub。

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

## 其他说明 / Notes
- `ui/main_window_kivy.py` 为主力UI，`ui/main_window_qt.py`为备用PyQt界面
- 字体已内置于 `assets/fonts/`
- `font_test.py` 可用于测试字体显示
- 旧版 `requirements.txt`、`ui/main_window.py` 已废弃
- 配置模板请参考 `config_template.py`

---

项目邮箱: manwjh@126.com

---

## 致谢 / Thanks
- 火山引擎 ASR & LLM API
- Kivy/KivyMD & PyQt
- 深圳王哥 & AI 