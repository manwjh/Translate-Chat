# =============================================================
# 文件名(File): lang_detect.py
# 版本(Version): v2.0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/07/29
# 简介(Description): 语言检测模块
# =============================================================

class LangDetect:
    def __init__(self):
        pass

    def detect(self, text):
        # 更精确的语言检测
        chinese_chars = sum(1 for c in text if '\u4e00' <= c <= '\u9fff')
        english_chars = sum(1 for c in text if c.isalpha() and ord(c) < 128)
        
        if chinese_chars > english_chars:
            return 'zh-CN'
        elif english_chars > 0:
            return 'en'
        else:
            return 'auto'  # 无法确定时使用自动检测 