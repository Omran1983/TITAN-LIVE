import os, time, hmac, hashlib
import urllib.parse as up
from pathlib import Path
from datetime import datetime, timezone

import pandas as pd
import requests
import streamlit as st
from dotenv import load_dotenv

# ---------- ENV ----------
PROJECT_ROOT = Path(__file__).resolve().parent
def use_env(envfile: str):
    env_path = (PROJECT_ROOT / envfile) if not Path(envfile).is_absolute() else Path(envfile)
    if not env_path.exists():
        env_path = PROJECT_ROOT / ".env"
    load_dotenv(dotenv_path=env_path, override=True)
    os.environ["ENV_FILE"] = env_path.name

def _env(k, d=""): v = os.getenv(k); return v if v not in (None,"") else d

# ---------- BINANCE ----------
TIME_OFFSET_MS = 0
def _base(): return _env("BINANCE_BASE_URL","https://api.binance.com")
def _key():  return _env("BINANCE_API_KEY")
def _sec():  return _env("BINANCE_API_SECRET")
def _server_time():
    r = requests.get(f"{_base()}/api/v3/time", timeout=10); r.raise_for_status(); return int(r.json()["serverTime"])
def _sync_time():
    global TIME_OFFSET_MS
    try: TIME_OFFSET_MS=_server_time()-int(time.time()*1000)
    except: pass
def _ts(): return int(time.time()*1000+TIME_OFFSET_MS)
def _sign(params:dict, secret:str)->str:
    qs = up.urlencode(params, doseq=True)
    import hmac, hashlib
    sig = hmac.new(secret.encode(), qs.encode(), hashlib.sha256).hexdigest()
    return f"{qs}&signature={sig}"

def get_account():
    _sync_time()
    url = f"{_base()}/api/v3/account?{_sign({'timestamp':_ts(),'recvWindow':15000}, _sec())}"
    r = requests.get(url, headers={"X-MBX-APIKEY": _key()}, timeout=20); r.raise_for_status(); return r.json()

def list_balances(min_total=0.00000001):
    acct = get_account()
    rows=[]
    for b in acct.get("balances",[]):
        free=float(b.get("free",0) or 0); locked=float(b.get("locked",0) or 0); tot=free+locked
        if tot>=min_total: rows.append({"Asset":b["asset"],"Free":free,"Locked":locked,"Total":tot})
    return pd.DataFrame(rows).sort_values(by="Total", ascending=False)

def place_market_order(symbol:str, side:str, qty=None, quote_qty=None, test=False):
    if not (_key() and _sec()): raise RuntimeError("Missing API key/secret")
    if is_killed(): raise RuntimeError("Kill Switch is ON. Orders are blocked.")
    _sync_time()
    endpoint="/api/v3/order/test" if test else "/api/v3/order"
    params={"symbol":symbol.upper(),"side":side.upper(),"type":"MARKET","timestamp":_ts(),
            "recvWindow":15000,"newOrderRespType":"FULL"}
    if quote_qty is not None: params["quoteOrderQty"]=quote_qty
    elif qty is not None: params["quantity"]=qty
    else: raise ValueError("Provide either qty or quote_qty")
    url=f"{_base()}{endpoint}?{_sign(params,_sec())}"
    r=requests.post(url, headers={"X-MBX-APIKEY":_key()}, timeout=20); r.raise_for_status()
    return r.json() if not test else {}

# ---------- LEDGER ----------
LEDGER = PROJECT_ROOT/"logs"/"trades.xlsx"
PENDING= LEDGER.with_suffix(".pending.xlsx")
def safe_read_ledger():
    for p in (LEDGER,PENDING):
        if p.exists():
            try: return pd.read_excel(p, sheet_name="Trades", engine="openpyxl")
            except: continue
    return pd.DataFrame()

# ---------- Fee-aware P&L ----------
def kl_close(symbol:str, ts_ms:int):
    try:
        r=requests.get(f"{_base()}/api/v3/klines", params={"symbol":symbol,"interval":"1m","startTime":ts_ms-60000,"endTime":ts_ms+60000,"limit":1}, timeout=10)
        r.raise_for_status(); arr=r.json()
        if arr: return float(arr[0][4])
    except: pass
    try:
        r2=requests.get(f"{_base()}/api/v3/ticker/price", params={"symbol":symbol}, timeout=10); r2.raise_for_status()
        return float(r2.json()["price"])
    except: return None

_px_cache={}
def fee_to_usdt(asset:str, amt:float, ts_ms:int)->float:
    if not asset or amt==0: return 0.0
    asset=asset.upper()
    if asset in ("USDT","FDUSD","BUSD"): return float(amt)
    sym=f"{asset}USDT"; key=(sym, ts_ms//60000)
    if key not in _px_cache: _px_cache[key]= kl_close(sym, ts_ms) or 0.0
    return float(amt)*_px_cache[key] if _px_cache[key] else 0.0

def compute_fifo_feeaware(df:pd.DataFrame):
    if df.empty: return pd.DataFrame(), pd.DataFrame(), pd.DataFrame()
    df=df.copy()
    df["Symbol"]=df["Symbol"].astype(str).str.upper()
    df=df[df["Symbol"].str.endswith("USDT")]
    for col in ("FilledQty","AvgFillPrice","Fee"):
        if col in df.columns: df[col]=pd.to_numeric(df[col], errors="coerce").fillna(0.0)
    df["_dt"]=pd.to_datetime(df.get("DateUTC", None), errors="coerce")
    df=df.sort_values(by=["_dt"]).reset_index(drop=True)

    openlots={}  # sym -> list(dict qty, price, fee_usdt, base_qty_for_alloc)
    closed=[]
    for _, r in df.iterrows():
        sym=r["Symbol"]; side=str(r.get("Side","")).upper()
        qty=float(r.get("FilledQty",0)); px=float(r.get("AvgFillPrice",0))
        dt = pd.to_datetime(r.get("DateUTC") or r.get("DateLocal"), errors="coerce")
        ts_ms=int(dt.timestamp()*1000) if pd.notna(dt) else int(time.time()*1000)
        fee_amt=float(r.get("Fee",0)); fee_ccy=str(r.get("FeeAsset",""))
        fee_usdt=fee_to_usdt(fee_ccy, fee_amt, ts_ms)

        if qty<=0 or px<=0: continue
        q=openlots.setdefault(sym,[])
        if side=="BUY":
            q.append({"qty":qty,"price":px,"fee_usdt":fee_usdt,"orig_qty":qty})
        elif side=="SELL":
            remain=qty; realized=0.0; matched=0.0; cost_side_fees=0.0
            while remain>1e-15 and q:
                lot=q[0]; use=min(lot["qty"], remain)
                realized += use*(px-lot["price"])
                matched  += use
                # proportional allocation of buy-fee
                if lot["orig_qty"]>0:
                    cost_side_fees += lot["fee_usdt"] * (use/lot["orig_qty"])
                lot["qty"] -= use; remain -= use
                if lot["qty"]<=1e-15: q.pop(0)
            sell_fee_usdt=fee_usdt
            net=realized - cost_side_fees - sell_fee_usdt
            if matched>0:
                closed.append({"CloseDate":str(r.get("DateLocal") or r.get("DateUTC")),
                               "Symbol":sym,"Qty":round(matched,8),
                               "BuyAvgPrice":round((px-realized/matched),8),
                               "SellAvgPrice":round(px,8),
                               "GrossPnL_USDT":round(realized,8),
                               "Fees_USDT":round(cost_side_fees+sell_fee_usdt,8),
                               "RealizedPnL_USDT":round(net,8)})

    openrows=[]
    for sym,lots in openlots.items():
        tot=sum(l["qty"] for l in lots)
        if tot>1e-15:
            cost=sum(l["qty"]*l["price"] for l in lots)
            fees=sum(l["fee_usdt"] for l in lots)
            openrows.append({"Symbol":sym,"Qty":round(tot,8),"AvgCost":round(cost/tot,8),"BuyFees_USDT":round(fees,8)})

    daily=(pd.DataFrame(closed)
            .assign(Date=lambda x: pd.to_datetime(x["CloseDate"], errors="coerce").dt.date)
            .groupby("Date")[["RealizedPnL_USDT","Fees_USDT","GrossPnL_USDT"]].sum()
            .reset_index() if len(closed) else pd.DataFrame(columns=["Date","RealizedPnL_USDT","Fees_USDT","GrossPnL_USDT"]))
    return pd.DataFrame(closed), pd.DataFrame(openrows), daily

# ---------- Kill Switch ----------
KILL_PATH = PROJECT_ROOT/"config"/"kill_switch.on"
def is_killed(): return KILL_PATH.exists()
def set_kill(on: bool):
    KILL_PATH.parent.mkdir(parents=True, exist_ok=True)
    if on: KILL_PATH.write_text("ON", encoding="utf-8")
    else:
        try: KILL_PATH.unlink()
        except FileNotFoundError: pass

# ---------- UI ----------
st.set_page_config(page_title="Binance Bot Dashboard", layout="wide")
st.sidebar.title("⚙️ Controls")
env_choice = st.sidebar.selectbox("Environment", [".env.mainnet",".env.testnet",".env"], index=0)
use_env(env_choice)
st.sidebar.caption(f"Loaded: {os.getenv('ENV_FILE','')} • Base: {_base()}")

# Kill switch
ks = st.sidebar.toggle("🛑 Kill Switch (block orders)", value=is_killed())
set_kill(ks)

test_mode = st.sidebar.toggle("Test order (no fill)", value=True)
symbol = st.sidebar.text_input("Symbol", value="BTCUSDT")
side   = st.sidebar.selectbox("Side", ["BUY","SELL"])
mode   = st.sidebar.radio("Amount type", ["quoteQty (USDT)","qty (base)"])
quote_qty = st.sidebar.number_input("quoteQty", min_value=1.0, value=11.0, step=1.0) if mode.startswith("quoteQty") else None
qty       = st.sidebar.number_input("qty", min_value=0.00000001, value=0.001, step=0.00000001, format="%.8f") if quote_qty is None else None

if st.sidebar.button("🚀 Submit Market Order"):
    try:
        data = place_market_order(symbol, side, qty=qty, quote_qty=quote_qty, test=test_mode)
        if test_mode:
            st.success("TEST order accepted (no fill).")
        else:
            st.success("Order filled/accepted.")
            try:
                from scripts.excel_logger import log_order_fill
                path = log_order_fill(data, env=os.getenv("ENV_FILE",".env.mainnet"))
                st.toast(f"Logged to: {path}", icon="✅")
            except Exception as e:
                st.warning(f"Order placed, but logging failed: {e}")
    except Exception as e:
        st.error(str(e))

# Main panes
c1, c2 = st.columns([1,2])

with c1:
    st.subheader("💰 Balances")
    try:
        st.dataframe(list_balances(), use_container_width=True)
    except Exception as e:
        st.error(f"Balances error: {e}")

with c2:
    st.subheader("📒 Ledger (last 200)")
    df = safe_read_ledger()
    if df.empty:
        st.info("No ledger yet.")
    else:
        st.dataframe(df.tail(200), use_container_width=True)

# P&L
st.subheader("📈 P&L")
if df.empty:
    st.info("No trades to analyze.")
else:
    closed, openpos, daily = compute_fifo_feeaware(df)

    k1,k2,k3,k4 = st.columns(4)
    k1.metric("Realized P&L (USDT)", f"{closed['RealizedPnL_USDT'].sum():.2f}" if not closed.empty else "0.00")
    k2.metric("Fees (USDT)", f"{closed['Fees_USDT'].sum():.2f}" if not closed.empty else "0.00")
    wins = (closed["RealizedPnL_USDT"]>0).sum() if not closed.empty else 0
    trades = len(closed) if not closed.empty else 0
    k3.metric("Win Rate", f"{(wins/max(trades,1))*100:.1f}%")
    k4.metric("Closed Trades", f"{trades}")

    t1,t2,t3 = st.tabs(["Closed Trades","Open Positions","Daily P&L"])
    with t1:
        st.dataframe(closed, use_container_width=True)
    with t2:
        st.dataframe(openpos, use_container_width=True)
    with t3:
        st.dataframe(daily, use_container_width=True)
