# =============================================================
# 文件名(File): speaker_change_detector.py
# 版本(Version): v0.1.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 说话人变化检测模块（跨平台）
# =============================================================

import numpy as np
import webrtcvad
from resemblyzer import VoiceEncoder, preprocess_wav
from scipy.spatial.distance import cosine
import collections
import threading

class SpeakerChangeDetector:
    def __init__(self, sample_rate=16000, vad_mode=1, window_ms=30, min_speech_ms=500, change_threshold=0.7):
        self.sample_rate = sample_rate
        self.vad = webrtcvad.Vad(vad_mode)
        self.window_ms = window_ms
        self.window_bytes = int(sample_rate * 2 * window_ms / 1000)
        self.min_speech_frames = int(min_speech_ms / window_ms)
        self.encoder = VoiceEncoder()
        self.change_threshold = change_threshold
        self.prev_embedding = None
        self.speech_buffer = bytearray()
        self.frame_queue = collections.deque()
        self.lock = threading.Lock()

    def is_speech(self, pcm_bytes):
        return self.vad.is_speech(pcm_bytes, self.sample_rate)

    def feed_pcm(self, pcm_bytes):
        """
        输入PCM字节流，自动分帧，检测说话人变化。
        返回：(pcm_chunk, is_speaker_changed)
        """
        results = []
        self.speech_buffer += pcm_bytes
        while len(self.speech_buffer) >= self.window_bytes:
            frame = self.speech_buffer[:self.window_bytes]
            self.speech_buffer = self.speech_buffer[self.window_bytes:]
            if self.is_speech(frame):
                self.frame_queue.append(frame)
            else:
                if len(self.frame_queue) >= self.min_speech_frames:
                    speech_pcm = b"".join(self.frame_queue)
                    is_changed = self._detect_change(speech_pcm)
                    results.append((speech_pcm, is_changed))
                self.frame_queue.clear()
        return results

    def flush(self):
        """
        处理剩余帧。
        """
        results = []
        if len(self.frame_queue) >= self.min_speech_frames:
            speech_pcm = b"".join(self.frame_queue)
            is_changed = self._detect_change(speech_pcm)
            results.append((speech_pcm, is_changed))
        self.frame_queue.clear()
        return results

    def _detect_change(self, speech_pcm):
        # Resemblyzer 需要float32, 16kHz, 单声道
        wav = np.frombuffer(speech_pcm, dtype=np.int16).astype(np.float32) / 32768.0
        embedding = self.encoder.embed_utterance(wav)
        is_changed = False
        if self.prev_embedding is not None:
            sim = 1 - cosine(self.prev_embedding, embedding)
            if sim < self.change_threshold:
                is_changed = True
        self.prev_embedding = embedding
        return is_changed 