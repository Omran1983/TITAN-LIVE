import os
from binance.spot import Spot
from dotenv import load_dotenv

load_dotenv(os.getenv("ENV_FILE", ".env"))
c = Spot(
    base_url=os.getenv("BINANCE_BASE_URL", "https://testnet.binance.vision"),
    api_key=os.getenv("BINANCE_API_KEY"),
    api_secret=os.getenv("BINANCE_API_SECRET"),
)

acct = c.account()
bals = [(b["asset"], b["free"]) for b in acct["balances"] if float(b["free"])>0 or float(b["locked"])>0]
print({"canTrade": acct.get("canTrade", True), "balances_sample": bals[:10]})
print({"recent_trades": c.my_trades(symbol=os.getenv("SYMBOL","BTCUSDT"), limit=10)})
