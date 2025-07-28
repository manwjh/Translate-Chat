# =============================================================
# 文件名(File): file_downloader.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 跨平台文件下载工具，支持目录选择和文件保存
# =============================================================

import os
import datetime
from kivy.utils import platform
from kivymd.uix.dialog import MDDialog
from kivymd.uix.button import MDFlatButton
from kivymd.uix.list import OneLineListItem
from kivymd.uix.boxlayout import MDBoxLayout
from kivymd.uix.textfield import MDTextField

class FileDownloader:
    """跨平台文件下载工具"""
    
    def __init__(self):
        self.dialog = None
        
    def get_default_download_dir(self):
        """获取默认下载目录"""
        if platform == 'android':
            # Android平台使用应用文档目录
            return os.path.join(os.path.expanduser("~"), "Documents")
        elif platform == 'macos':
            # macOS使用下载目录
            return os.path.expanduser("~/Downloads")
        elif platform == 'linux':
            # Linux使用下载目录
            return os.path.expanduser("~/Downloads")
        elif platform == 'win':
            # Windows使用下载目录
            return os.path.expanduser("~/Downloads")
        else:
            # 其他平台使用当前目录
            return os.getcwd()
    
    def generate_filename(self, prefix="translate_chat"):
        """生成文件名：年月日时分秒.txt"""
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"{prefix}_{timestamp}.txt"
    
    def save_chat_records(self, bubbles, callback=None):
        """保存聊天记录到文件"""
        if not bubbles:
            if callback:
                callback("Notice", "No records to download")
            return
            
        # 生成文件名和路径
        filename = self.generate_filename()
        default_dir = self.get_default_download_dir()
        filepath = os.path.join(default_dir, filename)
        
        try:
            # 创建下载目录（如果不存在）
            os.makedirs(default_dir, exist_ok=True)
            
            # 写入文件内容
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(f"Translate-Chat Conversation Record\n")
                f.write(f"Export Time: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"{'='*50}\n\n")
                
                for i, bubble in enumerate(bubbles, 1):
                    # 获取显示文本
                    display_text = bubble.corrected_text if bubble.corrected_text and bubble.corrected_text != bubble.original_text else bubble.original_text
                    
                    f.write(f"{i}. Original: {display_text}\n")
                    if bubble.translation:
                        f.write(f"   Translation: {bubble.translation}\n")
                    if bubble.timeout_tip:
                        f.write(f"   Note: {bubble.timeout_tip}\n")
                    f.write("\n")
            
            # 显示成功对话框
            if callback:
                callback("Download Success", f"File saved to:\n{filepath}")
                
        except Exception as e:
            if callback:
                callback("Download Failed", f"Error saving file:\n{str(e)}")
    
    def show_directory_selector(self, callback=None):
        """显示目录选择对话框（简化版）"""
        # 由于KivyMD的限制，这里提供一个简化的目录选择
        # 在实际应用中，可以考虑使用原生文件选择器
        
        content = MDBoxLayout(
            orientation='vertical',
            spacing=10,
            size_hint_y=None,
            height=200
        )
        
        # 显示当前默认目录
        default_dir = self.get_default_download_dir()
        content.add_widget(
            OneLineListItem(
                text=f"Default Directory: {default_dir}"
            )
        )
        
        # 添加说明
        content.add_widget(
            OneLineListItem(
                text="File will be saved to default download directory"
            )
        )
        
        dialog = MDDialog(
            title="Select Save Location",
            type="custom",
            content_cls=content,
            buttons=[
                MDFlatButton(
                    text="Cancel",
                    on_release=lambda x: dialog.dismiss()
                ),
                MDFlatButton(
                    text="OK",
                    on_release=lambda x: self._on_directory_selected(dialog, callback)
                )
            ]
        )
        
        self.dialog = dialog
        dialog.open()
    
    def _on_directory_selected(self, dialog, callback):
        """目录选择确认回调"""
        dialog.dismiss()
        if callback:
            callback()
    
    def show_dialog(self, title, text):
        """显示通用对话框"""
        dialog = MDDialog(
            title=title,
            text=text,
            buttons=[
                MDFlatButton(
                    text="OK",
                    on_release=lambda x: dialog.dismiss()
                )
            ]
        )
        dialog.open() 