import time
import psycopg2
from psycopg2.extras import RealDictCursor

def db_ping(db_url: str) -> dict:
    t0 = time.time()
    try:
        conn = psycopg2.connect(db_url, cursor_factory=RealDictCursor)
        cur = conn.cursor()
        cur.execute("select now() as now;")
        row = cur.fetchone()
        conn.close()
        return {"ok": True, "latency_ms": int((time.time() - t0) * 1000), "now": str(row["now"])}
    except Exception as e:
        return {"ok": False, "error": str(e)}

def service_health() -> dict:
    return {"ok": True, "service": "titan_server", "ts": int(time.time())}
