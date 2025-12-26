import requests
from logging_config import log

class PriceOracle:
    """
    The 'Truth Source'. Checks prices across multiple sources to prevent bad data.
    """
    def __init__(self):
        self.sources = {
            "mexc": "https://api.mexc.com/api/v3/ticker/price?symbol={symbol}",
            # "coingecko": "https://api.coingecko.com/api/v3/simple/price?ids={id}&vs_currencies=usd" 
            # CoinGecko is rate limited/requires IDs. We use MEXC as a secondary exchange source for simplicity.
        }

    def check_integrity(self, symbol: str, primary_price: float) -> bool:
        """
        Verifies if the primary price (Binance) is close to the secondary source.
        Returns True if SAFE, False if ANOMALY.
        """
        # Symbol mapping (Binance uses BTCUSDT, MEXC uses BTCUSDT)
        
        try:
            mexc_url = self.sources["mexc"].format(symbol=symbol)
            resp = requests.get(mexc_url, timeout=5)
            data = resp.json()
            secondary_price = float(data['price'])
            
            diff = abs(primary_price - secondary_price)
            pct_diff = (diff / primary_price) * 100
            
            if pct_diff > 0.5: # 0.5% deviation is HUGE for arbitrage.
                log.error(f"DATA ANOMALY: {symbol} Binance={primary_price}, MEXC={secondary_price} (Diff: {pct_diff:.2f}%)")
                return False
                
            return True
            
        except Exception as e:
            log.warning(f"Oracle check failed (Network Error): {e}. Proceeding with caution.")
            return True # Fail open (allow trading) if secondary source is down, or False to be paranoid.
