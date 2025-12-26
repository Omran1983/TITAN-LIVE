from pathlib import Path
from typing import Any, Dict
import os

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore


def load_config() -> Dict[str, Any]:
    root = Path(__file__).resolve().parents[1]
    base = root / "config" / "config.base.toml"
    env = root / "config" / "config.dev.toml"

    data: Dict[str, Any] = {}
    if base.exists():
        data.update(tomllib.loads(base.read_text(encoding="utf-8")))
    if env.exists():
        data.update(tomllib.loads(env.read_text(encoding="utf-8")))

    # Environment variables override TOML
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if supabase_url:
        data["supabase_url"] = supabase_url
    if supabase_key:
        data["supabase_service_role_key"] = supabase_key

    return data
