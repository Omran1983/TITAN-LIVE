import os, math, json, statistics as stats
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
sym=os.getenv("SYMBOL","BTCUSDT")
risk_usdt=float(os.getenv("RISK_USDT","2.5"))  # risk per scalp
c=Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
       api_key=os.getenv("BINANCE_API_KEY"),
       api_secret=os.getenv("BINANCE_API_SECRET"))
# Pull last ~60 1m candles quickly
rows=c.klines(symbol=sym, interval="1m", limit=60)
# TR proxy: high-low; ATR-lite = median(TR)
trs=[float(r[2])-float(r[3]) for r in rows]  # high-low
atr = stats.median(trs) if trs else 0.0
px = float(c.ticker_price(symbol=sym)["price"])
# If ATR tiny, use fallback micro size; else aim risk_usdt per trade at ~1*ATR stop
base_qty = (risk_usdt/atr) if atr>0 else (risk_usdt/px)
quote_qty = base_qty * px
# Clamp to sane bounds (min $3, max $25 per click for testnet bursts)
quote_qty = max(3.0, min(quote_qty, 25.0))
print(json.dumps({"atr":atr,"price":px,"quote":round(quote_qty,2)}))
