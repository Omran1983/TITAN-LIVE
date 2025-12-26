import os, json
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv('ENV_FILE','.env'))
c = Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
         api_key=os.getenv('BINANCE_API_KEY'),
         api_secret=os.getenv('BINANCE_API_SECRET'))
sym = os.getenv('SYMBOL','BTCUSDT')
orders = c.get_orders(symbol=sym, limit=500)
openers = [o for o in orders if o['status'] in ('NEW','PARTIALLY_FILLED')]
print(json.dumps({'open_count':len(openers),'ids':[o['orderId'] for o in openers]}, indent=2))
for o in openers:
    try:
        r = c.cancel_order(symbol=sym, orderId=o['orderId'])
        print({'canceled': o['orderId'], 'status': r.get('status')})
    except Exception as e:
        print({'cancel_err': o['orderId'], 'err': str(e)})
