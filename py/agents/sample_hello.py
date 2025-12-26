NAME = "hello_world"
DESC = "Demo plugin agent that returns a greeting."

def run(params: dict) -> dict:
    who = params.get("who","AZ")
    return {"ok": True, "msg": f"Hello, {who}!"}
