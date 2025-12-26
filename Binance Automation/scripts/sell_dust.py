import os, time, math, argparse, hmac, hashlib
import urllib.parse as up
from pathlib import Path

import requests
from scripts.env_loader import load_env
from scripts.excel_logger import log_order_fill

STABLES = {"USDT","BUSD","FDUSD","TUSD","USDC"}

TIME_OFFSET_MS = 0

def _env(k, d=""):
    v = os.getenv(k)
    return v if v not in (None,"") else d

def _base(): return _env("BINANCE_BASE_URL","https://api.binance.com")
def _key():  return _env("BINANCE_API_KEY")
def _sec():  return _env("BINANCE_API_SECRET")

def _server_time():
    r = requests.get(f"{_base()}/api/v3/time", timeout=10)
    r.raise_for_status()
    return int(r.json()["serverTime"])

def _sync_time():
    global TIME_OFFSET_MS
    try:
        st = _server_time()
        lt = int(time.time()*1000)
        TIME_OFFSET_MS = st - lt
    except Exception:
        pass

def _ts(): return int(time.time()*1000 + TIME_OFFSET_MS)

def _sign(params: dict, secret: str) -> str:
    qs = up.urlencode(params, doseq=True)
    sig = hmac.new(secret.encode(), qs.encode(), hashlib.sha256).hexdigest()
    return f"{qs}&signature={sig}"

def _req(method: str, path: str, params: dict = None, signed: bool = False):
    if signed:
        p = dict(params or {})
        p.setdefault("timestamp", _ts())
        p.setdefault("recvWindow", 15000)
        url = f"{_base()}{path}?{_sign(p, _sec())}"
        headers = {"X-MBX-APIKEY": _key()}
    else:
        url = f"{_base()}{path}"
        headers = {}
    r = requests.request(method, url, headers=headers, timeout=30)
    r.raise_for_status()
    return r

def exchange_info():
    return _req("GET","/api/v3/exchangeInfo").json()

def acct():
    return _req("GET","/api/v3/account", signed=True).json()

def ticker_price(symbol: str) -> float | None:
    r = _req("GET","/api/v3/ticker/price", params={"symbol": symbol})
    try:
        return float(r.json()["price"])
    except Exception:
        return None

def qty_quantize(sym_info: dict, qty: float) -> float:
    lot = next((f for f in sym_info.get("filters",[]) if f.get("filterType")=="LOT_SIZE"), None)
    if not lot:
        return float(f"{qty:.8f}")
    step = float(lot["stepSize"])
    minq = float(lot["minQty"])
    maxq = float(lot["maxQty"])
    q = max(minq, min(qty, maxq))
    q = math.floor(q / step) * step
    return float(f"{q:.8f}")

def min_notional_pass(sym_info: dict, notional: float) -> bool:
    filt = next((f for f in sym_info.get("filters",[]) if f.get("filterType") in ("NOTIONAL","MIN_NOTIONAL")), None)
    if not filt:
        return True
    mn = float(filt.get("minNotional") or 0)
    return notional >= mn

def place_market_sell(symbol: str, quantity: float, test: bool):
    endpoint = "/api/v3/order/test" if test else "/api/v3/order"
    params = {"symbol": symbol, "side":"SELL", "type":"MARKET",
              "quantity": quantity, "timestamp": _ts(), "recvWindow": 15000,
              "newOrderRespType": "FULL"}
    r = requests.post(f"{_base()}{endpoint}?{_sign(params,_sec())}",
                      headers={"X-MBX-APIKEY": _key()}, timeout=20)
    r.raise_for_status()
    return r.json() if not test else {}

def main():
    load_env()
    _sync_time()
    ap = argparse.ArgumentParser(description="Sell small balances to USDT (dust cleaner).")
    ap.add_argument("--min-usdt", type=float, default=5.0, help="Only sell balances worth at least this USDT.")
    ap.add_argument("--keep-bnb", type=float, default=0.02, help="Retain this BNB for fee discounts.")
    ap.add_argument("--include", default="", help="Comma-separated assets to include even if stable/excluded.")
    ap.add_argument("--exclude", default="", help="Comma-separated assets to skip.")
    ap.add_argument("--live", action="store_true", help="Execute real sells. Omit for dry-run (/order/test).")
    args = ap.parse_args()

    inc = {a.strip().upper() for a in args.include.split(",") if a.strip()}
    exc = {a.strip().upper() for a in args.exclude.split(",") if a.strip()}

    info = exchange_info()
    symmap = {s["symbol"]: s for s in info.get("symbols", []) if s.get("status")=="TRADING"}
    balances = acct().get("balances", [])

    plan = []
    for b in balances:
        asset = b["asset"].upper()
        free = float(b.get("free") or 0)
        if free <= 0: 
            continue
        if asset in STABLES and asset not in inc: 
            continue
        if asset in exc and asset not in inc:
            continue
        if asset == "BNB":
            free = max(0.0, free - args.keep_bnb)
            if free <= 0: 
                continue
        symbol = f"{asset}USDT"
        s_info = symmap.get(symbol)
        if not s_info:
            continue  # no USDT market for this asset
        price = ticker_price(symbol)
        if not price or price <= 0:
            continue
        qty = qty_quantize(s_info, free)
        notional = qty * price
        if notional < args.min_usdt:
            continue
        if not min_notional_pass(s_info, notional):
            continue
        plan.append((symbol, qty, notional))

    total = sum(n for _,_,n in plan)
    print("---- Dust Sell Plan ----")
    for sym, q, n in plan:
        print(f"{sym}  qty={q}  estUSDT={round(n,6)}")
    print(f"Total est USDT: {round(total,2)}")
    if not plan:
        print("Nothing to sell that meets filters/thresholds.")
        return

    for sym, q, n in plan:
        try:
            resp = place_market_sell(sym, q, test=(not args.live))
            if args.live:
                try:
                    log_order_fill(resp, env=os.getenv("ENV_FILE",".env.mainnet"))
                except Exception:
                    pass
            print(f"{sym}: {'PLACED' if args.live else 'DRYRUN_OK'}  qty={q}")
            time.sleep(0.12)
        except requests.HTTPError as e:
            print(f"{sym}: ERROR {e}")

if __name__ == "__main__":
    main()
