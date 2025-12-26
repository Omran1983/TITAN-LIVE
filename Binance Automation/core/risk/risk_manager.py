from dataclasses import dataclass
from datetime import time as dtime

@dataclass
class RiskState:
    trades_today: int = 0
    daily_pl_pct: float = 0.0
    weekly_drawdown_pct: float = 0.0

def in_allowed_session(now_utc, windows):
    t = now_utc.time()
    for w in windows:
        s = dtime.fromisoformat(w["start"]); e = dtime.fromisoformat(w["end"])
        if s <= t <= e: 
            return True
    return False

def can_trade_today(state: RiskState, cfg: dict, now_utc):
    if cfg["sessions"]["enable_session_filter"] and not in_allowed_session(now_utc, cfg["sessions"]["allowed_sessions_utc"]):
        return False, "Out of session"
    if state.trades_today >= cfg["risk"]["max_trades_per_day"]:
        return False, "Daily trade cap hit"
    if state.daily_pl_pct <= -cfg["risk"]["max_daily_loss_pct"]:
        return False, "Daily loss limit hit"
    if state.weekly_drawdown_pct <= -cfg["risk"]["max_weekly_drawdown_pct"]:
        return False, "Weekly drawdown limit hit"
    return True, ""

def position_size(account_balance, entry, stop, instrument, risk_pct):
    # Simplified: crypto tick assumed in price units; adapt to your venue as needed.
    if stop == entry:
        return 0.0
    risk_cash = account_balance * risk_pct
    risk_per_unit = abs(entry - stop)
    qty = risk_cash / risk_per_unit
    return max(0.0, qty)
