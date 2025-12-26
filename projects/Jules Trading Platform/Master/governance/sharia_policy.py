from datetime import datetime
from logging_config import log

class ShariaPolicy:
    """
    Enforces Sharia Compliance Rules.
    Only allows trading tokens that are explicitly WHITELISTED.
    """
    def __init__(self):
        self.whitelist = {
            "BTCUSDT": {"status": "ALLOWED", "reason": "Digital Gold. Store of Value."},
            "ETHUSDT": {"status": "ALLOWED", "reason": "Utility Token (Gas)."},
            "SOLUSDT": {"status": "ALLOWED", "reason": "Utility Token."},
            "PAXGUSDT": {"status": "ALLOWED", "reason": "Asset-Backed (Gold)."},
            "USDCUSDT": {"status": "ALLOWED", "reason": "Stablecoin (Backed)."},
            # "DOGEUSDT": {"status": "BLOCKED", "reason": "No utility. Speculative gambling."},
        }

    def validate_trade(self, symbol: str) -> bool:
        """
        Checks if the symbol is Halal to trade.
        """
        policy = self.whitelist.get(symbol)
        
        if not policy:
            log.warning(f"SHARIA BIOCK: {symbol} is not on the whitelist.")
            return False
            
        if policy['status'] != "ALLOWED":
            log.warning(f"SHARIA BLOCK: {symbol} is {policy['status']} because: {policy['reason']}")
            return False
            
        return True

    def get_whitelist(self):
        return self.whitelist
