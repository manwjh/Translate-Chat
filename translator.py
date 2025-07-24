import aiohttp
import asyncio
from config import TRANSLATE_API_URL, LLM_API_KEY, LLM_MODEL

class Translator:
    def __init__(self):
        pass

    async def translate(self, text, src_lang='auto', tgt_lang='en'):
        # 构造 prompt
        prompt = f"请将下列句子翻译成{tgt_lang}：{text}"
        headers = {
            "Authorization": f"Bearer {LLM_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": LLM_MODEL,
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(TRANSLATE_API_URL, headers=headers, json=payload, timeout=15) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    # 假设返回格式为 {"choices": [{"message": {"content": "翻译结果"}}]}
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