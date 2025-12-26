import os, csv, time, decimal, uuid
from datetime import datetime, timezone
from dotenv import load_dotenv
from binance.spot import Spot
from binance.error import ClientError

load_dotenv(os.getenv("ENV_FILE",".env"))

BASE = os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision")
AK   = os.getenv("BINANCE_API_KEY")
SK   = os.getenv("BINANCE_API_SECRET")
SYMBOL = os.getenv("SYMBOL","BTCUSDT")
BURSTS = int(os.getenv("BURSTS","5"))           # number of buy→sell cycles
QUOTE  = decimal.Decimal(os.getenv("QUOTE_QTY","6"))  # USDT per scalp (>=5 on testnet)
COOLDOWN_MS = int(os.getenv("COOLDOWN_MS","500"))     # pause between legs
RECV = int(os.getenv("RECV_WINDOW","5000"))
LOG = os.getenv("SCALP_LOG","scalp_trades.csv")

cli = Spot(base_url=BASE, api_key=AK, api_secret=SK)

# --- filters & rounding helpers ---
info = cli.exchange_info(symbol=SYMBOL)["symbols"][0]
fmap = {f["filterType"]: f for f in info["filters"]}
tick = decimal.Decimal(fmap["PRICE_FILTER"]["tickSize"])
step = decimal.Decimal(fmap["LOT_SIZE"]["stepSize"])
minq = decimal.Decimal(fmap["LOT_SIZE"]["minQty"])
min_notional = decimal.Decimal((fmap.get("NOTIONAL") or fmap.get("MIN_NOTIONAL"))["minNotional"])

def r_step(q):
    qd = decimal.Decimal(str(q))
    return (qd // step) * step

def now_ms():
    return int(time.time()*1000)

# init CSV
if not os.path.exists(LOG):
    with open(LOG,"w",newline="") as f:
        w = csv.writer(f)
        w.writerow(["ts","burst","leg","symbol","side","price","qty","quoteQty","orderId","status","note"])

def log_row(burst, leg, side, price, qty, quoteQty, orderId, status, note=""):
    with open(LOG,"a",newline="") as f:
        w = csv.writer(f)
        w.writerow([datetime.utcnow().isoformat(), burst, leg, SYMBOL, side, price, qty, quoteQty, orderId, status, note])

def ensure_notional_ok():
    px = decimal.Decimal(cli.ticker_price(symbol=SYMBOL)["price"])
    if QUOTE < min_notional:
        raise SystemExit(f"QUOTE_QTY {QUOTE} < min_notional {min_notional}")
    return px

def wait_fill(order_id, timeout_ms=4000):
    t0 = now_ms()
    while now_ms() - t0 < timeout_ms:
        o = cli.get_order(symbol=SYMBOL, orderId=order_id, recvWindow=RECV)
        if o["status"] in ("FILLED","PARTIALLY_FILLED"):
            return o
        time.sleep(0.05)
    return cli.get_order(symbol=SYMBOL, orderId=order_id, recvWindow=RECV)

def scalp_once(burst_idx):
    px = ensure_notional_ok()
    # BUY (MARKET by quote)
    cid_b = f"scalpB-{uuid.uuid4().hex[:16]}"
    try:
        ob = cli.new_order(symbol=SYMBOL, side="BUY", type="MARKET",
                           quoteOrderQty=str(QUOTE), newClientOrderId=cid_b, recvWindow=RECV)
        bid = ob["orderId"]
    except ClientError as e:
        log_row(burst_idx,"BUY","BUY","", "", str(QUOTE), "", "ERROR", f"{e.error_code}:{e.error_message}")
        return False

    obf = wait_fill(ob["orderId"])
    filled_qty = decimal.Decimal(obf.get("executedQty","0"))
    filled_quote = decimal.Decimal(obf.get("cummulativeQuoteQty","0"))
    log_row(burst_idx,"BUY","BUY", obf.get("price",""), str(filled_qty), str(filled_quote), ob["orderId"], obf.get("status",""))
    if filled_qty <= 0:
        return False

    # Round down to step, avoid dust
    qty_s = r_step(filled_qty * decimal.Decimal("0.999"))
    if qty_s < minq:
        log_row(burst_idx,"SELL","SELL","", str(qty_s), "", "", "SKIP","qty<min")
        return True

    time.sleep(COOLDOWN_MS/1000)

    # SELL (MARKET by quantity)
    cid_s = f"scalpS-{uuid.uuid4().hex[:16]}"
    try:
        osell = cli.new_order(symbol=SYMBOL, side="SELL", type="MARKET",
                              quantity=str(qty_s), newClientOrderId=cid_s, recvWindow=RECV)
    except ClientError as e:
        log_row(burst_idx,"SELL","SELL","", str(qty_s), "", "", "ERROR", f"{e.error_code}:{e.error_message}")
        return False

    osf = wait_fill(osell["orderId"])
    log_row(burst_idx,"SELL","SELL", osf.get("price",""), str(qty_s), osf.get("cummulativeQuoteQty",""), osell["orderId"], osf.get("status",""))
    return True

def main():
    ok_count=0
    for i in range(1, BURSTS+1):
        try:
            if scalp_once(i): ok_count+=1
        except Exception as e:
            log_row(i,"ERR","", "", "", "", "", "ERROR", str(e))
        time.sleep(COOLDOWN_MS/1000)
    print({"bursts": BURSTS, "success": ok_count, "log": LOG})

if __name__ == "__main__":
    main()
