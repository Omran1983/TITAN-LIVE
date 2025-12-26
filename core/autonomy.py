import json
import sys
from pathlib import Path
from enum import Enum, auto

class AutonomyLevel(Enum):
    L0_PASSIVE = 0
    L1_ADVISOR = 1
    L2_HUMAN_CONFIRM = 2
    L3_BOUNDED = 3
    L4_AUTONOMOUS = 4

class AutonomyGate:
    def __init__(self):
        self.root = Path(__file__).resolve().parent.parent
        self.config_path = self.root / "core" / "autonomy_config.json"
        self._load_config()

    def _load_config(self):
        if not self.config_path.exists():
            # Default to safely restrictive
            self.global_level = AutonomyLevel.L0_PASSIVE
            return

        try:
            data = json.loads(self.config_path.read_text())
            level_str = data.get("global_level", "L0_PASSIVE")
            self.global_level = AutonomyLevel[level_str]
        except Exception as e:
            print(f"⚠️ Autonomy Config Error: {e}. Defaulting to L0.")
            self.global_level = AutonomyLevel.L0_PASSIVE

    def check_permission(self, required_level: AutonomyLevel, action_name: str) -> bool:
        """
        Checks if the requested action's required level is permitted by the global setting.
        Logic: If Global Level < Required Level, DENY.
        """
        if self.global_level.value < required_level.value:
            print(f"⛔ AUTONOMY GATE DENIED: '{action_name}' requires {required_level.name}, System is {self.global_level.name}")
            return False
        
        print(f"✅ Autonomy Check Passed: '{action_name}' ({required_level.name}) <= System ({self.global_level.name})")
        return True

    def enforce(self, required_level: AutonomyLevel, action_name: str):
        """
        Hard enforcement. Exits if denied.
        """
        if not self.check_permission(required_level, action_name):
            sys.exit(13) # Custom Exit Code for Autonomy Violation

# Singleton Access
gate = AutonomyGate()
