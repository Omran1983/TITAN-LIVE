from __future__ import annotations
from loguru import logger
from pathlib import Path
from .settings import get_settings

def init_logging(reset: bool = True, json_rotation: str = "50 MB") -> None:
    cfg = get_settings()
    if reset:
        logger.remove()
    # Console (human)
    if cfg.logging.human_console:
        logger.add(lambda msg: print(msg, end=""), level=cfg.logging.level)
    # JSON file
    json_path = Path(cfg.logging.json_file)
    json_path.parent.mkdir(parents=True, exist_ok=True)
    logger.add(
        json_path,
        level=cfg.logging.level,
        rotation=json_rotation,
        enqueue=True,
        serialize=True,
        backtrace=False,
        diagnose=False
    )
    logger.bind(app=cfg.app.name, env=cfg.app.env).info("loguru initialized")
