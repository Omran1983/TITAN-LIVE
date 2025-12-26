import json
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, Any, Optional

class CapabilityRegistry:
    def __init__(self, db_url: str):
        self.db_url = db_url

    def db(self):
        return psycopg2.connect(self.db_url, cursor_factory=RealDictCursor)

    def upsert_capability(self, kind: str, name: str, category: str, capability_meta: dict, source_artifact_id: Optional[str] = None) -> dict:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    insert into az_capabilities(kind, name, category, capability_meta, source_artifact_id)
                    values (%s,%s,%s,%s,%s)
                    returning *
                    """,
                    (kind, name, category, json.dumps(capability_meta), source_artifact_id)
                )
                row = cur.fetchone()
                conn.commit()
                return dict(row)

    def list_capabilities(self, limit: int = 200) -> list[dict]:
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute("select * from az_capabilities order by created_at desc limit %s", (limit,))
                rows = cur.fetchall()
                return [dict(r) for r in rows]
