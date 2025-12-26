# LLM Security Threat Model (OWASP LLM Top 10 aligned)
Controls:
- Input filtering: deny prompt-injection patterns; strip tool directives from user text
- Output filtering: prevent exfiltration of secrets/configs
- Tool allowlist: only permitted tools callable; all tool calls logged
- Instruction hierarchy: system > developer > user; refuse on conflict
- Rate limiting + audit trail for agent actions
Testing:
- Red-team prompt suite under tests/security/
