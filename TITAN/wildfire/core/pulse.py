from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import List
import json
import asyncio

app = FastAPI()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                pass # Fail silently for dead connections

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep alive, maybe echo or receive commands later
            data = await websocket.receive_text()
            # await manager.broadcast({"message": f"Echo: {data}"})
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@app.post("/emit")
async def emit_event(event: dict):
    """
    Internal endpoint for agents to push events to the frontend.
    """
    await manager.broadcast(event)
    return {"status": "ok"}
