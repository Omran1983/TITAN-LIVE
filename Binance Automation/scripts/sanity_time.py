import os, time
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
srv = c.time()["serverTime"]
loc = int(time.time()*1000)
print({"server_ms": srv, "local_ms": loc, "delta_ms": srv - loc})
