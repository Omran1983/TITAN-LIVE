from infra.binance_client import spot, exchange_info
from core.config import settings

def main():
    sym = settings.SYMBOL
    acct = spot.account(recvWindow=settings.RECV_WINDOW)
    usdt_free = next((b for b in acct["balances"] if b["asset"]=="USDT"), {"free":"0"})["free"]

    info = exchange_info()
    s = next(x for x in info["symbols"] if x["symbol"] == sym)
    filt = next((f for f in s["filters"] if f["filterType"] in ("NOTIONAL","MIN_NOTIONAL")), None)
    min_notional = (filt.get("minNotional") if filt else "0") or "0"

    print("Free USDT:", usdt_free)
    print("Symbol:", sym)
    print("Min notional (USDT):", min_notional)
    print("Configured QUOTE_TRADE_USDT:", settings.QUOTE_TRADE_USDT)

if __name__ == "__main__":
    main()
