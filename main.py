# =============================================================
# 文件名(File): main.py
# 版本(Version): v0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 程序主入口
# =============================================================

import sys
import asyncio
import threading
from PyQt6.QtWidgets import QApplication
from ui.main_window import MainWindow
from audio_capture import AudioStream
from asr_client import VolcanoASRClientAsync
from lang_detect import LangDetect
from translator import Translator
import copy

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
        self.audio = AudioStream()
        import copy
        N = 10  # 超时固化包数
        last_text = None
        last_emit_time = None
        no_update_count = 0
        async def on_result(response):
            nonlocal last_text, last_emit_time, no_update_count
            if not self.running:
                return
            now = asyncio.get_event_loop().time()
            timeout_finalize = False
            if response.payload_msg:
                result = response.payload_msg.get('result', {})
                asr_utterances = result.get('utterances', [])
                updated = False
                current_text = None
                new_definite_utterances = []
                for utt in asr_utterances:
                    if utt.get('definite') and not utt.get('translation'):
                        if self.win.enable_translate:
                            src_lang = self.lang_detect.detect(utt['text'])
                            tgt_lang = 'en' if src_lang.startswith('zh') else 'zh'
                            utt['translation'] = await self.translator.translate(utt['text'], src_lang=src_lang, tgt_lang=tgt_lang)
                        else:
                            utt['translation'] = None
                        updated = True
                    if utt.get('text'):
                        current_text = utt['text']
                    # 收集所有新固化分句
                    if utt.get('definite') and utt.get('text'):
                        new_definite_utterances.append(utt)
                # 检查是否有新文本
                if current_text and current_text != getattr(self.win, 'last_shown_definite_text', None):
                    self.win.last_shown_definite_text = current_text
                    no_update_count = 0
                    last_emit_time = now
                else:
                    no_update_count += 1
                # 超时固化逻辑
                if no_update_count >= N and last_text:
                    timeout_finalize = True
                    utterance = {'text': last_text, 'definite': True, 'translation': None, 'timeout_finalize': True}
                    if self.win.enable_translate:
                        src_lang = self.lang_detect.detect(last_text)
                        tgt_lang = 'en' if src_lang.startswith('zh') else 'zh'
                        utterance['translation'] = await self.translator.translate(last_text, src_lang=src_lang, tgt_lang=tgt_lang)
                    self.win.asr_utterances_signal.emit([utterance])
                    no_update_count = 0
                    last_emit_time = now
                else:
                    # emit全部分句（包括未固化过程分句）
                    for utt in asr_utterances:
                        if utt.get('definite'):
                            utt['timeout_finalize'] = False
                    self.win.asr_utterances_signal.emit(asr_utterances)
                    if last_emit_time:
                        delay = now - last_emit_time
                        print(f"[ASR延迟] 识别到UI显示延迟: {delay:.3f}s")
                    last_emit_time = now
        async with VolcanoASRClientAsync(on_result=on_result) as asr:
            try:
                await asr.run(self.audio.audio_stream_generator())
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