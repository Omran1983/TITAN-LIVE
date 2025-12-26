from typing import Any, Dict
import httpx

from .config import load_config


class SupabaseClient:
    def __init__(self) -> None:
        cfg = load_config()
        base_url = cfg.get("supabase_url")
        key = cfg.get("supabase_service_role_key")

        if not base_url or not key:
            raise RuntimeError(
                "Supabase is not configured. "
                "Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the environment."
            )

        # Strip trailing slash if present
        self.base_url = base_url.rstrip("/")
        self.key = key

    @property
    def headers(self) -> Dict[str, str]:
        return {
            "apikey": self.key,
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }

    async def insert_command(self, record: Dict[str, Any]) -> Dict[str, Any]:
        """
        Insert a single command record into az_commands using Supabase REST.
        """
        url = f"{self.base_url}/rest/v1/az_commands"

        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, headers=self.headers, json=record, params={"select": "*"})
            resp.raise_for_status()
            data = resp.json()
            # Supabase returns a list when Prefer=return=representation
            if isinstance(data, list) and data:
                return data[0]
            return data
