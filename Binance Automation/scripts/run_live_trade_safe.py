import os, time, uuid, decimal
from binance.spot import Spot
from binance.error import ClientError
from dotenv import load_dotenv

load_dotenv(os.getenv('ENV_FILE','.env'))
c = Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
         api_key=os.getenv('BINANCE_API_KEY'),
         api_secret=os.getenv('BINANCE_API_SECRET'))

sym = os.getenv('SYMBOL','BTCUSDT'); recv=int(os.getenv('RECV_WINDOW','5000'))
new_id = f"cli-{uuid.uuid4().hex[:20]}"
info = c.exchange_info(symbol=sym)["symbols"][0]
f = {x["filterType"]: x for x in info["filters"]}
tick = decimal.Decimal(f["PRICE_FILTER"]["tickSize"])
step = decimal.Decimal(f["LOT_SIZE"]["stepSize"])
price = decimal.Decimal(c.ticker_price(symbol=sym)["price"])
qq = decimal.Decimal(os.getenv('QUOTE_QTY','12'))
try:
    o = c.new_order(symbol=sym, side='BUY', type='MARKET',
                    newClientOrderId=new_id,
                    quoteOrderQty=str(qq), recvWindow=recv)
    print({'status':'OK','orderId':o.get('orderId'),'cid':new_id})
except ClientError as e:
    # Fallback: compute base qty if quote qty path fails
    if e.error_code == -1013:
        qty = (qq/price)
        qty = (decimal.Decimal(str(qty)) // step) * step
        o = c.new_order(symbol=sym, side='BUY', type='MARKET',
                        quantity=str(qty), newClientOrderId=new_id, recvWindow=recv)
        print({'status':'OK_FALLBACK','orderId':o.get('orderId'),'qty':str(qty)})
    else:
        print({'status':'ERROR','code':e.error_code,'msg':e.error_message})
