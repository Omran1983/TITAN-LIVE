from aogrl_ops_pack import get_settings, init_logging, HttpClient, CacheManager, now_tz
from loguru import logger

def main():
    cfg = get_settings()
    init_logging()
    logger.info(f"Start demo at {now_tz()} env={cfg.app.env}")
    cache = CacheManager()
    cli = HttpClient()
    url = "https://api.binance.com/api/v3/time"
    cached = cache.get(url)
    if cached:
        logger.info("cache hit")
        print(cached)
        return
    try:
        r = cli.get(url)
        r.raise_for_status()
        data = r.json()
        cache.set(url, data, expire=30)
        print(data)
    finally:
        cli.close()

if __name__ == "__main__":
    main()
