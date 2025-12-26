from __future__ import annotations
import httpx
from typing import Any, Dict
from aogrl_ops_pack.time_utils import now_tz
from aogrl_ops_pack.cache import CacheManager

def binance_ping(_: Dict[str, Any]) -> Dict[str, Any]:
    with httpx.Client(http2=True, timeout=10) as c:
        r = c.get("https://api.binance.com/api/v3/ping")
    return {"ok": True, "status": r.status_code, "when": str(now_tz())}

def cache_warm(params: Dict[str, Any]) -> Dict[str, Any]:
    key = params.get("key", "warm")
    val = params.get("value", "ok")
    CacheManager().set(key, val)
    return {"ok": True, "key": key, "value": val}

BUILTINS = {
    "binance_ping": {"desc": "Check Binance API availability", "run": binance_ping},
    "cache_warm":   {"desc": "Write a test key to cache",      "run": cache_warm},
}
