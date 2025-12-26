from core.config import settings
from brain.ipde import decide
from exec.trade import tiny_test_trade

def run_once() -> bool:
    """
    One decision+execution cycle.
    Returns True if a BUY was placed, else False.
    """
    symbol = settings.SYMBOL
    d = decide(symbol)
    print("Decision:", d)

    if d.get("action") != "INVEST":
        print("No trade placed (action is not INVEST).")
        return False

    print("Placing tiny test trade on", symbol)
    try:
        res = tiny_test_trade(
            symbol=symbol,
            quote_usdt=settings.QUOTE_TRADE_USDT,
            tp_pct=settings.TAKE_PROFIT_PCT,
            sl_pct=settings.STOP_LOSS_PCT,
        )
        # Best-effort prints; keys may vary depending on path taken
        buy_id = (res.get("buy") or {}).get("orderId")
        oco = res.get("oco") or {}
        oco_id = oco.get("orderListId") or oco.get("orderId")
        print("BUY order id:", buy_id)
        if oco_id:
            print("OCO id:", oco_id)
        return True
    except Exception as e:
        print("run_once error:", repr(e))
        return False
