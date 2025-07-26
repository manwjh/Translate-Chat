# =============================================================
# 文件名(File): config_manager.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/1/27
# 简介(Description): 配置管理模块，支持环境变量和配置文件两种方式，跨平台兼容
# =============================================================

import os
import sys
import logging
from typing import Optional

# 日志配置
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

class ConfigManager:
    """配置管理器，支持环境变量和配置文件两种配置方式"""
    
    def __init__(self):
        self.platform = self._detect_platform()
        self.config = {}
        self._load_config()
    
    def _detect_platform(self) -> str:
        """检测当前运行平台"""
        if sys.platform.startswith('darwin'):
            return 'macos'
        elif sys.platform.startswith('linux'):
            return 'linux'
        elif 'android' in sys.platform.lower():
            return 'android'
        else:
            return 'unknown'
    
    def _load_config(self):
        """加载配置，优先使用环境变量"""
        logger.info(f"检测到平台: {self.platform}")
        
        # 尝试从环境变量加载配置
        env_config = self._load_from_env()
        if env_config:
            self.config = env_config
            logger.info("已从环境变量加载配置")
            return
        
        # 使用默认配置（仅用于开发测试）
        self.config = self._get_default_config()
        logger.warning("使用默认配置（仅用于开发测试）")
    
    def _load_from_env(self) -> Optional[dict]:
        """从环境变量加载配置"""
        config = {}
        
        # ASR配置
        asr_app_id = os.environ.get('ASR_APP_ID')
        asr_app_key = os.environ.get('ASR_APP_KEY')
        asr_access_key = os.environ.get('ASR_ACCESS_KEY')
        
        # LLM配置
        llm_api_key = os.environ.get('LLM_API_KEY')
        
        # 检查必要的环境变量是否存在
        if all([asr_app_key, asr_access_key, llm_api_key]):
            config.update({
                'ASR_WS_URL': "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async",
                'ASR_APP_ID': asr_app_id or "8388344882",  # 使用默认值或环境变量
                'ASR_APP_KEY': asr_app_key,
                'ASR_ACCESS_KEY': asr_access_key,
                'ASR_SAMPLE_RATE': 16000,
                'LLM_BASE_URL': "https://ark.cn-beijing.volces.com/api/v3",
                'LLM_API_KEY': llm_api_key,
                'LLM_MODEL': "doubao-seed-1-6-flash-250615",
                'TRANSLATE_API_URL': "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
            })
            return config
        
        return None
    

    
    def _get_default_config(self) -> dict:
        """获取默认配置（仅用于开发测试）"""
        return {
            'ASR_WS_URL': "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async",
            'ASR_APP_ID': "8388344882",
            'ASR_APP_KEY': "",  # 请通过环境变量设置
            'ASR_ACCESS_KEY': "",  # 请通过环境变量设置
            'ASR_SAMPLE_RATE': 16000,
            'LLM_BASE_URL': "https://ark.cn-beijing.volces.com/api/v3",
            'LLM_API_KEY': "",  # 请通过环境变量设置
            'LLM_MODEL': "doubao-seed-1-6-flash-250615",
            'TRANSLATE_API_URL': "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
        }
    
    def get(self, key: str, default=None):
        """获取配置项"""
        return self.config.get(key, default)
    
    def get_all(self) -> dict:
        """获取所有配置"""
        return self.config.copy()
    
    def validate_config(self) -> bool:
        """验证配置是否完整"""
        required_keys = ['ASR_APP_KEY', 'ASR_ACCESS_KEY', 'LLM_API_KEY']
        missing_keys = [key for key in required_keys if not self.config.get(key)]
        
        if missing_keys:
            logger.error(f"缺少必要的配置项: {missing_keys}")
            return False
        
        return True
    
    def print_config_status(self):
        """打印配置状态"""
        logger.info("=== 配置状态 ===")
        logger.info(f"平台: {self.platform}")
        logger.info(f"ASR_APP_KEY: {'已配置' if self.config.get('ASR_APP_KEY') else '未配置'}")
        logger.info(f"ASR_ACCESS_KEY: {'已配置' if self.config.get('ASR_ACCESS_KEY') else '未配置'}")
        logger.info(f"LLM_API_KEY: {'已配置' if self.config.get('LLM_API_KEY') else '未配置'}")
        logger.info("================")

# 全局配置管理器实例
config_manager = ConfigManager() 