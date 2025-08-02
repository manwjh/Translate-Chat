# =============================================================
# 文件名(File): __init__.py
# 版本(Version): v2.0.2
# 最后更新(Updated): 2025/07/29
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/07/29
# 简介(Description): Translate-Chat 项目包初始化文件，统一版本管理
# =============================================================

"""
Translate-Chat - 实时语音识别与翻译桌面应用

一个基于Kivy/KivyMD的跨平台桌面应用，支持实时语音识别和多语言翻译。
专注于桌面端体验，支持macOS和Linux系统。
"""

__version__ = "2.0.2"
__author__ = "深圳王哥 & AI"
__email__ = "support@translate-chat.com"
__description__ = "实时语音识别与翻译桌面应用"
__url__ = "https://github.com/manwjh/Translate-Chat"
__license__ = "MIT"

# 导出主要模块
from . import main
from . import config_manager
from . import translator
from . import asr_client

__all__ = [
    "__version__",
    "__author__", 
    "__email__",
    "__description__",
    "__url__",
    "__license__",
    "main",
    "config_manager", 
    "translator",
    "asr_client"
] 