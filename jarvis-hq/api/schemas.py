from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime


class CommandPayload(BaseModel):
    tool_name: str = Field(..., description="Name of the tool to execute, e.g. 'ps.run' or 'python.script'")
    args: Dict[str, Any] = Field(default_factory=dict, description="Arguments to the tool")


class EnqueuedCommand(BaseModel):
    id: Optional[str] = None
    source: str = "manual"
    priority: int = 10
    payload: CommandPayload
    requested_by: Optional[str] = None
    created_at: Optional[datetime] = None
