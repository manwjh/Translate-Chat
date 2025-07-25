# 翻译APP

**版本：v0.2**  
**作者：深圳王哥 & AI**  
**创建日期：2025/7/25**  

要实现一个跨平台（macOS + Linux）、轻量级、使用火山引擎的实时语音翻译对照软件，建议按以下结构分阶段规划和实现。目标是 简约界面 + 高效交互 + 稳定运行。

⸻

🧭 一、系统目标概述

功能	说明
🎙 实时语音转文字	利用火山 ASR 实现语音识别（支持流式）
🌐 语种识别 + 翻译	每段识别文本后，判断语种并翻译为另外语种（只实现中-英互译。即将识别为中文的句子翻译为英文，将识别为英文的句子翻译为中文）
☁️ 基于火山引擎API	使用火山 ASR 模型 + doubao LLM 模型


⸻

🏗 二、系统模块设计

1. 核心模块划分

🎧 语音采集模块
- 捕捉麦克风输入、处理流式音频
- PyAudio
🔊 实时ASR模块
- 与火山流式ASR模型通信，返回文字
- WebSocket + 火山引擎API
🌐 语种识别和翻译模块
- 判断语言种类
- 同时将当前文字翻译为对方语种
- 使用doubao-seed-1-6模型进行翻译，HTTP请求火山LLM
💬 UI界面模块
- 展示源语言和翻译后语言的对照内容显示，采用流式输出。


⸻

🖥 三、界面布局设计（简约模式）

**主界面布局：**

- **标题栏**：显示 "🔁 Translate Chat"
- **对话区域**：
  - A: What's your name!
  - ASI: 你叫什么名字？
  
  - B: 我叫Mike
  - BSI: My name is Mike
- **控制按钮区域**：
  - 🎙 Mic ON（麦克风开启）
  - ⏹ Stop（停止）
  - 🔄 Reset（重置）


⸻

🔧 四、技术实现建议

1. 音频采集与流式ASR
	•	使用 PyAudio实现麦克风流式采集
	•	对接火山流式ASR WebSocket接口
	•   火山的流式模型，支持字、句检测。

2. 语种识别
	•	通过 LLM检测语种（使用火山 doubao-seed-1-6-flash-250615 模型进行）

3. 翻译与LLM调用
	•	使用火山 doubao-seed-1-6-flash-250615 模型进行：
	•	翻译：请将下列句子翻译成[目标语种]：xxx
	•	其他拓展功能：段落总结、语法纠错

4. UI框架
	•	PyQt6：快速跨平台 GUI 原型

---

## 目录结构

```
Translate-Chat/
  ├── asr_client.py
  ├── audio_capture.py
  ├── config_template.py
  ├── lang_detect.py
  ├── main.py
  ├── README.md
  ├── requirements.txt
  ├── run.sh
  ├── Translate-Chat/
  │     └── README.md
  ├── translator.py
  ├── ui/
  │     └── main_window.py
  └── venv/
```

## 依赖
- Python 3.7+
- PyQt5

安装依赖：
```bash
pip install -r requirements.txt
```

## 运行方式
```bash
cd 翻译app
bash run.sh
```
或
```bash
cd 翻译app
python3 main.py
```

## 说明
- `ui/main_window.py`：主界面代码
- `translator.py`：翻译逻辑
- `config.py`：配置项
- `lang_detect.py`：语言检测
- `main.py`：程序入口
- `requirements.txt`：依赖列表
- `run.sh`：一键运行脚本
- `test.pcm`：测试用音频文件 