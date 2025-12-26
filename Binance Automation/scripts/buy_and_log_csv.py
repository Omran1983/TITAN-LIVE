import os, csv, time
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))

sym = os.getenv("SYMBOL","BTCUSDT")
path = os.getenv("TRADE_LOG","live_trade_log.csv")
cols = ["ts","symbol","side","price","qty","quoteQty","orderId"]

# ensure header
if not os.path.exists(path):
    with open(path,"w",newline="") as f: csv.DictWriter(f, fieldnames=cols).writeheader()

# place & log
o = c.new_order(symbol=sym, side="BUY", type="MARKET", quoteOrderQty="12", recvWindow=5000)
oid = o["orderId"]
fills = [t for t in c.my_trades(symbol=sym, limit=10) if t["orderId"]==oid]
row = {
  "ts": int(time.time()*1000),
  "symbol": sym,
  "side": "BUY",
  "price": fills[0]["price"] if fills else "",
  "qty": fills[0]["qty"] if fills else "",
  "quoteQty": fills[0]["quoteQty"] if fills else "",
  "orderId": oid
}
with open(path,"a",newline="") as f: csv.DictWriter(f, fieldnames=cols).writerow(row)
print({"logged_to": path, "orderId": oid})
