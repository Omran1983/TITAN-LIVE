from fastapi import APIRouter, HTTPException
from typing import List
from httpx import HTTPStatusError

from ..schemas import EnqueuedCommand
from ..supabase_client import SupabaseClient

router = APIRouter()

_sb_client: SupabaseClient | None = None


def get_client() -> SupabaseClient:
    global _sb_client
    if _sb_client is None:
        _sb_client = SupabaseClient()
    return _sb_client


@router.post("/", response_model=EnqueuedCommand)
async def enqueue_command(cmd: EnqueuedCommand):
    """
    Enqueue a command into existing az_commands table.

    We map our generic EnqueuedCommand model into YOUR schema:

    az_commands columns (from swagger):
      id, project, target_agent, command, args, status,
      created_at, picked_at, completed_at, error, agent,
      action, command_type, payload_json, updated_at,
      project_id, agent_id, department_id, priority, scheduled_at
    """
    if not cmd.payload or not cmd.payload.tool_name:
        raise HTTPException(status_code=400, detail="payload.tool_name is required")

    # Map our generic model into az_commands row
    record = {
        # Which project this belongs to (logical label)
        "project": "jarvis-hq",

        # The main command string – we use the tool name here
        "command": cmd.payload.tool_name,

        # Keep args in the dedicated JSONB column
        "args": cmd.payload.args or {},

        # Mark as queued for workers
        "status": "queued",

        # Priority column already exists in your table
        "priority": cmd.priority,

        # Who is “issuing” this from our side
        "agent": "jarvis-hq-api",

        # Extra structured info goes into payload_json (also JSONB)
        "payload_json": {
            "source": cmd.source,
            "requested_by": cmd.requested_by,
        },

        # Optional “type”/“action” for your older flows
        "command_type": "tool",
        "action": "run",
    }

    try:
        client = get_client()
        saved = await client.insert_command(record)
    except HTTPStatusError as e:
        # Bubble up a clearer error to the caller
        msg = f"Supabase HTTP {e.response.status_code}: {e.response.text}"
        raise HTTPException(status_code=500, detail=f"Failed to persist command: {msg}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to persist command: {e!r}")

    # Map DB row back into our API model
    cmd.id = str(saved.get("id")) if saved.get("id") is not None else cmd.id

    # Try to populate created_at if present
    if "created_at" in saved:
        from datetime import datetime

        try:
            raw = saved["created_at"]
            if isinstance(raw, str):
                cmd.created_at = datetime.fromisoformat(raw.replace("Z", "+00:00"))
        except Exception:
            # Not critical – we can ignore parse errors
            pass

    return cmd


@router.get("/", response_model=List[EnqueuedCommand])
async def list_commands():
    """
    For now, just return an empty list.
    You already have dashboards directly on Supabase.
    """
    return []
