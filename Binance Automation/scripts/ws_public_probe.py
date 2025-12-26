import os, ssl
from dotenv import load_dotenv
from websocket import WebSocketApp

load_dotenv(os.getenv('ENV_FILE','.env'))
host = os.getenv('BINANCE_WS_URL','wss://stream.testnet.binance.vision:9443').rstrip('/')
sym  = os.getenv('SYMBOL','BTCUSDT').lower()
url  = f"{host}/stream?streams={sym}@aggTrade/{sym}@kline_1m"
print({"public_probe": url})

def on_open(ws): print({"ws":"open"})
def on_msg(ws,m): 
    print(m); ws.close()
def on_err(ws,e): print({"ws_error": str(e)})
def on_close(ws,c,r): print({"ws":"close","code":c,"reason":r})

WebSocketApp(url, on_open=on_open, on_message=on_msg, on_error=on_err, on_close=on_close)\
    .run_forever(sslopt={"cert_reqs": ssl.CERT_NONE}, ping_interval=30, ping_timeout=10)
