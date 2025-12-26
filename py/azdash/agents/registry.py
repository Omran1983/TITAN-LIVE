from __future__ import annotations
import importlib.util, pathlib
from typing import Any, Dict, List, Callable
from .builtins import BUILTINS

AGENTS_ROOT = pathlib.Path(r"F:\AION-ZERO\py\agents")

def _load_plugins() -> Dict[str, Dict[str, Any]]:
    out: Dict[str, Dict[str, Any]] = {}
    if not AGENTS_ROOT.exists():
        return out
    for p in AGENTS_ROOT.glob("*.py"):
        name = f"azagent_{p.stem}"
        spec = importlib.util.spec_from_file_location(name, str(p))
        if not spec or not spec.loader:
            continue
        mod = importlib.util.module_from_spec(spec)
        try:
            spec.loader.exec_module(mod)  # type: ignore[attr-defined]
            agent_name = getattr(mod, "NAME", p.stem)
            desc = getattr(mod, "DESC", "")
            run = getattr(mod, "run", None)
            if callable(run):
                out[agent_name] = {"desc": desc, "run": run}
        except Exception:
            # skip broken plugin
            continue
    return out

_REGISTRY: Dict[str, Dict[str, Any]] = {**BUILTINS}
_REGISTRY.update(_load_plugins())

def list_agents() -> List[Dict[str, Any]]:
    return [{"name": k, "desc": v.get("desc", "")} for k, v in _REGISTRY.items()]

def run_agent(name: str, params: Dict[str, Any] | None = None) -> Dict[str, Any]:
    item = _REGISTRY.get(name)
    if not item:
        raise ValueError(f"unknown agent: {name}")
    fn: Callable[..., Dict[str, Any]] = item["run"]
    return fn(params or {})
# ---- AUTO-MERGE EXTRA AGENTS (do not remove) ----
try:
    from .extra import AGENTS_EXTRA as _EXTRA
    if isinstance(_EXTRA, dict):
        AGENTS.update(_EXTRA)
except Exception:
    pass
# -------------------------------------------------
