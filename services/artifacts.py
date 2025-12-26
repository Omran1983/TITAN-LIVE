import os
import json
import hashlib
from pathlib import Path
from typing import Tuple, Dict, Any, Optional
import psycopg2
from psycopg2.extras import RealDictCursor

class ArtifactStore:
    def __init__(self, db_url: str, artifact_dir: str):
        self.db_url = db_url
        self.artifact_dir = Path(artifact_dir)
        self.artifact_dir.mkdir(parents=True, exist_ok=True)

    def db(self):
        return psycopg2.connect(self.db_url, cursor_factory=RealDictCursor)

    def _sha256(self, b: bytes) -> str:
        return hashlib.sha256(b).hexdigest()

    def save_raw(self, source_type: str, source_uri: str, raw_bytes: bytes,
                 parsed: Optional[dict] = None, meta: Optional[dict] = None) -> Dict[str, Any]:
        parsed = parsed or {}
        meta = meta or {}

        h = self._sha256(raw_bytes)
        # Dedup by hash
        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute("select * from az_artifacts where content_hash=%s", (h,))
                existing = cur.fetchone()
                if existing:
                    return dict(existing)

        # Persist raw to disk
        filename = f"{h}.bin"
        raw_path = self.artifact_dir / filename
        raw_path.write_bytes(raw_bytes)

        with self.db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    insert into az_artifacts(source_type, source_uri, content_hash, raw_path, parsed, meta)
                    values (%s,%s,%s,%s,%s,%s)
                    returning *
                    """,
                    (source_type, source_uri, h, str(raw_path), json.dumps(parsed), json.dumps(meta))
                )
                row = cur.fetchone()
                conn.commit()
                return dict(row)
