# -*- coding: utf-8 -*-
import os, yaml
from typing import Any, Dict

CONFIG_PATH = os.path.join(os.getcwd(), "config.yaml")

def load_config() -> Dict[str, Any]:
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def save_config(cfg: Dict[str, Any]) -> None:
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        yaml.safe_dump(cfg, f, sort_keys=False, allow_unicode=True)

def set_symbols(symbols):
    cfg = load_config()
    cfg.setdefault("account", {})
    cfg["account"]["symbols"] = symbols
    save_config(cfg)

def set_risk_tier(tier):
    cfg = load_config()
    cfg.setdefault("risk", {})
    if tier not in cfg["risk"].get("tiers", {}):
        raise ValueError(f"Unknown risk tier: {tier}")
    cfg["risk"]["tier_default"] = tier
    save_config(cfg)

def update_risk_param(param_key: str, value):
    cfg = load_config()
    tier = cfg["risk"]["tier_default"]
    cfg["risk"]["tiers"][tier][param_key] = value
    save_config(cfg)
