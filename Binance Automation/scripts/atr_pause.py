import csv, math
from collections import deque
path = 'klines_BTCUSDT_1m.csv'
atr_n = 14
qs = deque(maxlen=atr_n)
atr=None; prev_close=None
with open(path) as f:
    rdr = csv.DictReader(f)
    for r in rdr:
        o=float(r['open']); h=float(r['high']); l=float(r['low']); c=float(r['close'])
        tr = max(h-l, abs(h-(prev_close if prev_close is not None else o)), abs(l-(prev_close if prev_close is not None else o)))
        qs.append(tr)
        if len(qs)==atr_n: atr = sum(qs)/atr_n
        prev_close=c
print({"atr": atr, "last_close": prev_close, "atr_pct": (atr/prev_close*100 if atr and prev_close else None)})
