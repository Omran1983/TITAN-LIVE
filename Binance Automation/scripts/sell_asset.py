from infra.binance_client import spot, exchange_info
from core.config import settings
from decimal import Decimal

def filters_for(symbol: str):
    info = exchange_info()
    for s in info["symbols"]:
        if s["symbol"] == symbol and s["status"] == "TRADING":
            lot = next(f for f in s["filters"] if f["filterType"] == "LOT_SIZE")
            return Decimal(lot["stepSize"]), Decimal(lot["minQty"])
    raise ValueError(f"No tradable symbol or LOT_SIZE for {symbol}")

def floor_to_step(qty: Decimal, step: Decimal) -> Decimal:
    if step == 0: return qty
    return (qty // step) * step

def sell_all_to_usdt(asset: str):
    symbol = f"{asset}USDT"
    step, min_qty = filters_for(symbol)

    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    bal = next((b for b in acct["balances"] if b["asset"] == asset), None)
    if not bal:
        print(f"No balance for {asset}.")
        return
    free = Decimal(bal["free"])
    qty = floor_to_step(free, step)
    if qty <= 0 or qty < min_qty:
        print(f"Nothing sellable: free={free}, step={step}, minQty={min_qty}")
        return

    res = spot.new_order(symbol=symbol, side="SELL", type="MARKET", quantity=str(qty))
    print(f"SOLD {asset}: orderId={res.get('orderId')} qty={qty}")
    return res

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python -m scripts.sell_asset <ASSET>, e.g., BTC")
        sys.exit(1)
    sell_all_to_usdt(sys.argv[1].upper())
