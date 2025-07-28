# Translate-Chat 配置指南

**文件名(File):** config_guide.md  
**版本(Version):** v1.0.0  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/7/25  
**简介(Description):** 详细的API配置指南，支持多平台环境变量配置

---

## 配置方式概述

本系统支持三种配置方式，按优先级排序：

1. **环境变量配置**（推荐）- 更安全，支持跨平台
2. **配置文件方式** - 传统方式，向后兼容
3. **默认配置** - 硬编码配置，仅用于开发测试

### 重要机制说明

**配置优先级机制**: 系统按以下优先级加载配置，最终所有配置都会统一存储在配置管理器中：

1. **环境变量** (最高优先级) - 存储在操作系统环境变量中
2. **config.py文件** (中等优先级) - 存储在项目目录的config.py文件中  
3. **默认配置** (最低优先级) - 硬编码在代码中（仅用于开发测试）

**统一存储机制**: 无论使用哪种配置方式，最终所有配置都会被统一存储在 `config_manager.config` 字典中，确保配置访问的一致性和统一性。

---

## 方式一：环境变量配置（推荐）

### 1.1 使用配置脚本（最简单）

#### macOS/Linux/Android
```bash
# 交互式配置
bash scripts/setup_env.sh -i

# 检查配置
bash scripts/setup_env.sh -c

# 移除配置
bash scripts/setup_env.sh -r
```

#### Windows
```cmd
# 交互式配置
scripts\setup_env.bat -i

# 检查配置
scripts\setup_env.bat -c
```

### 1.2 手动设置环境变量

#### macOS/Linux/Android (Bash/Zsh)
```bash
# 临时设置（当前会话有效）
export ASR_APP_ID="你的ASR_APP_ID"
export ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"
export LLM_API_KEY="你的LLM_API_KEY"

# 永久设置（添加到shell配置文件）
echo 'export ASR_APP_ID="你的ASR_APP_ID"' >> ~/.bashrc
echo 'export ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"' >> ~/.bashrc
echo 'export LLM_API_KEY="你的LLM_API_KEY"' >> ~/.bashrc

# 重新加载配置
source ~/.bashrc
```

#### Windows (PowerShell)
```powershell
# 临时设置（当前会话有效）
$env:ASR_APP_ID="你的ASR_APP_ID"
$env:ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"
$env:LLM_API_KEY="你的LLM_API_KEY"

# 永久设置（用户级别）
[Environment]::SetEnvironmentVariable("ASR_APP_ID", "你的ASR_APP_ID", "User")
[Environment]::SetEnvironmentVariable("ASR_ACCESS_KEY", "你的ASR_ACCESS_KEY", "User")
[Environment]::SetEnvironmentVariable("LLM_API_KEY", "你的LLM_API_KEY", "User")
```

#### Windows (CMD)
```cmd
# 临时设置（当前会话有效）
set ASR_APP_ID=你的ASR_APP_ID
set ASR_ACCESS_KEY=你的ASR_ACCESS_KEY
set LLM_API_KEY=你的LLM_API_KEY

# 永久设置（用户级别）
setx ASR_APP_ID "你的ASR_APP_ID"
setx ASR_ACCESS_KEY "你的ASR_ACCESS_KEY"
setx LLM_API_KEY "你的LLM_API_KEY"
```

### 1.3 Android 特殊配置

在Android环境中，可以使用以下方式：

```bash
# Termux 环境
export ASR_APP_ID="你的ASR_APP_ID"
export ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"
export LLM_API_KEY="你的LLM_API_KEY"

# 添加到 ~/.bashrc 实现永久设置
echo 'export ASR_APP_ID="你的ASR_APP_ID"' >> ~/.bashrc
echo 'export ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"' >> ~/.bashrc
echo 'export LLM_API_KEY="你的LLM_API_KEY"' >> ~/.bashrc
```

---

## 方式二：配置文件方式

### 2.1 配置方式（推荐使用环境变量）

```bash
# 方式一：使用图形界面配置（推荐）
python3 setup_config.py

# 方式二：使用配置脚本
bash scripts/setup_env.sh -i

# 方式三：手动设置环境变量
export ASR_APP_ID="你的ASR_APP_ID"
export ASR_ACCESS_KEY="你的ASR_ACCESS_KEY"
export LLM_API_KEY="你的LLM_API_KEY"
```

### 2.2 配置文件内容示例

```python
# 火山ASR配置
ASR_WS_URL = "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async"
ASR_APP_ID = "你的ASR_APP_ID"
ASR_ACCESS_KEY = "你的ASR_ACCESS_KEY"
ASR_SAMPLE_RATE = 16000

# LLM（翻译/语种识别）配置
LLM_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
LLM_API_KEY = "你的LLM_API_KEY"
LLM_MODEL = "doubao-seed-1-6-flash-250615"

# 其他可选配置
TRANSLATE_API_URL = LLM_BASE_URL + "/chat/completions"
```

---

## 配置验证

### 3.1 使用脚本验证

```bash
# macOS/Linux/Android
bash scripts/setup_env.sh -c

# Windows
scripts\setup_env.bat -c
```

### 3.2 手动验证

```bash
# 检查环境变量
echo $ASR_APP_ID
echo $ASR_ACCESS_KEY
echo $LLM_API_KEY

# 或者在Python中验证
python3 -c "
import os
print('ASR_APP_ID:', os.environ.get('ASR_APP_ID', '未设置'))
print('ASR_ACCESS_KEY:', os.environ.get('ASR_ACCESS_KEY', '未设置'))
print('LLM_API_KEY:', os.environ.get('LLM_API_KEY', '未设置'))
"
```

---

## 配置优先级

系统按以下优先级加载配置：

1. **环境变量** - 最高优先级（推荐）
2. **默认配置** - 最低优先级（仅用于开发测试，不包含敏感信息）

### 配置加载流程详解

```
启动程序 → 配置管理器初始化 → 按优先级检查配置源:
    1. 检查环境变量 → 如果存在，加载到config_manager.config
    2. 使用默认配置 → 如果环境变量不存在，加载到config_manager.config
    ↓
所有模块通过config_manager.config访问配置
```

### 统一存储机制

**重要**: 无论使用哪种配置方式，最终所有配置都会被统一存储在 `config_manager.config` 字典中！

```python
# 在config_manager.py中
class ConfigManager:
    def __init__(self):
        self.config = {}  # 这里是所有配置的最终统一存储位置
        self._load_config()
    
    def _load_config(self):
        # 按优先级加载，最终都存储到self.config中
        if env_config:
            self.config = env_config      # 环境变量 → 统一存储
        elif file_config:
            self.config = file_config     # config.py → 统一存储
        else:
            self.config = default_config  # 默认配置 → 统一存储
```

### 配置访问方式

```python
# 方式1: 通过配置管理器（推荐）
from config_manager import config_manager
value = config_manager.get('ASR_APP_ID')

# 方式2: 直接导入（向后兼容）
from config_manager import ASR_APP_ID
# ASR_APP_ID实际上是从config_manager.config中获取的
```

### 存储位置说明

| 配置方式 | 原始存储位置 | 最终统一存储位置 |
|---------|-------------|-----------------|
| **环境变量** | 操作系统环境变量 | config_manager.config |
| **config.py文件** | 项目目录下的config.py文件 | config_manager.config |
| **默认配置** | 代码中硬编码 | config_manager.config |

---

## 常见问题

### Q1: 环境变量设置后程序仍然报错
**A:** 确保重新启动终端或重新加载shell配置文件：
```bash
source ~/.bashrc  # 或 ~/.zshrc
```

### Q2: Windows下环境变量不生效
**A:** Windows需要重新启动命令提示符或PowerShell，或者使用`setx`命令设置用户级环境变量。

### Q3: Android环境下配置问题
**A:** 在Android环境中，确保在正确的shell中设置环境变量，并添加到`~/.bashrc`文件中。

### Q4: 配置文件和环境变量冲突
**A:** 环境变量优先级更高，会覆盖配置文件中的设置。

---

## 安全建议

1. **使用环境变量** - 避免将密钥写入代码文件
2. **不要提交密钥** - 确保`config.py`在`.gitignore`中
3. **定期更换密钥** - 定期更新API密钥
4. **限制访问权限** - 确保配置文件权限正确

---

## 联系支持

如有配置问题，请联系：manwjh@126.com 