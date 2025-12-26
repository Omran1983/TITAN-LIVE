import os
from core.config import settings

# Handle both SecretStr and plain str
key = getattr(settings, 'BINANCE_API_KEY')
try:
    key = key.get_secret_value()
except AttributeError:
    pass

def mask(s: str) -> str:
    return (s[:4] + "..." + s[-4:]) if isinstance(s, str) and len(s) >= 8 else "<unavailable>"

print("ENV_FILE env var:", os.getenv("ENV_FILE"))
print("BINANCE_BASE_URL:", settings.BINANCE_BASE_URL)
print("API key (masked):", mask(key))
