from __future__ import annotations
from pydantic import BaseModel, Field
from pathlib import Path
import tomllib

CFG_DIR = Path(r"F:/AION-ZERO/config".replace("/", "\\"))
BASE = CFG_DIR / "base.toml"
LOCAL = CFG_DIR / "env.local.toml"

class LoggingCfg(BaseModel):
    level: str = "INFO"
    human_console: bool = True
    json_file: str = "F:/AION-ZERO/logs/ops.jsonl"

class HttpCfg(BaseModel):
    timeout_sec: int = 20
    max_connections: int = 50
    retries: int = 5
    backoff_min: int = 1
    backoff_max: int = 10

class CacheCfg(BaseModel):
    path: str = "F:/AION-ZERO/cache"
    size_limit_mb: int = 256
    ttl_sec_default: int = 3600

class TzCfg(BaseModel):
    tz: str = "Indian/Mauritius"

class AppCfg(BaseModel):
    name: str = "AOGRL Ops Pack"
    env: str = "local"

class Settings(BaseModel):
    app: AppCfg = Field(default_factory=AppCfg)
    logging: LoggingCfg = Field(default_factory=LoggingCfg)
    timezone: TzCfg = Field(default_factory=TzCfg)
    http: HttpCfg = Field(default_factory=HttpCfg)
    cache: CacheCfg = Field(default_factory=CacheCfg)

def _load_toml(path: Path) -> dict:
    if not path.exists(): return {}
    with path.open("rb") as f:
        return tomllib.load(f)

def get_settings() -> Settings:
    base = _load_toml(BASE)
    local = _load_toml(LOCAL)
    merged = dict(base)
    for k, v in local.items():
        if isinstance(v, dict) and isinstance(merged.get(k), dict):
            merged[k].update(v)
        else:
            merged[k] = v
    return Settings.model_validate(merged)
