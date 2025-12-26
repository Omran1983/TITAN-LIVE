from __future__ import annotations
from diskcache import Cache
from pathlib import Path
from .settings import get_settings

class CacheManager:
    def __init__(self):
        cfg = get_settings().cache
        p = Path(cfg.path)
        p.mkdir(parents=True, exist_ok=True)
        self.cache = Cache(p)

    def get(self, key):
        return self.cache.get(key)

    def set(self, key, value, expire: int | None = None):
        ttl = expire if expire is not None else get_settings().cache.ttl_sec_default
        self.cache.set(key, value, expire=ttl)

    def memoize(self, timeout: int | None = None):
        ttl = timeout if timeout is not None else get_settings().cache.ttl_sec_default
        return self.cache.memoize(expire=ttl)
