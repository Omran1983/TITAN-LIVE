import os, decimal
from binance.spot import Spot
from dotenv import load_dotenv

load_dotenv(os.getenv("ENV_FILE", ".env"))
c = Spot(
    base_url=os.getenv("BINANCE_BASE_URL", "https://testnet.binance.vision"),
    api_key=os.getenv("BINANCE_API_KEY"),
    api_secret=os.getenv("BINANCE_API_SECRET"),
)

symbol = os.getenv("SYMBOL","BTCUSDT")

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

acct = c.account()
btc_free = next((float(b["free"]) for b in acct["balances"] if b["asset"]=="BTC"), 0.0)
if btc_free <= 0:
    print({"status":"ERROR","msg":"No BTC to protect; buy first."}); raise SystemExit(1)

last = float(c.ticker_price(symbol=symbol)["price"])
tick, step = _filters(symbol)

qty = _round_step(btc_free * 0.99, step)
tp  = _round_tick(last * 1.01, tick)
sl_trig = _round_tick(last * 0.99, tick)   # STOP_LOSS trigger
sl_lim  = _round_tick(float(sl_trig) * 0.999, tick)

tp_order = c.new_order(symbol=symbol, side="SELL", type="LIMIT", timeInForce="GTC", quantity=qty, price=tp)
sl_order = c.new_order(symbol=symbol, side="SELL", type="STOP_LOSS_LIMIT", timeInForce="GTC", quantity=qty, price=sl_lim, stopPrice=sl_trig)

print({"tp_orderId": tp_order.get("orderId"), "sl_orderId": sl_order.get("orderId")})
