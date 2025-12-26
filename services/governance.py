import os
import json
import time
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Optional, Dict, Any
from pathlib import Path

# --- Registry: define what exists, what risk it is, and what authority is required ---
ACTION_REGISTRY: Dict[str, Dict[str, Any]] = {
    # Safe info ops
    "titan:health": {"risk": "L0", "authority": "L0", "audit": True, "cooldown": 0},
    "titan:website_review": {"risk": "L1", "authority": "L1", "audit": True, "cooldown": 2},

    # Medium/High risk ops examples (wire later)
    "titan:restart_n8n": {"risk": "L4", "authority": "L3", "audit": True, "cooldown": 300},
    "ollama:pull": {"risk": "L2", "authority": "L1", "audit": True, "cooldown": 60},

    # Emergency
    "admin:set_killswitch": {"risk": "L4", "authority": "L4", "audit": True, "cooldown": 0},
    "admin:reset_killswitch": {"risk": "L4", "authority": "L4", "audit": True, "cooldown": 0},
}

AUTH_RANK = {"L0": 0, "L1": 1, "L2": 2, "L3": 3, "L4": 4}

class Governance:
    def __init__(self, db_url: str, killswitch_path: str, token_authority: Dict[str, str]):
        self.db_url = db_url
        self.killswitch_path = Path(killswitch_path)
        self.token_authority = token_authority
        self._cooldowns: Dict[str, float] = {}

    def db(self):
        return psycopg2.connect(self.db_url, cursor_factory=RealDictCursor)

    def authority_from_token(self, token: str) -> str:
        if not token:
            return "L0"
        return self.token_authority.get(token, "L0")

    def killswitch_active(self) -> bool:
        return self.killswitch_path.exists()

    def set_killswitch(self, active: bool) -> None:
        if active:
            self.killswitch_path.parent.mkdir(parents=True, exist_ok=True)
            self.killswitch_path.write_text("ON", encoding="utf-8")
        else:
            if self.killswitch_path.exists():
                self.killswitch_path.unlink()

    def require_action(self, action_key: str) -> Dict[str, Any]:
        if action_key not in ACTION_REGISTRY:
            raise ValueError(f"Unknown action_key: {action_key}")
        return ACTION_REGISTRY[action_key]

    def check_cooldown(self, action_key: str) -> bool:
        cd = ACTION_REGISTRY[action_key].get("cooldown", 0)
        if cd <= 0:
            return True
        last = self._cooldowns.get(action_key, 0)
        return (time.time() - last) >= cd

    def bump_cooldown(self, action_key: str) -> None:
        self._cooldowns[action_key] = time.time()

    def create_intent(self, agent_name: str, ui_intent: str, proposed_action: str,
                      confidence: float, risk_level: str, explanation: str,
                      decision_metadata: Optional[dict] = None) -> str:
        decision_metadata = decision_metadata or {}
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    insert into az_intents(agent_name, ui_intent, proposed_action, confidence, risk_level, explanation, decision_metadata)
                    values (%s,%s,%s,%s,%s,%s,%s)
                    returning id
                    """,
                    (agent_name, ui_intent, proposed_action, confidence, risk_level, explanation, json.dumps(decision_metadata)),
                )
                row = cur.fetchone()
                conn.commit()
                return str(row["id"])

    def approve_intent(self, intent_id: str, approver: str) -> None:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    update az_intents
                    set status='APPROVED',
                        decision_metadata = coalesce(decision_metadata,'{}'::jsonb) || jsonb_build_object('approved_by', %s, 'approved_at', now())
                    where id=%s
                    """,
                    (approver, intent_id),
                )
                conn.commit()

    def mark_intent_executed(self, intent_id: str) -> None:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute("update az_intents set status='EXECUTED' where id=%s", (intent_id,))
                conn.commit()

    def get_intent(self, intent_id: str) -> Optional[dict]:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute("select * from az_intents where id=%s", (intent_id,))
                row = cur.fetchone()
                return dict(row) if row else None

    def audit(self, actor: str, actor_id: str, action_key: str, intent_id: Optional[str],
              risk_level: str, authority_required: str, authority_used: str,
              ok: bool, request: dict, result: dict, error: Optional[str] = None) -> None:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    insert into az_audit_log(actor, actor_id, action_key, intent_id, risk_level, authority_required, authority_used,
                                             ok, request, result, error)
                    values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    """,
                    (
                        actor, actor_id, action_key, intent_id,
                        risk_level, authority_required, authority_used,
                        ok, json.dumps(request or {}), json.dumps(result or {}), error
                    ),
                )
                conn.commit()

    def validate(self, action_key: str, token: str, intent_id: Optional[str]) -> Dict[str, Any]:
        spec = self.require_action(action_key)
        risk = spec["risk"]
        required = spec["authority"]
        used = self.authority_from_token(token)

        # Kill-switch blocks everything except reset
        if self.killswitch_active() and action_key != "admin:reset_killswitch":
            return {"ok": False, "reason": "KILLSWITCH_ACTIVE", "risk": risk, "required": required, "used": used}

        if AUTH_RANK[used] < AUTH_RANK[required]:
            return {"ok": False, "reason": "INSUFFICIENT_AUTHORITY", "risk": risk, "required": required, "used": used}

        if not self.check_cooldown(action_key):
            return {"ok": False, "reason": "COOLDOWN_ACTIVE", "risk": risk, "required": required, "used": used}

        # Intents required for anything above L1 (customize to taste)
        if AUTH_RANK[risk] >= AUTH_RANK["L2"]:
            if not intent_id:
                return {"ok": False, "reason": "INTENT_REQUIRED", "risk": risk, "required": required, "used": used}
            intent = self.get_intent(intent_id)
            if not intent:
                return {"ok": False, "reason": "INTENT_NOT_FOUND", "risk": risk, "required": required, "used": used}
            if intent.get("status") != "APPROVED":
                return {"ok": False, "reason": f"INTENT_NOT_APPROVED({intent.get('status')})", "risk": risk, "required": required, "used": used}
            # Optionally: intent proposed_action must match
            if intent.get("proposed_action") != action_key:
                return {"ok": False, "reason": "INTENT_ACTION_MISMATCH", "risk": risk, "required": required, "used": used}

        return {"ok": True, "reason": "OK", "risk": risk, "required": required, "used": used}
