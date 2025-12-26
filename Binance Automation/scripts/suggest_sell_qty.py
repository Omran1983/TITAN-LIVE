import os, argparse, math
import requests
from scripts.env_loader import load_env

load_env()

def _env(k,d=""): v=os.getenv(k); return v if v not in (None,"") else d
BASE=_env("BINANCE_BASE_URL","https://api.binance.com")
KEY =_env("BINANCE_API_KEY")
SEC =_env("BINANCE_API_SECRET")

def exchange_info(symbol):
    j=requests.get(f"{BASE}/api/v3/exchangeInfo", timeout=15).json()
    for s in j["symbols"]:
        if s["symbol"]==symbol: return s
    raise SystemExit("symbol not found")

def book(symbol):
    j=requests.get(f"{BASE}/api/v3/ticker/bookTicker", params={"symbol":symbol}, timeout=10).json()
    return float(j["bidPrice"]), float(j["askPrice"])

def account_free(asset):
    import time, hmac, hashlib, urllib.parse as up
    ts=int(time.time()*1000)
    qs=up.urlencode({"timestamp":ts, "recvWindow":15000})
    sig=hmac.new(SEC.encode(), qs.encode(), hashlib.sha256).hexdigest()
    url=f"{BASE}/api/v3/account?{qs}&signature={sig}"
    j=requests.get(url, headers={"X-MBX-APIKEY":KEY}, timeout=20).json()
    for b in j["balances"]:
        if b["asset"]==asset:
            return float(b["free"])
    return 0.0

def quantize(sym_info, qty):
    lot=next(f for f in sym_info["filters"] if f["filterType"]=="LOT_SIZE")
    step=float(lot["stepSize"]); minq=float(lot["minQty"]); maxq=float(lot["maxQty"])
    q=max(minq, min(qty, maxq))
    q=math.floor(q/step)*step
    return float(f"{q:.8f}")

def min_notional(sym_info, notional):
    f=next((x for x in sym_info["filters"] if x["filterType"] in ("NOTIONAL","MIN_NOTIONAL")), None)
    return True if not f else (notional >= float(f.get("minNotional", 0)))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--symbol", required=True, help="e.g., BTCUSDT")
    ap.add_argument("--target-usdt", type=float, default=11.0)
    ap.add_argument("--percent", type=float, default=None, help="sell % of free balance instead of target-usdt")
    args=ap.parse_args()

    sym=args.symbol.upper(); asset=sym.replace("USDT","")
    s_info=exchange_info(sym)
    bid,_=book(sym)
    free=account_free(asset)

    if args.percent is not None:
        est_qty=free * (args.percent/100.0)
    else:
        est_qty=min(free, args.target_usdt / bid)

    q=quantize(s_info, est_qty)
    notional=q*bid
    ok=min_notional(s_info, notional)

    print(f"Free {asset}: {free}")
    print(f"Bid: {bid}")
    print(f"Suggested qty: {q}  (~{round(notional,2)} USDT)  minNotionalOK={ok}")
    if not ok: print("Increase amount; current notional is below exchange minimum.")
    if q<=0: print('Qty is zero after quantization; increase amount or check balance.')

if __name__=="__main__":
    main()
