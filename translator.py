# =============================================================
# 文件名(File): translator.py
# 版本(Version): v0.2.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 翻译逻辑模块，含语法检查与提示词优化
# =============================================================

import aiohttp
import asyncio
import logging
from config import TRANSLATE_API_URL, LLM_API_KEY, LLM_MODEL

# 日志配置
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

class Translator:
    def __init__(self):
        pass

    async def translate(self, text, src_lang='auto', tgt_lang='en'):
        # 构造 prompt
        if src_lang == 'auto':
            prompt = f"""
你是一个严格的专业翻译工具，请遵守以下规则对输入文本进行翻译：
- 自动识别原文语言；
- 翻译目标语言为：【{tgt_lang}】；
- 必须准确传达原文含义；
- 如原文有严重语法错误且无法翻译，请仅输出：【语法错误】；
- 不得添加任何解释、注释、润色或格式标记；
- 最终只输出翻译后的文本内容。

原文：
{text}
"""
        else:
            prompt = f"""
你是一个严格的专业翻译工具，请将以下内容从【{src_lang}】翻译为【{tgt_lang}】，遵守以下规则：
- 必须准确传达原文含义；
- 不允许添加、删除、修改、润色或解释内容；
- 如果存在语法错误用谐音去努力恢复，如果无法恢复，请输出【语法错误】；
- 如遇严重语法错误且无法翻译，请仅输出：【语法错误】；
- 最终只输出翻译后的文本内容。

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
                {"role": "system", "content": "你是一个高精度的翻译助手，只输出翻译结果。"},
                {"role": "user", "content": prompt.strip()}
            ]
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    TRANSLATE_API_URL,
                    headers=headers,
                    json=payload,
                    timeout=15
                ) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                        if not content.strip():
                            logging.warning("返回内容为空，原文片段: %s", text[:30])
                            return "[翻译失败: 空响应]"
                        return content.strip()
                    else:
                        logging.error("翻译失败 %d，内容片段：%s", resp.status, text[:30])
                        return f"[翻译失败: {resp.status}] {text}"
        except Exception as e:
            logging.exception("请求异常: %s", str(e))
            return f"[翻译异常] {text}"

# 测试用
if __name__ == "__main__":
    async def test():
        t = Translator()
        result = await t.translate("你好，世界！", src_lang="zh", tgt_lang="en")
        print("翻译结果：", result)

    asyncio.run(test())