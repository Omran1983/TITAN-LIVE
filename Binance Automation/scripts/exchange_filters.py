import os, decimal, json
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))
sym = os.getenv("SYMBOL","BTCUSDT")
info = c.exchange_info(symbol=sym)["symbols"][0]
filters = {f["filterType"]: f for f in info["filters"]}
out = {
  "symbol": sym,
  "price_tickSize": filters["PRICE_FILTER"]["tickSize"],
  "qty_stepSize": filters["LOT_SIZE"]["stepSize"],
  "qty_minQty": filters["LOT_SIZE"]["minQty"],
  "min_notional": filters.get("NOTIONAL", {}).get("minNotional") or filters.get("MIN_NOTIONAL", {}).get("minNotional"),
  "quote_asset": info["quoteAsset"],
  "base_asset": info["baseAsset"]
}
print(json.dumps(out, indent=2))
