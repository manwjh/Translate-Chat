# =============================================================
# 文件名(File): api_config_screen.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): API配置界面，支持桌面和手机系统
# =============================================================

import os
import json
import platform
from kivy.lang import Builder
from kivy.properties import StringProperty, BooleanProperty
from kivy.clock import Clock
from kivy.core.window import Window
from kivy.metrics import dp

from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.card import MDCard
from kivymd.uix.button import MDRaisedButton, MDTextButton
from kivymd.uix.textfield import MDTextField
from kivymd.uix.label import MDLabel
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.dialog import MDDialog
from kivymd.uix.list import OneLineListItem
from kivymd.uix.selectioncontrol import MDSwitch
from kivymd.uix.toolbar import MDTopAppBar

# 检测平台
def get_platform():
    if platform.system() == "Darwin":
        return "macos"
    elif platform.system() == "Linux":
        return "linux"
    elif platform.system() == "Windows":
        return "windows"
    elif "android" in platform.system().lower():
        return "android"
    else:
        return "unknown"

# 获取配置文件路径
def get_config_file_path():
    platform_type = get_platform()
    home = os.path.expanduser("~")
    
    if platform_type == "macos":
        # 检测shell类型
        shell = os.environ.get('SHELL', '')
        if 'zsh' in shell:
            return os.path.join(home, '.zshrc')
        else:
            return os.path.join(home, '.bash_profile')
    elif platform_type == "linux":
        shell = os.environ.get('SHELL', '')
        if 'zsh' in shell:
            return os.path.join(home, '.zshrc')
        else:
            return os.path.join(home, '.bashrc')
    elif platform_type == "android":
        return os.path.join(home, '.bashrc')
    else:
        return os.path.join(home, '.bashrc')

# KV语言界面定义
KV = '''
<APIConfigScreen>:
    MDBoxLayout:
        orientation: 'vertical'
        md_bg_color: app.theme_cls.bg_darkest

        MDTopAppBar:
            title: "API配置"
            left_action_items: [["arrow-left", lambda x: root.go_back()]]
            elevation: 0
            md_bg_color: app.theme_cls.primary_color

        ScrollView:
            MDBoxLayout:
                orientation: 'vertical'
                padding: dp(16)
                spacing: dp(16)
                adaptive_height: True

                # 配置说明卡片
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "配置说明"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDLabel:
                        text: "请填入您的火山引擎API密钥信息。配置将保存到环境变量中，确保安全。"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]

                # ASR配置卡片
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "语音识别 (ASR) 配置"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDTextField:
                        id: asr_app_key
                        hint_text: "ASR_APP_KEY (必填)"
                        helper_text: "火山引擎ASR应用密钥"
                        helper_text_mode: "on_focus"
                        text: root.asr_app_key
                        on_text: root.asr_app_key = self.text

                    MDTextField:
                        id: asr_access_key
                        hint_text: "ASR_ACCESS_KEY (必填)"
                        helper_text: "火山引擎访问密钥"
                        helper_text_mode: "on_focus"
                        text: root.asr_access_key
                        on_text: root.asr_access_key = self.text

                    MDTextField:
                        id: asr_app_id
                        hint_text: "ASR_APP_ID (可选)"
                        helper_text: "火山引擎应用ID，留空使用默认值"
                        helper_text_mode: "on_focus"
                        text: root.asr_app_id
                        on_text: root.asr_app_id = self.text

                # LLM配置卡片
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "大语言模型 (LLM) 配置"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDTextField:
                        id: llm_api_key
                        hint_text: "LLM_API_KEY (必填)"
                        helper_text: "大语言模型API密钥"
                        helper_text_mode: "on_focus"
                        text: root.llm_api_key
                        on_text: root.llm_api_key = self.text

                # 操作按钮
                MDBoxLayout:
                    orientation: 'horizontal'
                    spacing: dp(12)
                    size_hint_y: None
                    height: dp(48)
                    padding: [0, dp(8), 0, 0]

                    MDRaisedButton:
                        text: "保存配置"
                        on_release: root.save_config()
                        size_hint_x: 0.5

                    MDRaisedButton:
                        text: "检查配置"
                        on_release: root.check_config()
                        size_hint_x: 0.5

                # 配置状态
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "配置状态"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDLabel:
                        id: config_status
                        text: root.config_status_text
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]

                # 帮助信息
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "获取API密钥"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDLabel:
                        text: "1. 访问火山引擎控制台\\n2. 创建ASR应用获取APP_KEY和ACCESS_KEY\\n3. 创建LLM应用获取API_KEY\\n4. 填入上述信息并保存"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]

                    MDTextButton:
                        text: "访问火山引擎控制台"
                        on_release: root.open_volcano_console()
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: dp(48)
'''

class APIConfigScreen(MDScreen):
    """API配置界面"""
    
    # 配置属性
    asr_app_key = StringProperty("")
    asr_access_key = StringProperty("")
    asr_app_id = StringProperty("8388344882")
    llm_api_key = StringProperty("")
    config_status_text = StringProperty("未配置")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dialog = None
        self.config_file_path = get_config_file_path()
        self.platform = get_platform()
        
        # 加载现有配置
        self.load_existing_config()
        
        # 更新状态
        Clock.schedule_once(self.update_config_status, 0.1)
    
    def load_existing_config(self):
        """加载现有配置"""
        # 从环境变量加载
        self.asr_app_key = os.environ.get('ASR_APP_KEY', '')
        self.asr_access_key = os.environ.get('ASR_ACCESS_KEY', '')
        self.asr_app_id = os.environ.get('ASR_APP_ID', '8388344882')
        self.llm_api_key = os.environ.get('LLM_API_KEY', '')
    
    def save_config(self):
        """保存配置到环境变量"""
        # 验证必填项
        if not self.asr_app_key or not self.asr_access_key or not self.llm_api_key:
            self.show_dialog("错误", "请填写所有必填项")
            return
        
        try:
            # 备份原配置文件
            if os.path.exists(self.config_file_path):
                backup_path = f"{self.config_file_path}.backup.{int(Clock.get_time())}"
                with open(self.config_file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(content)
            
            # 添加配置到文件
            config_content = f"""

# 添加时间: {Clock.get_time()}
export ASR_APP_KEY="{self.asr_app_key}"
export ASR_ACCESS_KEY="{self.asr_access_key}"
export LLM_API_KEY="{self.llm_api_key}"
export ASR_APP_ID="{self.asr_app_id}"
"""
            
            with open(self.config_file_path, 'a', encoding='utf-8') as f:
                f.write(config_content)
            
            # 设置当前会话的环境变量
            os.environ['ASR_APP_KEY'] = self.asr_app_key
            os.environ['ASR_ACCESS_KEY'] = self.asr_access_key
            os.environ['LLM_API_KEY'] = self.llm_api_key
            os.environ['ASR_APP_ID'] = self.asr_app_id
            
            self.show_dialog("成功", f"配置已保存到 {self.config_file_path}\\n请重新启动应用或重新加载配置文件")
            self.update_config_status()
            
        except Exception as e:
            self.show_dialog("错误", f"保存配置失败: {str(e)}")
    
    def check_config(self):
        """检查配置状态"""
        status = []
        
        # 检查环境变量
        if os.environ.get('ASR_APP_KEY'):
            status.append("ASR_APP_KEY: 已设置")
        else:
            status.append("ASR_APP_KEY: 未设置")
        
        if os.environ.get('ASR_ACCESS_KEY'):
            status.append("ASR_ACCESS_KEY: 已设置")
        else:
            status.append("ASR_ACCESS_KEY: 未设置")
        
        if os.environ.get('LLM_API_KEY'):
            status.append("LLM_API_KEY: 已设置")
        else:
            status.append("LLM_API_KEY: 未设置")
        
        if os.environ.get('ASR_APP_ID'):
            status.append("ASR_APP_ID: 已设置")
        else:
            status.append("ASR_APP_ID: 未设置（使用默认值）")
        
        # 检查配置文件
        if os.path.exists(self.config_file_path):
            with open(self.config_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if 'ASR_APP_KEY' in content:
                    status.append("配置文件: 包含API配置")
                else:
                    status.append("配置文件: 未找到API配置")
        else:
            status.append("配置文件: 不存在")
        
        status_text = "\\n".join(status)
        self.show_dialog("配置检查", status_text)
    
    def update_config_status(self, *args):
        """更新配置状态显示"""
        if os.environ.get('ASR_APP_KEY') and os.environ.get('ASR_ACCESS_KEY') and os.environ.get('LLM_API_KEY'):
            self.config_status_text = "配置完整，可以正常使用"
        elif os.environ.get('ASR_APP_KEY') or os.environ.get('ASR_ACCESS_KEY') or os.environ.get('LLM_API_KEY'):
            self.config_status_text = "配置不完整，请补充缺失的配置项"
        else:
            self.config_status_text = "未配置，请填写API密钥信息"
    
    def show_dialog(self, title, text):
        """显示对话框"""
        if self.dialog:
            self.dialog.dismiss()
        
        self.dialog = MDDialog(
            title=title,
            text=text,
            buttons=[
                MDRaisedButton(
                    text="确定",
                    on_release=lambda x: self.dialog.dismiss()
                )
            ]
        )
        self.dialog.open()
    
    def open_volcano_console(self):
        """打开火山引擎控制台"""
        import webbrowser
        webbrowser.open("https://console.volcengine.com/")
    
    def go_back(self):
        """返回主界面"""
        # 这里需要根据实际应用结构来实现
        pass

class APIConfigApp(MDApp):
    """API配置应用"""
    
    def build(self):
        self.theme_cls.primary_palette = "Blue"
        self.theme_cls.theme_style = "Dark"
        return Builder.load_string(KV)

if __name__ == "__main__":
    APIConfigApp().run() 