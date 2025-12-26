from datetime import datetime, timedelta, timezone
from infra.binance_client import spot
from core.config import settings
from utils.trade_logger import upsert_fills, build_fifo_pnl

def main():
    symbol = settings.SYMBOL
    # Pull last 7 days; adjust if you need more history
    start = int((datetime.now(timezone.utc) - timedelta(days=7)).timestamp() * 1000)
    trades = spot.my_trades(symbol=symbol, startTime=start)
    upsert_fills(trades)
    build_fifo_pnl()
    print(f"Synced fills for {symbol}: {len(trades)} rows. P&L updated.")

if __name__ == "__main__":
    main()
