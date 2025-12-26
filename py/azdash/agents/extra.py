from __future__ import annotations
from typing import Any, Dict
from .providers.web_tools import ddg_search, fb_top_pages, ollama_chat

def agent_web_search(params: Dict[str, Any]) -> Dict[str, Any]:
    q = params.get("q") or params.get("query") or ""
    n = int(params.get("n", 10))
    return {"agent": "web_search", "q": q, "n": n, "results": ddg_search(q, n)}

def agent_fb_top_pages(params: Dict[str, Any]) -> Dict[str, Any]:
    topic = params.get("topic") or params.get("q") or "Indian ladies wear"
    n     = int(params.get("n", 10))
    return {"agent": "fb_top_pages", "topic": topic, "n": n, **fb_top_pages(topic, n)}

def agent_ollama_chat(params: Dict[str, Any]) -> Dict[str, Any]:
    prompt = params.get("prompt") or params.get("q") or "Say hi"
    model  = params.get("model", "llama3.1:8b")
    host   = params.get("host", "http://127.0.0.1:11434")
    return {"agent": "ollama_chat", **ollama_chat(prompt, model=model, host=host)}

AGENTS_EXTRA = {
    "web_search":  agent_web_search,
    "fb_top_pages": agent_fb_top_pages,
    "ollama_chat": agent_ollama_chat,
}
