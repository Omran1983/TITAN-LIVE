from __future__ import annotations

import httpx
from types import SimpleNamespace
from tenacity import (
    Retrying, stop_after_attempt, wait_exponential, retry_if_exception_type
)

# Settings fallback to avoid import-time crashes
try:
    from .settings import get_settings  # expected to provide .http config
except Exception:
    def get_settings():
        return SimpleNamespace(http=SimpleNamespace(
            timeout_sec=15,
            max_connections=20,
            retries=5,
            backoff_min=0.5,
            backoff_max=8,
        ))

def _build_client() -> httpx.Client:
    cfg = get_settings().http
    return httpx.Client(
        timeout=cfg.timeout_sec,
        limits=httpx.Limits(
            max_keepalive_connections=cfg.max_connections,
            max_connections=cfg.max_connections,
        ),
        http2=True,
    )

class RetryPolicy:
    """Back-compat container with .stop and .wait like before."""
    def __init__(self, retries: int | None = None, backoff_min: float | None = None, backoff_max: float | None = None) -> None:
        cfg = get_settings().http
        r = retries if retries is not None else getattr(cfg, "retries", 3)
        bmin = backoff_min if backoff_min is not None else getattr(cfg, "backoff_min", 0.5)
        bmax = backoff_max if backoff_max is not None else getattr(cfg, "backoff_max", 8)
        self.stop = stop_after_attempt(r)
        self.wait = wait_exponential(min=bmin, max=bmax)

class HttpClient:
    def __init__(self) -> None:
        self.client = _build_client()
        pol = RetryPolicy()
        self._retry = Retrying(
            stop=pol.stop,
            wait=pol.wait,
            retry=retry_if_exception_type(
                (httpx.ReadTimeout, httpx.ConnectError, httpx.RemoteProtocolError)
            ),
            reraise=True,
        )

    def get(self, url: str, **kwargs) -> httpx.Response:
        for attempt in self._retry:
            with attempt:
                return self.client.get(url, **kwargs)

    def post(self, url: str, **kwargs) -> httpx.Response:
        for attempt in self._retry:
            with attempt:
                return self.client.post(url, **kwargs)

    def close(self) -> None:
        self.client.close()
