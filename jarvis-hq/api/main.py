from fastapi import FastAPI
from .routers import commands

app = FastAPI(
    title="Jarvis HQ Control Plane",
    version="0.1.0",
    description="Central API for Jarvis/AION-ZERO commands, tools and workers."
)

app.include_router(commands.router, prefix="/api/commands", tags=["commands"])


@app.get("/health")
async def health():
    return {"status": "ok"}
