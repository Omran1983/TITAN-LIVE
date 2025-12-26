# LLM Security (OWASP-style) short checklist
- Input filters: strip prompts asking to reveal secrets/system.
- Output filters: block secrets/keys; redact tokens/envs.
- Tool allowlist: only approved ops callable by agents.
- Instruction hierarchy: system > developer > user.
- Anti-exfil: remove URLs to internal repos/logs from outputs.
- Log all tool calls with args; zero sensitive payloads in logs.
