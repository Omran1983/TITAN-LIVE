import os
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
sym = os.getenv("SYMBOL","BTCUSDT")
orders = c.get_orders(symbol=sym, limit=500)
openers = [o for o in orders if o.get("status") in ("NEW","PARTIALLY_FILLED")]
print({"symbol": sym, "open_count": len(openers), "open_orders": openers})
