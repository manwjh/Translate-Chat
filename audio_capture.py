# =============================================================
# 文件名(File): audio_capture.py
# 版本(Version): v0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 音频采集模块
# =============================================================

import pyaudio
import threading
import queue
import asyncio

class AudioStream:
    def __init__(self, rate=16000, channels=1, frames_per_buffer=1024, input_device_index=None):
        self.rate = rate
        self.channels = channels
        self.frames_per_buffer = frames_per_buffer
        self.input_device_index = input_device_index
        self.p = pyaudio.PyAudio()
        self.stream = None
        self.audio_queue = queue.Queue()
        self.running = False
        self.thread = None

    def start(self):
        if self.running:
            return
        self.running = True
        self.stream = self.p.open(
            format=pyaudio.paInt16,
            channels=self.channels,
            rate=self.rate,
            input=True,
            frames_per_buffer=self.frames_per_buffer,
            input_device_index=self.input_device_index,
            stream_callback=self._callback
        )
        self.stream.start_stream()
        self.thread = threading.Thread(target=self._consume)
        self.thread.start()

    def _callback(self, in_data, frame_count, time_info, status):
        self.audio_queue.put(in_data)
        return (None, pyaudio.paContinue)

    def stop(self):
        if not self.running:
            return
        self.running = False
        # 唤醒 audio_queue.get
        self.audio_queue.put(None)
        if self.stream is not None:
            try:
                if self.stream.is_active():
                    self.stream.stop_stream()
            except Exception:
                pass
            try:
                self.stream.close()
            except Exception:
                pass
            self.stream = None
        if self.thread is not None:
            self.thread.join()
            self.thread = None
        if self.p is not None:
            try:
                self.p.terminate()
            except Exception:
                pass
            self.p = None

    def _consume(self):
        while self.running:
            try:
                data = self.audio_queue.get(timeout=0.1)
                if data is None:
                    break
                self.on_audio(data)
            except queue.Empty:
                continue

    def on_audio(self, data):
        """Override this method to process audio data chunk by chunk."""
        pass

    async def audio_stream_generator(self, chunk_ms=60):
        """
        异步生成器：每chunk_ms毫秒产出一包音频数据。
        用于ASR流式推送。
        """
        bytes_per_ms = self.rate * self.channels * 2 // 1000  # 16bit=2bytes
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
            # 处理最后一包
            yield buf, True

    def __del__(self):
        # 避免多次析构导致崩溃，不在此自动stop
        pass 