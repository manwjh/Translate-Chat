# =============================================================
# 文件名(File): audio_capture.py
# 版本(Version): v0.5
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 跨平台音频采集模块，桌面用PyAudio，Android用Plyer
# =============================================================

try:
    from kivy.utils import platform as kivy_platform
except ImportError:
    kivy_platform = None

if kivy_platform == "android":
    from audio_capture_plyer import AudioStream
else:
    from audio_capture_pyaudio import AudioStream 