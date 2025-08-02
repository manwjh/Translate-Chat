#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# =============================================================
# File Name: sys_config_window.py
# Version: v2.0.2
# Author: Shenzhen Wangge & AI
# Created: 2025/07/29
# Description: API configuration interface with encrypted storage support, can run independently or integrate into main program
# =============================================================

import os
import platform
import time

# 设置Kivy日志级别，减少重复信息
os.environ["KIVY_LOG_LEVEL"] = "error"
from kivy.lang import Builder
from kivy.properties import StringProperty, BooleanProperty
from kivy.clock import Clock
from kivy.metrics import dp

# Font configuration - set before importing KivyMD
from kivy.core.text import LabelBase
from kivy.resources import resource_add_path

# 使用系统字体，支持多语言显示

from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.card import MDCard
from kivymd.uix.button import MDRaisedButton, MDTextButton
from kivymd.uix.textfield import MDTextField
from kivymd.uix.label import MDLabel
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.dialog import MDDialog
from kivymd.uix.toolbar import MDTopAppBar
from kivymd.uix.selectioncontrol import MDSwitch

# Detect platform
def get_platform():
    if platform.system() == "Darwin":
        return "macos"
    elif platform.system() == "Linux":
        return "linux"
    elif platform.system() == "Windows":
        return "windows"
    else:
        return "unknown"

# Interface definition
KV = '''
<APIConfigScreen>:
    md_bg_color: app.theme_cls.bg_darkest if app else (0.1,0.1,0.1,1)
    
    # Main Container - 三段式布局
    MDBoxLayout:
        orientation: 'vertical'
        spacing: 0
        
        # Top Bar
        MDTopAppBar:
            title: "System Configuration"
            right_action_items: [["menu", lambda x: root.go_back()]]
            elevation: 4
            md_bg_color: app.theme_cls.primary_color if app else (0.2,0.2,0.2,1)
            size_hint_y: None
            height: dp(56)
        
        # Parameter Settings Area
        ScrollView:
            size_hint_y: 1
            MDBoxLayout:
                orientation: 'vertical'
                padding: dp(16)
                spacing: dp(16)
                adaptive_height: True
                
                # Configuration instructions card
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Configuration Instructions"
                        font_style: 'H6'
                        font_name: 'SystemFont'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "Please enter your Volcano Engine API key information. Configuration will be securely saved to local encrypted storage."
                        font_style: 'Body2'
                        font_name: 'SystemFont'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                
                # ASR configuration card
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Speech Recognition (ASR) Configuration"
                        font_style: 'H6'
                        font_name: 'SystemFont'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDTextField:
                        id: asr_app_id
                        hint_text: "ASR_APP_ID (Required)"
                        helper_text: "Volcano Engine ASR application ID"
                        helper_text_mode: "on_focus"
                        font_name: 'SystemFont'
                        text: root.asr_app_id
                        on_text: root.asr_app_id = self.text
                    MDTextField:
                        id: asr_access_key
                        hint_text: "ASR_ACCESS_KEY (Required)"
                        helper_text: "Volcano Engine access key"
                        helper_text_mode: "on_focus"
                        font_name: 'SystemFont'
                        text: root.asr_access_key
                        on_text: root.asr_access_key = self.text

                # LLM configuration card
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Large Language Model (LLM) Configuration"
                        font_style: 'H6'
                        font_name: 'SystemFont'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDTextField:
                        id: llm_api_key
                        hint_text: "LLM_API_KEY (Required)"
                        helper_text: "Large language model API key"
                        helper_text_mode: "on_focus"
                        font_name: 'SystemFont'
                        text: root.llm_api_key
                        on_text: root.llm_api_key = self.text

                # Translation settings card
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Translation Settings"
                        font_style: 'H6'
                        font_name: 'SystemFont'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDBoxLayout:
                        orientation: 'horizontal'
                        spacing: dp(16)
                        size_hint_y: None
                        height: dp(48)
                        MDLabel:
                            text: "Show Translation"
                            font_name: 'SystemFont'
                            theme_text_color: 'Secondary'
                            size_hint_y: None
                            height: self.texture_size[1]
                        MDSwitch:
                            id: translate_switch
                            active: root.show_translation
                            on_active: root.on_translate_switch_changed

                # Configuration status card
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(12)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Configuration Status"
                        font_style: 'H6'
                        font_name: 'SystemFont'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        id: config_status
                        text: root.config_status_text
                        font_name: 'SystemFont'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]

        # Button Area
        MDBoxLayout:
            orientation: 'horizontal'
            size_hint_y: None
            height: dp(60)
            padding: dp(16), dp(8), dp(16), dp(16)
            spacing: dp(12)
            MDRaisedButton:
                text: "Save Configuration"
                font_name: 'SystemFont'
                on_release: root.save_config()
                size_hint_x: 1
            MDRaisedButton:
                text: "Check Configuration"
                font_name: 'SystemFont'
                on_release: root.check_config()
                size_hint_x: 1
'''

Builder.load_string(KV)

class APIConfigScreen(MDScreen):
    """API configuration interface"""
    asr_app_id = StringProperty("")
    asr_access_key = StringProperty("")
    llm_api_key = StringProperty("")
    config_status_text = StringProperty("Not configured")
    show_translation = BooleanProperty(True)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dialog = None
        self.platform = get_platform()
        self.load_existing_config()
        Clock.schedule_once(self.update_config_status, 0.1)
    
    def load_existing_config(self):
        """Load existing configuration from environment variables and encrypted storage"""
        # Priority: load from environment variables (developer mode)
        self.asr_app_id = os.environ.get('ASR_APP_ID', '')
        self.asr_access_key = os.environ.get('ASR_ACCESS_KEY', '')
        self.llm_api_key = os.environ.get('LLM_API_KEY', '')
        
        # Load translation setting from environment variable
        translation_setting = os.environ.get('SHOW_TRANSLATION', 'True')
        self.show_translation = translation_setting.lower() in ('true', '1', 'yes')
        
        # If environment variables are empty, try to load from encrypted storage
        if not all([self.asr_app_id, self.asr_access_key, self.llm_api_key]):
            try:
                from config_manager import config_manager
                if config_manager.secure_storage:
                    encrypted_config = config_manager.secure_storage.load_config()
                    if not self.asr_app_id and encrypted_config.get('ASR_APP_ID'):
                        self.asr_app_id = encrypted_config['ASR_APP_ID']
                    if not self.asr_access_key and encrypted_config.get('ASR_ACCESS_KEY'):
                        self.asr_access_key = encrypted_config['ASR_ACCESS_KEY']
                    if not self.llm_api_key and encrypted_config.get('LLM_API_KEY'):
                        self.llm_api_key = encrypted_config['LLM_API_KEY']
                    if encrypted_config.get('ASR_APP_ID'):
                        self.asr_app_id = encrypted_config['ASR_APP_ID']
                    
                    # Load translation setting from encrypted storage
                    if 'SHOW_TRANSLATION' in encrypted_config:
                        self.show_translation = encrypted_config['SHOW_TRANSLATION']
            except Exception as e:
                print(f"[配置] 加载加密配置失败: {e}")
    
    def save_config(self):
        """Save configuration to encrypted storage"""
        try:
            # Prepare configuration data with user input
            config_data = {}
            
            # Add API keys if provided
            if self.asr_app_id:
                config_data['ASR_APP_ID'] = self.asr_app_id
            if self.asr_access_key:
                config_data['ASR_ACCESS_KEY'] = self.asr_access_key
            if self.llm_api_key:
                config_data['LLM_API_KEY'] = self.llm_api_key
            
            # Always include translation setting
            config_data['SHOW_TRANSLATION'] = self.show_translation
            
            # Save to encrypted storage
            from config_manager import config_manager
            if config_manager.save_config(config_data):
                # Set environment variables for current process (compatibility)
                if self.asr_app_id:
                    os.environ['ASR_APP_ID'] = self.asr_app_id
                if self.asr_access_key:
                    os.environ['ASR_ACCESS_KEY'] = self.asr_access_key
                if self.llm_api_key:
                    os.environ['LLM_API_KEY'] = self.llm_api_key
                os.environ['SHOW_TRANSLATION'] = str(self.show_translation)
                
                # Update main app translation setting if available
                self.update_main_app_translation_setting()
                
                # Show success dialog
                self.show_success_dialog()
            else:
                self.show_dialog("Error", "Failed to save configuration, please check storage permissions")
        except Exception as e:
            self.show_dialog("Error", f"Failed to save configuration: {str(e)}")
    
    def show_success_dialog(self):
        """Show success dialog and return to main interface"""
        if self.dialog:
            self.dialog.dismiss()
        self.dialog = MDDialog(
            title="Configuration Successful",
            text="Configuration has been securely saved to local encrypted storage\n\nReturning to main interface...",
            buttons=[
                MDRaisedButton(
                    text="OK",
                    on_release=self.on_config_success
                )
            ]
        )
        self.dialog.open()
    
    def on_config_success(self, *args):
        """Callback after successful configuration"""
        if self.dialog:
            self.dialog.dismiss()
        # Return to main interface
        self.go_back()
    
    def on_translate_switch_changed(self, active):
        """Handle translation switch change"""
        self.show_translation = active
        print(f"[配置] 翻译开关状态: {active}")
        
        # Auto-save translation setting
        try:
            from config_manager import config_manager
            if config_manager.secure_storage:
                existing_config = config_manager.secure_storage.load_config()
                if existing_config:
                    # Update existing configuration with new translation setting
                    existing_config['SHOW_TRANSLATION'] = active
                    if config_manager.save_config(existing_config):
                        os.environ['SHOW_TRANSLATION'] = str(active)
                        self.update_main_app_translation_setting()
                        print(f"[配置] 翻译设置已自动保存: {active}")
                    else:
                        print(f"[配置] 翻译设置保存失败")
                else:
                    print(f"[配置] 没有现有配置，无法保存翻译设置")
            else:
                print(f"[配置] 加密存储未初始化，无法保存翻译设置")
        except Exception as e:
            print(f"[配置] 保存翻译设置时出错: {e}")
    
    def update_main_app_translation_setting(self):
        """Update main app translation setting if available"""
        try:
            # Try to update main app setting if it exists
            if hasattr(self, 'app') and self.app and hasattr(self.app, 'show_translation'):
                self.app.show_translation = self.show_translation
                print(f"[配置] 已更新主应用翻译设置: {self.show_translation}")
        except Exception as e:
            print(f"[配置] 更新主应用翻译设置失败: {e}")
    
    def go_back(self):
        """Return to main interface"""
        # Switch back to main interface by main program ScreenManager
        if self.parent and hasattr(self.parent, 'current'):
            self.parent.current = 'main'
        # If running independently, close the app
        elif hasattr(self, 'app') and self.app:
            self.app.stop()
        else:
            # If no app reference, exit directly
            import sys
            sys.exit(0)
    
    def check_config(self):
        """Check configuration status"""
        status = []
        
        # Check environment variables
        if os.environ.get('ASR_APP_ID'):
            status.append("[Success] ASR_APP_ID: Environment variable set")
        else:
            status.append("[Failed] ASR_APP_ID: Environment variable not set")
        
        if os.environ.get('ASR_ACCESS_KEY'):
            status.append("[Success] ASR_ACCESS_KEY: Environment variable set")
        else:
            status.append("[Failed] ASR_ACCESS_KEY: Environment variable not set")
        
        if os.environ.get('LLM_API_KEY'):
            status.append("[Success] LLM_API_KEY: Environment variable set")
        else:
            status.append("[Failed] LLM_API_KEY: Environment variable not set")
        
        # Check encrypted storage
        try:
            from config_manager import config_manager
            if config_manager.secure_storage:
                encrypted_config = config_manager.secure_storage.load_config()
                if encrypted_config:
                    status.append("[Success] Encrypted storage: Contains configuration data")
                    if encrypted_config.get('ASR_APP_ID'):
                        status.append("  - ASR_APP_ID: Saved")
                    if encrypted_config.get('ASR_ACCESS_KEY'):
                        status.append("  - ASR_ACCESS_KEY: Saved")
                    if encrypted_config.get('LLM_API_KEY'):
                        status.append("  - LLM_API_KEY: Saved")
                else:
                    status.append("[Failed] Encrypted storage: No configuration data")
            else:
                status.append("[Failed] Encrypted storage: Not initialized")
        except Exception as e:
            status.append(f"[Failed] Encrypted storage: Check failed ({str(e)})")
        
        status_text = "\n".join(status)
        self.show_dialog("Configuration Check", status_text)
    
    def update_config_status(self, *args):
        """Update configuration status display"""
        try:
            from config_manager import config_manager
            if config_manager.validate_config():
                source = config_manager._get_config_source()
                self.config_status_text = f"[Success] Configuration complete, source: {source}"
            elif any([self.asr_app_id, self.asr_access_key, self.llm_api_key]):
                self.config_status_text = "[Warning] Configuration incomplete, please supplement missing configuration items"
            else:
                self.config_status_text = "[Failed] Not configured, please fill in API key information"
        except Exception as e:
            self.config_status_text = f"[Failed] Configuration check failed: {str(e)}"
    
    def show_dialog(self, title, text):
        """Show dialog"""
        if self.dialog:
            self.dialog.dismiss()
        self.dialog = MDDialog(
            title=title,
            text=text,
            buttons=[
                MDRaisedButton(
                    text="OK",
                    on_release=lambda x: self.dialog.dismiss()
                )
            ]
        )
        self.dialog.open()
    
    def open_volcano_console(self):
        """Open Volcano Engine console"""
        import webbrowser
        webbrowser.open("https://console.volcengine.com/")
    
    def go_back(self):
        """Return to main interface"""
        # Switch back to main interface by main program ScreenManager
        if self.parent and hasattr(self.parent, 'current'):
            self.parent.current = 'main'
        # If running independently, close the app
        elif hasattr(self, 'app') and self.app:
            self.app.stop()
        else:
            # If no app reference, exit directly
            import sys
            sys.exit(0)

class APIConfigApp(MDApp):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # 借鉴 test_font_fix.py 的成功经验：直接注册字体
        try:
            from utils.font_utils import register_system_font
            font_name = register_system_font()
            print(f"[DEBUG] Config app font registered: {font_name}")
        except Exception as e:
            print(f"[DEBUG] Config app font registration failed: {e}")
            font_name = 'Roboto'
        self.font_name = font_name
    
    def build(self):
        self.theme_cls.primary_palette = "Blue"
        self.theme_cls.theme_style = "Dark"
        screen = APIConfigScreen()
        screen.app = self  # Save app reference for closing
        return screen

if __name__ == "__main__":
    APIConfigApp().run() 