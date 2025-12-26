import os
from pathlib import Path
from dotenv import load_dotenv

def load_env() -> str | None:
    """
    Loads environment variables from an .env file.
    Priority:
      1) $ENV_FILE (relative to project root)
      2) .env
      3) .env.mainnet
      4) .env.testnet
    """
    project_root = Path(__file__).resolve().parents[1]
    env_name = os.getenv("ENV_FILE", "").strip()

    candidates = []
    if env_name:
        p = Path(env_name)
        candidates.append(p if p.is_absolute() else project_root / env_name)

    candidates += [
        project_root / ".env",
        project_root / ".env.mainnet",
        project_root / ".env.testnet",
    ]

    for c in candidates:
        if c.exists():
            load_dotenv(dotenv_path=c, override=False)
            os.environ.setdefault("ENV_FILE", c.name)
            print(f"[env] loaded: {c}")
            return str(c)

    # Fall back to process env only
    print("[env] WARNING: no .env file found; relying on existing process env")
    return None
