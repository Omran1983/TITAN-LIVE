import os, csv, time
from binance.spot import Spot
from dotenv import load_dotenv
from datetime import datetime, timezone

load_dotenv(os.getenv('ENV_FILE','.env'))
c = Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
         api_key=os.getenv('BINANCE_API_KEY'),
         api_secret=os.getenv('BINANCE_API_SECRET'))

sym = os.getenv('SYMBOL','BTCUSDT'); interval=os.getenv('INTERVAL','1m')
out = os.getenv('OUT_CSV', f'klines_{sym}_{interval}.csv')

# pull last N klines (Binance limit ~1000 per call)
N = int(os.getenv('KLIMIT','1000'))
rows = c.klines(symbol=sym, interval=interval, limit=N)
cols = ["openTime","open","high","low","close","volume","closeTime","qav","trades","takerBaseVol","takerQuoteVol","ignore"]
with open(out,"w",newline="") as f:
    w = csv.writer(f); w.writerow(cols)
    for r in rows: w.writerow(r)
print({"exported": out, "rows": len(rows)})
