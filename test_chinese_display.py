#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# =============================================================
# 文件名(File): test_chinese_display.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 测试中文字符显示的简单脚本
# =============================================================

import os
import sys
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button

class TestApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # 测试中文字符
        test_texts = [
            "API配置",
            "语音识别 (ASR) 配置", 
            "大语言模型 (LLM) 配置",
            "配置说明",
            "保存配置",
            "检查配置"
        ]
        
        for text in test_texts:
            label = Label(
                text=text,
                font_size='18sp',
                color=(1, 1, 1, 1),
                size_hint_y=None,
                height=40
            )
            layout.add_widget(label)
        
        # 添加一个按钮
        button = Button(
            text="测试按钮",
            size_hint_y=None,
            height=50
        )
        layout.add_widget(button)
        
        return layout

if __name__ == "__main__":
    TestApp().run() 