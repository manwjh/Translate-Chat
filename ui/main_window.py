from PyQt6.QtCore import pyqtSignal
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QTextEdit, QPushButton, QHBoxLayout, QLabel
import sys

class MainWindow(QWidget):
    asr_signal = pyqtSignal(str, str, bool)  # text, translation, is_final

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
        btn_layout.addWidget(self.mic_btn)
        btn_layout.addWidget(self.stop_btn)
        btn_layout.addWidget(self.reset_btn)
        btn_layout.addStretch()
        main_layout.addLayout(btn_layout)

        # 信号连接
        self.asr_signal.connect(self.on_asr_result)
        # 存储内容
        self.final_texts = []

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

    def on_mic(self):
        # 预留：控制麦克风开关
        pass

    def on_stop(self):
        # 预留：停止识别
        pass

    def on_reset(self):
        # 清空内容
        self.final_texts.clear()
        self.chat_area.clear()

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