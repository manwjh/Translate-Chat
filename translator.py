# =============================================================
# 文件名(File): translator.py
# 版本(Version): v0.4.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 翻译 + ASR纠偏，返回纠错&翻译结果结构
# =============================================================

import aiohttp
import asyncio
import logging
from config_manager import config_manager

# 日志配置
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

class Translator:
    def __init__(self):
        pass

    async def translate(self, text, src_lang='auto', tgt_lang='en'):
        # 构造 prompt，返回两个部分：纠错原文 + 翻译结果
        if src_lang == 'auto':
            prompt = f"""
你是一个高精度语音识别后处理专家，请处理以下自动语音识别（ASR）文本，输出两部分结果：

步骤一：根据语义上下文和发音相似原则，对识别结果进行纠错，包括：
- 掉字、同音字、错别字；
- 中文语序问题；
- 英文误识别（如“狗狗妈”→“Google Map”）；
- 拼音或音译词不标准；

步骤二：将纠错后的句子翻译为【{tgt_lang}】，翻译要求：
- 精准传达语义；
- 不要解释或注释；
- 无法理解内容请标注：【语义无法识别】。

请返回如下格式：

【纠错后原文】<修正后的原文>  
【翻译结果】<翻译后的内容>

原始ASR内容如下：
{text}
"""
        else:
            prompt = f"""
你是一个语言专家，请将下列【{src_lang}】文本翻译为【{tgt_lang}】，翻译前请先做ASR错误纠正，包括：
- 同音字、错别字；
- 拼音误识别；
- 英文词混淆；
- 语法混乱、口语简化等问题。

请返回如下格式：

【纠错后原文】<修正后的原文>  
【翻译结果】<翻译后的内容>

原始内容：
{text}
"""

        headers = {
            "Authorization": f"Bearer {config_manager.get('LLM_API_KEY')}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": config_manager.get('LLM_MODEL'),
            "messages": [
                {"role": "system", "content": "你是一个语音转写纠错和翻译专家，返回结构化结果。"},
                {"role": "user", "content": prompt.strip()}
            ]
        }

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    config_manager.get('TRANSLATE_API_URL'),
                    headers=headers,
                    json=payload,
                    timeout=15
                ) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        content = data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()

                        # 简单解析两个部分
                        corrected = ""
                        translation = ""

                        for line in content.splitlines():
                            line = line.strip()
                            if line.startswith("【纠错后原文】"):
                                corrected = line.replace("【纠错后原文】", "").strip()
                            elif line.startswith("【翻译结果】"):
                                translation = line.replace("【翻译结果】", "").strip()

                        if not corrected and not translation:
                            logging.warning("无法解析结构化响应，原始返回：%s", content)
                            return {
                                "corrected": "[解析失败]",
                                "translation": "[翻译失败]",
                                "raw": content
                            }

                        return {
                            "corrected": corrected,
                            "translation": translation,
                            "raw": content
                        }
                    else:
                        logging.error("翻译失败 %d，内容片段：%s", resp.status, text[:30])
                        return {
                            "corrected": "[请求失败]",
                            "translation": text,
                            "raw": f"[翻译失败: {resp.status}]"
                        }
        except Exception as e:
            logging.exception("请求异常: %s", str(e))
            return {
                "corrected": "[异常]",
                "translation": text,
                "raw": f"[翻译异常] {str(e)}"
            }

# 测试用
if __name__ == "__main__":
    async def test():
        t = Translator()
        sample_texts = [
            "我要去音行办卡",
            "查一下狗狗妈的路线",
            "明天定票上海",
            "Chair GPT怎么用",
            "白九喝多了",
        ]
        for txt in sample_texts:
            result = await t.translate(txt, src_lang="zh", tgt_lang="en")
                    # 移除翻译过程的详细打印，避免信息过多
        # print(f"原文: {txt}")
        # print("纠错:", result["corrected"])
        # print("翻译:", result["translation"])
        # print("----")

    asyncio.run(test())