# 版本管理脚本使用说明

**文件名(File):** VERSION_MANAGER_USAGE.md  
**版本(Version):** v2.0.2  
**作者(Author):** 深圳王哥 & AI  
**创建日期(Created):** 2025/07/29  
**简介(Description):** 版本管理脚本详细使用说明

---

## 🎯 脚本功能

版本管理脚本 (`scripts/version_manager.py`) 是一个自动化工具，用于管理Translate-Chat项目的版本号和文件创建日期。

### 主要功能
- ✅ **版本号统一管理**: 自动更新所有文件的版本号
- ✅ **时间自动获取**: AI自动获取当前时间，无需手动输入
- ✅ **创建日期同步**: 自动更新文件头部的创建日期
- ✅ **版本一致性验证**: 检查所有文件版本号是否一致
- ✅ **更新日志生成**: 自动生成CHANGELOG.md条目
- ✅ **项目信息查询**: 显示当前项目状态信息

---

## 🚀 使用方法

### 1. 查看项目信息
```bash
# 显示当前项目状态
python3 scripts/version_manager.py info
```

**输出示例:**
```
==================================================
📊 项目信息
==================================================
当前版本: 2.0.2
当前日期: 2025/07/29
当前时间: 2025/07/29 12:07:29
项目根目录: /Users/wangjunhui/playcode/Translate-Chat
需要管理的文件数量: 19
==================================================
```

### 2. 验证版本一致性
```bash
# 检查所有文件版本号是否一致
python3 scripts/version_manager.py validate
```

**输出示例:**
```
验证版本号一致性 (当前版本: 2.0.2)
--------------------------------------------------
✅ 版本一致: /Users/wangjunhui/playcode/Translate-Chat/main.py
✅ 版本一致: /Users/wangjunhui/playcode/Translate-Chat/asr_client.py
...
所有文件版本号一致 ✅
```

### 3. 自动版本升级
```bash
# 自动升级补丁版本 (2.0.2 -> 2.0.3)
python3 scripts/version_manager.py bump

# 自动升级并更新创建日期
python3 scripts/version_manager.py bump --update-date

# 自动升级并添加更新日志
python3 scripts/version_manager.py bump --changes "修复了某个bug" "添加了新功能"

# 完整升级（版本+日期+日志）
python3 scripts/version_manager.py bump --update-date --changes "重大功能更新" "性能优化"
```

### 4. 指定版本更新
```bash
# 更新到指定版本
python3 scripts/version_manager.py update --version 2.1.0

# 更新到指定版本并同步日期
python3 scripts/version_manager.py update --version 2.1.0 --update-date

# 更新到指定版本并添加日志
python3 scripts/version_manager.py update --version 2.1.0 --changes "新版本发布"
```

---

## 📋 参数说明

### 主要操作
- `info` - 显示项目信息
- `validate` - 验证版本一致性
- `bump` - 自动版本升级
- `update` - 指定版本更新

### 可选参数
- `--version, -v` - 指定新版本号 (格式: x.y.z)
- `--changes, -c` - 更新内容描述 (可多个)
- `--update-date, -d` - 同时更新文件创建日期

---

## 🔧 支持的文件类型

脚本会自动管理以下文件的版本号和创建日期：

### Python文件
- `main.py` - 主程序入口
- `asr_client.py` - 语音识别客户端
- `translator.py` - 翻译模块
- `config_manager.py` - 配置管理
- `setup_config.py` - 配置设置
- `hotwords.py` - 热词检测
- `lang_detect.py` - 语言检测
- `audio_capture.py` - 音频采集
- `audio_capture_pyaudio.py` - PyAudio音频采集

### UI文件
- `ui/main_window_kivy.py` - Kivy主窗口
- `ui/sys_config_window.py` - 系统配置窗口
- `ui/sys_config_window_simple.py` - 简化配置窗口

### 工具文件
- `utils/font_utils.py` - 字体工具
- `utils/file_downloader.py` - 文件下载器
- `utils/secure_storage.py` - 安全存储
- `utils/__init__.py` - 工具包初始化

### 配置文件
- `requirements-desktop.txt` - 桌面版依赖
- `pyproject.toml` - 项目配置
- `__init__.py` - 项目初始化

---

## 📝 版本号格式

### 支持的版本号格式
- `# 版本(Version): v2.0.2`
- `# Version: v2.0.2`
- `version = "2.0.2"`
- `__version__ = "2.0.2"`

### 支持的日期格式
- `# 创建日期(Created): 2025/07/29`
- `# Created: 2025/07/29`
- `# 创建日期(Created): 2025-07-29`
- `# Created: 2025-07-29`

---

## 🎯 使用场景

### 日常开发
```bash
# 开发完成后，升级补丁版本
python3 scripts/version_manager.py bump --update-date --changes "修复用户反馈的问题"
```

### 功能发布
```bash
# 新功能发布，升级次版本
python3 scripts/version_manager.py update --version 2.1.0 --update-date --changes "新增语音识别功能" "优化翻译性能"
```

### 重大更新
```bash
# 重大重构，升级主版本
python3 scripts/version_manager.py update --version 3.0.0 --update-date --changes "完全重构UI界面" "支持多语言" "性能大幅提升"
```

### 质量检查
```bash
# 发布前检查版本一致性
python3 scripts/version_manager.py validate
```

---

## ⚠️ 注意事项

1. **备份重要文件**: 脚本会修改多个文件，建议在运行前备份
2. **版本号格式**: 必须使用 x.y.z 格式 (如 2.0.2)
3. **Git提交**: 运行脚本后记得提交更改到Git
4. **测试验证**: 版本更新后建议运行测试确保功能正常

---

## 🔮 高级用法

### 批量更新多个版本
```bash
# 快速升级多个版本
for version in 2.0.3 2.0.4 2.0.5; do
    python3 scripts/version_manager.py update --version $version --update-date --changes "快速迭代更新"
done
```

### 自动化脚本集成
```bash
#!/bin/bash
# 自动化发布脚本示例

echo "开始版本发布流程..."

# 1. 验证版本一致性
python3 scripts/version_manager.py validate
if [ $? -ne 0 ]; then
    echo "版本验证失败，退出"
    exit 1
fi

# 2. 升级版本
python3 scripts/version_manager.py bump --update-date --changes "自动化发布"

# 3. 构建项目
python3 -m build

# 4. 提交到Git
git add .
git commit -m "Release v$(python3 -c "import sys; sys.path.append('.'); from __init__ import __version__; print(__version__)")"
git tag "v$(python3 -c "import sys; sys.path.append('.'); from __init__ import __version__; print(__version__)")"

echo "发布完成！"
```

---

**最后更新**: 2025/07/29  
**脚本版本**: v2.0.2 