import sys
import asyncio
import threading
from PyQt6.QtWidgets import QApplication
from ui.main_window import MainWindow
from audio_capture import AudioStream
from asr_client import VolcanoASRClientAsync
from lang_detect import LangDetect
from translator import Translator

class ASRController:
    def __init__(self, win):
        self.win = win
        self.audio = AudioStream()
        self.asr_task = None
        self.running = False
        self.loop = None
        self.lang_detect = LangDetect()
        self.translator = Translator()
        # 绑定按钮
        self.win.mic_btn.clicked.connect(self.toggle_mic)
        self.win.stop_btn.clicked.connect(self.stop)
        self.win.reset_btn.clicked.connect(self.reset)
        self.update_mic_btn()

    def update_mic_btn(self):
        self.win.mic_btn.setText('🎙 Mic ON' if not self.running else '⏸ Mic OFF')

    def toggle_mic(self):
        if self.running:
            self.stop()
        else:
            self.start()

    def start(self):
        if self.running:
            return
        self.running = True
        self.update_mic_btn()
        self.loop = threading.Thread(target=self._run_asr, daemon=True)
        self.loop.start()

    def stop(self):
        self.running = False
        self.audio.stop()
        self.update_mic_btn()
        if self.loop and self.loop.is_alive():
            self.loop.join(timeout=1)

    def reset(self):
        self.stop()
        self.win.on_reset()

    def _run_asr(self):
        asyncio.run(self._asr_flow())

    async def _do_translate_and_emit(self, text, src_lang, tgt_lang, is_final):
        translation = await self.translator.translate(text, src_lang=src_lang, tgt_lang=tgt_lang)
        self.win.asr_signal.emit(text, translation, is_final)

    async def _asr_flow(self):
        def on_result(response):
            if not self.running:
                return
            if response.payload_msg:
                result = response.payload_msg.get('result', {})
                text = result.get('text', '')
                is_final = result.get('is_final', True)
                if text and is_final:
                    src_lang = self.lang_detect.detect(text)
                    tgt_lang = 'en' if src_lang.startswith('zh') else 'zh'
                    asyncio.create_task(self._do_translate_and_emit(text, src_lang, tgt_lang, is_final))
        self.audio = AudioStream()
        async with VolcanoASRClientAsync(on_result=on_result) as asr:
            try:
                await asr.run(self.audio.audio_stream_generator(chunk_ms=200))
            except Exception as e:
                print("ASR error:", e)
        self.running = False
        self.update_mic_btn()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    controller = ASRController(win)
    win.controller = controller  # 便于UI关闭时调用
    sys.exit(app.exec()) 