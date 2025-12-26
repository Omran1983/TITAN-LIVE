import asyncio
import os
from datetime import datetime
from logging_config import log

class HealthMonitor:
    """
    Writes a heartbeat to a file/DB. 
    The 'Citadel' UI watches this. If it stops updating, it sounds the alarm.
    """
    def __init__(self):
        self.heartbeat_file = "live/heartbeat.json"
        
    async def run(self):
        log.info("Health Monitor active.")
        while True:
            try:
                import json
                with open(self.heartbeat_file, 'w') as f:
                    json.dump({
                        "status": "ONLINE",
                        "timestamp": datetime.now().isoformat(),
                        "component": "ControlPlane"
                    }, f)
            except Exception as e:
                log.error(f"Health Monitor Failed: {e}")
                
            await asyncio.sleep(10)
