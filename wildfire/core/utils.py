import os
import json
import time
import httpx
from typing import Optional, Dict, Any, List

# Configuration
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").strip()
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
PROJECT_ROOT = "F:\\AION-ZERO\\TITAN"

def sb_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }

def sb_url(table: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{table}"

def now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S%z")

class SupabaseClient:
    def __init__(self):
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise ValueError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")

    def select(self, table: str, query: str) -> List[Dict]:
        return httpx.get(f"{sb_url(table)}?{query}", headers=sb_headers()).json()

    def insert(self, table: str, payload: Dict) -> List[Dict]:
        r = httpx.post(sb_url(table), headers=sb_headers(), json=payload)
        r.raise_for_status()
        return r.json()

    def patch(self, table: str, query: str, payload: Dict) -> List[Dict]:
        r = httpx.patch(f"{sb_url(table)}?{query}", headers=sb_headers(), json=payload)
        r.raise_for_status()
        return r.json()

    def emit_event(self, source: str, event_type: str, message: str, payload: Dict = None, command_id: str = None, severity: str = "info"):
        payload = payload or {}
        # 1. Log to DB
        try:
            self.insert("az_events", {
                "source": source,
                "event_type": event_type,
                "message": message,
                "payload": payload,
                "command_id": command_id,
                "severity": severity
            })
        except Exception:
            pass # DB might fail, but continue to Pulse
        
        # 2. Broadcast to Pulse (Real-time)
        try:
            import requests     
            pulse_data = {
                "source": source,
                "type": event_type,
                "message": message,
                "command_id": command_id,
                "payload": payload,
                "severity": severity,
                "timestamp": now_iso()
            }
            # Timeout is critical to avoid blocking if Pulse is down
            requests.post("http://127.0.0.1:8000/emit", json=pulse_data, timeout=0.05)
        except Exception:
            pass # Pulse down or network error
