import os, decimal, json
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c=Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
       api_key=os.getenv("BINANCE_API_KEY"),
       api_secret=os.getenv("BINANCE_API_SECRET"))
sym=os.getenv("SYMBOL","BTCUSDT")
acct = c.account()
base = sym.replace("USDT","")
free = next((float(b["free"]) for b in acct["balances"] if b["asset"]==base), 0.0)
if free<=0:
    print({"status":"ERROR","msg":f"No {base} to protect"}); raise SystemExit(1)
info=c.exchange_info(symbol=sym)["symbols"][0]; f={x["filterType"]:x for x in info["filters"]}
step=decimal.Decimal(f["LOT_SIZE"]["stepSize"]); tick=decimal.Decimal(f["PRICE_FILTER"]["tickSize"])
def rstep(q): 
    q=decimal.Decimal(str(q)); return str((q//step)*step)
def rtick(p):
    p=decimal.Decimal(str(p)); return str((p//tick)*tick)
last = float(c.ticker_price(symbol=sym)["price"])
tp_pct = float(os.getenv("TP_PCT","1.0"))/100.0
sl_pct = float(os.getenv("SL_PCT","1.0"))/100.0
tp  = last*(1+tp_pct); sl_trig = last*(1-sl_pct); sl_lim = sl_trig*0.999
qty_each = rstep(free*0.10)  # protect ~10% chunks fast
# Place two legs (LIMIT TP + STOP_LOSS_LIMIT)
tp_o = c.new_order(symbol=sym, side="SELL", type="LIMIT", timeInForce="GTC", quantity=qty_each, price=rtick(tp))
sl_o = c.new_order(symbol=sym, side="SELL", type="STOP_LOSS_LIMIT", timeInForce="GTC", quantity=qty_each, price=rtick(sl_lim), stopPrice=rtick(sl_trig))
print(json.dumps({"status":"OK","tp_orderId":tp_o.get("orderId"), "sl_orderId":sl_o.get("orderId"), "qty_each":qty_each}))
