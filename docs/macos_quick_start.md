# Translate Chat - macOS 快速开始指南

**版本**: v2.1.0  
**更新时间**: 2025/7/25  
**适用系统**: macOS 10.15+ (Catalina及以上)

---

## 🚀 一键运行

```bash
# 1. 下载项目
git clone https://github.com/manwjh/Translate-Chat.git
cd Translate-Chat

# 2. 一键运行（自动安装依赖并启动）
bash run.sh
```



---

## 📋 系统要求

- **macOS**: 10.15 (Catalina) 或更高版本
- **Python**: 3.8 - 3.11 (推荐 3.10)
- **内存**: 至少 4GB RAM
- **存储**: 至少 500MB 可用空间

---

## 🔧 环境检查

### 检查Python版本
```bash
python3 --version
# 应该显示 Python 3.8.x 到 3.11.x
```

### 检查Git（macOS通常自带）
```bash
git --version
# 如果提示未安装，系统会自动提示安装Xcode Command Line Tools
```

---

## ⚙️ 首次配置

1. **启动程序后，会自动进入配置界面**
2. **填写API密钥信息**：
   - `ASR_APP_ID`: 火山引擎ASR应用ID
   - `ASR_ACCESS_KEY`: 火山引擎访问密钥
   - `LLM_API_KEY`: 豆包API密钥
3. **点击保存**，配置会自动加密保存到本地
4. **配置完成后自动进入主界面**

### 🔑 获取API密钥

#### 火山引擎ASR
1. 访问 [火山引擎控制台](https://console.volcengine.com/)
2. 开通语音识别服务
3. 创建应用，获取 `ASR_APP_ID` 和 `ASR_ACCESS_KEY`

#### 豆包API
1. 访问 [豆包开放平台](https://www.doubao.com/)
2. 注册账号并开通API服务
3. 获取 `LLM_API_KEY`

---

## 🎯 使用说明

### 主界面功能
- **Mic ON**: 开始语音识别和翻译
- **Stop**: 停止语音识别
- **Reset**: 清空聊天记录
- **翻译开关**: 控制是否显示翻译结果

### 快捷键
- **Ctrl+C**: 复制选中的聊天内容到剪贴板

### 热词功能
- 在底部输入框添加热词，提高识别准确率
- 热词会自动保存，下次启动时自动加载

---

## 🛠️ 常见问题

### Q1: 提示"缺少依赖"
```bash
# 重新运行一键脚本
bash run.sh
```

### Q2: 音频权限问题
- 系统偏好设置 → 安全性与隐私 → 麦克风
- 确保允许终端或Python访问麦克风

### Q3: 网络连接问题
- 检查网络连接
- 确保能访问火山引擎和豆包API

### Q4: 配置丢失
- 配置文件存储在加密存储中
- 如需重新配置，删除程序后重新运行即可

---

## 📁 项目结构

```
Translate-Chat/
├── main.py                 # 主程序入口
├── run.sh                  # 一键运行脚本
├── requirements-desktop.txt # macOS依赖列表
├── ui/                     # 用户界面
│   ├── main_window_kivy.py # 主界面
│   └── sys_config_window.py # 配置界面
├── docs/                   # 文档
└── scripts/               # 构建脚本
```

---

## 🔄 更新程序

```bash
# 进入项目目录
cd Translate-Chat

# 拉取最新代码
git pull origin main

# 重新运行（自动更新依赖）
bash run.sh
```

---

## 📞 技术支持

- **GitHub Issues**: [项目问题反馈](https://github.com/manwjh/Translate-Chat/issues)
- **文档**: 查看 `docs/` 目录下的详细文档
- **配置指南**: 参考 `docs/config_guide.md`

---

## 📝 更新日志

### v2.1.0 (2025/7/25)
- ✅ 解决日志重复输出问题
- ✅ 优化UI界面显示
- ✅ 统一配置字段
- ✅ 修复配置页面问题

### v2.0.0 (2025/7/25)
- ✅ 支持KivyMD界面
- ✅ 支持加密存储配置
- ✅ 支持热词功能
- ✅ 支持多语言翻译

---

**享受使用 Translate Chat！** 🎉 