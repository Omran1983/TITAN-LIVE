from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr
import os, sys, pathlib, textwrap

def _choose_env_file():
    # 1) If ENV_FILE set, use it
    env_override = os.environ.get("ENV_FILE")
    if env_override and pathlib.Path(env_override).is_file():
        return env_override
    # 2) Probe in priority: .env.mainnet -> .env.prod -> .env.testnet -> .env
    for cand in (".env.mainnet", ".env.prod", ".env.testnet", ".env"):
        if pathlib.Path(cand).is_file():
            return cand
    # 3) Nothing found; default to testnet (still works with missing file)
    return ".env.testnet"

_EFFECTIVE_ENV = _choose_env_file()

class Settings(BaseSettings):
    BINANCE_BASE_URL: str = "https://testnet.binance.vision"
    # Required for your client (SecretStr so .get_secret_value() works)
    BINANCE_API_KEY: SecretStr
    BINANCE_API_SECRET: SecretStr

    # Common optional fields (kept optional so extra keys don't crash; client may read them)
    RECV_WINDOW: int = 5000
    SYMBOL: str = "BTCUSDT"
    MODE: str | None = None
    BASE_URL: str | None = None
    TIMEOUT_MS: int = 10000
    ALLOWED_PUBLIC_IP: str | None = None

    # Accept unknown keys silently (extra="ignore")
    model_config = SettingsConfigDict(
        env_file=_EFFECTIVE_ENV,
        env_file_encoding="utf-8",
        extra="ignore",
    )

try:
    settings = Settings()
    # Loud, explicit startup banner
    print(textwrap.dedent(f"""
    [config] effective_env_file: {_EFFECTIVE_ENV}
    [config] keys:
      - BINANCE_API_KEY: {'set' if settings.BINANCE_API_KEY.get_secret_value() else 'missing'}
      - BINANCE_API_SECRET: {'set' if settings.BINANCE_API_SECRET.get_secret_value() else 'missing'}
      - SYMBOL: {settings.SYMBOL}
      - RECV_WINDOW: {settings.RECV_WINDOW}
    """).strip())
except Exception as e:
    print(f"[CONFIG ERROR] Could not load settings. Looked at: {_EFFECTIVE_ENV}", file=sys.stderr)
    print("Required: BINANCE_API_KEY, BINANCE_API_SECRET. Optional: RECV_WINDOW, SYMBOL, etc.", file=sys.stderr)
    raise