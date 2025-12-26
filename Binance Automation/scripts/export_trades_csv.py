import os, csv
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
sym = os.getenv("SYMBOL","BTCUSDT")
trades = c.my_trades(symbol=sym, limit=1000)
path = os.getenv("OUT_CSV","trades_export.csv")
cols = ["time","symbol","orderId","price","qty","quoteQty","commission","commissionAsset","isBuyer","isMaker","isBestMatch"]
with open(path,"w",newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols); w.writeheader()
    for t in trades:
        w.writerow({k: t.get(k) for k in cols})
print({"exported": path, "rows": len(trades)})
