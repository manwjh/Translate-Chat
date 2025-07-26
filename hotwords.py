# =============================================================
# 文件名(File): hotwords.py
# 版本(Version): v1.0
# 作者(Author): 深圳王哥 & AI
# 创建日期(Created): 2025/7/25
# 简介(Description): 热词管理模块，负责热词的增删查改与本地持久化。
# =============================================================

import os
import json

HOTWORDS_FILE = os.path.join(os.path.dirname(__file__), "hotwords.json")
MAX_LENGTH = 300  # 最大总字符数

def load_hotwords():
    if not os.path.exists(HOTWORDS_FILE):
        return []
    try:
        with open(HOTWORDS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return [item["text"] for item in data.get("context", {}).get("context_data", [])]
    except Exception:
        return []

def save_hotwords(hotwords):
    context = {
        "context": {
            "context_type": "dialog_ctx",
            "context_data": [{"text": w} for w in hotwords]
        }
    }
    with open(HOTWORDS_FILE, "w", encoding="utf-8") as f:
        json.dump(context, f, ensure_ascii=False, indent=2)

def add_hotword(word):
    word = word.strip()
    if not word:
        return False
    hotwords = load_hotwords()
    if word in hotwords:
        return False
    # 计算新热词加入后的总长度
    total_length = sum(len(w) for w in hotwords) + len(word)
    while total_length > MAX_LENGTH and hotwords:
        # 移除最早的热词
        total_length -= len(hotwords[0])
        hotwords.pop(0)
    hotwords.append(word)
    save_hotwords(hotwords)
    return True

def remove_hotword(word):
    hotwords = load_hotwords()
    if word in hotwords:
        hotwords.remove(word)
        save_hotwords(hotwords)
        return True
    return False

def get_hotwords():
    return load_hotwords() 