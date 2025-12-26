from __future__ import annotations
from datetime import datetime
from zoneinfo import ZoneInfo
from .settings import get_settings

def now_tz():
    tz = get_settings().timezone.tz
    try:
        return datetime.now(ZoneInfo(tz))
    except Exception:
        # Fallback to naive now if TZ missing on system
        return datetime.now()
