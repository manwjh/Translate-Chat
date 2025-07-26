# =============================================================
# 文件名(File): main.py
# 版本(Version): v0.1.4
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 程序主入口，统一使用 Kivy 版主界面，支持环境变量和加密存储配置
# =============================================================

import sys
import os
from config_manager import config_manager

def main():
    """主程序入口"""
    # 打印配置状态
    config_manager.print_config_status()
    
    # 验证配置
    if not config_manager.validate_config():
        print("检测到配置缺失，正在启动配置界面...")
        print()
        print("配置说明：")
        print("1. 请填写火山引擎API密钥信息")
        print("2. 配置将安全保存到本地加密存储")
        print("3. 配置完成后程序将自动启动")
        print()
        
        # 自动启动配置界面
        try:
            from ui.sys_config_window import APIConfigApp
            config_app = APIConfigApp()
            config_app.run()
            
            # 配置完成后重新验证
            if config_manager.validate_config():
                print("配置完成，正在启动主程序...")
                from ui.main_window_kivy import run_app
                run_app()
            else:
                print("配置验证失败，程序退出")
                sys.exit(1)
                
        except Exception as e:
            print(f"启动配置界面失败: {e}")
            print()
            print("请手动运行配置程序：")
            print("python3 setup_config.py")
            sys.exit(1)
    else:
        # 配置完整，直接启动应用
        from ui.main_window_kivy import run_app
        run_app()

if __name__ == "__main__":
    main() 