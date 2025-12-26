import numpy as np

def ema(arr, period):
    k = 2/(period+1)
    ema_val, prev = [], None
    for x in arr:
        prev = x if prev is None else (x - prev)*k + prev
        ema_val.append(prev)
    return np.array(ema_val)

def atr(high, low, close, period=14):
    trs = []
    for i in range(len(high)):
        if i == 0:
            trs.append(high[i] - low[i])
        else:
            pc = close[i-1]
            trs.append(max(high[i]-low[i], abs(high[i]-pc), abs(low[i]-pc)))
    alpha = 1/period
    vals, prev = [], None
    for tr in trs:
        prev = tr if prev is None else (1-alpha)*prev + alpha*tr
        vals.append(prev)
    return np.array(vals)

def detect_breakout_pullback(candles, min_break=8, pull_min=0.38, pull_max=0.62, use_vwap=True):
    closes = np.array([c["close"] for c in candles])
    highs  = np.array([c["high"] for c in candles])
    lows   = np.array([c["low"]  for c in candles])
    vols   = np.array([c.get("volume",1.0) for c in candles])

    e20 = ema(closes, 20); e50 = ema(closes, 50)
    trend_up = e20[-1] > e50[-1]
    trend_dn = e20[-1] < e50[-1]

    N=30
    r_high, r_low = highs[-N:].max(), lows[-N:].min()
    broke_up   = closes[-2] <= r_high and closes[-1] > r_high * (1 + min_break*0.00001)
    broke_down = closes[-2] >= r_low  and closes[-1] < r_low  * (1 - min_break*0.00001)

    def retraced_ok(direction):
        leg = (closes[-1]-r_high) if direction=="up" else (r_low - closes[-1])
        if leg == 0: 
            return False
        pb = abs((closes[-1]-closes[-2]) / (leg if leg!=0 else 1))
        return pull_min <= pb <= pull_max

    if use_vwap:
        pv = np.cumsum(closes*vols)/np.cumsum(vols)
        vwap_reclaim_up   = closes[-2] < pv[-2] and closes[-1] > pv[-1]
        vwap_reclaim_down = closes[-2] > pv[-2] and closes[-1] < pv[-1]
    else:
        vwap_reclaim_up = vwap_reclaim_down = True

    long_ok  = trend_up and broke_up   and retraced_ok("up")   and vwap_reclaim_up
    short_ok = trend_dn and broke_down and retraced_ok("down") and vwap_reclaim_down

    return {"long": long_ok, "short": short_ok, "range_high": r_high, "range_low": r_low, "ema20": e20[-1], "ema50": e50[-1]}

def plan_trade(side, entry, invalidation, atr_val, rr_primary=2.0, atr_mult=1.1):
    stop = invalidation - atr_mult*atr_val if side=="long" else invalidation + atr_mult*atr_val
    risk_per_unit = abs(entry - stop)
    tp1 = entry + (risk_per_unit) if side=="long" else entry - (risk_per_unit)
    tp2 = entry + rr_primary*(risk_per_unit) if side=="long" else entry - rr_primary*(risk_per_unit)
    return {"entry": entry, "stop": stop, "tp1": tp1, "tp2": tp2}
