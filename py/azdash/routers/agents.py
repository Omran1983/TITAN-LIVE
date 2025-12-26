from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from ..agents.registry import list_agents, run_agent
from ..jobs import new_job, update_job, list_jobs, Job, _now

router = APIRouter()

class RunReq(BaseModel):
    name: str
    params: dict | None = None

@router.get("/", summary="List agents")
def list_agents_route():
    return {"ok": True, "agents": list_agents()}

@router.post("/run", summary="Run an agent immediately")
def run_agent_route(req: RunReq):
    try:
        res = run_agent(req.name, req.params or {})
        return {"ok": True, "result": res}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/run_job", summary="Queue and run in background")
def run_job_route(req: RunReq, bg: BackgroundTasks):
    job = new_job(req.name, req.params or {})
    def _work(jid: str, name: str, params: dict):
        j = Job(id=jid, name=name, params=params, status="running", created_at=_now(), started_at=_now())
        update_job(j)
        try:
            res = run_agent(name, params or {})
            j.status="done"; j.result=res; j.finished_at=_now()
        except Exception as e:
            j.status="error"; j.error=str(e); j.finished_at=_now()
        finally:
            update_job(j)
    bg.add_task(_work, job.id, req.name, req.params or {})
    return {"ok": True, "job": job.__dict__}

@router.get("/jobs", summary="List job statuses")
def jobs_route(limit: int = 50):
    return {"ok": True, "jobs": list_jobs(limit)}
