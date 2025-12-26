Jarvis Local Ops Cluster
========================

This folder contains your local automation "brain" for Jarvis / AION-ZERO.

Main pieces:
- docker-compose.yml : runs Ollama, board-llm, and PS-based agents
- .env               : Supabase + Ollama + general config
- scripts\           : PowerShell agents
- services\          : supporting services (board-llm, helpers)
- logs\              : log output from agents
- config\            : JSON rule files

Quick start (after filling .env):

  cd F:\Jarvis-LocalOps
  docker compose up -d

