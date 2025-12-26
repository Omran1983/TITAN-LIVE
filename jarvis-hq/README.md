# Jarvis HQ

Central control plane for Jarvis / AION-ZERO.

Structure:
- api/          FastAPI control-plane API
- runner/       Local executors (PowerShell, Python, etc.)
- telegram/     Telegram -> Jarvis command gateway
- config/       TOML-based config (non-secret)
- docker/       Docker Compose definitions
- scripts/      Helper scripts (Run-Api, Run-TelegramBot)
- logs/         Runtime logs

Next steps:
1. Create a virtualenv and install requirements.
2. Configure .env from .env.example.
3. Run API and Telegram bot (locally or via Docker).
4. Wire Supabase az_commands and full queue logic.
