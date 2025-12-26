from pydantic import BaseModel
from typing import Dict, Any, List, Optional

class PlanStep(BaseModel):
    step_id: str
    tool: str
    action: Dict[str, Any]

class Plan(BaseModel):
    task_id: str
    goal: str
    steps: List[PlanStep]
    success_criteria: List[str]

class PlanRequest(BaseModel):
    task_id: str
    goal: str
    context: Dict[str, Any]
    limits: Dict[str, Any]

class PlanResponse(BaseModel):
    status: str
    plan: Plan
