import os
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
sym = os.getenv("SYMBOL","BTCUSDT")
oid = int(os.getenv("ORDER_ID","0"))
print(c.get_order(symbol=sym, orderId=oid))
