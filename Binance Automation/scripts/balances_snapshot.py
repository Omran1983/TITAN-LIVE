import os, json
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
a = c.account()
nonzero = [{ "asset": b["asset"], "free": b["free"], "locked": b["locked"] }
           for b in a["balances"] if float(b["free"])>0 or float(b["locked"])>0]
print(json.dumps(nonzero[:15], indent=2))
