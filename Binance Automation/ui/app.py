import os, json, decimal, time
import pandas as pd
import streamlit as st
from dotenv import load_dotenv
from binance.spot import Spot
from binance.error import ClientError

# ---------- helpers ----------
def make_client(env_file):
    load_dotenv(env_file)
    base = os.getenv("BINANCE_BASE_URL","https://testnet.binance.vision")
    ak   = os.getenv("BINANCE_API_KEY")
    sk   = os.getenv("BINANCE_API_SECRET")
    return Spot(base_url=base, api_key=ak, api_secret=sk)

def with_client(env_file):
    try:
        c = make_client(env_file)
        c.ping()
        return c, None
    except Exception as e:
        return None, str(e)

def price(c, symbol):
    return decimal.Decimal(c.ticker_price(symbol=symbol)["price"])

def account_sample(c):
    a = c.account()
    bals = [(b["asset"], b["free"]) for b in a["balances"] if float(b["free"])>0 or float(b["locked"])>0]
    return a.get("canTrade", True), bals[:12]

def open_orders(c, symbol):
    return [o for o in c.get_orders(symbol=symbol, limit=500) if o["status"] in ("NEW","PARTIALLY_FILLED")]

def buy_quote(c, symbol, quote_qty, recv=5000):
    return c.new_order(symbol=symbol, side="BUY", type="MARKET", quoteOrderQty=str(quote_qty), recvWindow=recv)

def sell_pct(c, symbol, pct, recv=5000):
    acct = c.account()
    base = symbol.replace("USDT","").replace("BUSD","")
    free = next((decimal.Decimal(b["free"]) for b in acct["balances"] if b["asset"]==base), decimal.Decimal("0"))
    qty = (free * decimal.Decimal(pct)/decimal.Decimal(100))
    # round to step
    info = c.exchange_info(symbol=symbol)["symbols"][0]
    f = {x["filterType"]: x for x in info["filters"]}
    step = decimal.Decimal(f["LOT_SIZE"]["stepSize"])
    qty = (qty // step) * step
    if qty <= 0:
        raise ValueError("No free balance to sell.")
    return c.new_order(symbol=symbol, side="SELL", type="MARKET", quantity=str(qty), recvWindow=recv)

def place_bracket(c, symbol, tp_pct, sl_pct):
    px = price(c, symbol)
    acct = c.account()
    base = symbol.replace("USDT","").replace("BUSD","")
    free = next((decimal.Decimal(b["free"]) for b in acct["balances"] if b["asset"]==base), decimal.Decimal("0"))
    if free <= 0:
        raise ValueError("No position to protect; buy first.")
    info = c.exchange_info(symbol=symbol)["symbols"][0]
    f = {x["filterType"]: x for x in info["filters"]}
    tick = decimal.Decimal(f["PRICE_FILTER"]["tickSize"])
    step = decimal.Decimal(f["LOT_SIZE"]["stepSize"])
    qty  = (free * decimal.Decimal("0.99"))
    qty  = (qty // step) * step
    tp   = (px * (decimal.Decimal(1) + decimal.Decimal(tp_pct)/decimal.Decimal(100)))
    sl_t = (px * (decimal.Decimal(1) - decimal.Decimal(sl_pct)/decimal.Decimal(100)))
    sl_l = (sl_t * decimal.Decimal("0.999"))
    # round to tick
    def rt(v): 
        return ((v // tick) * tick).quantize(tick)
    tp, sl_t, sl_l = rt(tp), rt(sl_t), rt(sl_l)
    # place both legs (no OCO due to signature variance on testnet lib)
    o1 = c.new_order(symbol=symbol, side="SELL", type="LIMIT", timeInForce="GTC", quantity=str(qty), price=str(tp))
    o2 = c.new_order(symbol=symbol, side="SELL", type="STOP_LOSS_LIMIT", timeInForce="GTC", quantity=str(qty), price=str(sl_l), stopPrice=str(sl_t))
    return {"tp_orderId": o1.get("orderId"), "sl_orderId": o2.get("orderId"), "tp": str(tp), "sl_trig": str(sl_t)}

def cancel_all(c, symbol):
    # safer: cancel only still-open orders
    outs = []
    for o in open_orders(c, symbol):
        try:
            r = c.cancel_order(symbol=symbol, orderId=o["orderId"])
            outs.append({"orderId": o["orderId"], "status": r.get("status")})
        except Exception as e:
            outs.append({"orderId": o["orderId"], "err": str(e)})
    return outs

# ---------- UI ----------
st.set_page_config(page_title="Binance Quick Bot", layout="wide")
st.title("⚡ Binance Quick Bot – Testnet/Prod")

col0, col1, col2 = st.columns([2,2,2], gap="large")

with col0:
    st.subheader("Environment")
    env_choice = st.radio("ENV", [".env.testnet",".env.prod"], index=0, horizontal=True)
    client, err = with_client(env_choice)
    if err: st.error(f"Client init failed: {err}")
    else:
        can, bals = account_sample(client)
        st.success(f"Connected · canTrade={can}")
        st.caption("Balances (sample):")
        st.dataframe(pd.DataFrame(bals, columns=["Asset","Free"]), use_container_width=True)

with col1:
    st.subheader("Rapid Fire")
    symbol = st.text_input("Symbol", "BTCUSDT")
    quote  = st.number_input("Buy amount (quote, USDT)", min_value=5.0, value=12.0, step=1.0)
    colB1, colB2, colB3 = st.columns(3)
    if colB1.button("💸 Market BUY"):
        try:
            r = buy_quote(client, symbol, quote)
            st.success(f"BUY OK · orderId={r.get('orderId')}")
        except ClientError as e:
            st.error(f"BUY failed: {e.error_code} {e.error_message}")
    sellpct = st.slider("Quick SELL % of position", 5, 100, 25, step=5)
    if colB2.button("🧾 Market SELL %"):
        try:
            r = sell_pct(client, symbol, sellpct)
            st.success(f"SELL OK · orderId={r.get('orderId')}")
        except Exception as e:
            st.error(f"SELL failed: {e}")
    tp_pct = st.number_input("TP %", value=1.0, step=0.1)
    sl_pct = st.number_input("SL %", value=1.0, step=0.1)
    if colB3.button("🛡️ Place Bracket (TP/SL)"):
        try:
            r = place_bracket(client, symbol, tp_pct, sl_pct)
            st.success(f"BRACKET OK · TP#{r['tp_orderId']} SL#{r['sl_orderId']} (tp={r['tp']} slTrig={r['sl_trig']})")
        except Exception as e:
            st.error(f"Bracket failed: {e}")

with col2:
    st.subheader("Ops")
    if st.button("🔎 Open Orders"):
        o = open_orders(client, symbol)
        st.write(o if o else "None")
    if st.button("🧨 Cancel Open Orders"):
        st.write(cancel_all(client, symbol))
    if st.button("📈 Latest Price"):
        try:
            px = price(client, symbol)
            st.metric(label=f"{symbol} last", value=str(px))
        except Exception as e:
            st.error(str(e))

st.divider()
st.subheader("Trade Log (trades_export.csv / live_trade_log.csv if present)")
for f in ["trades_export.csv","live_trade_log.csv"]:
    if os.path.isfile(f):
        try:
            df = pd.read_csv(f)
            st.caption(f"Showing: {f}")
            st.dataframe(df.tail(50), use_container_width=True)
        except Exception:
            pass
