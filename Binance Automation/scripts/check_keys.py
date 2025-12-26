import os, re
from core.config import settings

def mask(val):
    s = val
    try:
        # Pydantic SecretStr -> reveal for length/masking only
        if hasattr(val, 'get_secret_value'):
            s = val.get_secret_value()
    except Exception:
        s = str(val) if val is not None else ''
    s = s or ''
    return (s[:4] + '...' + s[-4:]) if len(s) >= 8 else s