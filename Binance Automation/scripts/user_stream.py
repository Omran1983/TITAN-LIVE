import os, json, threading, time
from dotenv import load_dotenv

load_dotenv(os.getenv('ENV_FILE','.env'))

# REST for listenKey
from binance.spot import Spot
rest = Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
            api_key=os.getenv('BINANCE_API_KEY'),
            api_secret=os.getenv('BINANCE_API_SECRET'))

listen = rest.new_listen_key()['listenKey']
print({'listenKey': listen})

def keepalive():
    while True:
        try:
            rest.renew_listen_key(listenKey=listen)
        except Exception as e:
            print({'keepalive_err': str(e)})
        time.sleep(25*60)
threading.Thread(target=keepalive, daemon=True).start()

# Try new import first, then legacy fallback
ws = None
try:
    from binance.websocket.spot.websocket_client import SpotWebsocketClient as Wss
    ws = Wss()
    def on_msg(_id, msg): print(msg)
    ws.start()
    ws.user_data(listen_key=listen, id=1, callback=on_msg)
except Exception as e:
    print({'ws_import_fallback': str(e)})
    try:
        from binance.websocket.websocket_client import WebsocketClient as WssOld
        ws = WssOld(stream_url=os.getenv('BINANCE_WS_URL','wss://testnet.binance.vision'))
        def on_open(_): ws.user_data(listen_key=listen)
        def on_message(_, msg): print(msg)
        ws.start()
        ws._on_open = on_open
        ws._on_message = on_message
    except Exception as e2:
        print({'ws_failed': str(e2)})
        raise SystemExit(1)

try:
    while True: time.sleep(1)
except KeyboardInterrupt:
    if ws: ws.stop()
