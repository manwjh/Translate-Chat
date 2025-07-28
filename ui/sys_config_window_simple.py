# =============================================================
# 文件名(File): sys_config_window_simple.py
# 版本(Version): v1.0.0
# 作者(Author): AI Assistant
# 创建日期(Created): 2025/7/28
# 简介(Description): 简化的系统配置窗口，使用MDTopAppBar
# =============================================================

import os
import sys

# 确保UTF-8编码
if sys.platform.startswith('darwin'):  # macOS
    os.environ['PYTHONIOENCODING'] = 'utf-8'
    os.environ['LC_ALL'] = 'zh_CN.UTF-8'
    os.environ['LANG'] = 'zh_CN.UTF-8'

from kivy.lang import Builder
from kivy.properties import StringProperty, BooleanProperty
from kivy.metrics import dp
from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.card import MDCard
from kivymd.uix.button import MDRaisedButton
from kivymd.uix.textfield import MDTextField
from kivymd.uix.label import MDLabel
from kivymd.uix.boxlayout import MDBoxLayout

# 注册字体
try:
    from utils.font_utils import register_system_font
    font_name = register_system_font()
    print(f"[DEBUG] Font registered: {font_name}")
except Exception as e:
    print(f"[DEBUG] Font registration failed: {e}")
    font_name = 'Roboto'

KV = '''
<APIConfigScreen>:
    md_bg_color: app.theme_cls.bg_darkest if app else (0.1,0.1,0.1,1)
    
    MDTopAppBar:
        title: "System Configuration"
        right_action_items: [["menu", lambda x: root.go_back()]]
        elevation: 4
        md_bg_color: app.theme_cls.primary_color if app else (0.2,0.2,0.2,1)
        pos_hint: {'top': 1}
        size_hint_y: None
        height: dp(56)
    
    ScrollView:
        pos_hint: {'top': 0.9, 'bottom': 0}
        MDBoxLayout:
            orientation: 'vertical'
            padding: dp(16)
            spacing: dp(16)
            adaptive_height: True
            
            MDLabel:
                text: "系统配置"
                halign: 'center'
                font_size: '24sp'
                font_name: 'SystemFont'
            
            MDLabel:
                text: "点击右上角菜单按钮返回"
                halign: 'center'
                font_size: '16sp'
                font_name: 'SystemFont'
            
            MDRaisedButton:
                text: "返回主界面"
                font_name: 'SystemFont'
                pos_hint: {'center_x': 0.5}
                on_release: root.go_back()
'''

Builder.load_string(KV)

class APIConfigScreen(MDScreen):
    """简化的API配置界面"""
    
    def go_back(self):
        """返回主界面"""
        print("返回主界面")
        # 这里可以添加返回逻辑

class APIConfigApp(MDApp):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.font_name = font_name
    
    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Blue"
        
        # 设置窗口大小
        try:
            from kivy.core.window import Window
            Window.size = (400, 600)
        except Exception:
            pass
        
        return APIConfigScreen()

if __name__ == '__main__':
    APIConfigApp().run() 