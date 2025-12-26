from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

import tomllib  # Python 3.11+


"""
Jarvis config loader for AION-ZERO.

- Reads the canonical base TOML:
    F:\\AION-ZERO\\config\\base.toml

- Optionally merges in:
    F:\\AION-ZERO\\config\\local.toml   (for overrides)

- Exposes:
    load_config()      -> full merged dict
    get_prompt_block() -> a single [prompt.xxx] block
"""


# Project root: ...\AION-ZERO
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# Config files
BASE_TOML = PROJECT_ROOT / "config" / "base.toml"
LOCAL_TOML = PROJECT_ROOT / "config" / "local.toml"


def _load_toml(path: Path) -> Dict[str, Any]:
    """Load TOML file if it exists, else return empty dict."""
    if not path.exists():
        return {}
    with path.open("rb") as f:
        return tomllib.load(f)


def _deep_merge(a: Dict[str, Any], b: Dict[str, Any]) -> Dict[str, Any]:
    """
    Deep-merge dict b into dict a (a wins where keys conflict unless both values are dicts).
    Returns a NEW dict.
    """
    result: Dict[str, Any] = {}

    # copy from a
    for k, v in a.items():
        result[k] = v

    # merge from b
    for k, v in b.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = _deep_merge(result[k], v)
        else:
            result[k] = v

    return result


def load_config() -> Dict[str, Any]:
    """
    Load base + optional local TOML and return merged config.
    """
    base_cfg = _load_toml(BASE_TOML)
    local_cfg = _load_toml(LOCAL_TOML)

    if not base_cfg:
        raise FileNotFoundError(f"Base TOML not found or empty: {BASE_TOML}")

    if local_cfg:
        return _deep_merge(base_cfg, local_cfg)
    return base_cfg


def get_prompt_block(key: str) -> Dict[str, Any]:
    """
    Return config for [prompt.<key>].

    Accepts both:
      - "auto_sql"
      - "prompt.auto_sql"

    Example:
        get_prompt_block("auto_sql")
        get_prompt_block("prompt.auto_sql")
    """
    cfg = load_config()
    prompts = cfg.get("prompt", {})

    normalized = key.strip()

    # Allow "prompt.auto_sql" style
    if normalized.startswith("prompt."):
        normalized = normalized.split(".", 1)[1].strip()

    if normalized not in prompts:
        available = ", ".join(sorted(prompts.keys()))
        raise KeyError(f"Prompt '{key}' not found. Available: {available}")

    return prompts[normalized]


if __name__ == "__main__":
    # Quick debug: list all prompt keys
    cfg = load_config()
    prompts = cfg.get("prompt", {})
    print("Loaded prompts:", ", ".join(sorted(prompts.keys())))
