# app/agent_pnl_snippet.py
import os, sqlite3, pandas as pd
from datetime import datetime, timedelta, timezone

def pnl_last_2d_table():
    import streamlit as st
    DB_PATH = os.path.join("runtime","autobot.db")
    if not os.path.exists(DB_PATH):
        st.caption("No DB yet.")
        return
    con = sqlite3.connect(DB_PATH)
    t0 = int((datetime.now(timezone.utc) - timedelta(days=2)).timestamp()*1000)
    df = pd.read_sql_query("SELECT * FROM trades WHERE ts >= ? ORDER BY ts DESC", con, params=(t0,))
    con.close()
    if df.empty:
        st.caption("No trades in the last 2 days.")
        return
    st.dataframe(df, use_container_width=True, height=320)
