# =============================================================
# 文件名(File): secure_storage.py
# 版本(Version): v1.0.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 跨平台加密存储工具，支持桌面端和Android端安全存储API密钥
# =============================================================

import os
import json
import base64
import hashlib
import logging
from kivy.utils import platform

# 日志配置
logger = logging.getLogger(__name__)

class SecureStorage:
    """跨平台加密存储工具"""
    
    def __init__(self):
        self.storage_path = self._get_storage_path()
        self.fernet_key = self._get_fernet_key()
        # 减少初始化信息的详细程度
        # logger.info(f"加密存储初始化完成，存储路径: {self.storage_path}")
    
    def _get_storage_path(self):
        """获取存储路径"""
        try:
            if platform == "android":
                from android.storage import app_storage_path
                return os.path.join(app_storage_path(), "api_config.enc")
            else:
                # 桌面端使用 Kivy 用户数据目录
                try:
                    from kivy.app import App
                    app = App.get_running_app()
                    if app:
                        return os.path.join(app.user_data_dir, "api_config.enc")
                except:
                    pass
                
                # 独立运行时使用用户目录
                return os.path.expanduser("~/.translate_chat_api.enc")
        except Exception as e:
            logger.error(f"获取存储路径失败: {e}")
            # 降级到当前目录
            return "api_config.enc"
    
    def _get_fernet_key(self):
        """生成加密密钥"""
        try:
            # 使用设备唯一标识符+项目盐生成密钥
            if platform == "android":
                try:
                    from jnius import autoclass
                    Secure = autoclass('android.provider.Settings$Secure')
                    PythonActivity = autoclass('org.kivy.android.PythonActivity')
                    android_id = Secure.getString(PythonActivity.mActivity.getContentResolver(), Secure.ANDROID_ID)
                    base = android_id
                except Exception as e:
                    logger.warning(f"获取Android ID失败: {e}")
                    base = "android_default"
            else:
                base = os.environ.get("USER", "default_user")
            
            salt = "TranslateChatSalt2025"
            key = hashlib.sha256((base + salt).encode()).digest()
            return base64.urlsafe_b64encode(key[:32])
        except Exception as e:
            logger.error(f"生成加密密钥失败: {e}")
            # 降级到固定密钥（仅用于开发测试）
            return b"TranslateChatDefaultKey32BytesLong123"
    
    def save_config(self, config: dict):
        """保存加密配置"""
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(self.storage_path), exist_ok=True)
            
            # 加密数据
            from cryptography.fernet import Fernet
            f = Fernet(self.fernet_key)
            encrypted_data = f.encrypt(json.dumps(config, ensure_ascii=False).encode('utf-8'))
            
            # 写入文件
            with open(self.storage_path, "wb") as f:
                f.write(encrypted_data)
            
            # 只保留业务相关日志，不输出底层存储状态
        except Exception as e:
            logger.error(f"[存储] 配置加密保存失败: {e}")
    
    def load_config(self) -> dict:
        """加载加密配置"""
        try:
            if not os.path.exists(self.storage_path):
                logger.info("加密配置文件不存在")
                return {}
            
            # 读取加密数据
            with open(self.storage_path, "rb") as f:
                encrypted_data = f.read()
            
            # 解密数据
            from cryptography.fernet import Fernet
            f = Fernet(self.fernet_key)
            decrypted_data = f.decrypt(encrypted_data)
            config = json.loads(decrypted_data.decode('utf-8'))
            
            # 只保留业务相关日志，不输出底层存储状态
            return config
        except Exception as e:
            logger.error(f"[存储] 加载加密配置失败: {e}")
            return {}
    
    def clear_config(self):
        """清除配置"""
        try:
            if os.path.exists(self.storage_path):
                os.remove(self.storage_path)
                logger.info("加密配置文件已清除")
            return True
        except Exception as e:
            logger.error(f"清除配置失败: {e}")
            return False
    
    def config_exists(self):
        """检查配置是否存在"""
        try:
            if not os.path.exists(self.storage_path):
                return False
            
            # 尝试加载配置验证完整性
            config = self.load_config()
            required_keys = ['ASR_APP_ID', 'ASR_ACCESS_KEY', 'LLM_API_KEY']
            return all(config.get(key) for key in required_keys)
        except Exception as e:
            logger.error(f"检查配置存在性失败: {e}")
            return False 