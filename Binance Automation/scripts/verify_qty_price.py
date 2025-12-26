import os, decimal
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
sym = os.getenv("SYMBOL","BTCUSDT")
qty_in = decimal.Decimal(os.getenv("QTY","0.0001"))
price_in = decimal.Decimal(os.getenv("PRICE","100000"))
info = c.exchange_info(symbol=sym)["symbols"][0]
f = {x["filterType"]: x for x in info["filters"]}
step = decimal.Decimal(f["LOT_SIZE"]["stepSize"]); minq = decimal.Decimal(f["LOT_SIZE"]["minQty"])
tick = decimal.Decimal(f["PRICE_FILTER"]["tickSize"])
qty_ok = (qty_in >= minq) and (qty_in % step == 0)
px_ok = (price_in % tick == 0)
print({"qty_in": str(qty_in), "qty_min": str(minq), "qty_step": str(step), "qty_ok": qty_ok,
       "price_in": str(price_in), "tick": str(tick), "price_ok": px_ok})
