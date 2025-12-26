import os, ssl, time, threading
from dotenv import load_dotenv
from websocket import WebSocketApp
from binance.spot import Spot

load_dotenv(os.getenv('ENV_FILE','.env'))

BASE = os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision')
AK   = os.getenv('BINANCE_API_KEY')
SK   = os.getenv('BINANCE_API_SECRET')

rest = Spot(base_url=BASE, api_key=AK, api_secret=SK)

def new_key():
    return rest.new_listen_key()["listenKey"]

def keepalive(k, stopflag):
    while not stopflag["stop"]:
        time.sleep(25*60)
        try: rest.renew_listen_key(listenKey=k)
        except Exception as e: print({"keepalive_err": str(e)})

def run_ws(url):
    ok = {"opened": False}
    def on_open(ws): ok["opened"]=True; print({"ws":"open","url":url}); ws.close()
    def on_error(ws,err): print({"probe_error": str(err)})
    def on_close(ws,code,reason): print({"ws":"close","code":code,"reason":reason})
    ws = WebSocketApp(url, on_open=on_open, on_message=lambda *_:None, on_error=on_error, on_close=on_close)
    ws.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE}, ping_interval=30, ping_timeout=10)
    return ok["opened"]

def first_working_url(k):
    # ✅ Correct testnet WS bases
    bases = [
        os.getenv("BINANCE_WS_URL","wss://stream.testnet.binance.vision:9443").rstrip('/'),
        "wss://stream.testnet.binance.vision:9443",
        "wss://stream.testnet.binance.vision:443",
    ]
    paths = [lambda b,kk: f"{b}/ws/{kk}", lambda b,kk: f"{b}/stream?streams={kk}"]
    for b in bases:
        for make in paths:
            url = make(b, k); print({"probing": url})
            if run_ws(url): return url
    return None

def start_user_stream():
    k = new_key()
    url = first_working_url(k)
    if not url: print({"fatal":"no_ws_endpoint_worked"}); return
    print({"listenKey":k,"selected_url":url})

    stop = {"stop": False}
    threading.Thread(target=keepalive, args=(k,stop), daemon=True).start()

    def on_open(ws): print({"ws":"open"})
    def on_msg(ws,msg): print(msg)
    def on_err(ws,err): print({"ws_error": str(err)})
    def on_close(ws,code,reason): print({"ws":"close","code":code,"reason":reason})

    while True:
        app = WebSocketApp(url, on_open=on_open, on_message=on_msg, on_error=on_err, on_close=on_close)
        try:
            app.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE}, ping_interval=900, ping_timeout=10)
        except KeyboardInterrupt:
            stop["stop"]=True; break
        time.sleep(2)
        k = new_key()
        url = first_working_url(k) or url
        print({"reconnect_new_listenKey": k, "next_url": url})

if __name__ == "__main__":
    start_user_stream()
