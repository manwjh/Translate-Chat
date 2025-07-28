# =============================================================
# 文件名(File): config_manager.py
# 版本(Version): v2.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 配置管理模块，移除Android支持，专注桌面平台
# =============================================================

import os
import sys
import logging
from typing import Optional

# 日志配置
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

# 设置Kivy日志级别，减少重复信息
os.environ["KIVY_LOG_LEVEL"] = "error"

class ConfigManager:
    """配置管理器，支持环境变量、加密存储和默认配置三种配置方式"""
    
    def __init__(self):
        self.platform = self._detect_platform()
        self.config = {}
        self.secure_storage = None
        self._init_secure_storage()
        self._load_config()
    
    def _detect_platform(self) -> str:
        """检测当前运行平台"""
        if sys.platform.startswith('darwin'):
            return 'macos'
        elif sys.platform.startswith('linux'):
            return 'linux'
        else:
            return 'unknown'
    
    def _init_secure_storage(self):
        """初始化加密存储"""
        try:
            from utils.secure_storage import SecureStorage
            self.secure_storage = SecureStorage()
            # logger.info("加密存储初始化成功")
        except Exception as e:
            logger.warning(f"加密存储初始化失败: {e}")
            self.secure_storage = None
    
    def _load_config(self):
        """加载配置，按优先级顺序"""
        # logger.info(f"检测到平台: {self.platform}")
        
        # 1. 优先使用环境变量（开发者模式）
        env_config = self._load_from_env()
        if env_config:
            self.config = env_config
            # logger.info("已从环境变量加载配置")
            return
        
        # 2. 从加密存储加载（用户模式）
        encrypted_config = self._load_from_encrypted_storage()
        if encrypted_config:
            self.config = encrypted_config
            # logger.info("已从加密存储加载配置")
            return
        
        # 3. 使用默认配置（兜底）
        self.config = self._get_default_config()
        logger.warning("[配置] 使用默认配置（仅用于开发测试）")
    
    def _load_from_env(self) -> Optional[dict]:
        """从环境变量加载配置"""
        config = {}
        
        # ASR配置
        asr_app_id = os.environ.get('ASR_APP_ID')
        asr_access_key = os.environ.get('ASR_ACCESS_KEY')
        
        # LLM配置
        llm_api_key = os.environ.get('LLM_API_KEY')
        
        # 检查必要的环境变量是否存在
        if all([asr_app_id, asr_access_key, llm_api_key]):
            config.update({
                'ASR_WS_URL': "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel",
                'ASR_APP_ID': asr_app_id or "8388344882",  # 使用默认值或环境变量
                'ASR_ACCESS_KEY': asr_access_key,
                'ASR_SAMPLE_RATE': 16000,
                'LLM_BASE_URL': "https://ark.cn-beijing.volces.com/api/v3",
                'LLM_API_KEY': llm_api_key,
                'LLM_MODEL': "doubao-seed-1-6-flash-250615",
                'TRANSLATE_API_URL': "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
            })
            return config
        
        return None
    
    def _load_from_encrypted_storage(self) -> Optional[dict]:
        """从加密存储加载配置"""
        if not self.secure_storage:
            return None
        
        try:
            config = self.secure_storage.load_config()
            
            # 检查必要的配置项是否存在
            required_keys = ['ASR_APP_ID', 'ASR_ACCESS_KEY', 'LLM_API_KEY']
            if all(config.get(key) for key in required_keys):
                # 补充默认配置项
                config.update({
                    'ASR_WS_URL': "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async",
                    'ASR_APP_ID': config.get('ASR_APP_ID', "8388344882"),
                    'ASR_SAMPLE_RATE': 16000,
                    'LLM_BASE_URL': "https://ark.cn-beijing.volces.com/api/v3",
                    'LLM_MODEL': "doubao-seed-1-6-flash-250615",
                    'TRANSLATE_API_URL': "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
                })
                return config
        except Exception as e:
            logger.error(f"从加密存储加载配置失败: {e}")
        
        return None
    
    def _get_default_config(self) -> dict:
        """获取默认配置（仅用于开发测试）"""
        return {
            'ASR_WS_URL': "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async",
            'ASR_APP_ID': "8388344882",  # 请通过环境变量或加密存储设置
            'ASR_ACCESS_KEY': "",  # 请通过环境变量或加密存储设置
            'ASR_SAMPLE_RATE': 16000,
            'LLM_BASE_URL': "https://ark.cn-beijing.volces.com/api/v3",
            'LLM_API_KEY': "",  # 请通过环境变量或加密存储设置
            'LLM_MODEL': "doubao-seed-1-6-flash-250615",
            'TRANSLATE_API_URL': "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
        }
    
    def get(self, key: str, default=None):
        """获取配置项"""
        return self.config.get(key, default)
    
    def get_all(self) -> dict:
        """获取所有配置"""
        return self.config.copy()
    
    def save_config(self, config_data):
        """保存配置到加密存储"""
        if not self.secure_storage:
            logger.error("加密存储未初始化，无法保存配置")
            return False
        
        try:
            # 验证必要的配置项
            required_keys = ['ASR_APP_ID', 'ASR_ACCESS_KEY', 'LLM_API_KEY']
            if not all(config_data.get(key) for key in required_keys):
                logger.error("配置数据不完整，缺少必要的API密钥")
                return False
            
            success = self.secure_storage.save_config(config_data)
            if success:
                logger.info("配置已成功保存到加密存储")
                # 重新加载配置
                self._load_config()
            return success
        except Exception as e:
            logger.error(f"保存配置失败: {e}")
            return False
    
    def clear_config(self):
        """清除加密存储的配置"""
        if not self.secure_storage:
            logger.error("加密存储未初始化，无法清除配置")
            return False
        
        try:
            success = self.secure_storage.clear_config()
            if success:
                logger.info("加密存储配置已清除")
                # 重新加载配置
                self._load_config()
            return success
        except Exception as e:
            logger.error(f"清除配置失败: {e}")
            return False
    
    def validate_config(self) -> bool:
        """验证配置是否完整"""
        required_keys = ['ASR_APP_ID', 'ASR_ACCESS_KEY', 'LLM_API_KEY']
        missing_keys = [key for key in required_keys if not self.config.get(key)]
        
        if missing_keys:
            logger.error(f"缺少必要的配置项: {missing_keys}")
            return False
        
        return True
    
    def print_config_status(self):
        """打印配置状态"""
        source = self._get_config_source()
        # 只保留业务相关日志
        if source == "默认配置":
            logger.warning("[配置] 使用默认配置，请设置API密钥")
        else:
            logger.info("[配置] 配置完整，可以正常使用")
    
    def _get_config_source(self) -> str:
        """获取配置来源"""
        if os.environ.get('ASR_APP_ID') and os.environ.get('ASR_ACCESS_KEY') and os.environ.get('LLM_API_KEY'):
            return "环境变量"
        elif self.secure_storage and self.secure_storage.config_exists():
            return "加密存储"
        else:
            return "默认配置"

# 全局配置管理器实例
config_manager = ConfigManager() 