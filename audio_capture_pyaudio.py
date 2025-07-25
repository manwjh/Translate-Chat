# =============================================================
# 文件名(File): audio_capture_pyaudio.py
# 版本(Version): v0.1.1
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 桌面端 PyAudio 音频采集实现
# =============================================================

import threading
import queue
import asyncio
import pyaudio

class AudioStream:
    def __init__(self, rate=16000, channels=1, frames_per_buffer=1024, input_device_index=None):
        self.rate = rate
        self.channels = channels
        self.frames_per_buffer = frames_per_buffer
        self.input_device_index = input_device_index
        self.audio_queue = queue.Queue()
        self.running = False
        self.thread = None
        self.audio = pyaudio.PyAudio()
        self.stream = None

    def start(self):
        if self.running:
            return
        self.running = True
        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=self.channels,
            rate=self.rate,
            input=True,
            input_device_index=self.input_device_index,
            frames_per_buffer=self.frames_per_buffer,
            stream_callback=self._audio_callback
        )
        self.stream.start_stream()
        self.thread = threading.Thread(target=self._consume)
        self.thread.start()

    def stop(self):
        if not self.running:
            return
        self.running = False
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
            self.stream = None
        self.audio_queue.put(None)
        if self.thread is not None:
            self.thread.join()
            self.thread = None

    def _audio_callback(self, in_data, frame_count, time_info, status):
        if self.running:
            self.audio_queue.put(in_data)
        return (None, pyaudio.paContinue)

    def _consume(self):
        while self.running:
            try:
                data = self.audio_queue.get(timeout=0.1)
                if data is None:
                    break
                self.on_audio(data)
            except queue.Empty:
                continue
            except Exception as e:
                print(f"音频处理错误: {e}")
                continue

    def on_audio(self, data):
        pass

    async def audio_stream_generator(self, chunk_ms=60):
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
        if self.stream:
            self.stream.close()
        if self.audio:
            self.audio.terminate() 