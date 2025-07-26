# =============================================================
# 文件名(File): audio_capture_plyer.py
# 版本(Version): v0.1.1
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): Android Plyer 音频采集实现
# =============================================================

import threading
import queue
import asyncio
import time
import os
from plyer import audio

class AudioStream:
    def __init__(self, rate=16000, channels=1, frames_per_buffer=1024, input_device_index=None):
        self.rate = rate
        self.channels = channels
        self.frames_per_buffer = frames_per_buffer
        self.audio_queue = queue.Queue()
        self.running = False
        self.thread = None
        self.audio_file = "recorded.wav"
        self.last_pos = 0

    def start(self):
        if self.running:
            return
        self.running = True
        audio.start(filename=self.audio_file)
        self.thread = threading.Thread(target=self._consume)
        self.thread.start()

    def stop(self):
        if not self.running:
            return
        self.running = False
        audio.stop()
        self.audio_queue.put(None)
        if self.thread is not None:
            self.thread.join()
            self.thread = None

    def _consume(self):
        while self.running:
            try:
                time.sleep(0.05)
                if not os.path.exists(self.audio_file):
                    continue
                with open(self.audio_file, "rb") as f:
                    f.seek(self.last_pos)
                    data = f.read(4096)
                    if data:
                        self.audio_queue.put(data)
                        self.last_pos = f.tell()
            except Exception:
                continue

    def on_audio(self, data):
        pass

    async def audio_stream_generator(self, chunk_ms=100):
        bytes_per_ms = self.rate * self.channels * 2 // 1000
        chunk_bytes = bytes_per_ms * chunk_ms
        buf = b""
        loop = asyncio.get_event_loop()
        self.start()
        try:
            while self.running:
                data = await loop.run_in_executor(None, self.audio_queue.get)
                if data is None:
                    break
                buf += data
                while len(buf) >= chunk_bytes:
                    pcm = buf[:chunk_bytes]
                    yield pcm, False
                    buf = buf[chunk_bytes:]
        finally:
            self.stop()
        if buf:
            yield buf, True

    def __del__(self):
        pass 