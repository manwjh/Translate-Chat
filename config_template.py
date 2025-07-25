# =============================================================
# 文件名(File): config_template.py
# 版本(Version): v0.2
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 配置模板文件
# =============================================================

# 配置文件模板
# 请复制此文件为 config.py 并填入您的API令牌

# 火山ASR配置
ASR_WS_URL = "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async"
ASR_APP_ID = "YOUR_ASR_APP_ID"  # 请替换为您的APP_ID
ASR_APP_KEY = "YOUR_ASR_APP_KEY"  # 请替换为您的APP_KEY
ASR_ACCESS_KEY = "YOUR_ASR_ACCESS_KEY"  # 请替换为您的ACCESS_KEY
ASR_SAMPLE_RATE = 16000

# LLM（翻译/语种识别）配置
LLM_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
LLM_API_KEY = "YOUR_LLM_API_KEY"  # 请替换为您的API_KEY
LLM_MODEL = "doubao-seed-1-6-flash-250615"

# 其他可选配置
TRANSLATE_API_URL = LLM_BASE_URL + "/chat/completions" 