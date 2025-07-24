class LangDetect:
    def __init__(self):
        pass

    def detect(self, text):
        # TODO: 实现语言检测逻辑
        return 'zh-CN' if any('\u4e00' <= c <= '\u9fff' for c in text) else 'en' 