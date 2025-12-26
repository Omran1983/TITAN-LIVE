# autobot/agent.py
import os, sys, time, sqlite3, json, traceback
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

DB_PATH = os.path.join(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")), "runtime", "autobot.db")
ROOT    = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RUNTIME = os.path.join(ROOT, "runtime")
STOPF   = os.path.join(ROOT, "STOP.AUTO")
CFG     = os.path.join(ROOT, "config.yaml")

def now_ms():
    return int(datetime.now(timezone.utc).timestamp() * 1000)

def log(msg):
    # prints go to bot_streamlit.log because we redirect stdout/err from PowerShell
    print(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), msg, flush=True)

def open_db():
    os.makedirs(RUNTIME, exist_ok=True)
    con = sqlite3.connect(DB_PATH)
    con.execute("""CREATE TABLE IF NOT EXISTS events(
        ts INTEGER, level TEXT, src TEXT, msg TEXT
    )""")
    con.execute("""CREATE TABLE IF NOT EXISTS trades(
        ts INTEGER, symbol TEXT, id TEXT, orderId TEXT, side TEXT,
        qty REAL, price REAL, quoteQty REAL, isBuyer BOOLEAN, isMaker BOOLEAN, isBestMatch BOOLEAN
    )""")
    con.commit()
    return con

def ev(con, level, src, msg):
    con.execute("INSERT INTO events(ts,level,src,msg) VALUES(?,?,?,?)", (now_ms(), level, src, msg))
    con.commit()

def load_symbols():
    import yaml
    try:
        with open(CFG, "r", encoding="utf-8") as f:
            cfg = yaml.safe_load(f) or {}
        syms = cfg.get("account", {}).get("symbols", ["BTCUSDT","ETHUSDT"])
        if isinstance(syms, list) and syms:
            return syms
    except Exception:
        pass
    return ["BTCUSDT","ETHUSDT"]

def get_client():
    try:
        from binance.spot import Spot as S
    except Exception:
        return None, "binance-connector not importable"
    env = (os.getenv("ENV") or "MAINNET").upper()
    ak  = os.getenv("BINANCE_API_KEY")
    sk  = os.getenv("BINANCE_API_SECRET")
    base = None
    if env == "TESTNET":
        base = "https://testnet.binance.vision"
    elif env == "BINANCE_US":
        base = "https://api.binance.us"
    try:
        cli = S(api_key=ak, api_secret=sk) if base is None else S(base_url=base, api_key=ak, api_secret=sk)
        _ = cli.ping()
        return cli, None
    except Exception as e:
        return None, str(e)

def backfill_last_2_days(cli, con, symbols):
    start = int((datetime.now(timezone.utc) - timedelta(days=2)).timestamp() * 1000)
    wrote = 0
    for sym in symbols:
        try:
            rows = cli.my_trades(sym, startTime=start)  # spot account trades
            for r in rows:
                # avoid dup insert by (symbol,id)
                exists = con.execute("SELECT 1 FROM trades WHERE symbol=? AND id=?", (sym, str(r.get("id")))).fetchone()
                if exists: continue
                con.execute("""INSERT INTO trades(ts,symbol,id,orderId,side,qty,price,quoteQty,isBuyer,isMaker,isBestMatch)
                               VALUES(?,?,?,?,?,?,?,?,?,?,?)""",
                            (int(r.get("time",0)), sym, str(r.get("id")),
                             str(r.get("orderId")), ("BUY" if r.get("isBuyer") else "SELL"),
                             float(r.get("qty",0) or r.get("qty")), float(r.get("price",0)),
                             float(r.get("quoteQty",0)), bool(r.get("isBuyer")), bool(r.get("isMaker")), bool(r.get("isBestMatch"))))
                wrote += 1
            con.commit()
        except Exception as e:
            ev(con, "WARN", "backfill", f"{sym} error: {e}")
    return wrote

def main():
    # load env first
    load_dotenv(os.path.join(ROOT, ".env.mainnet"))
    os.makedirs(RUNTIME, exist_ok=True)
    con = open_db()
    ev(con, "INFO", "agent", "Booting agent")

    cli, err = get_client()
    if not cli:
        ev(con, "ERROR", "auth", f"Binance client not available: {err}")
        log(f"[AUTH] FAIL: {err}")
        time.sleep(3)
        return

    symbols = load_symbols()
    ev(con, "INFO", "agent", f"Symbols: {symbols}")
    log(f"ENV={os.getenv('ENV','MAINNET')} symbols={symbols}")

    wrote = backfill_last_2_days(cli, con, symbols)
    ev(con, "INFO", "backfill", f"wrote={wrote}")

    # main loop: simple heartbeat; expand with your strategy later
    while True:
        if os.path.exists(STOPF):
            ev(con, "INFO", "agent", "STOP.AUTO detected — exiting")
            log("STOP requested — exit.")
            break
        try:
            # lightweight heartbeat: account weight but proves auth is alive
            _ = cli.ping()
        except Exception as e:
            ev(con, "ERROR", "heartbeat", str(e))
        time.sleep(20)

if __name__ == "__main__":
    try:
        main()
    except Exception:
        try:
            with open(os.path.join(RUNTIME,"agent_crash.txt"), "a", encoding="utf-8") as f:
                f.write(traceback.format_exc()+"\n")
        finally:
            raise
