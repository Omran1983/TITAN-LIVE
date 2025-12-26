import os, time, hmac, hashlib, argparse, json
import urllib.parse as up
import requests
from scripts.env_loader import load_env
from scripts.excel_logger import log_order_fill

def _env(k, d=""):
    v = os.getenv(k)
    return v if v not in (None, "") else d

def _sign(params: dict, secret: str) -> str:
    qs = up.urlencode(params, doseq=True)
    sig = hmac.new(secret.encode(), qs.encode(), hashlib.sha256).hexdigest()
    return f"{qs}&signature={sig}"

def fetch_order(symbol: str, order_id: int):
    base = _env("BINANCE_BASE_URL", "https://api.binance.com")
    key  = _env("BINANCE_API_KEY")
    sec  = _env("BINANCE_API_SECRET")
    if not key or not sec:
        raise RuntimeError("Missing BINANCE_API_KEY / BINANCE_API_SECRET")

    ts = int(time.time() * 1000)
    params = {"symbol": symbol.upper(), "orderId": order_id, "timestamp": ts, "recvWindow": 10000}
    url = f"{base}/api/v3/order?{_sign(params, sec)}"
    r = requests.get(url, headers={"X-MBX-APIKEY": key}, timeout=15)
    r.raise_for_status()
    return r.json()

def main():
    load_env()
    ap = argparse.ArgumentParser(description="Fetch a Binance order by ID and log it to Excel.")
    ap.add_argument("--symbol", required=True)
    ap.add_argument("--orderId", required=True, type=int)
    args = ap.parse_args()

    data = fetch_order(args.symbol, args.orderId)
    # Shape it closer to a place-order response for logger compatibility
    shaped = {
        "symbol": data.get("symbol"),
        "orderId": data.get("orderId"),
        "clientOrderId": data.get("clientOrderId"),
        "price": data.get("price"),
        "origQty": data.get("origQty"),
        "executedQty": data.get("executedQty"),
        "cummulativeQuoteQty": data.get("cummulativeQuoteQty"),
        "status": data.get("status"),
        "timeInForce": data.get("timeInForce"),
        "type": data.get("type"),
        "side": data.get("side"),
        # 'fills' not available via this endpoint; logger will fallback
    }
    print("Fetched order:")
    print(json.dumps(shaped, indent=2))

    path = log_order_fill(shaped, env=_env("ENV_FILE", ".env.mainnet"))
    print(f"Logged to: {path}")

if __name__ == "__main__":
    main()
