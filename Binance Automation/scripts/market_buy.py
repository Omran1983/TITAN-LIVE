import os, time, hmac, hashlib, json, argparse, math, urllib.parse as up
from decimal import Decimal, ROUND_DOWN, getcontext
import requests
from scripts.env_loader import load_env

load_env()
getcontext().prec = 28  # high precision for Decimal math

def _env(k, d=""):
    v = os.getenv(k)
    return v if v not in (None, "") else d

BASE = _env("BINANCE_BASE_URL", "https://api.binance.com")
KEY  = _env("BINANCE_API_KEY")
SEC  = _env("BINANCE_API_SECRET")

def _sign(params: dict) -> str:
    qs = up.urlencode(params, doseq=True)
    sig = hmac.new(SEC.encode(), qs.encode(), hashlib.sha256).hexdigest()
    return f"{qs}&signature={sig}"

def _req(method: str, path: str, params: dict | None = None, signed: bool = False):
    params = params or {}
    headers = {}
    if signed:
        url = f"{BASE}{path}?{_sign(params)}"
        headers = {"X-MBX-APIKEY": KEY}
    else:
        qs = f"?{up.urlencode(params, doseq=True)}" if params else ""
        url = f"{BASE}{path}{qs}"
    r = requests.request(method, url, headers=headers, timeout=20)
    if r.status_code >= 400:
        try:
            payload = r.json()
        except Exception:
            payload = {"raw": r.text}
        raise requests.HTTPError(f"{r.status_code} {path} → {payload}", response=r)
    return r

def _exchange_info_symbol(symbol: str) -> dict:
    data = _req("GET", "/api/v3/exchangeInfo").json()
    for s in data.get("symbols", []):
        if s.get("symbol") == symbol:
            return s
    raise ValueError(f"Symbol {symbol} not found")

def _book_ticker(symbol: str) -> tuple[float, float]:
    j = _req("GET", "/api/v3/ticker/bookTicker", params={"symbol": symbol}).json()
    return float(j["bidPrice"]), float(j["askPrice"])

def _dec_no_sci(d: Decimal) -> str:
    s = format(d, "f")  # no scientific notation
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    return s if s else "0"

def _quantize_qty(sym_info: dict, qty: float) -> Decimal:
    lot = next((f for f in sym_info.get("filters", []) if f.get("filterType") == "LOT_SIZE"), None)
    if not lot:
        return Decimal(str(qty))
    step = Decimal(str(lot["stepSize"]))
    minq = Decimal(str(lot["minQty"]))
    maxq = Decimal(str(lot["maxQty"]))
    q = Decimal(str(qty))
    if q < minq:
        q = minq
    if q > maxq:
        q = maxq
    # floor to step
    q = (q // step) * step
    return q

def _min_notional_ok(sym_info: dict, notional: Decimal) -> bool:
    filt = next((f for f in sym_info.get("filters", []) if f.get("filterType") in ("NOTIONAL", "MIN_NOTIONAL")), None)
    if not filt:
        return True
    mn = Decimal(str(filt.get("minNotional") or "0"))
    return notional >= mn

def place_market_order(symbol: str, side: str, qty: float | None = None, quote_qty: float | None = None,
                       recv_window: int = 15000, test: bool = False):
    if not KEY or not SEC:
        raise RuntimeError("Missing BINANCE_API_KEY / BINANCE_API_SECRET")

    symbol = symbol.upper()
    side = side.upper()
    endpoint = "/api/v3/order/test" if test else "/api/v3/order"

    # Fetch symbol info up-front (for filters/formatting)
    s_info = _exchange_info_symbol(symbol)

    # SELL with quoteQty → convert to qty using bid, quantize, and format as decimal string
    qty_str = None
    quote_str = None

    if side == "SELL" and quote_qty is not None:
        bid, _ = _book_ticker(symbol)
        est_qty = Decimal(str(quote_qty)) / Decimal(str(bid))
        q = _quantize_qty(s_info, float(est_qty))
        notional = q * Decimal(str(bid))
        if q <= 0 or not _min_notional_ok(s_info, notional):
            raise RuntimeError("SELL notional too low after quantization. Increase amount.")
        qty_str = _dec_no_sci(q)
    elif qty is not None:
        q = _quantize_qty(s_info, float(qty))
        if q <= 0:
            raise RuntimeError("Quantity becomes zero after quantization; increase amount.")
        qty_str = _dec_no_sci(q)
    elif quote_qty is not None:
        # BUY by quote (or SELL if allowed above) — format quote as plain decimal too
        quote_str = _dec_no_sci(Decimal(str(quote_qty)))
    else:
        raise ValueError("Provide either qty or quoteQty")

    params = {
        "symbol": symbol,
        "side": side,
        "type": "MARKET",
        "timestamp": int(time.time() * 1000),
        "recvWindow": recv_window,
        "newOrderRespType": "FULL",
    }
    if qty_str is not None:
        params["quantity"] = qty_str
    if quote_str is not None:
        params["quoteOrderQty"] = quote_str

    url = f"{BASE}{endpoint}?{_sign(params)}"
    r = requests.post(url, headers={"X-MBX-APIKEY": KEY}, timeout=20)

    if test:
        print(f"TEST order response: {r.status_code} {r.text}")
        return None

    try:
        r.raise_for_status()
    except requests.HTTPError as e:
        try:
            print("Error payload:", r.json())
        except Exception:
            print("Error body:", r.text)
        raise

    data = r.json()
    print("Order response:")
    print(json.dumps(data, indent=2))

    # Log to Excel + CSV
    try:
        from scripts.excel_logger import log_order_fill
        xlsx_path = log_order_fill(data, env=_env("ENV_FILE", ".env.mainnet"))
        print(f"Logged to: {xlsx_path}")
    except Exception as log_err:
        print(f"Logging failed: {log_err}")

    return data

def main():
    ap = argparse.ArgumentParser(description="MARKET order: BUY supports quoteQty; SELL supports qty or quoteQty (auto-converted).")
    ap.add_argument("--symbol", required=True)
    ap.add_argument("--side", default="BUY", choices=["BUY", "SELL"])
    ap.add_argument("--qty", type=float)
    ap.add_argument("--quoteQty", type=float)
    ap.add_argument("--recvWindow", type=int, default=15000)
    ap.add_argument("--test", action="store_true")
    args = ap.parse_args()

    place_market_order(args.symbol, args.side, qty=args.qty, quote_qty=args.quoteQty,
                       recv_window=args.recvWindow, test=args.test)

if __name__ == "__main__":
    main()
