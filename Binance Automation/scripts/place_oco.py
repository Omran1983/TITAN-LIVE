import os, decimal
from binance.spot import Spot
from dotenv import load_dotenv

load_dotenv(os.getenv("ENV_FILE", ".env"))
c = Spot(
    base_url=os.getenv("BINANCE_BASE_URL", "https://testnet.binance.vision"),
    api_key=os.getenv("BINANCE_API_KEY"),
    api_secret=os.getenv("BINANCE_API_SECRET"),
)

symbol = os.getenv("SYMBOL", "BTCUSDT")

def _filters(sym: str):
    info = c.exchange_info(symbol=sym)["symbols"][0]["filters"]
    f = {x["filterType"]: x for x in info}
    tick = decimal.Decimal(f["PRICE_FILTER"]["tickSize"])
    step = decimal.Decimal(f["LOT_SIZE"]["stepSize"])
    return tick, step

def _round_step(qty: float, step: decimal.Decimal) -> str:
    q = decimal.Decimal(str(qty))
    return str((q // step) * step)

def _round_tick(px: float, tick: decimal.Decimal) -> str:
    p = decimal.Decimal(str(px))
    return str((p // tick) * tick)

# 1) ensure BTC available
acct = c.account()
free_btc = next((float(b["free"]) for b in acct["balances"] if b["asset"]=="BTC"), 0.0)
if free_btc <= 0:
    print({"status":"ERROR","msg":"No BTC to place OCO. Buy first."}); raise SystemExit(1)

# 2) compute prices
last = float(c.ticker_price(symbol=symbol)["price"])
tp_raw = last * 1.01            # +1% take-profit
stop_trig_raw = last * 0.99     # -1% stop trigger
stop_lim_raw  = stop_trig_raw * 0.999

# 3) round to instrument precision
tick, step = _filters(symbol)
abovePrice   = _round_tick(tp_raw, tick)
belowStop    = _round_tick(stop_trig_raw, tick)
belowPrice   = _round_tick(stop_lim_raw, tick)
qty          = _round_step(free_btc * 0.98, step)  # keep 2% dust to avoid insuff balance

# 4) send OCO: SELL side, above leg is LIMIT_MAKER (TP), below leg is STOP_LOSS_LIMIT
oco = c.new_oco_order(
    symbol=symbol,
    side="SELL",
    quantity=qty,
    aboveType="LIMIT_MAKER",
    abovePrice=abovePrice,
    belowType="STOP_LOSS_LIMIT",
    belowStopPrice=belowStop,
    belowPrice=belowPrice,
    belowTimeInForce="GTC"
)

print({"status":"OK","orderListId": oco.get("orderListId"),
       "qty": qty, "tp": abovePrice, "stop": belowStop, "stopLimit": belowPrice})
