# =============================================================
# 文件名(File): main.py
# 版本(Version): v0.1.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 程序主入口，统一使用 Kivy 版主界面，支持环境变量配置
# =============================================================

import sys
from config_manager import config_manager

def main():
    """主程序入口"""
    # 打印配置状态
    config_manager.print_config_status()
    
    # 验证配置
    if not config_manager.validate_config():
        print("错误：配置验证失败，请检查API密钥配置")
        print("请设置以下环境变量：")
        print("  export ASR_APP_KEY=你的ASR_APP_KEY")
        print("  export ASR_ACCESS_KEY=你的ASR_ACCESS_KEY")
        print("  export LLM_API_KEY=你的LLM_API_KEY")
        print("请使用图形界面配置或设置环境变量")
        sys.exit(1)
    
    # 启动应用
    from ui.main_window_kivy import run_app
    run_app()

if __name__ == "__main__":
    main() 