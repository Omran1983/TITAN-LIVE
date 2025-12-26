import json
import time
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Optional

class SelfHeal:
    def __init__(self, db_url: str):
        self.db_url = db_url

    def db(self):
        return psycopg2.connect(self.db_url, cursor_factory=RealDictCursor)

    def open_incident(self, kind: str, severity: str, summary: str, evidence: dict) -> str:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    insert into az_incidents(kind, severity, summary, evidence)
                    values (%s,%s,%s,%s)
                    returning id
                    """,
                    (kind, severity, summary, json.dumps(evidence))
                )
                row = cur.fetchone()
                conn.commit()
                return str(row["id"])

    def mark_fixed(self, incident_id: str) -> None:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute("update az_incidents set status='FIXED' where id=%s", (incident_id,))
                conn.commit()
