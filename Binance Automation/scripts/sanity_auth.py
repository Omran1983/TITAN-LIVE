import os
from binance.spot import Spot
from binance.error import ClientError
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
print("Ping:", c.ping())
try:
    a = c.account()
    print("Account OK:", a.get("canTrade", True))
except ClientError as e:
    print("Auth fail:", e.status_code, e.error_code, e.error_message)
