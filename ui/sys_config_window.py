#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# =============================================================
# File Name: sys_config_window.py
# Version: v1.2.1
# Author: Shenzhen Wangge & AI
# Created: 2025/1/27
# Description: API configuration interface with encrypted storage support, can run independently or integrate into main program
# =============================================================

import os
import platform
import time
from kivy.lang import Builder
from kivy.properties import StringProperty
from kivy.clock import Clock
from kivy.metrics import dp

# Font configuration - set before importing KivyMD
from kivy.core.text import LabelBase
from kivy.resources import resource_add_path

# Auto-adapt font path
font_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../assets/fonts'))
if not os.path.exists(os.path.join(font_path, 'NotoSansSC-VariableFont_wght.ttf')):
    font_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'assets/fonts'))

# Add font path
resource_add_path(font_path)

# Register Chinese font - always use local font
def setup_fonts():
    """Always register and use the local font file."""
    font_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../assets/fonts/NotoSansSC-VariableFont_wght.ttf'))
    try:
        LabelBase.register('CustomFont', font_path)
        print(f"Custom font registered: {font_path}")
        return font_path
    except Exception as e:
        print(f"Custom font registration failed: {e}")
        return font_path  # Still return path for fallback

FONT_NAME = setup_fonts()

from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen
from kivymd.uix.card import MDCard
from kivymd.uix.button import MDRaisedButton, MDTextButton
from kivymd.uix.textfield import MDTextField
from kivymd.uix.label import MDLabel
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.dialog import MDDialog
from kivymd.uix.toolbar import MDTopAppBar

# Detect platform
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

# Interface definition
KV = '''
# Global font settings - always use local font
<MDLabel>:
    font_name: app.chinese_font if app and hasattr(app, 'chinese_font') else 'assets/fonts/NotoSansSC-VariableFont_wght.ttf'
<MDRaisedButton>:
    font_name: app.chinese_font if app and hasattr(app, 'chinese_font') else 'assets/fonts/NotoSansSC-VariableFont_wght.ttf'
<MDTextButton>:
    font_name: app.chinese_font if app and hasattr(app, 'chinese_font') else 'assets/fonts/NotoSansSC-VariableFont_wght.ttf'
<MDTextField>:
    font_name: app.chinese_font if app and hasattr(app, 'chinese_font') else 'assets/fonts/NotoSansSC-VariableFont_wght.ttf'
<MDTopAppBar>:
    font_name: app.chinese_font if app and hasattr(app, 'chinese_font') else 'assets/fonts/NotoSansSC-VariableFont_wght.ttf'

<APIConfigScreen>:
    md_bg_color: app.theme_cls.bg_darkest if app else (0.1,0.1,0.1,1)
    MDBoxLayout:
        orientation: 'horizontal'
        size_hint_y: None
        height: dp(56)
        MDTopAppBar:
            title: "API Configuration"
            right_action_items: [[">", lambda x: root.go_back()]]
            elevation: 0
            md_bg_color: app.theme_cls.primary_color if app else (0.2,0.2,0.2,1)
            size_hint_x: 1
        MDTextButton:
            text: ">"
            on_release: root.go_back()
            theme_text_color: "Custom"
            text_color: 1, 1, 1, 1
            font_size: "24sp"
            size_hint_x: None
            width: dp(48)
            pos_hint: {"center_y": 0.5}
        ScrollView:
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
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "Please enter your Volcano Engine API key information. Configuration will be securely saved to local encrypted storage."
                        font_style: 'Body2'
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
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDTextField:
                        id: asr_app_key
                        hint_text: "ASR_APP_KEY (Required)"
                        helper_text: "Volcano Engine ASR application key"
                        helper_text_mode: "on_focus"
                        text: root.asr_app_key
                        on_text: root.asr_app_key = self.text
                    MDTextField:
                        id: asr_access_key
                        hint_text: "ASR_ACCESS_KEY (Required)"
                        helper_text: "Volcano Engine access key"
                        helper_text_mode: "on_focus"
                        text: root.asr_access_key
                        on_text: root.asr_access_key = self.text
                    MDTextField:
                        id: asr_app_id
                        hint_text: "ASR_APP_ID (Optional)"
                        helper_text: "Volcano Engine application ID, leave empty to use default value"
                        helper_text_mode: "on_focus"
                        text: root.asr_app_id
                        on_text: root.asr_app_id = self.text
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
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDTextField:
                        id: llm_api_key
                        hint_text: "LLM_API_KEY (Required)"
                        helper_text: "Large language model API key"
                        helper_text_mode: "on_focus"
                        text: root.llm_api_key
                        on_text: root.llm_api_key = self.text
                # Operation buttons
                MDBoxLayout:
                    orientation: 'horizontal'
                    spacing: dp(12)
                    size_hint_y: None
                    height: dp(48)
                    padding: [0, dp(8), 0, 0]
                    MDRaisedButton:
                        text: "Save Configuration"
                        on_release: root.save_config()
                        size_hint_x: 0.5
                    MDRaisedButton:
                        text: "Check Configuration"
                        on_release: root.check_config()
                        size_hint_x: 0.5
                # Configuration status
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Configuration Status"
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
                # Help information
                MDCard:
                    orientation: 'vertical'
                    padding: dp(16)
                    spacing: dp(8)
                    size_hint_y: None
                    height: self.minimum_height
                    md_bg_color: app.theme_cls.bg_dark if app else (0.15,0.15,0.15,1)
                    MDLabel:
                        text: "Get API Keys"
                        font_style: 'H6'
                        theme_text_color: 'Primary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "1. Visit Volcano Engine Console"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "2. Create ASR application to get APP_KEY and ACCESS_KEY"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "3. Create LLM application to get API_KEY"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDLabel:
                        text: "4. Fill in the above information and save"
                        font_style: 'Body2'
                        theme_text_color: 'Secondary'
                        size_hint_y: None
                        height: self.texture_size[1]
                    MDBoxLayout:
                        orientation: 'horizontal'
                        size_hint_y: None
                        height: dp(48)
                        MDLabel:
                            text: ""
                            size_hint_x: 1
                        MDTextButton:
                            text: ">"
                            on_release: root.open_volcano_console()
                            theme_text_color: 'Primary'
                            size_hint_x: None
                            width: dp(48)
'''

Builder.load_string(KV)

class APIConfigScreen(MDScreen):
    """API configuration interface"""
    asr_app_key = StringProperty("")
    asr_access_key = StringProperty("")
    asr_app_id = StringProperty("8388344882")
    llm_api_key = StringProperty("")
    config_status_text = StringProperty("Not configured")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dialog = None
        self.platform = get_platform()
        self.load_existing_config()
        Clock.schedule_once(self.update_config_status, 0.1)
    
    def load_existing_config(self):
        """Load existing configuration from environment variables and encrypted storage"""
        # Priority: load from environment variables (developer mode)
        self.asr_app_key = os.environ.get('ASR_APP_KEY', '')
        self.asr_access_key = os.environ.get('ASR_ACCESS_KEY', '')
        self.asr_app_id = os.environ.get('ASR_APP_ID', '8388344882')
        self.llm_api_key = os.environ.get('LLM_API_KEY', '')
        
        # If environment variables are empty, try to load from encrypted storage
        if not all([self.asr_app_key, self.asr_access_key, self.llm_api_key]):
            try:
                from config_manager import config_manager
                if config_manager.secure_storage:
                    encrypted_config = config_manager.secure_storage.load_config()
                    if not self.asr_app_key and encrypted_config.get('ASR_APP_KEY'):
                        self.asr_app_key = encrypted_config['ASR_APP_KEY']
                    if not self.asr_access_key and encrypted_config.get('ASR_ACCESS_KEY'):
                        self.asr_access_key = encrypted_config['ASR_ACCESS_KEY']
                    if not self.llm_api_key and encrypted_config.get('LLM_API_KEY'):
                        self.llm_api_key = encrypted_config['LLM_API_KEY']
                    if encrypted_config.get('ASR_APP_ID'):
                        self.asr_app_id = encrypted_config['ASR_APP_ID']
            except Exception as e:
                print(f"Failed to load encrypted configuration: {e}")
    
    def save_config(self):
        """Save configuration to encrypted storage"""
        if not self.asr_app_key or not self.asr_access_key or not self.llm_api_key:
            self.show_dialog("Error", "Please fill in all required fields")
            return
        
        try:
            # Prepare configuration data
            config_data = {
                'ASR_APP_KEY': self.asr_app_key,
                'ASR_ACCESS_KEY': self.asr_access_key,
                'ASR_APP_ID': self.asr_app_id,
                'LLM_API_KEY': self.llm_api_key
            }
            
            # Save to encrypted storage
            from config_manager import config_manager
            if config_manager.save_config(config_data):
                # Also set environment variables for current process (compatibility)
                os.environ['ASR_APP_KEY'] = self.asr_app_key
                os.environ['ASR_ACCESS_KEY'] = self.asr_access_key
                os.environ['LLM_API_KEY'] = self.llm_api_key
                os.environ['ASR_APP_ID'] = self.asr_app_id
                
                # Show success dialog and automatically close application
                self.show_success_dialog()
            else:
                self.show_dialog("Error", "Failed to save configuration, please check storage permissions")
        except Exception as e:
            self.show_dialog("Error", f"Failed to save configuration: {str(e)}")
    
    def show_success_dialog(self):
        """Show success dialog and automatically close application"""
        if self.dialog:
            self.dialog.dismiss()
        self.dialog = MDDialog(
            title="Configuration Successful",
            text="Configuration has been securely saved to local encrypted storage\n\nThe program will automatically start the main interface",
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
        # Delay closing application to let user see success message
        Clock.schedule_once(self.close_app, 0.5)
    
    def close_app(self, *args):
        """Close configuration application"""
        # Stop application
        if hasattr(self, 'app') and self.app:
            self.app.stop()
        else:
            # If no app reference, exit directly
            import sys
            sys.exit(0)
    
    def check_config(self):
        """Check configuration status"""
        status = []
        
        # Check environment variables
        if os.environ.get('ASR_APP_KEY'):
            status.append("[Success] ASR_APP_KEY: Environment variable set")
        else:
            status.append("[Failed] ASR_APP_KEY: Environment variable not set")
        
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
                    if encrypted_config.get('ASR_APP_KEY'):
                        status.append("  - ASR_APP_KEY: Saved")
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
            elif any([self.asr_app_key, self.asr_access_key, self.llm_api_key]):
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
        # No operation when running independently
        pass

class APIConfigApp(MDApp):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.chinese_font = FONT_NAME
    
    def build(self):
        self.theme_cls.primary_palette = "Blue"
        self.theme_cls.theme_style = "Dark"
        screen = APIConfigScreen()
        screen.app = self  # Save app reference for closing
        return screen

if __name__ == "__main__":
    APIConfigApp().run() 