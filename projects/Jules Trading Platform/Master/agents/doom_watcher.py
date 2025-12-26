import asyncio
from data.binance_client import BinanceDataClient
from logging_config import log
from .ollama_client import OllamaClient

class DoomWatcher:
    """
    The 'Paranoid' Agent. 
    Monitors Critical System Health factors like Stablecoin Pegs.
    """
    def __init__(self, data_client: BinanceDataClient):
        self.data_client = data_client
        self.ollama = OllamaClient()
        self.is_doom_mode = False

    async def check_peg(self):
        """
        Checks USDT/USDC prices. If significant de-peg, triggers ALARM.
        """
        try:
            # We check the price of USDCUSDT. It should be ~1.0000
            # If it drops to 0.95, it means one of them is failing.
            # Ideally we check USDT/USD (Fiat) but on crypto-only exchange, we check stable pairs.
            ticker = await self.data_client.async_client.get_symbol_ticker(symbol="USDCUSDT")
            price = float(ticker['price'])
            
            # Hard Rule: De-peg detection
            if price < 0.98 or price > 1.02:
                log.warning(f"DOOM WATCHER: Stablecoin Peg De-stablized! USDC/USDT = {price}")
                
                # Ask AI for an opinion (just to be sure it's not a known flash event)
                analysis = self.ollama.generate(
                    prompt=f"USDC/USDT is trading at {price}. Is this a critical de-peg event requiring emergency exit?",
                    system_prompt="You are a risk management AI. Answer YES or NO with reason."
                )
                log.info(f"Doom Watcher AI Opinion: {analysis}")
                
                # If critical, we would set self.is_doom_mode = True
                
            else:
                # log.debug(f"Doom Watcher: Peg Stable ({price})")
                pass

        except Exception as e:
            log.error(f"Doom Watcher Check Failed: {e}")

    async def run_loop(self):
        """Standard visual loop"""
        log.info("Doom Watcher active.")
        while True:
            await self.check_peg()
            await asyncio.sleep(60) # Check every minute
