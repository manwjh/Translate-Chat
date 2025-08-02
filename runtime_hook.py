# =============================================================
# 文件名(File): runtime_hook.py
# 版本(Version): v1.0.0
# 创建日期(Created): 2025/1/28
# 简介(Description): PyInstaller运行时钩子 - 处理独立可执行文件依赖
# =============================================================

import os
import sys
import subprocess
import platform

def setup_environment():
    """设置运行环境"""
    # 设置环境变量
    os.environ['KIVY_NO_ARGS'] = '1'
    os.environ['KIVY_NO_FILE_LOG'] = '1'
    
    # 设置音频后端
    if platform.system() == 'Linux':
        os.environ['KIVY_AUDIO'] = 'pyaudio'
    
    # 设置数据目录
    if getattr(sys, 'frozen', False):
        # 如果是打包的可执行文件
        base_path = sys._MEIPASS
        os.environ['KIVY_DATA_DIR'] = base_path
    else:
        # 如果是开发环境
        base_path = os.path.dirname(os.path.abspath(__file__))
    
    return base_path

def check_dependencies():
    """检查系统依赖"""
    missing_deps = []
    
    # 检查PortAudio
    try:
        import pyaudio
        pyaudio.PyAudio()
    except Exception as e:
        missing_deps.append(f"PortAudio: {e}")
    
    # 检查其他依赖
    try:
        import kivy
        import kivymd
        import websocket
        import aiohttp
        import cryptography
    except ImportError as e:
        missing_deps.append(f"Python依赖: {e}")
    
    return missing_deps

def install_missing_deps():
    """安装缺失的依赖"""
    system = platform.system().lower()
    
    if system == 'linux':
        # Linux系统
        try:
            # 尝试安装PortAudio
            subprocess.run(['sudo', 'apt-get', 'update'], check=False)
            subprocess.run(['sudo', 'apt-get', 'install', '-y', 'portaudio19-dev'], check=False)
        except:
            pass
    elif system == 'darwin':
        # macOS系统
        try:
            subprocess.run(['brew', 'install', 'portaudio'], check=False)
        except:
            pass

def main():
    """主函数"""
    # 设置环境
    base_path = setup_environment()
    
    # 检查依赖
    missing_deps = check_dependencies()
    
    if missing_deps:
        print("警告: 检测到缺失的依赖:")
        for dep in missing_deps:
            print(f"  - {dep}")
        
        # 尝试自动安装
        print("尝试自动安装缺失的依赖...")
        install_missing_deps()
        
        # 再次检查
        missing_deps = check_dependencies()
        if missing_deps:
            print("错误: 无法解决依赖问题，请手动安装:")
            for dep in missing_deps:
                print(f"  - {dep}")
            return False
    
    return True

# 在模块导入时执行
if __name__ == '__main__':
    main()
else:
    # 作为运行时钩子执行
    main() 