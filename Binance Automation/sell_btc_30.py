from binance.spot import Spot
import os, math, sys, pathlib

SYMBOL = "BTCUSDT"

def load_env_from_file():
    env_file = os.getenv("ENV_FILE", ".env.mainnet")
    p = pathlib.Path(env_file)
    if not p.exists():
        return
    for line in p.read_text(encoding="utf-8", errors="ignore").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        k = k.strip()
        v = v.strip().strip('"').strip("'")
        # Don't overwrite if already present
        if k and (k not in os.environ or not os.environ[k]):
            os.environ[k] = v

def get_filter(symbol_info, ftype):
    for f in symbol_info.get("filters", []):
        if f.get("filterType") == ftype:
            return f
    return {}

def floor_step(qty, step):
    if step is None or step == 0:
        return qty
    return math.floor(qty / step) * step

def main():
    load_env_from_file()

    key = os.getenv("BINANCE_API_KEY")
    sec = os.getenv("BINANCE_API_SECRET")
    if not key or not sec:
        print("ERROR: API keys missing (BINANCE_API_KEY/SECRET)."); sys.exit(1)

    c = Spot(api_key=key, api_secret=sec)

    # Free BTC
    acct = c.account()
    free_btc = 0.0
    for b in acct["balances"]:
        if b["asset"] == "BTC":
            free_btc = float(b["free"])
            break
    if free_btc <= 0:
        print("No free BTC to sell."); return

    # Exchange filters & price
    ex = c.exchange_info(symbol=SYMBOL)
    s = ex["symbols"][0]
    lot = get_filter(s, "LOT_SIZE")
    mlot = get_filter(s, "MARKET_LOT_SIZE")
    min_notional = get_filter(s, "MIN_NOTIONAL")

    stepSize = float(mlot.get("stepSize") or lot.get("stepSize") or "0.000001")
    minQty   = float(mlot.get("minQty")   or lot.get("minQty")   or "0.000001")

    book = c.book_ticker(symbol=SYMBOL)
    bid  = float(book["bidPrice"])

    # Target: sell 30% of FREE BTC
    target = free_btc * 0.30
    qty = floor_step(target, stepSize)
    if qty < minQty:
        print(f"Computed qty {qty} < minQty {minQty}; nothing to sell."); return

    min_not = float(min_notional.get("minNotional") or "0")
    est_notional = qty * bid
    if min_not > 0 and est_notional < min_not:
        needed_qty = (min_not / bid)
        qty2 = floor_step(max(qty, needed_qty), stepSize)
        if qty2 * bid < min_not:
            print(f"Qty {qty2} still below MIN_NOTIONAL {min_not}; aborting."); return
        qty = qty2

    if qty > free_btc:
        qty = floor_step(free_btc, stepSize)

    qty_str = f"{qty:.8f}".rstrip('0').rstrip('.')
    print(f"Selling 30% BTC free: free={free_btc}, qty={qty_str}, est_notional~{qty*bid:.2f} @bid {bid}")

    if qty <= 0:
        print("No valid qty to sell after filters."); return

    res = c.new_order(symbol=SYMBOL, side="SELL", type="MARKET", quantity=qty_str)
    print(res)

if __name__ == "__main__":
    main()
