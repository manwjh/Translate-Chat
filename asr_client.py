# =============================================================
# 文件名(File): asr_client.py
# 版本(Version): v0.1.1
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 火山ASR客户端模块
# =============================================================

import aiohttp
import asyncio
import struct
import gzip
import uuid
import json
from config import ASR_WS_URL, ASR_APP_KEY, ASR_ACCESS_KEY, ASR_SAMPLE_RATE
import logging

# 新增导入
#from speaker_change_detector import SpeakerChangeDetector

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 火山ASR协议相关常量
class ProtocolVersion:
    V1 = 0b0001

class MessageType:
    CLIENT_FULL_REQUEST = 0b0001
    CLIENT_AUDIO_ONLY_REQUEST = 0b0010
    SERVER_FULL_RESPONSE = 0b1001
    SERVER_ERROR_RESPONSE = 0b1111

class MessageTypeSpecificFlags:
    NO_SEQUENCE = 0b0000
    POS_SEQUENCE = 0b0001
    NEG_SEQUENCE = 0b0010
    NEG_WITH_SEQUENCE = 0b0011

class SerializationType:
    NO_SERIALIZATION = 0b0000
    JSON = 0b0001

class CompressionType:
    GZIP = 0b0001

# 协议头构造
class AsrRequestHeader:
    def __init__(self):
        self.message_type = MessageType.CLIENT_FULL_REQUEST
        self.message_type_specific_flags = MessageTypeSpecificFlags.POS_SEQUENCE
        self.serialization_type = SerializationType.JSON
        self.compression_type = CompressionType.GZIP
        self.reserved_data = bytes([0x00])

    def with_message_type(self, message_type: int):
        self.message_type = message_type
        return self

    def with_message_type_specific_flags(self, flags: int):
        self.message_type_specific_flags = flags
        return self

    def with_serialization_type(self, serialization_type: int):
        self.serialization_type = serialization_type
        return self

    def with_compression_type(self, compression_type: int):
        self.compression_type = compression_type
        return self

    def with_reserved_data(self, reserved_data: bytes):
        self.reserved_data = reserved_data
        return self

    def to_bytes(self) -> bytes:
        header = bytearray()
        header.append((ProtocolVersion.V1 << 4) | 1)
        header.append((self.message_type << 4) | self.message_type_specific_flags)
        header.append((self.serialization_type << 4) | self.compression_type)
        header.extend(self.reserved_data)
        return bytes(header)

    @staticmethod
    def default_header():
        return AsrRequestHeader()

# 请求构造
class RequestBuilder:
    @staticmethod
    def new_auth_headers() -> dict:
        reqid = str(uuid.uuid4())
        return {
            "X-Api-Resource-Id": "volc.bigasr.sauc.duration",
            "X-Api-Request-Id": reqid,
            "X-Api-Access-Key": ASR_ACCESS_KEY,
            "X-Api-App-Key": ASR_APP_KEY
        }

    @staticmethod
    def new_full_client_request(seq: int) -> bytes:
        header = AsrRequestHeader.default_header() \
            .with_message_type_specific_flags(MessageTypeSpecificFlags.POS_SEQUENCE)
        payload = {
            "user": {"uid": "demo_uid"},
            "audio": {
                "format": "pcm",  # 恢复为PCM编码
                "codec": "raw",
                "rate": ASR_SAMPLE_RATE,
                "bits": 16,
                "channel": 1
            },
            "request": {
                "model_name": "bigmodel",
                "enable_itn": True,
                "enable_punc": True,
                "enable_ddc": True,
                "show_utterances": True,
                "result_type": "single",
                "vad_segment_duration": 600,
                # "end_window_size": 800,
                # "force_to_speech_time": 1000,
                "enable_nonstream": False
            }
        }
        payload_bytes = json.dumps(payload).encode('utf-8')
        compressed_payload = gzip.compress(payload_bytes)
        payload_size = len(compressed_payload)
        request = bytearray()
        request.extend(header.to_bytes())
        request.extend(struct.pack('>i', seq))
        request.extend(struct.pack('>I', payload_size))
        request.extend(compressed_payload)
        return bytes(request)

    @staticmethod
    def new_audio_only_request(seq: int, segment: bytes, is_last: bool = False) -> bytes:
        header = AsrRequestHeader.default_header()
        if is_last:
            header.with_message_type_specific_flags(MessageTypeSpecificFlags.NEG_WITH_SEQUENCE)
            seq = -seq
        else:
            header.with_message_type_specific_flags(MessageTypeSpecificFlags.POS_SEQUENCE)
        header.with_message_type(MessageType.CLIENT_AUDIO_ONLY_REQUEST)
        request = bytearray()
        request.extend(header.to_bytes())
        request.extend(struct.pack('>i', seq))
        compressed_segment = gzip.compress(segment)
        request.extend(struct.pack('>I', len(compressed_segment)))
        request.extend(compressed_segment)
        return bytes(request)

# 响应解析
class AsrResponse:
    def __init__(self):
        self.code = 0
        self.event = 0
        self.is_last_package = False
        self.payload_sequence = 0
        self.payload_size = 0
        self.payload_msg = None

    def to_dict(self):
        return {
            "code": self.code,
            "event": self.event,
            "is_last_package": self.is_last_package,
            "payload_sequence": self.payload_sequence,
            "payload_size": self.payload_size,
            "payload_msg": self.payload_msg
        }

class ResponseParser:
    @staticmethod
    def parse_response(msg: bytes) -> AsrResponse:
        response = AsrResponse()
        header_size = msg[0] & 0x0f
        message_type = msg[1] >> 4
        message_type_specific_flags = msg[1] & 0x0f
        serialization_method = msg[2] >> 4
        message_compression = msg[2] & 0x0f
        payload = msg[header_size*4:]
        if message_type_specific_flags & 0x01:
            response.payload_sequence = struct.unpack('>i', payload[:4])[0]
            payload = payload[4:]
        if message_type_specific_flags & 0x02:
            response.is_last_package = True
        if message_type_specific_flags & 0x04:
            response.event = struct.unpack('>i', payload[:4])[0]
            payload = payload[4:]
        if message_type == MessageType.SERVER_FULL_RESPONSE:
            response.payload_size = struct.unpack('>I', payload[:4])[0]
            payload = payload[4:]
        elif message_type == MessageType.SERVER_ERROR_RESPONSE:
            response.code = struct.unpack('>i', payload[:4])[0]
            response.payload_size = struct.unpack('>I', payload[4:8])[0]
            payload = payload[8:]
        if not payload:
            return response
        if message_compression == CompressionType.GZIP:
            try:
                payload = gzip.decompress(payload)
            except Exception as e:
                logger.error(f"Failed to decompress payload: {e}")
                return response
        try:
            if serialization_method == SerializationType.JSON:
                response.payload_msg = json.loads(payload.decode('utf-8'))
        except Exception as e:
            logger.error(f"Failed to parse payload: {e}")
        return response

# 错误码与原因映射
ASR_ERROR_CODE_MAP = {
    20000000: "成功",
    45000001: "请求参数无效：请求参数缺失必需字段 / 字段值无效 / 重复请求。",
    45000002: "空音频",
    45000081: "等包超时",
    45000151: "音频格式不正确",
    55000031: "服务器繁忙：服务过载，无法处理当前请求。",
}

def get_asr_error_reason(code):
    if code in ASR_ERROR_CODE_MAP:
        return ASR_ERROR_CODE_MAP[code]
    if 55000000 <= code <= 55099999:
        return "服务内部处理错误"
    return "未知错误"

# 主ASR客户端
class VolcanoASRClientAsync:
    def __init__(self, on_result=None, segment_duration=200):
        self.seq = 1
        self.segment_duration = segment_duration
        self.on_result = on_result
        self.session = None
        self.conn = None
        self.running = False
        # 新增：说话人变化检测器
        #self.speaker_detector = SpeakerChangeDetector(sample_rate=ASR_SAMPLE_RATE)

    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self

    async def __aexit__(self, exc_type, exc, tb):
        if self.conn and not self.conn.closed:
            await self.conn.close()
        if self.session and not self.session.closed:
            await self.session.close()

    async def connect(self):
        headers = RequestBuilder.new_auth_headers()
        self.conn = await self.session.ws_connect(ASR_WS_URL, headers=headers)
        self.running = True
        logger.info(f"Connected to {ASR_WS_URL}")

    async def send_full_client_request(self):
        request = RequestBuilder.new_full_client_request(self.seq)
        await self.conn.send_bytes(request)
        logger.info(f"Sent full client request with seq: {self.seq}")
        self.seq += 1

    async def send_audio_stream(self, audio_generator):
        buf = b""
        count = 0
        # 新增：用于说话人检测的缓冲
        #detector = self.speaker_detector
        async for chunk, is_last in audio_generator:
            buf += chunk
            count += 1
            # 说话人检测
            #results = detector.feed_pcm(chunk)
            #for speech_pcm, is_changed in results:
            #    if is_changed:
            #        print("[SpeakerChange] 检测到说话人变化！")
            if count == 2 or is_last:
                request = RequestBuilder.new_audio_only_request(self.seq, buf, is_last=is_last)
                await self.conn.send_bytes(request)
                logger.info(f"Sent audio chunk seq={self.seq} size={len(request)} bytes last={is_last} ")
                if not is_last:
                    self.seq += 1
                buf = b""
                count = 0
        # 处理最后剩余帧
        #for speech_pcm, is_changed in detector.flush():
        #    if is_changed:
        #        print("[SpeakerChange] 检测到说话人变化！（结尾）")

    async def receive_results(self):
        async for msg in self.conn:
            if msg.type == aiohttp.WSMsgType.BINARY:
                response = ResponseParser.parse_response(msg.data)
                # 仅当包含有效text时打印payload_msg的json内容
                if response.payload_msg:
                    result = response.payload_msg.get('result', {})
                    text = result.get('text', '')
                    if text:
                        import json
                        print("[ASR JSON]", json.dumps(response.payload_msg, ensure_ascii=False))
                if response.code != 0:
                    reason = get_asr_error_reason(response.code)
                    logger.error(f"ASR错误码: {response.code}, 原因: {reason}")
                if self.on_result:
                    ret = self.on_result(response)
                    if asyncio.iscoroutine(ret):
                        await ret
                if response.is_last_package or response.code != 0:
                    break
            elif msg.type == aiohttp.WSMsgType.ERROR:
                logger.error(f"WebSocket error: {msg.data}")
                break
            elif msg.type == aiohttp.WSMsgType.CLOSED:
                logger.info("WebSocket connection closed")
                break

    async def run(self, audio_generator):
        await self.connect()
        await self.send_full_client_request()
        send_task = asyncio.create_task(self.send_audio_stream(audio_generator))
        await self.receive_results()
        send_task.cancel()
        try:
            await send_task
        except asyncio.CancelledError:
            pass 