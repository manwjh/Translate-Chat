import subprocess
import os
from kivy.core.text import LabelBase

# 指定字体关键字进行搜索
FONT_SEARCH_KEYWORDS = [
    "PingFang",        # macOS
    "Noto Sans CJK",   # Ubuntu/Debian
    "WenQuanYi",       # Debian/CentOS
    "SimSun",          # Wine/部分中文支持
    "Microsoft YaHei"  # 少部分有安装
]

def find_font_by_keywords(keywords):
    """
    用 fc-list 查找包含关键词的字体路径
    """
    try:
        output = subprocess.check_output(['fc-list', ':lang=zh', 'file'], universal_newlines=True)
    except Exception:
        return None

    font_paths = output.strip().split('\n')
    for path in font_paths:
        for kw in keywords:
            if kw.lower() in path.lower():
                font_file = path.split(":")[0]
                if os.path.exists(font_file):
                    return font_file
    return None

def register_system_font():
    """
    自动检测并注册系统中的中文支持字体，返回字体名。
    """
    font_path = find_font_by_keywords(FONT_SEARCH_KEYWORDS)
    if font_path:
        LabelBase.register(name="SystemFont", fn_regular=font_path)
        return "SystemFont"
    return "Roboto"  # fallback，Kivy默认字体 