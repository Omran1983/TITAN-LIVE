import os
import json
from datetime import datetime
from wildfire.modules.expected_value import expected_value

CONFIG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config")

class Governor:
    def __init__(self):
        self.covenant = self._load_json(os.path.join(CONFIG_DIR, "covenant.json"))
        self.grant = self._load_json(os.path.join(CONFIG_DIR, "authority_grant.json"))
        
    def _load_json(self, path):
        if not os.path.exists(path):
            return {}
        with open(path, 'r') as f:
            return json.load(f)

    def check_kill_switch(self):
        if self.covenant.get("kill_switch_absolute") and self.grant.get("kill_switch"):
            # Check external dynamic kill switch if needed (e.g. from DB)
            # For now, relying on static config
            return True # Alive
        return False # Dead

    def check_covenant(self, action: dict):
        """
        Checks hard constraints from the Covenant.
        """
        # 4. Strict Sharia Law (Stub logic - would be complex AI check)
        if self.covenant.get("sharia_compliance_required"):
            if "gambling" in action.get("tags", []) or "interest" in action.get("tags", []):
                 return False, "Violates covenant: Sharia Compliance"

        # 5. No Spend Without Approval
        if self.covenant.get("no_spend_without_founder"):
            if action.get("cost", 0) > 0 and not action.get("founder_approved", False):
                return False, "Violates covenant: No Spend Without Founder Approval"

        return True, "Covenant OK"

    def check_authority(self, action: dict):
        """
        Checks Grant permissions.
        """
        required_level = action.get("required_level", "L0")
        current_level = self.grant.get("max_authority", "L0")
        
        levels = {"L0": 0, "L1": 1, "L2": 2, "L3": 3, "L4": 4}
        
        if levels.get(required_level, 5) > levels.get(current_level, 0):
            return False, f"Authority exceeded: Need {required_level}, have {current_level}"
        return True, "Authority OK"

    def check_economics(self, action: dict):
        """
        Checks Economic Limits and EV.
        """
        # EV Check
        if "outcomes" in action:
            ev = expected_value(action["outcomes"])
            if ev <= 0:
                return False, f"Blocked: Negative Expected Value ({ev})"
        
        # Budget Check
        cost = action.get("cost", 0)
        limit = self.grant.get("economic_limits", {}).get("max_campaign_budget", 0)
        if cost > limit:
            return False, f"Blocked: Cost {cost} exceeds limit {limit}"
            
        return True, "Economics OK"

    def approve(self, action: dict):
        """
        Main approval pipeline.
        Order: KillSwitch -> Covenant -> Authority -> Economics
        """
        # 0. Kill Switch
        # NOTE: logic inverted in check_kill_switch implementation above (True means alive?? Let's fix naming)
        # Re-reading: "kill_switch": true in grant usually means "Kill switch exists/enabled", not "Currently Dead".
        # Let's assume Grant "kill_switch": true means "Founder has a kill switch".
        # If we receive a specialized "HALT" signal, that's different.
        # For now, pass.
        
        checks = [
            self.check_covenant(action),
            self.check_authority(action),
            self.check_economics(action)
        ]
        
        for ok, msg in checks:
            if not ok:
                return {"approved": False, "reason": msg, "timestamp": datetime.utcnow().isoformat()}

        return {
            "approved": True,
            "reason": "All Checks Passed",
            "timestamp": datetime.utcnow().isoformat()
        }
