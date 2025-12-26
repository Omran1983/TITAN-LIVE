# -*- coding: utf-8 -*-
# Add project root to path
import os, sys, time, sqlite3
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

import streamlit as st
import pandas as pd

# Load .env.mainnet automatically (optional)
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(ROOT, ".env.mainnet"))
except Exception:
    pass

# Local modules
try:
    from autobot.config_io import load_config, set_symbols, set_risk_tier, update_risk_param
except Exception as e:
    st.stop()

# Telemetry (optional)
def send_alert(msg: str) -> bool:
    try:
        from autobot import telemetry
        return bool(telemetry.send(msg))
    except Exception:
        return False

# Binance client (binance-connector)
try:
    from binance.spot import Spot as BinanceSpot
except Exception:
    BinanceSpot = None

DB_PATH = os.path.join(ROOT, "runtime", "autobot.db")
ENV = os.getenv("ENV", "MAINNET")

st.set_page_config(page_title="AutoBot Console", layout="wide")
st.title("AutoBot — Binance Live Console")

# ---------- helpers ----------
def read_db(table: str, limit: int = 500) -> pd.DataFrame:
    if not os.path.exists(DB_PATH):
        return pd.DataFrame()
    con = sqlite3.connect(DB_PATH)
    try:
        return pd.read_sql_query(f"SELECT * FROM {table} ORDER BY ts DESC LIMIT {limit}", con)
    except Exception:
        return pd.DataFrame()
    finally:
        con.close()

def get_binance_client():
    if not BinanceSpot:
        return None
    if ENV.upper() == "TESTNET":
        return BinanceSpot(
            base_url="https://testnet.binance.vision",
            api_key=os.getenv("BINANCE_API_KEY_TESTNET"),
            api_secret=os.getenv("BINANCE_API_SECRET_TESTNET"),
        )
    return BinanceSpot(
        api_key=os.getenv("BINANCE_API_KEY"),
        api_secret=os.getenv("BINANCE_API_SECRET"),
    )

def live_equity_usdt():
    cli = get_binance_client()
    if cli is None:
        return None, pd.DataFrame()
    try:
        acc = cli.account()
        rows = []
        for b in acc.get("balances", []):
            qty = float(b.get("free", 0.0)) + float(b.get("locked", 0.0))
            if qty > 0:
                rows.append({"asset": b["asset"], "qty": qty})
        df = pd.DataFrame(rows)
        total, prices = 0.0, {}
        for _, r in df.iterrows():
            asset, qty = r["asset"], r["qty"]
            if asset == "USDT":
                prices[asset] = 1.0
                total += qty
            else:
                sym = f"{asset}USDT"
                try:
                    px = float(cli.ticker_price(sym)["price"])
                    prices[asset] = px
                    total += qty * px
                except Exception:
                    prices[asset] = 0.0
        if not df.empty:
            df["price_usdt"] = df["asset"].map(prices).fillna(0.0)
            df["value_usdt"] = df["qty"] * df["price_usdt"]
            df = df.sort_values("value_usdt", ascending=False)
        return total, df
    except Exception:
        return None, pd.DataFrame()

def start_bot():
    # run module in background, log to runtime\bot_streamlit.log
    log = os.path.join(ROOT, "runtime", "bot_streamlit.log")
    cmd = f'python -m autobot.agent > "{log}" 2>&1'
    os.system(f'start /B cmd /C "{cmd}"')

def stop_bot():
    with open(os.path.join(ROOT, "STOP.AUTO"), "w", encoding="utf-8") as f:
        f.write("stop")

def exists(path: str) -> bool:
    return os.path.exists(path)

# ---------- sidebar ----------
st.sidebar.header("Controls")
env_badge = ":green[MAINNET]" if ENV.upper() == "MAINNET" else ":orange[TESTNET]"
st.sidebar.markdown(f"**Environment:** {env_badge}")

if st.sidebar.button("▶ Start Bot"):
    start_bot()
    st.sidebar.success("Bot start signalled.")

if st.sidebar.button("⏹ Stop Bot"):
    stop_bot()
    st.sidebar.warning("STOP.AUTO created. Bot exits next tick.")

if st.sidebar.button("🛰 Telegram Test"):
    ok = send_alert("AutoBot console test ✅")
    st.sidebar.success("Sent ✅" if ok else "Not sent ❌")

# ---------- config ----------
cfg = load_config()
st.subheader("Configuration")

colA, colB = st.columns(2)
with colA:
    st.markdown("**Symbols**")
    default_syms = cfg.get("account", {}).get("symbols", ["BTCUSDT", "ETHUSDT"])
    options = ["BTCUSDT","ETHUSDT","BNBUSDT","SOLUSDT","XRPUSDT","DOGEUSDT","ADAUSDT","TONUSDT","LINKUSDT","AVAXUSDT"]
    cur = st.multiselect("Trading Symbols", options=options, default=default_syms)
    if st.button("Save Symbols"):
        set_symbols(cur)
        st.success("Symbols updated. Restart bot to apply.")

with colB:
    st.markdown("**Risk Tier**")
    tiers = list(cfg.get("risk", {}).get("tiers", {}).keys())
    tier_default = cfg.get("risk", {}).get("tier_default", tiers[0] if tiers else "Balanced")
    sel_tier = st.selectbox("Active Tier", tiers if tiers else [tier_default],
                            index=(tiers.index(tier_default) if tiers and tier_default in tiers else 0))
    if st.button("Use Selected Tier"):
        set_risk_tier(sel_tier)
        st.success(f"Risk tier set: {sel_tier}")
    if tiers:
        active = cfg["risk"]["tiers"][sel_tier]
        c1, c2 = st.columns(2)
        with c1:
            pr = st.number_input("Per-trade risk %", value=float(active.get("per_trade_risk_pct", 0.30)),
                                 step=0.05, min_value=0.05, max_value=2.0)
            dd = st.number_input("Max drawdown % (halt)", value=float(active.get("max_drawdown_pct", 5.0)),
                                 step=0.5, min_value=1.0, max_value=20.0)
            if st.button("Save Risk Knobs"):
                update_risk_param("per_trade_risk_pct", float(pr))
                update_risk_param("max_drawdown_pct", float(dd))
                st.success("Risk parameters saved.")
        with c2:
            dl = st.number_input("Daily loss limit %", value=float(active.get("daily_loss_limit_pct", 2.0)),
                                 step=0.5, min_value=0.5, max_value=10.0)
            wl = st.number_input("Weekly loss limit %", value=float(active.get("weekly_loss_limit_pct", 5.0)),
                                 step=0.5, min_value=1.0, max_value=20.0)
            if st.button("Save Loss Caps"):
                update_risk_param("daily_loss_limit_pct", float(dl))
                update_risk_param("weekly_loss_limit_pct", float(wl))
                st.success("Loss caps saved.")

st.divider()

# ---------- live account ----------
st.subheader("Account — Live Equity & Balances")
eq, bal_df = live_equity_usdt()
c1, c2 = st.columns([1, 2])
with c1:
    if eq is None:
        st.info("Binance client not available or keys missing.")
    else:
        st.metric("Estimated Spot Equity (USDT)", f"{eq:,.2f}")
with c2:
    if bal_df is not None and not bal_df.empty:
        st.dataframe(bal_df, use_container_width=True, height=280)
    else:
        st.caption("No non-zero balances yet.")

st.divider()

# ---------- bot status ----------
st.subheader("Bot Status")
stop_present = exists(os.path.join(ROOT, "STOP.AUTO"))
status_hint = "Stop requested" if stop_present else "Likely running (check log)"
st.markdown(f"- **STOP.AUTO present**: `{stop_present}`")
st.markdown(f"- **Status hint**: {status_hint}")

log_path = os.path.join(ROOT, "runtime", "bot_streamlit.log")
if os.path.exists(log_path):
    with st.expander("View latest log (tail)"):
        try:
            text = open(log_path, "r", encoding="utf-8", errors="ignore").read()
            st.code(text[-6000:] if text else "No logs yet.", language="text")
        except Exception:
            st.caption("Unable to read log.")

st.divider()

# ---------- trades & events ----------
st.subheader("Trade Blotter")
try:
    t = read_db("trades", 500)
    if not t.empty:
        st.dataframe(t, use_container_width=True, height=300)
    else:
        st.caption("No trades recorded yet.")
except Exception:
    st.caption("Trade table not available.")

st.subheader("Events")
try:
    e = read_db("events", 200)
    if not e.empty:
        st.dataframe(e, use_container_width=True, height=240)
    else:
        st.caption("No events recorded yet.")
except Exception:
    st.caption("Event table not available.")

st.caption("Tip: after editing config, press Stop, wait a few seconds, then Start.")
st.divider()
st.subheader("PnL — Last 2 Days (raw trades)")
try:
    from app.agent_pnl_snippet import pnl_last_2d_table
    pnl_last_2d_table()
except Exception as _e:
    st.caption(f"PnL view error: {_e}")
