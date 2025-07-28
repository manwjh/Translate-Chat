# =============================================================
# 文件名(File): main.py
# 版本(Version): v0.1.4
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 程序主入口，统一使用 Kivy 版主界面，支持环境变量和加密存储配置
# =============================================================

import os
os.environ["KIVY_LOG_LEVEL"] = "error"  # 只显示error，完全禁止info级别
os.environ["KIVY_NO_CONSOLELOG"] = "1"  # 禁止Kivy控制台日志，避免重复

import sys
import logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

from config_manager import config_manager
from utils.font_utils import register_system_font

def main():
    """主程序入口"""
    # 注册系统字体，供全局使用
    font_name = register_system_font()
    os.environ["TRANSLATE_CHAT_FONT_NAME"] = font_name
    # 打印配置状态
    config_manager.print_config_status()
    
    # 验证配置
    if not config_manager.validate_config():
        print("[配置] 检测到配置缺失，正在启动配置界面...")
        
        # 自动启动配置界面
        try:
            from ui.sys_config_window import APIConfigApp
            config_app = APIConfigApp()
            config_app.run()
            
            # 配置完成后重新验证
            if config_manager.validate_config():
                print("[配置] 配置完成，正在启动主程序...")
                from ui.main_window_kivy import run_app
                run_app()
            else:
                print("[配置] 配置验证失败，程序退出")
                sys.exit(1)
                
        except Exception as e:
            print(f"[配置] 启动配置界面失败: {e}")
            print("[配置] 请手动运行配置程序：python3 setup_config.py")
            sys.exit(1)
    else:
        # 配置完整，直接启动应用
        from ui.main_window_kivy import run_app
        run_app()

if __name__ == "__main__":
    main() 