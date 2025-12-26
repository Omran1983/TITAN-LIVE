import os, json, threading, time, ssl
from dotenv import load_dotenv
from binance.spot import Spot
from websocket import WebSocketApp

load_dotenv(os.getenv('ENV_FILE','.env'))

BASE   = os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision')
WS_URL = os.getenv('BINANCE_WS_URL','wss://testnet.binance.vision')

rest = Spot(base_url=BASE,
            api_key=os.getenv('BINANCE_API_KEY'),
            api_secret=os.getenv('BINANCE_API_SECRET'))

def get_listen_key():
    return rest.new_listen_key()['listenKey']

def renew_listen_key(k):
    try:
        rest.renew_listen_key(listenKey=k); return True
    except Exception as e:
        print({'keepalive_err': str(e)}); return False

def start_stream():
    k = get_listen_key()
    url = f"{WS_URL}/stream?streams={k}"
    print({'listenKey': k, 'ws_url': url})

    stop = {'flag': False}
    def keepalive():
        while not stop['flag']:
            time.sleep(25*60)
            renew_listen_key(k)

    def run_once(u):
        def on_open(ws):  print({'ws':'open'})
        def on_msg(ws,m): print(m)
        def on_err(ws,e): print({'ws_error': str(e)})
        def on_close(ws,c,r): print({'ws':'close','code':c,'reason':r})
        WebSocketApp(u, on_open=on_open, on_message=on_msg, on_error=on_err, on_close=on_close)\
            .run_forever(sslopt={'cert_reqs': ssl.CERT_NONE}, ping_interval=900, ping_timeout=10)

    threading.Thread(target=keepalive, daemon=True).start()

    try:
        while True:
            run_once(url)
            time.sleep(2)
            k = get_listen_key()
            url = f"{WS_URL}/stream?streams={k}"
            print({'reconnect_new_listenKey': k})
    except KeyboardInterrupt:
        stop['flag'] = True

if __name__ == "__main__":
    start_stream()
