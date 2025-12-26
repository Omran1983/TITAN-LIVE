import os, time, hmac, hashlib, argparse, urllib.parse as up
from decimal import Decimal, getcontext
import requests
from scripts.env_loader import load_env

getcontext().prec = 28
STABLES = {"USDT","FDUSD","BUSD","TUSD","USDC"}

def d(x): return Decimal(str(x))

def _env(k, d=""):
    v = os.getenv(k)
    return v if v not in (None,"") else d

def _sign(params: dict, secret: str) -> str:
    qs = up.urlencode(params, doseq=True)
    sig = hmac.new(secret.encode(), qs.encode(), hashlib.sha256).hexdigest()
    return f"{qs}&signature={sig}"

def _normalize_asset(asset: str) -> tuple[str, str]:
    """Return (normalized_asset_for_pricing, note)."""
    a = asset.upper()
    if a.startswith("LD") and len(a) > 2:
        base = a[2:]
        return base, f"LD→{base}"
    return a, ""

def fetch_symbols(base):
    r = requests.get(f"{base}/api/v3/exchangeInfo", timeout=20); r.raise_for_status()
    return {s["symbol"] for s in r.json().get("symbols", []) if s.get("status")=="TRADING"}

def ticker_price(base, symbol):
    r = requests.get(f"{base}/api/v3/ticker/price", params={"symbol":symbol}, timeout=10)
    if not r.ok: return None
    try: return d(r.json()["price"])
    except: return None

def account_balances(base, key, sec):
    ts = int(time.time()*1000)
    qs = _sign({"timestamp": ts, "recvWindow": 15000}, sec)
    r = requests.get(f"{base}/api/v3/account?{qs}", headers={"X-MBX-APIKEY": key}, timeout=20)
    r.raise_for_status()
    out=[]
    for b in r.json().get("balances", []):
        qty = d(b.get("free") or 0) + d(b.get("locked") or 0)
        if qty > 0:
            out.append((b["asset"].upper(), qty))
    return out

def price_in_usdt(base, symbols, asset, cache):
    a = asset.upper()
    if a in STABLES: return d(1)
    # direct USDT
    sym = f"{a}USDT"
    if sym in symbols:
        if sym not in cache: cache[sym] = ticker_price(base, sym) or d(0)
        return cache[sym]
    # 2-hop via BTC/BNB/ETH
    for mid in ("BTC","BNB","ETH"):
        s1=f"{a}{mid}"; s2=f"{mid}USDT"
        if s1 in symbols and s2 in symbols:
            if s1 not in cache: cache[s1]=ticker_price(base, s1) or d(0)
            if s2 not in cache: cache[s2]=ticker_price(base, s2) or d(0)
            if cache[s1] and cache[s2]:
                return cache[s1]*cache[s2]
    return None

def main():
    load_env()
    base=_env("BINANCE_BASE_URL","https://api.binance.com")
    key=_env("BINANCE_API_KEY"); sec=_env("BINANCE_API_SECRET")

    ap=argparse.ArgumentParser(description="Equity in USDT and P&L vs cash-in.")
    ap.add_argument("--cash-in", type=float, required=True)
    args=ap.parse_args()
    cash_in = d(args.cash_in)

    symbols = fetch_symbols(base)
    bals = account_balances(base, key, sec)

    cache={}
    total=d(0); rows=[]; unknown=[]
    for asset, qty in bals:
        norm, note = _normalize_asset(asset)
        px = price_in_usdt(base, symbols, norm, cache)
        if px is None:
            unknown.append((asset, float(qty)))
            continue
        val = qty * px if norm not in STABLES else qty  # USDT-like stays qty
        rows.append((asset, norm, note, f"{qty:.8f}", f"{px:.8f}", f"{val:.8f}"))
        total += val

    print("=== Equity Now (USDT) ===")
    print(f"{'Asset':<10} {'PricedAs':<10} {'Note':<8} {'Qty':>16} {'PriceUSDT':>16} {'ValueUSDT':>16}")
    for a,na,n,q,p,v in rows:
        print(f"{a:<10} {na:<10} {n:<8} {q:>16} {p:>16} {v:>16}")
    print("-"*70)
    print(f"{'Total Equity':<24}: {total:.8f} USDT")
    print(f"{'Cash In (baseline)':<24}: {cash_in:.8f} USDT")
    pnl = total - cash_in
    ret = (pnl / cash_in * d(100)) if cash_in>0 else d(0)
    print(f"{'Net P&L':<24}: {pnl:.8f} USDT")
    print(f"{'Return %':<24}: {ret:.2f}%")

    if unknown:
        print("\n[Info] Unpriced assets (no USDT/BTC/BNB/ETH route):")
        for a,q in unknown:
            print(f"  - {a}: qty {q}")

if __name__=='__main__':
    main()
