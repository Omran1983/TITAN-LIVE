from typing import Tuple
from infra.binance_client import spot
import statistics

def get_klines(symbol: str, interval: str = "1h", limit: int = 220):
    # [ openTime, open, high, low, close, volume, ... ]
    return spot.klines(symbol, interval, limit=limit)

def sma(values, n):
    if len(values) < n:
        return None
    return statistics.fmean(values[-n:])

def regime_score(symbol: str) -> Tuple[float, float, float]:
    """Return (score[0..100], sma50, sma200)."""
    ks = get_klines(symbol, "1h", 220)
    closes = [float(k[4]) for k in ks]
    sma50 = sma(closes, 50)
    sma200 = sma(closes, 200)
    if sma50 is None or sma200 is None:
        return (50.0, 0.0, 0.0)  # neutral if not enough data
    # Simple scoring:
    base = 50.0
    if sma50 > sma200:
        base += 20
    # Add small momentum tilt: recent close vs sma50
    if closes[-1] > sma50:
        base += 10
    # Clamp
    score = max(0.0, min(100.0, base))
    return (score, sma50, sma200)

def decide(symbol: str) -> dict:
    score, sma50, sma200 = regime_score(symbol)
    if score >= 65:
        action = "INVEST"
    elif score >= 40:
        action = "HOLD"
    else:
        action = "WITHDRAW"
    return {
        "symbol": symbol,
        "score": round(score, 1),
        "action": action,
        "sma50": round(sma50, 2),
        "sma200": round(sma200, 2),
    }
