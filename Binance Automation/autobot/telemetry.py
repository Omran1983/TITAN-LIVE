# -*- coding: utf-8 -*-
import os, requests

TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
CHAT  = os.getenv("TELEGRAM_CHAT_ID")

def send(msg: str):
    if not TOKEN or not CHAT:
        return False
    try:
        r = requests.post(
            f"https://api.telegram.org/bot{TOKEN}/sendMessage",
            data={"chat_id": CHAT, "text": msg[:4096]}
        )
        return r.ok
    except Exception:
        return False
