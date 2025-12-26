from __future__ import annotations
import os, httpx
from typing import Any, Dict, List

def ddg_search(query: str, n: int = 10) -> List[Dict[str, Any]]:
    """Simple web search (titles + links)"""
    try:
        from duckduckgo_search import DDGS
        rows = []
        with DDGS() as ddgs:
            for hit in ddgs.text(query, max_results=n):
                rows.append({"title": hit.get("title"), "link": hit.get("href") or hit.get("link")})
        return rows
    except Exception as e:
        return [{"error": str(e)}]

def fb_top_pages(topic: str, n: int = 10) -> Dict[str, Any]:
    """
    Prefer Facebook Graph API if token present, else fall back to web search.
    Set env FB_TOKEN for Graph API: https://graph.facebook.com/v20.0/search?type=page
    """
    tok = os.getenv("FB_TOKEN")
    if tok:
        url = "https://graph.facebook.com/v20.0/search"
        qs  = {"type":"page", "q": topic, "fields":"name,fan_count,link", "limit": str(n), "access_token": tok}
        try:
            r = httpx.get(url, params=qs, timeout=20)
            data = r.json()
            pages = [
                {"name": p.get("name"), "fans": p.get("fan_count"), "link": p.get("link")}
                for p in (data.get("data") or [])
            ]
            return {"source":"graph_api", "pages": pages}
        except Exception as e:
            return {"source":"graph_api", "error": str(e)}
    # Fallback via web search (public pages only)
    q = f'site:facebook.com "{topic}"'
    return {"source":"search", "pages": ddg_search(q, n)}

def ollama_chat(prompt: str, model: str = "llama3.1:8b", host: str = "http://127.0.0.1:11434") -> Dict[str, Any]:
    """
    Local LLM via Ollama. Change model to any pulled name (e.g., qwen2.5:7b, deepseek-r1:7b).
    """
    try:
        body = {"model": model, "prompt": prompt, "stream": False}
        r = httpx.post(f"{host}/api/generate", json=body, timeout=120)
        j = r.json()
        return {"model": model, "ok": True, "text": j.get("response")}
    except Exception as e:
        return {"model": model, "ok": False, "error": str(e)}
