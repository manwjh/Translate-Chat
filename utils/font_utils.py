# =============================================================
# 文件名(File): font_utils.py
# 版本(Version): v2.0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/07/29
# 简介(Description): 字体工具模块，自动检测并注册系统中文字体，彻底解决中文显示问题
# =============================================================

import subprocess
import os
import sys
import platform
from kivy.core.text import LabelBase

# 指定字体关键字进行搜索，按优先级排序
FONT_SEARCH_KEYWORDS = [
    "PingFang SC",     # macOS 简体中文
    "PingFang TC",     # macOS 繁体中文
    "PingFang",        # macOS 通用
    "Noto Sans SC",    # Google Noto 简体中文
    "Noto Sans TC",    # Google Noto 繁体中文
    "Noto Sans CJK",   # Google Noto CJK
    "WenQuanYi",       # Linux 文泉驿
    "SimSun",          # Windows 宋体
    "Microsoft YaHei", # Windows 微软雅黑
    "Source Han Sans", # Adobe 思源黑体
    "Hiragino Sans",   # macOS 冬青黑体
    "STHeiti",         # macOS 华文黑体
    "STSong",          # macOS 华文宋体
    "Arial Unicode MS", # macOS 通用Unicode字体
]

def get_platform_font_paths():
    """根据平台返回常见字体路径"""
    system = platform.system()
    
    if system == "Darwin":  # macOS
        return [
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/STHeiti Light.ttc",
            "/System/Library/Fonts/STHeiti Medium.ttc",
            "/System/Library/Fonts/STSong.ttc",
            "/System/Library/Fonts/Arial Unicode MS.ttf",
            "/Library/Fonts/Arial Unicode MS.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/Monaco.ttf",
        ]
    elif system == "Linux":
        return [
            "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
            "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
            "/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf",
        ]
    elif system == "Windows":
        return [
            "C:/Windows/Fonts/msyh.ttc",
            "C:/Windows/Fonts/simsun.ttc",
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/calibri.ttf",
        ]
    else:
        return []

def find_font_by_keywords(keywords):
    """
    用 fc-list 查找包含关键词的字体路径
    """
    try:
        # 先尝试查找中文语言字体
        output = subprocess.check_output(['fc-list', ':lang=zh', 'file'], universal_newlines=True)
        font_paths = output.strip().split('\n')
        
        # 按优先级搜索字体
        for kw in keywords:
            for path in font_paths:
                if kw.lower() in path.lower():
                    font_file = path.split(":")[0]
                    if os.path.exists(font_file):
                        print(f"[字体] 找到字体: {kw} -> {font_file}")
                        return font_file
    except Exception as e:
        print(f"[字体] fc-list 查找失败: {e}")
        
    # 如果 fc-list 失败，尝试直接查找常见字体路径
    common_font_paths = get_platform_font_paths()
    
    for font_path in common_font_paths:
        if os.path.exists(font_path):
            print(f"[字体] 找到字体文件: {font_path}")
            return font_path
            
    return None

def register_system_font():
    """
    自动检测并注册系统中的中文支持字体，返回字体名。
    增强版本：支持多平台、多回退机制
    """
    # 检查是否已经注册过
    try:
        LabelBase.get_system_font('SystemFont')
        print("[字体] SystemFont 已注册，跳过重复注册")
        return "SystemFont"
    except:
        pass
    
    # 尝试注册系统字体
    font_path = find_font_by_keywords(FONT_SEARCH_KEYWORDS)
    if font_path:
        try:
            LabelBase.register(name="SystemFont", fn_regular=font_path)
            print(f"[字体] 成功注册字体: SystemFont -> {font_path}")
            return "SystemFont"
        except Exception as e:
            print(f"[字体] 注册字体失败: {e}")
    
    # 如果注册失败，尝试使用 Kivy 内置的中文字体支持
    try:
        # 检查是否有内置的中文字体支持
        from kivy.core.text import DEFAULT_FONT
        print(f"[字体] 使用默认字体: {DEFAULT_FONT}")
        return DEFAULT_FONT
    except:
        pass
    
    # 最后的回退：尝试注册系统默认字体
    try:
        system_fonts = get_platform_font_paths()
        for font_path in system_fonts:
            if os.path.exists(font_path):
                try:
                    LabelBase.register(name="SystemFont", fn_regular=font_path)
                    print(f"[字体] 回退注册字体: SystemFont -> {font_path}")
                    return "SystemFont"
                except:
                    continue
    except Exception as e:
        print(f"[字体] 回退字体注册失败: {e}")
    
    print("[字体] 使用最终回退字体: Roboto")
    return "Roboto"  # fallback，Kivy默认字体

def test_font_rendering(font_name="SystemFont"):
    """
    测试字体渲染效果
    """
    try:
        from kivy.core.text import Label
        test_text = "测试中文显示 Test English 123"
        label = Label(text=test_text, font_name=font_name)
        label.refresh()
        
        # 检查是否有渲染问题
        if label.texture and label.texture.width > 0:
            print(f"[字体测试] {font_name} 渲染正常")
            return True
        else:
            print(f"[字体测试] {font_name} 渲染失败")
            return False
    except Exception as e:
        print(f"[字体测试] 测试失败: {e}")
        return False

def get_font_info():
    """
    获取当前系统字体信息
    """
    info = {
        "platform": platform.system(),
        "python_version": sys.version,
        "kivy_version": None,
        "registered_fonts": [],
        "system_fonts": []
    }
    
    try:
        import kivy
        info["kivy_version"] = kivy.__version__
    except:
        pass
    
    try:
        # 获取已注册的字体
        info["registered_fonts"] = list(LabelBase.get_system_fonts())
    except:
        pass
    
    try:
        # 获取系统字体列表
        if platform.system() == "Darwin":  # macOS
            output = subprocess.check_output(['fc-list', ':lang=zh', 'family'], universal_newlines=True)
            info["system_fonts"] = [line.split(':')[1].strip() for line in output.strip().split('\n') if ':' in line]
    except:
        pass
    
    return info 