# =============================================================
# 文件名(File): api_config_app.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 独立的API配置应用，支持桌面和手机系统
# =============================================================

import os
import platform
import time
from kivy.lang import Builder
from kivy.properties import StringProperty
from kivy.clock import Clock
from kivy.metrics import dp

from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.card import MDCard
from kivymd.uix.button import MDRaisedButton, MDTextButton
from kivymd.uix.textfield import MDTextField
from kivymd.uix.label import MDLabel
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.dialog import MDDialog
from kivymd.uix.toolbar import MDTopAppBar

# 检测平台和获取配置文件路径
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

def get_config_file_path():
    platform_type = get_platform()
    home = os.path.expanduser("~")
    
    if platform_type == "macos":
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

# 界面定义
KV = '''
MDScreen:
    md_bg_color: app.theme_cls.bg_darkest

    MDBoxLayout:
        orientation: 'vertical'

        MDTopAppBar:
            title: "Translate-Chat API配置"
            elevation: 0
            md_bg_color: app.theme_cls.primary_color

        ScrollView:
            MDBoxLayout:
                orientation: 'vertical'
                padding: dp(16)
                spacing: dp(16)
                adaptive_height: True

                # 欢迎卡片
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "欢迎使用 Translate-Chat"
                        font_style: 'H5'
                        theme_text_color: 'Primary'
                        halign: 'center'
                        size_hint_y: None
                        height: self.texture_size[1]
                        font_name: 'NotoSansSC'

                    MDLabel:
                        text: "请配置您的火山引擎API密钥以开始使用语音翻译功能"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        halign: 'center'
                        size_hint_y: None
                        height: self.texture_size[1]
                        font_name: 'NotoSansSC'

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
                        font_name: 'NotoSansSC'

                    MDTextField:
                        id: asr_app_key
                        hint_text: "ASR_APP_KEY (必填)"
                        helper_text: "火山引擎ASR应用密钥"
                        helper_text_mode: "on_focus"
                        text: app.asr_app_key
                        on_text: app.asr_app_key = self.text

                    MDTextField:
                        id: asr_access_key
                        hint_text: "ASR_ACCESS_KEY (必填)"
                        helper_text: "火山引擎访问密钥"
                        helper_text_mode: "on_focus"
                        text: app.asr_access_key
                        on_text: app.asr_access_key = self.text

                    MDTextField:
                        id: asr_app_id
                        hint_text: "ASR_APP_ID (可选)"
                        helper_text: "火山引擎应用ID，留空使用默认值"
                        helper_text_mode: "on_focus"
                        text: app.asr_app_id
                        on_text: app.asr_app_id = self.text

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
                        font_name: 'NotoSansSC'

                    MDTextField:
                        id: llm_api_key
                        hint_text: "LLM_API_KEY (必填)"
                        helper_text: "大语言模型API密钥"
                        helper_text_mode: "on_focus"
                        text: app.llm_api_key
                        on_text: app.llm_api_key = self.text

                # 操作按钮
                MDBoxLayout:
                    orientation: 'horizontal'
                    spacing: dp(12)
                    size_hint_y: None
                    height: dp(48)
                    padding: [0, dp(8), 0, 0]

                    MDRaisedButton:
                        text: "保存配置"
                        on_release: app.save_config()
                        size_hint_x: 0.5
                        font_name: 'NotoSansSC'

                    MDRaisedButton:
                        text: "检查配置"
                        on_release: app.check_config()
                        size_hint_x: 0.5
                        font_name: 'NotoSansSC'

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
                        font_name: 'NotoSansSC'

                    MDLabel:
                        id: config_status
                        text: app.config_status_text
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                        font_name: 'NotoSansSC'

                # 帮助信息
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDLabel:
                        text: "如何获取API密钥？"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                        font_name: 'NotoSansSC'

                    MDLabel:
                        text: "1. 访问火山引擎控制台\\n2. 创建ASR应用获取APP_KEY和ACCESS_KEY\\n3. 创建LLM应用获取API_KEY\\n4. 填入上述信息并保存"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                        font_name: 'NotoSansSC'

                    MDTextButton:
                        text: "访问火山引擎控制台"
                        on_release: app.open_volcano_console()
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: dp(48)
                        font_name: 'NotoSansSC'

                # 开始使用按钮
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark

                    MDRaisedButton:
                        text: "开始使用 Translate-Chat"
                        on_release: app.start_main_app()
                        size_hint_x: 1
                        md_bg_color: app.theme_cls.primary_color
                        font_name: 'NotoSansSC'
'''

class APIConfigApp(MDApp):
    """API配置应用"""
    
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
                backup_path = f"{self.config_file_path}.backup.{int(time.time())}"
                with open(self.config_file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(content)
            
            # 添加配置到文件
            config_content = f"""

# Translate-Chat API配置
# 添加时间: {time.strftime('%Y-%m-%d %H:%M:%S')}
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
            
            self.show_dialog("成功", f"配置已保存到 {self.config_file_path}\\n\\n请重新启动应用或执行以下命令使配置生效:\\nsource {self.config_file_path}")
            self.update_config_status()
            
        except Exception as e:
            self.show_dialog("错误", f"保存配置失败: {str(e)}")
    
    def check_config(self):
        """检查配置状态"""
        status = []
        
        # 检查环境变量
        if os.environ.get('ASR_APP_KEY'):
            status.append("✅ ASR_APP_KEY: 已设置")
        else:
            status.append("❌ ASR_APP_KEY: 未设置")
        
        if os.environ.get('ASR_ACCESS_KEY'):
            status.append("✅ ASR_ACCESS_KEY: 已设置")
        else:
            status.append("❌ ASR_ACCESS_KEY: 未设置")
        
        if os.environ.get('LLM_API_KEY'):
            status.append("✅ LLM_API_KEY: 已设置")
        else:
            status.append("❌ LLM_API_KEY: 未设置")
        
        if os.environ.get('ASR_APP_ID'):
            status.append("✅ ASR_APP_ID: 已设置")
        else:
            status.append("⚠️ ASR_APP_ID: 未设置（使用默认值）")
        
        # 检查配置文件
        if os.path.exists(self.config_file_path):
            with open(self.config_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if 'ASR_APP_KEY' in content:
                    status.append("✅ 配置文件: 包含API配置")
                else:
                    status.append("❌ 配置文件: 未找到API配置")
        else:
            status.append("❌ 配置文件: 不存在")
        
        status_text = "\\n".join(status)
        self.show_dialog("配置检查", status_text)
    
    def update_config_status(self, *args):
        """更新配置状态显示"""
        if os.environ.get('ASR_APP_KEY') and os.environ.get('ASR_ACCESS_KEY') and os.environ.get('LLM_API_KEY'):
            self.config_status_text = "✅ 配置完整，可以正常使用"
        elif os.environ.get('ASR_APP_KEY') or os.environ.get('ASR_ACCESS_KEY') or os.environ.get('LLM_API_KEY'):
            self.config_status_text = "⚠️ 配置不完整，请补充缺失的配置项"
        else:
            self.config_status_text = "❌ 未配置，请填写API密钥信息"
    
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
                    on_release=lambda x: self.dialog.dismiss(),
                    font_name='NotoSansSC'
                )
            ]
        )
        self.dialog.open()
    
    def open_volcano_console(self):
        """打开火山引擎控制台"""
        import webbrowser
        webbrowser.open("https://console.volcengine.com/")
    
    def start_main_app(self):
        """启动主应用"""
        # 检查配置是否完整
        if not (os.environ.get('ASR_APP_KEY') and os.environ.get('ASR_ACCESS_KEY') and os.environ.get('LLM_API_KEY')):
            self.show_dialog("提示", "请先完成API配置")
            return
        
        # 这里可以启动主应用
        self.show_dialog("提示", "配置完成！可以运行 python main.py 启动主应用")
    
    def build(self):
        self.theme_cls.primary_palette = "Blue"
        self.theme_cls.theme_style = "Dark"
        
        # 设置中文字体
        from kivy.core.text import LabelBase
        from kivy.resources import resource_add_path
        
        # 添加字体路径
        resource_add_path('assets/fonts')
        
        # 注册中文字体
        try:
            LabelBase.register('NotoSansSC', 'NotoSansSC-VariableFont_wght.ttf')
        except:
            # 如果字体文件不存在，使用系统默认字体
            pass
        
        return Builder.load_string(KV)

if __name__ == "__main__":
    APIConfigApp().run() 