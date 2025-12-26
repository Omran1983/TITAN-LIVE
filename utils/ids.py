import time
import uuid

def new_uuid() -> str:
    return str(uuid.uuid4())

def new_ulidish() -> str:
    # not a real ULID, but stable enough for UI keys
    return f"{int(time.time()*1000)}-{uuid.uuid4().hex[:8]}"
