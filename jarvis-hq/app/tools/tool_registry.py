ToolRegistry.register(
    name="reachx.env.apply",
    description="Apply correct SUPABASE env to ReachX UI",
    schema={
        "type": "object",
        "properties": {
            "project_root": {"type": "string"}
        },
        "required": []
    }
)
