import os, decimal, json
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv("ENV_FILE",".env"))
c = Spot(base_url=os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision"),
         api_key=os.getenv("BINANCE_API_KEY"),
         api_secret=os.getenv("BINANCE_API_SECRET"))

def filters(symbol: str):
    info = c.exchange_info(symbol=symbol)["symbols"][0]["filters"]
    f = {x["filterType"]: x for x in info}
    return decimal.Decimal(f["PRICE_FILTER"]["tickSize"]), decimal.Decimal(f["LOT_SIZE"]["stepSize"])

def round_price(px: float, tick: decimal.Decimal) -> str:
    p = decimal.Decimal(str(px))
    return str((p // tick) * tick)

def round_qty(qty: float, step: decimal.Decimal) -> str:
    q = decimal.Decimal(str(qty))
    return str((q // step) * step)

if __name__ == "__main__":
    sym = os.getenv("SYMBOL","BTCUSDT")
    tick, step = filters(sym)
    print(json.dumps({"symbol": sym, "tick": str(tick), "step": str(step)}, indent=2))
