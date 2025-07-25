from kivy.app import App
from kivy.uix.label import Label
import os
from kivy.core.text import LabelBase
# 适配任何运行目录，使用实际字体文件名
FONT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../assets/fonts/NotoSansSC-VariableFont_wght.ttf'))
LabelBase.register(name="NotoSansSC", fn_regular=FONT_PATH)

class TestApp(App):
    def build(self):
        return Label(text="中文测试", font_name="NotoSansSC", font_size=40)

if __name__ == "__main__":
    TestApp().run()
