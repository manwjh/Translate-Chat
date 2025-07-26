#!/usr/bin/env python3
# =============================================================
# 文件名(File): setup_config.py
# 版本(Version): v1.1.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): API配置启动脚本，支持加密存储
# =============================================================

"""
Translate-Chat API配置工具

使用方法:
    python3 setup_config.py

功能:
    - 启动图形界面配置API密钥
    - 支持桌面和手机系统
    - 自动保存到加密存储
    - 配置一次，永久有效
"""

import sys
import os

def main():
    """主函数"""
    print("=" * 50)
    print("    Translate-Chat API配置工具")
    print("=" * 50)
    print()
    
    # 检查依赖
    try:
        import kivymd
        print("KivyMD依赖检查通过")
    except ImportError:
        print("缺少KivyMD依赖")
        print("请运行: pip install kivymd==1.1.1")
        return
    
    try:
        import cryptography
        print("加密库依赖检查通过")
    except ImportError:
        print("缺少加密库依赖")
        print("请运行: pip install cryptography>=3.4.8")
        return
    
    # 启动配置界面
    print("启动API配置界面...")
    print()
    print("配置说明：")
    print("- 配置将安全保存到本地加密存储")
    print("- 配置一次，后续启动自动加载")
    print("- 支持桌面端和Android端")
    print()
    
    try:
        from ui.sys_config_window import APIConfigApp
        APIConfigApp().run()
    except Exception as e:
        print(f"启动失败: {e}")
        print()
        print("备选方案:")
        print("1. 使用命令行配置: bash scripts/setup_env.sh -i")
        print("2. 手动设置环境变量")
        print("3. 检查依赖安装: pip install -r requirements-desktop.txt")

if __name__ == "__main__":
    main() 