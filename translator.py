# =============================================================
# 文件名(File): translator.py
# 版本(Version): v0.1.1
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 翻译逻辑模块
# =============================================================

import aiohttp
import asyncio
from config import TRANSLATE_API_URL, LLM_API_KEY, LLM_MODEL

class Translator:
    def __init__(self):
        pass

    async def translate(self, text, src_lang='auto', tgt_lang='en'):
        # 构造 prompt
        if src_lang == 'auto':
            prompt = f"""
    请将以下句子翻译成【{tgt_lang}】。要求：
    - 准确传达原文含义；
    - 如果原文存在语法错误，直接修正，不要解释原因；
    - 不添加、删除、润色或解释；
    - 仅输出翻译后的内容。

    原文：
    {text}
    """
        else:
            prompt = f"""
    请将以下内容从【{src_lang}】翻译成【{tgt_lang}】。要求：
    - 准确传达原文含义；
    - 不添加、删除、润色或解释；
    - 仅输出翻译后的内容。

    原文：
    {text}
    """

        headers = {
            "Authorization": f"Bearer {LLM_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": LLM_MODEL,
            "messages": [
                {"role": "user", "content": prompt.strip()}
            ]
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(TRANSLATE_API_URL, headers=headers, json=payload, timeout=15) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return data.get("choices", [{}])[0].get("message", {}).get("content", "")
                else:
                    return f"[翻译失败: {resp.status}] {text}"
# 测试用
if __name__ == "__main__":
    async def test():
        t = Translator()
        result = await t.translate("你好，世界！", src_lang="zh", tgt_lang="en")
        print(result)
    asyncio.run(test()) 