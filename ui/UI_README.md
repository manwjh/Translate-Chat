# Translate Chat 主界面说明 / Main Window Guide

---

## 界面布局 / Layout Overview

- **窗口标题**：Translate Chat
- **整体分为三部分**：
  1. 顶部标题区
  2. 中部对话区
  3. 底部控制区

---

## 区域说明 / Area Details

### 1. 顶部标题区 / Top Title Area
- 显示应用名称（Translate Chat）
- 字体大且加粗，突出显示应用身份

### 2. 中部对话区 / Central Chat Area
- 展示所有对话内容，支持中英文对照
- 每条固化分句（已确认的识别结果）以白色字体显示，分句之间有间隔
- 翻译内容显示为灰色小字，原文在上，翻译在下
- 超时固化的分句会有红色小字提示
- 未固化分句（临时识别结果）以黄色斜体显示，仅显示最新一条，突出当前识别进度

### 3. 底部控制区 / Bottom Control Area
- 包含四个控件（从左到右）：
  - 麦克风开关按钮（显示当前麦克风状态）
  - 停止识别按钮
  - 重置按钮（清空所有内容）
  - “是否翻译”复选框（控制是否显示翻译内容）
- 按钮整体靠左排列，右侧自动补齐空白

---

## 主要功能 / Main Features

- **中英文对照显示**：每条语音分句及其翻译分两行展示，便于对照理解
- **分句固化**：识别到的分句固化后以气泡样式追加，防止重复
- **实时高亮**：未固化分句以黄色斜体高亮，增强用户感知
- **超时提示**：超时固化分句有红色提示
- **一键重置**：点击重置按钮可清空所有内容
- **翻译开关**：可通过复选框控制是否显示翻译内容

---

## 交互逻辑 / Interaction Logic

- 识别到的分句会自动追加到对话区，内容分为原文和翻译
- 固化分句自动去重，避免重复显示
- 支持多轮对话，内容会不断追加
- “是否翻译”复选框可随时切换翻译显示
- 重置按钮可随时清空所有内容，方便重新开始
- 关闭窗口时自动退出应用

---

## 前端与后端通讯流程图 / Frontend-Backend Communication Flow

以下流程图展示了Translate Chat主界面与ASR后端通讯的主要步骤：

The following diagram illustrates the main steps of communication between the Translate Chat UI and the ASR backend:

```mermaid
sequenceDiagram
    participant User
    participant UI as Kivy前端
    participant ASR as ASR客户端
    participant Cloud as 火山ASR云服务

    User->>UI: 点击Mic按钮 / Click Mic
    UI->>ASR: 启动音频采集与识别线程 / Start audio & ASR thread
    ASR->>Cloud: 建立WebSocket连接 / Connect WebSocket
    loop 音频流 / Audio stream
        ASR->>Cloud: 发送音频数据 / Send audio
        Cloud-->>ASR: 返回识别结果(JSON) / Return result (JSON)
        ASR-->>UI: 回调on_result(response)
        UI->>UI: _show_asr_utterances(utterances)
    end
    User->>UI: 点击Stop/Reset / Click Stop/Reset
    UI->>ASR: 停止音频采集/清空界面 / Stop audio/clear UI
```

---

## 适用场景 / Usage Scenarios

- 语音翻译、实时对话、语言学习等需要中英文对照和分句展示的场景

---

如需进一步开发或定制，请参考主界面源代码。

For further development or customization, please refer to the main window source code. 