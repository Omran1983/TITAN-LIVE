from infra.binance_client import spot, ticker_price, exchange_info
from core.config import settings
from decimal import Decimal

def symbol_exists(base: str, quote: str = "USDT") -> bool:
    info = exchange_info()
    return any(s["symbol"] == f"{base}{quote}" and s["status"] == "TRADING" for s in info["symbols"])

def main():
    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    balances = [b for b in acct["balances"] if float(b["free"]) > 0 or float(b["locked"]) > 0]
    print(f"--- Non-zero Spot balances ({len(balances)}) ---")
    total_est = Decimal("0")
    rows = []
    for b in balances:
        asset = b["asset"]
        free = Decimal(b["free"])
        locked = Decimal(b["locked"])
        est = Decimal("0")
        sym = f"{asset}USDT"
        if asset != "USDT" and symbol_exists(asset, "USDT"):
            try:
                px = Decimal(ticker_price(sym)["price"])
                est = free * px
            except Exception:
                pass
        elif asset == "USDT":
            est = free
        rows.append((asset, free, locked, est))
        total_est += est
    # pretty print
    rows.sort(key=lambda r: r[3], reverse=True)
    for asset, free, locked, est in rows:
        print(f"{asset:8s}  free={free:.8f}  locked={locked:.8f}  est_USDT~{est:.2f}")
    print(f"----------------------------------------------")
    print(f"Estimated liquid USDT value ~ {total_est:.2f}")
if __name__ == "__main__":
    main()

