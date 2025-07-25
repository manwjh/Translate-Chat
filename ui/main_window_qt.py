# =============================================================
# 文件名(File): main_window.py
# 版本(Version): v0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 主界面代码
# =============================================================

from PyQt6.QtCore import pyqtSignal
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QTextEdit, QPushButton, QHBoxLayout, QLabel, QCheckBox
import sys

class MainWindow(QWidget):
    asr_signal = pyqtSignal(str, str, bool)  # text, translation, is_final
    asr_utterances_signal = pyqtSignal(list)  # 新增信号

    def __init__(self):
        super().__init__()
        self.setWindowTitle('Translate Chat')
        self.resize(500, 600)
        main_layout = QVBoxLayout(self)

        # 顶部标题
        title = QLabel('🔁 Translate Chat')
        title.setStyleSheet('font-size: 22px; font-weight: bold; padding: 8px;')
        main_layout.addWidget(title)

        # 对照区
        self.chat_area = QTextEdit(self)
        self.chat_area.setReadOnly(True)
        main_layout.addWidget(self.chat_area)

        # 底部按钮区
        btn_layout = QHBoxLayout()
        self.mic_btn = QPushButton('🎙 Mic ON', self)
        self.stop_btn = QPushButton('⏹ Stop', self)
        self.reset_btn = QPushButton('🔄 Reset', self)
        self.translate_checkbox = QCheckBox('是否翻译', self)  # 先创建
        self.translate_checkbox.setChecked(False)
        self.enable_translate = False
        self.translate_checkbox.stateChanged.connect(self.on_translate_checkbox_changed)
        btn_layout.addWidget(self.mic_btn)
        btn_layout.addWidget(self.stop_btn)
        btn_layout.addWidget(self.reset_btn)
        btn_layout.addWidget(self.translate_checkbox)
        btn_layout.addStretch()
        main_layout.addLayout(btn_layout)

        # 信号连接
        self.asr_signal.connect(self.on_asr_result)
        self.asr_utterances_signal.connect(self.show_asr_utterances)  # 连接信号
        # 存储内容
        self.final_texts = []
        self.final_bubbles = []  # 存储所有已显示的固化分句
        self.last_shown_definite_text = None
        self.final_utterance_keys = set()  # 用于分句去重

        # 按钮事件（预留）
        self.mic_btn.clicked.connect(self.on_mic)
        self.stop_btn.clicked.connect(self.on_stop)
        self.reset_btn.clicked.connect(self.on_reset)

    def on_asr_result(self, text, translation, is_final):
        if is_final:
            self.show_final_asr_text(text, translation)

    def show_final_asr_text(self, text, translation):
        # 添加到聊天区和缓存
        self.final_texts.append((text, translation))
        self.chat_area.append(f"A: {text}")
        self.chat_area.append(f"ASI: {translation}\n")

    def show_asr_utterances(self, utterances):
        # 固化分句处理
        for utt in utterances:
            text = utt.get('text', '')
            definite = utt.get('definite', False)
            translation = utt.get('translation', None)
            timeout_finalize = utt.get('timeout_finalize', False)
            start_time = utt.get('start_time')
            end_time = utt.get('end_time')
            key = (text, start_time, end_time)
            if definite and text and key not in self.final_utterance_keys:
                bubble = f"<div style='margin:8px 0;padding:8px 0;border-radius:0px;color:#fff;font-size:18px;'>"
                bubble += f"<span>{text}</span>"
                if translation:
                    bubble += f"<br/><span style='color:gray'>{translation}</span>"
                if timeout_finalize:
                    bubble += f"<br/><span style='color:red;font-size:14px;'>(超时固化)</span>"
                bubble += "</div>"
                self.final_bubbles.append(bubble)
                self.final_utterance_keys.add(key)
        self.chat_area.clear()
        for bubble in self.final_bubbles:
            self.chat_area.append(bubble)
        # 只显示最新的未固化分句（黄色斜体）
        interim = None
        for utt in utterances:
            text = utt.get('text', '')
            definite = utt.get('definite', False)
            if not definite and text:
                interim = text
        if interim:
            yellow_line = f"<div style='margin:8px 0;padding:8px 0;border-radius:0px;color:#FFD600;font-size:18px;'><i>{interim}</i></div>"
            self.chat_area.append(yellow_line)
        # 打印当前UI内容和interim
        print("[UI LOG] 当前chat_area内容:")
        print(self.chat_area.toPlainText())
        print("[UI LOG] interim(黄色斜体):", interim)

    def on_mic(self):
        # 预留：控制麦克风开关
        pass

    def on_stop(self):
        # 预留：停止识别
        pass

    def on_reset(self):
        self.final_texts.clear()
        self.chat_area.clear()
        self.final_bubbles.clear()
        self.last_shown_definite_text = None

    def on_translate_checkbox_changed(self, state):
        self.enable_translate = bool(state)

    def closeEvent(self, event):
        if hasattr(self, 'controller'):
            self.controller.stop()
        QApplication.quit()
        event.accept()

# 仅用于本地测试窗口
if __name__ == '__main__':
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    # 模拟信号
    win.on_asr_result('What\'s your name!', '你叫什么名字？', True)
    win.on_asr_result('我叫Mike', 'My name is Mike', True)
    sys.exit(app.exec()) 