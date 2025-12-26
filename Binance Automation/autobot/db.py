# autobot/db.py
import os, sqlite3, time
DB_PATH = os.path.join("runtime","autobot.db")

def _con():
    os.makedirs("runtime", exist_ok=True)
    return sqlite3.connect(DB_PATH, isolation_level=None)

def ensure():
    with _con() as c:
        c.execute("""CREATE TABLE IF NOT EXISTS trades(
            trade_id INTEGER PRIMARY KEY,
            ts INTEGER, symbol TEXT, side TEXT,
            qty REAL, price REAL, quote_qty REAL,
            commission REAL, commission_asset TEXT,
            order_id INTEGER, is_maker INTEGER
        )""")
        c.execute("CREATE INDEX IF NOT EXISTS idx_trades_ts ON trades(ts)")
        c.execute("""CREATE TABLE IF NOT EXISTS events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts INTEGER, level TEXT, message TEXT
        )""")

def put_event(level, msg):
    with _con() as c:
        c.execute("INSERT INTO events(ts,level,message) VALUES (?,?,?)", (int(time.time()*1000), level, msg))

def upsert_trade(row: dict):
    with _con() as c:
        c.execute("""INSERT OR IGNORE INTO trades
            (trade_id,ts,symbol,side,qty,price,quote_qty,commission,commission_asset,order_id,is_maker)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
            (int(row["id"]), int(row["time"]), row["symbol"], ("SELL" if row.get("isBuyer")==False else "BUY"),
             float(row["qty"]), float(row["price"]), float(row["quoteQty"]),
             float(row.get("commission",0) or 0), row.get("commissionAsset") or "",
             int(row.get("orderId",0)), 1 if row.get("isMaker") else 0))
