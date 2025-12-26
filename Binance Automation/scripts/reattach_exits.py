from decimal import Decimal
from core.config import settings
from infra.binance_client import spot, exchange_info, ticker_price

def base_asset_from(symbol: str) -> str:
    info = exchange_info()
    for s in info["symbols"]:
        if s["symbol"] == symbol:
            return s["baseAsset"]
    raise ValueError(f"Symbol not found: {symbol}")

def lot_tick(symbol: str):
    info = exchange_info()
    for s in info["symbols"]:
        if s["symbol"] == symbol:
            lot = next(f for f in s["filters"] if f["filterType"] == "LOT_SIZE")
            pricef = next(f for f in s["filters"] if f["filterType"] == "PRICE_FILTER")
            return Decimal(lot["stepSize"]), Decimal(pricef["tickSize"])
    raise ValueError("Filters missing")

def floor_to_step(x: Decimal, step: Decimal) -> Decimal:
    return (x // step) * step if step != 0 else x

def attach_exits():
    symbol = settings.SYMBOL
    base = base_asset_from(symbol)
    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    bal = next((b for b in acct["balances"] if b["asset"] == base), None)
    if not bal:
        print(f"No balance for {base}.")
        return
    free_qty = Decimal(bal["free"])
    if free_qty <= 0:
        print(f"No {base} position to protect.")
        return

    step, tick = lot_tick(symbol)
    qty = floor_to_step(free_qty, step)
    if qty <= 0:
        print("Free qty below min step; increase size or trade again.")
        return

    last = Decimal(ticker_price(symbol)["price"])
    tp = floor_to_step(last * Decimal(1 + settings.TAKE_PROFIT_PCT), tick)
    stop = floor_to_step(last * Decimal(1 - settings.STOP_LOSS_PCT), tick)
    stop_limit = floor_to_step(stop * (Decimal(1) - Decimal(str(settings.OCO_STOP_LIMIT_BUFFER))), tick)

    # Place TP (LIMIT) and SL (STOP_LOSS_LIMIT)
    tp_res = spot.new_order(symbol=symbol, side="SELL", type="LIMIT",
                            quantity=str(qty), price=str(tp), timeInForce="GTC")
    sl_res = spot.new_order(symbol=symbol, side="SELL", type="STOP_LOSS_LIMIT",
                            quantity=str(qty), price=str(stop_limit),
                            stopPrice=str(stop), timeInForce="GTC")
    print("TP order id:", tp_res.get("orderId"))
    print("SL order id:", sl_res.get("orderId"))

if __name__ == "__main__":
    attach_exits()
