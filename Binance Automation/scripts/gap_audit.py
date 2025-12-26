import os, json, decimal
from binance.spot import Spot
from binance.error import ClientError
from dotenv import load_dotenv

load_dotenv(os.getenv('ENV_FILE','.env'))

base = os.getenv('BINANCE_BASE_URL')
ak   = os.getenv('BINANCE_API_KEY')
sk   = os.getenv('BINANCE_API_SECRET')
sym  = os.getenv('SYMBOL','BTCUSDT')
recv = int(os.getenv('RECV_WINDOW','5000'))
qq_s = os.getenv('QUOTE_QTY','12')

ok = {"env_ok": bool(base and ak and sk)}

try:
    c = Spot(base_url=base, api_key=ak, api_secret=sk)
    ok["ping_ok"] = (c.ping()=={})
    acct = c.account(recvWindow=recv)
    ok["canTrade"] = acct.get("canTrade", True)

    info = c.exchange_info(symbol=sym)["symbols"][0]
    filters = {f["filterType"]: f for f in info["filters"]}
    min_notional = decimal.Decimal((filters.get("NOTIONAL") or filters.get("MIN_NOTIONAL"))["minNotional"])
    quote_qty = decimal.Decimal(qq_s)
    ok["meets_min_notional"] = (quote_qty >= min_notional)

    _ = c.get_orders(symbol=sym, limit=1)
    ok["orders_endpoint"] = True
except ClientError as e:
    ok["client_error"] = {"code": e.error_code, "msg": e.error_message}

print(json.dumps(ok, indent=2))
