"""
Tests for TITAN-HR Compliance Rules (blocks/hr_compliance)
"""
import json
from pathlib import Path
from typing import Any, Dict, Set

ALLOWED_RULE_TYPES: Set[str] = {
    "salary_floor",
    "increment_policy",
    "obligation",
    "reporting",
    "audit"
}

REQUIRED_TOP_KEYS = {"version", "effective_date", "jurisdiction", "source", "rules"}
REQUIRED_RULE_KEYS = {"id", "name", "description", "type", "parameters"}

def _fail(msg: str) -> None:
    raise SystemExit(f"❌ PRB rules validation failed: {msg}")

def _is_non_empty_str(x: Any) -> bool:
    return isinstance(x, str) and x.strip() != ""

def _load_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        _fail(f"File not found: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        _fail(f"Invalid JSON in {path}: {e}")

def validate_prb_rules(doc: Dict[str, Any]) -> None:
    # Top-level validation
    missing = REQUIRED_TOP_KEYS - set(doc.keys())
    if missing:
        _fail(f"Missing top-level keys: {sorted(missing)}")

    if not _is_non_empty_str(doc["version"]):
        _fail("Top-level 'version' must be a non-empty string")

    if not _is_non_empty_str(doc["effective_date"]):
        _fail("Top-level 'effective_date' must be a non-empty string (YYYY-MM-DD recommended)")

    if not _is_non_empty_str(doc["jurisdiction"]):
        _fail("Top-level 'jurisdiction' must be a non-empty string")

    if not _is_non_empty_str(doc["source"]):
        _fail("Top-level 'source' must be a non-empty string")

    rules = doc["rules"]
    if not isinstance(rules, list) or len(rules) == 0:
        _fail("Top-level 'rules' must be a non-empty list")

    # Rule-level validation
    seen_ids: Set[str] = set()

    for idx, rule in enumerate(rules):
        if not isinstance(rule, dict):
            _fail(f"Rule at index {idx} must be an object")

        missing_rule = REQUIRED_RULE_KEYS - set(rule.keys())
        if missing_rule:
            _fail(f"Rule[{idx}] missing keys: {sorted(missing_rule)}")

        rid = rule["id"]
        if not _is_non_empty_str(rid):
            _fail(f"Rule[{idx}] 'id' must be a non-empty string")
        if rid in seen_ids:
            _fail(f"Duplicate rule id detected: {rid}")
        seen_ids.add(rid)

        if not _is_non_empty_str(rule["name"]):
            _fail(f"Rule[{idx}] 'name' must be a non-empty string")
        if not _is_non_empty_str(rule["description"]):
            _fail(f"Rule[{idx}] 'description' must be a non-empty string")

        rtype = rule["type"]
        if not _is_non_empty_str(rtype):
            _fail(f"Rule[{idx}] 'type' must be a non-empty string")
        if rtype not in ALLOWED_RULE_TYPES:
            _fail(f"Rule[{idx}] 'type' invalid '{rtype}'. Allowed: {sorted(ALLOWED_RULE_TYPES)}")

        params = rule["parameters"]
        if not isinstance(params, dict):
            _fail(f"Rule[{idx}] 'parameters' must be an object")

        # Optional 'value' validation (only required for some types)
        if rtype == "salary_floor":
            if "value" not in rule:
                _fail(f"Rule[{idx}] salary_floor must include numeric 'value'")
            if not isinstance(rule["value"], (int, float)):
                _fail(f"Rule[{idx}] salary_floor 'value' must be numeric")

    print("✅ PRB rules validation passed")

def main() -> None:
    here = Path(__file__).resolve().parent
    rules_path = here / "prb_2026.json"
    doc = _load_json(rules_path)
    validate_prb_rules(doc)

if __name__ == "__main__":
    main()
