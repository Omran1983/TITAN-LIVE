import os
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv('ENV_FILE','.env'))
c = Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
         api_key=os.getenv('BINANCE_API_KEY'),
         api_secret=os.getenv('BINANCE_API_SECRET'))
sym = os.getenv('SYMBOL','BTCUSDT')
print({'ping': c.ping()=={}})
print({'canTrade': c.account().get('canTrade', True)})
print({'price': c.ticker_price(symbol=sym)})
print({'orders_endpoint': len(c.get_orders(symbol=sym, limit=1))>=0})
