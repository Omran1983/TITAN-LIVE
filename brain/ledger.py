# F:\AION-ZERO\brain\ledger.py
import os, json, sqlite3, hashlib, re
from datetime import datetime, timezone
from uuid import uuid4

ROOT = r"F:\AION-ZERO"
DB_PATH = os.environ.get("AZ_LEDGER_DB", r"F:\AION-ZERO\brain\ledger.db")

# Redact BOTH: known env values + key=value patterns
REDACT_KEYS = [
    "SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_ANON_KEY",
    "GOOGLE_API_KEY",
    "GOOGLE_AI_KEY",
    "JARVIS_COMMANDS_API_KEY",
]

# Hard limits to prevent DB bloat
MAX_TEXT = 200_000          # cap any single stored blob
MAX_ARTIFACT_PREVIEW = 2_000

def _now():
    # store as UTC (stable across machines)
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

def _json(x):
    try:
        return json.dumps(x, ensure_ascii=False)
    except Exception:
        return json.dumps(str(x), ensure_ascii=False)

def _hash_text(s: str) -> str:
    return hashlib.sha256((s or "").encode("utf-8", errors="ignore")).hexdigest()

def _clip(s: str, n: int) -> str:
    if not s:
        return s
    return s if len(s) <= n else (s[:n] + "…")

def _redact(text: str) -> str:
    """
    Best-effort redaction:
      - replaces actual secret VALUES if present in env
      - redacts patterns like KEY=xxxxx or "KEY":"xxxxx"
    Never rewrites the key name itself (prevents corrupting code/JSON).
    """
    if not text:
        return text

    t = text

    # 1) redact any actual env secret values
    for k in REDACT_KEYS:
        val = os.environ.get(k)
        if val and isinstance(val, str) and val.strip():
            t = t.replace(val, "[REDACTED]")

    # 2) redact KEY=... patterns (dotenv style)
    for k in REDACT_KEYS:
        # KEY=something (until newline)
        t = re.sub(rf"({re.escape(k)}\s*=\s*)([^\n\r]+)", r"\1[REDACTED]", t)

        # "KEY": "something"
        t = re.sub(rf'("{re.escape(k)}"\s*:\s*")([^"]+)(")', r'\1[REDACTED]\3', t)

        # 'KEY': 'something'
        t = re.sub(rf"('{re.escape(k)}'\s*:\s*')([^']+)(')", r"\1[REDACTED]\3", t)

    # 3) clip to protect DB size
    return _clip(t, MAX_TEXT)

def connect():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    con = sqlite3.connect(DB_PATH, timeout=10)  # busy timeout fallback
    # Hardening
    con.execute("PRAGMA journal_mode=WAL;")
    con.execute("PRAGMA synchronous=NORMAL;")
    con.execute("PRAGMA foreign_keys=ON;")
    con.execute("PRAGMA busy_timeout=5000;")
    return con

def init():
    with connect() as con:
        con.execute("""
        CREATE TABLE IF NOT EXISTS az_events (
            id TEXT PRIMARY KEY,
            ts TEXT NOT NULL,
            project TEXT,
            actor TEXT,
            event_type TEXT NOT NULL,
            intent TEXT,
            input TEXT,
            output TEXT,
            status TEXT,
            error TEXT,
            risk_level TEXT,
            correlation_id TEXT,
            parent_id TEXT,
            tags TEXT
        )""")
        con.execute("""
        CREATE TABLE IF NOT EXISTS az_outcomes (
            id TEXT PRIMARY KEY,
            event_id TEXT NOT NULL,
            ts TEXT NOT NULL,
            metric TEXT NOT NULL,
            value REAL,
            unit TEXT,
            target REAL,
            score REAL,
            verdict TEXT,
            evidence TEXT,
            lesson TEXT,
            next_action TEXT,
            FOREIGN KEY(event_id) REFERENCES az_events(id) ON DELETE CASCADE
        )""")
        con.execute("""
        CREATE TABLE IF NOT EXISTS az_artifacts (
            id TEXT PRIMARY KEY,
            ts TEXT NOT NULL,
            event_id TEXT NOT NULL,
            kind TEXT NOT NULL,
            path TEXT,
            before_hash TEXT,
            after_hash TEXT,
            preview TEXT,
            content TEXT,
            FOREIGN KEY(event_id) REFERENCES az_events(id) ON DELETE CASCADE
        )""")

        # Indexes (this matters once you start querying in the UI)
        con.execute("CREATE INDEX IF NOT EXISTS idx_events_ts ON az_events(ts)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_events_corr ON az_events(correlation_id)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_events_type ON az_events(event_type)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_events_project ON az_events(project)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_outcomes_event ON az_outcomes(event_id)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_artifacts_event ON az_artifacts(event_id)")
        con.commit()

def log_event(*, project=None, actor=None, event_type="unknown", intent=None,
              input=None, output=None, status=None, error=None,
              risk_level="low", correlation_id=None, parent_id=None, tags=None):
    eid = str(uuid4())
    cid = correlation_id or str(uuid4())

    row = (
        eid, _now(), project, actor, event_type, intent,
        _redact(_json(input)),
        _redact(_json(output)),
        status,
        _redact(str(error) if error else None),
        risk_level, cid, parent_id, _json(tags or []),
    )

    with connect() as con:
        con.execute("""INSERT INTO az_events
        (id, ts, project, actor, event_type, intent, input, output, status, error, risk_level, correlation_id, parent_id, tags)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", row)
        con.commit()

    return {"event_id": eid, "correlation_id": cid}

def log_outcome(*, event_id: str, metric: str, value=None, unit=None, target=None,
                score=None, verdict=None, evidence=None, lesson=None, next_action=None):
    oid = str(uuid4())
    row = (
        oid, event_id, _now(), metric, value, unit, target, score, verdict,
        _redact(_json(evidence)),
        _clip(_redact(lesson) if lesson else None, 10_000),
        _clip(_redact(next_action) if next_action else None, 10_000),
    )
    with connect() as con:
        con.execute("""INSERT INTO az_outcomes
        (id, event_id, ts, metric, value, unit, target, score, verdict, evidence, lesson, next_action)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", row)
        con.commit()
    return oid

def log_artifact(*, event_id: str, kind: str, path: str, before_text: str = "", after_text: str = "", content: str = ""):
    """
    Stores hashes + a tiny safe preview for debugging.
    'content' is optional — keep it empty unless you explicitly want it.
    """
    aid = str(uuid4())

    before_hash = _hash_text(before_text)
    after_hash = _hash_text(after_text)

    # Preview: redacted diff-friendly slice (not full file)
    preview_src = (after_text or before_text or "")
    preview = _clip(_redact(preview_src), MAX_ARTIFACT_PREVIEW)

    row = (
        aid, _now(), event_id, kind, path,
        before_hash, after_hash,
        preview,
        _clip(_redact(content), MAX_TEXT),
    )

    with connect() as con:
        con.execute("""INSERT INTO az_artifacts
        (id, ts, event_id, kind, path, before_hash, after_hash, preview, content)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""", row)
        con.commit()
    return aid
