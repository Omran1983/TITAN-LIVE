from binance.spot import Spot
from decimal import Decimal, getcontext
import os, sys, pathlib, json

SYMBOL = "BTCUSDT"
DRY_RUN = False  # set False to execute

def load_env_from_file():
    p = pathlib.Path(os.getenv("ENV_FILE", ".env.mainnet"))
    if p.exists():
        for ln in p.read_text(encoding="utf-8", errors="ignore").splitlines():
            s = ln.strip()
            if not s or s.startswith("#") or "=" not in s: 
                continue
            k, v = s.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

def D(x): return Decimal(str(x))

def step_places(step_str: str) -> int:
    try:
        return max(0, -Decimal(step_str).as_tuple().exponent)
    except:
        return 0

def to_step(qty: Decimal, step: Decimal) -> Decimal:
    if step <= 0:  # guard
        return qty
    # floor to multiple of step
    return (qty // step) * step

def parse_step(s):
    try:
        v = D(s)
        return v
    except:
        return D("0")

def main():
    getcontext().prec = 28
    load_env_from_file()

    key = os.getenv("BINANCE_API_KEY"); sec = os.getenv("BINANCE_API_SECRET")
    if not key or not sec:
        print("ERROR: API keys missing (BINANCE_API_KEY/SECRET)."); sys.exit(1)

    c = Spot(api_key=key, api_secret=sec)

    # Balances
    free = D("0"); locked = D("0")
    for b in c.account().get("balances", []):
        if b["asset"] == "BTC":
            free = D(b["free"]); locked = D(b["locked"]); break
    if free <= 0:
        print("No free BTC to sell."); return

    # Exchange filters
    ex = c.exchange_info(symbol=SYMBOL)
    sym = ex["symbols"][0]
    filters = { f["filterType"]: f for f in sym["filters"] }

    lot      = filters.get("LOT_SIZE", {})
    mlot     = filters.get("MARKET_LOT_SIZE", {})
    minnot   = filters.get("MIN_NOTIONAL", {})

    lot_step = parse_step(lot.get("stepSize", "0"))
    lot_minQ = parse_step(lot.get("minQty",   "0"))
    lot_maxQ = parse_step(lot.get("maxQty",   "0"))

    m_step   = parse_step(mlot.get("stepSize", "0"))
    m_minQ   = parse_step(mlot.get("minQty",   "0"))
    m_maxQ   = parse_step(mlot.get("maxQty",   "0"))

    # Prefer MARKET_LOT_SIZE only if it has a valid (>0) step
    if m_step > 0:
        step = m_step; minQ = m_minQ; maxQ = m_maxQ
        step_src = "MARKET_LOT_SIZE"
    else:
        step = lot_step; minQ = lot_minQ; maxQ = lot_maxQ
        step_src = "LOT_SIZE"

    min_notional = parse_step(minnot.get("minNotional", "0"))

    # Price for notional
    bid = D(c.book_ticker(symbol=SYMBOL)["bidPrice"])

    # Target 30% of FREE (not touching locked)
    target = free * D("0.30")
    qty = to_step(target, step)

    # Enforce minQty
    if qty < minQ:
        qty = to_step(minQ, step)

    # Cap by free and maxQty if defined
    if maxQ > 0 and qty > maxQ:
        qty = to_step(maxQ, step)
    if qty > free:
        qty = to_step(free, step)

    # Enforce MIN_NOTIONAL (bump up to min, but never exceed free)
    if min_notional > 0 and (qty * bid) < min_notional:
        need = min_notional / bid
        # ceil to next step
        mult = (need / step).to_integral_value(rounding="ROUND_CEILING")
        qty  = mult * step
        if qty > free:
            qty = to_step(free, step)

    if qty <= 0:
        print("No valid qty after filters.")
        print(json.dumps({
            "free": str(free),
            "locked": str(locked),
            "lot_step": str(lot_step),
            "mlot_step": str(m_step),
            "chosen_step": str(step),
            "minQty": str(minQ),
            "minNotional": str(min_notional),
            "bid": str(bid),
        }, indent=2))
        return

    places = step_places(str(step)) if step > 0 else 8
    qty_str = f"{qty:.{places}f}"

    report = {
        "symbol": SYMBOL,
        "free_btc": str(free),
        "locked_btc": str(locked),
        "step_source": step_src,
        "lot_step": str(lot_step),
        "market_step": str(m_step),
        "chosen_step": str(step),
        "minQty": str(minQ),
        "maxQty": str(maxQ),
        "min_notional": str(min_notional),
        "bid": f"{bid:.8f}",
        "target_30pct": f"{target:.8f}",
        "final_qty": qty_str,
        "est_notional": f"{(qty*bid):.2f}",
        "dry_run": DRY_RUN
    }
    print("Computed order:")
    print(json.dumps(report, indent=2))

    if DRY_RUN:
        print("DRY_RUN = False → not sending order. Set DRY_RUN=False.")
        return

    res = c.new_order(symbol=SYMBOL, side="SELL", type="MARKET", quantity=qty_str)
    print("ORDER RESULT:")
    print(json.dumps(res, indent=2))

if __name__ == "__main__":
    main()

