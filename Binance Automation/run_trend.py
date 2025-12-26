import os, sys, time, hmac, hashlib, requests, argparse, urllib.parse as up

def env_get(k, default=None):
    v = os.environ.get(k)
    return v if v is not None else default

BASE = env_get("BASE", env_get("BINANCE_BASE_URL", "https://api.binance.com"))
API_KEY = env_get("BINANCE_API_KEY") or env_get("KEY")
API_SECRET = env_get("BINANCE_API_SECRET") or env_get("SECRET")
LIVE = (env_get("LIVE","false").lower() in ("true","1","yes"))

session = requests.Session()
session.headers.update({"X-MBX-APIKEY": API_KEY} if API_KEY else {})

def now_ms():
    return int(time.time()*1000)

def sign(params:dict)->str:
    q = up.urlencode(params, doseq=True)
    sig = hmac.new(API_SECRET.encode(), q.encode(), hashlib.sha256).hexdigest()
    return q + "&signature=" + sig

def api_get(path, params=None, auth=False):
    url = f"{BASE}{path}"
    if auth:
        if not API_KEY or not API_SECRET:
            raise SystemExit("Missing API creds")
        params = params or {}
        params.update({"timestamp": now_ms(), "recvWindow": 5000})
        q = sign(params)
        url = url + "?" + q
        r = session.get(url, timeout=15)
    else:
        r = session.get(url, params=params, timeout=15)
    r.raise_for_status()
    return r.json()

def api_post(path, params=None):
    if not API_KEY or not API_SECRET:
        raise SystemExit("Missing API creds")
    url = f"{BASE}{path}"
    params = params or {}
    params.update({"timestamp": now_ms(), "recvWindow": 5000})
    q = sign(params)
    r = session.post(url, data=q, timeout=15, headers={"Content-Type":"application/x-www-form-urlencoded"})
    r.raise_for_status()
    return r.json()

def get_price(symbol:str)->float:
    j = api_get("/api/v3/ticker/price", {"symbol": symbol})
    return float(j["price"])

def market_buy_quote(symbol:str, quote_usdt:float):
    params = {
        "symbol": symbol,
        "side": "BUY",
        "type": "MARKET",
        "quoteOrderQty": f"{quote_usdt:.2f}",
        "newOrderRespType": "ACK"
    }
    return api_post("/api/v3/order", params)

def run_once(symbols, interval, quote_per_buy, cooldown_sec):
    for sym in symbols:
        px = get_price(sym)
        print(f"[{sym}] px={px:.6f} quote={quote_per_buy}")
        if LIVE:
            try:
                resp = market_buy_quote(sym, quote_per_buy)
                print(f"[{sym}] BUY OK: {resp}")
            except requests.HTTPError as e:
                print(f"[{sym}] BUY ERR: {e.response.text}")
        else:
            print(f"[{sym}] DRY-RUN (LIVE=false). Would BUY market for quote {quote_per_buy}.")
        time.sleep(1)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--symbols", default="BTCUSDT,ETHUSDT")
    ap.add_argument("--interval", default="15m")
    ap.add_argument("--quote-per-buy", type=float, default=25.0)
    ap.add_argument("--cooldown-sec", type=int, default=10)
    ap.add_argument("--once", action="store_true")
    args = ap.parse_args()

    symbols = [s.strip().upper() for s in args.symbols.split(",") if s.strip()]
    print(f"BASE={BASE} LIVE={LIVE} symbols={symbols} interval={args.interval} quote={args.quote_per_buy}")

    if args.once:
        run_once(symbols, args.interval, args.quote_per_buy, args.cooldown_sec)
        return

    while True:
        run_once(symbols, args.interval, args.quote_per_buy, args.cooldown_sec)
        time.sleep(args.cooldown_sec)

if __name__ == "__main__":
    if not API_KEY or not API_SECRET:
        sys.exit("No BINANCE_API_KEY/SECRET in env. Aborting.")
    # sanity ping
    try:
        api_get("/api/v3/time")
    except Exception as e:
        sys.exit(f"Exchange ping failed: {e}")
    main()
