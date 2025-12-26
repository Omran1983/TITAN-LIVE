import json
from datetime import datetime
from logging_config import log

class DecisionLogger:
    """
    The 'Black Box' Recorder.
    Logs the full context of every trade decision.
    """
    def __init__(self):
        self.filename = "live/decision_log.jsonl" # JSON Lines format

    def log_context(self, symbol: str, signal: str, sentiment: float, 
                    volatility_atr: float, risk_approved: bool, reason: str = ""):
        """
        Snapshots the state of the world at the moment of decision.
        """
        entry = {
            "timestamp": datetime.now().isoformat(),
            "symbol": symbol,
            "signal": signal,
            "context": {
                "sentiment_score": sentiment,
                "volatility_atr": volatility_atr if volatility_atr else 0.0,
                "market_regime": "TODO" # Can pass in if available
            },
            "risk_check": {
                "approved": risk_approved,
                "reason": reason
            }
        }
        
        try:
            with open(self.filename, 'a') as f:
                f.write(json.dumps(entry) + "\n")
        except Exception as e:
            log.error(f"Failed to write to Black Box: {e}")

    def log_sharia_block(self, symbol: str, reason: str):
         self.log_context(symbol, "SHARIA_BLOCK", 0, 0, False, reason)
