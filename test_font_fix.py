#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from kivy.app import App
from kivy.lang import Builder
from kivy.uix.boxlayout import BoxLayout
from kivy.core.text import LabelBase
from utils.font_utils import register_system_font

# 导入 KivyMD 组件
from kivymd.app import MDApp
from kivymd.uix.label import MDLabel
from kivymd.uix.button import MDRaisedButton
from kivymd.uix.toolbar import MDTopAppBar

# 注册字体
font_name = register_system_font()
print(f"[TEST] Font registered: {font_name}")

# 定义KV字符串
kv_string = '''
BoxLayout:
    orientation: 'vertical'
    md_bg_color: 0.12, 0.12, 0.12, 1  # 深色背景
    
    MDTopAppBar:
        title: 'Test App'
        right_action_items: [["menu", lambda x: print("Menu clicked")]]
        elevation: 0
        md_bg_color: 0.2, 0.6, 1, 1
    
    BoxLayout:
        orientation: 'vertical'
        padding: 20
        spacing: 10
        
        MDLabel:
            text: '欢迎光临 Hello World!'
            font_name: 'SystemFont'
            font_size: 24
            theme_text_color: 'Custom'
            text_color: 0.2, 0.2, 0.2, 1
            size_hint_y: None
            height: 50
        
        MDLabel:
            text: 'English text test'
            font_name: 'SystemFont'
            font_size: 18
            theme_text_color: 'Custom'
            text_color: 0.8, 0.8, 0.8, 1
            size_hint_y: None
            height: 40
        
        MDRaisedButton:
            text: '测试按钮 Test Button'
            font_name: 'SystemFont'
            size_hint: None, None
            size: 200, 50
            pos_hint: {'center_x': 0.5}
'''

class TestApp(MDApp):
    def build(self):
        return Builder.load_string(kv_string)

if __name__ == '__main__':
    TestApp().run() 